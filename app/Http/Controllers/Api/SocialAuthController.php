<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use App\Models\UserSession;
use App\Services\SocialTokenVerifier;
use App\Traits\Auditable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;

class SocialAuthController extends BaseApiController
{
    use Auditable;

    // POST /api/v1/auth/google   { id_token, fcm_token? }
    public function google(Request $request, SocialTokenVerifier $verifier): JsonResponse
    {
        $this->throttle('social-google:' . $request->ip());

        $request->validate([
            'id_token'  => 'required|string',
            'fcm_token' => 'nullable|string|max:4096',
        ]);

        try {
            $info = $verifier->google($request->id_token);
        } catch (\Throwable $e) {
            Log::warning('Google token rejected', ['error' => $e->getMessage()]);
            return $this->unauthorized('Invalid Google token.');
        }

        return $this->loginOrRegister(
            $request,
            'google_id',
            $info['sub'],
            $info['email'],
            $info['email_verified'],
            $info['name'] ?? 'Google User',
            'google'
        );
    }

    // POST /api/v1/auth/apple  { identity_token, nonce?, name?, fcm_token? }
    // Apple only returns name + email on the FIRST authorization, so the app
    // forwards `name`; email is read from the verified token.
    public function apple(Request $request, SocialTokenVerifier $verifier): JsonResponse
    {
        $this->throttle('social-apple:' . $request->ip());

        $request->validate([
            'identity_token' => 'required|string',
            'nonce'          => 'nullable|string|max:255',
            'name'           => 'nullable|string|max:255',
            'fcm_token'      => 'nullable|string|max:4096',
        ]);

        try {
            $info = $verifier->apple($request->identity_token, $request->nonce);
        } catch (\Throwable $e) {
            Log::warning('Apple token rejected', ['error' => $e->getMessage()]);
            return $this->unauthorized('Invalid Apple token.');
        }

        return $this->loginOrRegister(
            $request,
            'apple_id',
            $info['sub'],
            $info['email'],
            $info['email_verified'],
            trim((string) $request->input('name')) ?: 'Apple User',
            'apple'
        );
    }

    // ─────────────────────────────────────────────────────────

    private function loginOrRegister(
        Request $request,
        string $providerColumn,
        string $providerId,
        ?string $email,
        bool $emailVerified,
        string $name,
        string $provider
    ): JsonResponse {
        try {
            DB::beginTransaction();

            // 1) Provider ID is the stable identity (Apple email can change / be hidden)
            $user = User::where($providerColumn, $providerId)->first();

            // 2) Link to an existing account by email, only when the provider verified it
            if (!$user && $email && $emailVerified) {
                $user = User::where('email', $email)->first();
                if ($user) {
                    $user->forceFill([$providerColumn => $providerId])->save();
                }
            }

            // 3) Brand-new customer
            if (!$user) {
                $user = new User();
                $user->forceFill([
                    'name'              => $name,
                    'email'             => $email,
                    $providerColumn     => $providerId,
                    'password'          => Hash::make(Str::random(40)),
                    'email_verified_at' => $email && $emailVerified ? now() : null,
                    'status'            => 'active',
                    'is_active'         => true,
                    'locale'            => 'en',
                ])->save();
                $user->assignRole('CUSTOMER');
                $this->logAudit("register_{$provider}", 'auth', $user->id, "Customer registered via {$provider}");
            }

            // Technicians must pass admin approval — never auto-activate them here
            if ($user->hasRole('FUNDI')) {
                DB::commit();
                if (!$user->is_active || $user->status !== 'active') {
                    return $this->forbidden('Your technician account requires admin approval.');
                }
            } else {
                if (!$user->is_active || $user->status !== 'active') {
                    // suspended / deactivated by admin must stay blocked
                    if (in_array($user->status, ['suspended', 'deactivated', 'banned'], true)) {
                        DB::commit();
                        return $this->forbidden('Account is not active.');
                    }
                    $user->forceFill(['status' => 'active', 'is_active' => true])->save();
                }
                if (!$user->email_verified_at && $email && $emailVerified) {
                    $user->forceFill(['email_verified_at' => now()])->save();
                }
                DB::commit();
            }

            $token = $user->createToken('auth_token')->plainTextToken;
            $this->createSession($user, $request, $token);

            $user->forceFill([
                'last_login_at' => now(),
                'last_login_ip' => $request->ip(),
            ]);
            if ($request->filled('fcm_token')) {
                $user->fcm_device_token = $request->fcm_token;
            }
            $user->save();

            $this->logAudit("login_{$provider}", 'auth', $user->id, "Logged in via {$provider}");

            return $this->successResponse([
                'user'  => $user->only(['id', 'name', 'email', 'phone', 'locale', 'fcm_device_token']),
                'roles' => $user->getRoleNames(),
                'token' => $token,
            ], ucfirst($provider) . ' login successful.');
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error("{$provider} login failed", ['error' => $e->getMessage()]);
            return $this->serverError(ucfirst($provider) . ' sign-in failed. Please try again.');
        }
    }

    private function createSession(User $user, Request $request, string $token): void
    {
        $tokenId = explode('|', $token)[0] ?? null;
        if (!$tokenId) {
            return;
        }

        UserSession::create([
            'user_id'       => $user->id,
            'token'         => $tokenId,
            'ip_address'    => $request->ip(),
            'user_agent'    => $request->userAgent(),
            'device_name'   => str_contains((string) $request->userAgent(), 'Dart') ? 'Mobile App' : 'Unknown',
            'last_activity' => now(),
            'expires_at'    => now()->addDays(30),
            'is_active'     => true,
        ]);
    }

    private function throttle(string $key): void
    {
        if (RateLimiter::tooManyAttempts($key, 10)) {
            abort(429, 'Too many attempts. Please try again in ' . RateLimiter::availableIn($key) . ' seconds.');
        }
        RateLimiter::hit($key, 60);
    }
}