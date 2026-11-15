<?php
namespace App\Http\Controllers\Api;

use App\Models\UserSession;
use App\Traits\Auditable;
use Illuminate\Http\Request;

class UserSessionController extends BaseApiController
{
    use Auditable;

    public function index(Request $request)
    {
        $currentTokenId = $request->user()->currentAccessToken()->id;

        $sessions = $request->user()
            ->sessions()
            ->orderBy('last_activity', 'desc')
            ->get()
            ->map(fn($session) => [
                'id'            => $session->id,
                'ip_address'    => $session->ip_address,
                'device_name'   => $session->device_name,
                'last_activity' => $session->last_activity,
                'is_active'     => $session->is_active,
                'is_current'    => (int) $session->token === (int) $currentTokenId, // ✅ fixed
            ]);

        return $this->successResponse($sessions, __('messages.sessions_retrieved'));
    }

    public function destroy(Request $request, $id)
    {
        $session = UserSession::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        // Delete the actual Sanctum token too
        $request->user()->tokens()->where('id', $session->token)->delete();
        $session->delete();

        $this->logAudit('revoke_session', 'session', $id, 'Revoked a session');

        return $this->successResponse(null, __('messages.session_revoked'));
    }

    public function destroyOthers(Request $request)
    {
        $user           = $request->user();
        $currentTokenId = $user->currentAccessToken()->id;

        // Get token IDs to delete
        $otherTokenIds = UserSession::where('user_id', $user->id)
            ->where('token', '!=', $currentTokenId)
            ->pluck('token');

        // Delete Sanctum tokens
        $user->tokens()->whereIn('id', $otherTokenIds)->delete();

        // Delete session rows
        $count = UserSession::where('user_id', $user->id)
            ->where('token', '!=', $currentTokenId)
            ->delete();

        $this->logAudit('revoke_other_sessions', 'session', null, "Revoked {$count} other sessions");

        return $this->successResponse(null, __('messages.other_sessions_revoked', ['count' => $count]));
    }

    public function destroyAll(Request $request)
    {
        $user = $request->user();

        $user->tokens()->delete();
        UserSession::where('user_id', $user->id)->delete();

        $this->logAudit('revoke_all_sessions', 'session', null, 'Revoked all sessions');

        return $this->successResponse(null, __('messages.all_sessions_revoked'));
    }
}