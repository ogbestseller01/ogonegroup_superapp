<?php

namespace App\Http\Controllers\Api;

use App\Models\DeviceUserMap;
use App\Models\UserDeviceToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DeviceTokenController extends BaseApiController
{
    /**
     * PUBLIC — POST /api/v1/device-token
     *
     * Called by the super app (anonymous) and by mini apps (with Sanctum).
     * No auth required, so the super app can register at boot.
     *
     * Body:
     *   fcm_device_token : string (required)
     *   platform         : "android" | "ios" (required)
     *   app              : "og_one_super" | "fundi" | "nearby" (optional, default "og_one_super")
     *   device_id        : string (optional, strongly recommended — stable per install)
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'fcm_device_token' => 'required|string|max:512',
            'platform'         => 'required|string|in:android,ios',
            'app'              => 'nullable|string|in:og_one_super,fundi,nearby',
            'device_id'        => 'nullable|string|max:128',
        ]);

        $app  = $data['app'] ?? UserDeviceToken::APP_SUPER;
        $user = $request->user();

        try {
            // Anonymous super app → try to resolve user via device_id map
            if (!$user && !empty($data['device_id'])) {
                $map  = DeviceUserMap::where('device_id', $data['device_id'])->first();
                $user = $map?->user;
            }

            UserDeviceToken::updateOrCreate(
                ['token' => $data['fcm_device_token'], 'app' => $app],
                [
                    'user_id'      => $user?->id,
                    'platform'     => $data['platform'],
                    'device_id'    => $data['device_id'] ?? null,
                    'last_seen_at' => now(),
                ]
            );

            if ($user && $app === UserDeviceToken::APP_SUPER) {
                $user->forceFill(['fcm_device_token' => $data['fcm_device_token']])->save();
            }

            return $this->successResponse(
                [
                    'app'         => $app,
                    'platform'    => $data['platform'],
                    'linked_user' => $user?->id,
                ],
                'Device token registered.'
            );
        } catch (\Throwable $e) {
            Log::error('DeviceTokenController@store failed', [
                'error'   => $e->getMessage(),
                'app'     => $app,
                'user_id' => $user?->id,
            ]);
            return $this->errorResponse('Could not register device token.', 500);
        }
    }

    /**
     * PUBLIC — DELETE /api/v1/device-token
     * Body: fcm_device_token (required), app (optional)
     */
    public function destroy(Request $request)
    {
        $data = $request->validate([
            'fcm_device_token' => 'required|string|max:512',
            'app'              => 'nullable|string|in:og_one_super,fundi,nearby',
        ]);

        $app = $data['app'] ?? UserDeviceToken::APP_SUPER;

        UserDeviceToken::where('token', $data['fcm_device_token'])
            ->where('app', $app)
            ->delete();

        $user = $request->user();
        if ($user && $user->fcm_device_token === $data['fcm_device_token']) {
            $user->forceFill(['fcm_device_token' => null])->save();
        }

        return $this->successResponse(null, 'Device token removed.');
    }

    /**
     * AUTH — POST /api/v1/auth/device-token/link
     * Called by mini apps right after login so anonymous super-app tokens
     * get associated with this user.
     */
    public function link(Request $request)
    {
        $data = $request->validate([
            'device_id' => 'required|string|max:128',
        ]);

        $user = $request->user();

        DeviceUserMap::updateOrCreate(
            ['device_id' => $data['device_id']],
            ['user_id'   => $user->id]
        );

        // Attach any anonymous super-app token for this device to the user
        UserDeviceToken::where('device_id', $data['device_id'])
            ->whereNull('user_id')
            ->update(['user_id' => $user->id]);

        return $this->successResponse(null, 'Device linked to user.');
    }
}