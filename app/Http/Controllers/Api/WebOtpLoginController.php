<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use App\Models\Otp;
use App\Models\FailedLoginAttempt;
use App\Models\UserSession;
use App\Services\OtpDeliveryService;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Carbon\Carbon;

class WebOtpLoginController extends BaseApiController
{
    use Auditable;

    private const ALLOWED_ROLES = [
        'ADMINISTRATOR',
        'MANAGER',
        'MONITORING_OFFICER',
        'FINANCE',
    ];

    /**
     * Normalize phone number - remove +, spaces, dashes, parentheses, dots
     */
    private function normalizePhoneNumber(string $phone): string
    {
        // Remove all non-numeric characters
        return preg_replace('/[^0-9]/', '', $phone);
    }

    /**
     * Find user by email or normalized phone
     */
    private function findUserByIdentifier(string $identifier): ?User
    {
        // First try as email
        $user = User::where('email', $identifier)->first();
        
        if ($user) {
            return $user;
        }

        // Try as phone - normalize both the search term and stored phone
        $normalizedIdentifier = $this->normalizePhoneNumber($identifier);
        
        // Get all users with phone numbers
        $users = User::whereNotNull('phone')->get();
        
        foreach ($users as $user) {
            $normalizedPhone = $this->normalizePhoneNumber($user->phone);
            if ($normalizedPhone === $normalizedIdentifier) {
                return $user;
            }
        }

        return null;
    }

    /**
     * Step 1: Validate credentials + role → send OTP via SMS
     * POST /api/v1/auth/web-otp/request
     */
    public function requestOtp(Request $request, OtpDeliveryService $otpDelivery)
    {
        $this->ensureNotRateLimited('web-otp-request:' . $request->ip(), 5, 60);

        $request->validate([
            'email'    => 'required|string',
            'password' => 'required|string',
        ]);

        $login = $request->email;
        
        // Use the improved finder with phone normalization
        $user = $this->findUserByIdentifier($login);

        if ($user && $user->locked_until && $user->locked_until->isFuture()) {
            $minutes = now()->diffInMinutes($user->locked_until) + 1;
            return $this->errorResponse("Account temporarily locked. Try again in {$minutes} minute(s).", 429);
        }

        if (!$user || !Hash::check($request->password, $user->password)) {
            FailedLoginAttempt::record($login, $request->ip());

            if ($user) {
                $failures = FailedLoginAttempt::where('login', $login)
                    ->where('created_at', '>', now()->subMinutes(30))
                    ->count();

                if ($failures >= 5) {
                    $user->update(['locked_until' => now()->addMinutes(30)]);
                }
            }

            $this->logAudit('web_otp_login_failed', 'auth', 'user', "Failed web OTP login for: {$login}");
            return $this->unauthorized('Invalid credentials.');
        }

        if ($user->locked_until) {
            $user->update(['locked_until' => null]);
        }

        if (is_null($user->email_verified_at)) {
            return $this->forbidden('Please verify your email first.');
        }

        if (!$user->is_active || $user->status !== 'active') {
            return $this->forbidden('Account is not active.');
        }

        $userRoles = $user->getRoleNames()->toArray();
        $hasAllowedRole = !empty(array_intersect($userRoles, self::ALLOWED_ROLES));

        if (!$hasAllowedRole) {
            $this->logAudit('web_otp_login_denied', 'auth', 'user', "Role not allowed for OTP login: {$user->email}");
            return $this->forbidden('OTP login is only available for authorized staff roles.');
        }

        if (empty($user->phone)) {
            return $this->errorResponse('No phone number registered. Contact admin.', 422);
        }

        $recent = Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_LOGIN_OTP)
            ->where('created_at', '>', now()->subMinutes(1))
            ->exists();

        if ($recent) {
            return $this->errorResponse('Please wait at least 1 minute before requesting another OTP.', 429);
        }

        Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_LOGIN_OTP)
            ->delete();

        $plainOtp = Otp::generateOtp();

        $otp = Otp::create([
            'email'      => $user->email,
            'otp'        => Hash::make($plainOtp),
            'type'       => Otp::TYPE_LOGIN_OTP,
            'name'       => $user->name,
            'expires_at' => now()->addMinutes(5),
            'is_used'    => false,
            'attempts'   => 0,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $otp->plain_otp = $plainOtp;

        $delivery = $otpDelivery->deliver($user, $otp);

        if (($delivery['channel'] ?? '') === 'failed') {
            return $this->serverError('Failed to send OTP. Please try again later.');
        }

        $this->logAudit('web_otp_requested', 'auth', 'user', "Login OTP sent to {$user->email}");

        return $this->successResponse([
            'email'       => $user->email,
            'otp_channel' => $delivery['channel'] ?? 'sms',
            'sent_to'     => $delivery['otp_sent_to'] ?? $user->phone,
            'expires_in'  => 5,
        ], 'OTP sent successfully. Please check your SMS.');
    }

    /**
     * Step 2: Verify OTP → issue Sanctum token
     * POST /api/v1/auth/web-otp/verify
     */
    public function verifyOtp(Request $request)
    {
        $this->ensureNotRateLimited('web-otp-verify:' . $request->ip(), 8, 60);

        $request->validate([
            'email' => 'required|email',
            'otp'   => 'required|string|size:6',
        ]);

        $otpRecord = Otp::where('email', $request->email)
            ->where('type', Otp::TYPE_LOGIN_OTP)
            ->where('is_used', false)
            ->where('expires_at', '>', now())
            ->latest()
            ->first();

        if (!$otpRecord || !Hash::check($request->otp, $otpRecord->otp)) {
            if ($otpRecord) {
                $otpRecord->increment('attempts');
                if ($otpRecord->attempts >= 5) {
                    $otpRecord->update(['is_used' => true]);
                }
            }
            return $this->errorResponse('Invalid or expired OTP code.', 422);
        }

        $otpRecord->update(['is_used' => true]);

        $user = User::where('email', $request->email)->firstOrFail();

        $userRoles = $user->getRoleNames()->toArray();
        if (empty(array_intersect($userRoles, self::ALLOWED_ROLES))) {
            return $this->forbidden('Unauthorized role.');
        }

        if (!$user->is_active || $user->status !== 'active') {
            return $this->forbidden('Account is not active.');
        }

        $token = $user->createToken('web_otp_auth_token')->plainTextToken;
        $this->createSession($user, $request, $token);

        $user->update([
            'last_login_at' => now(),
            'last_login_ip' => $request->ip(),
        ]);

        $this->logAudit('web_otp_login_success', 'auth', 'user', "User logged in via OTP: {$user->email}");

        return $this->successResponse([
            'user'  => $user->only(['id', 'name', 'email', 'phone', 'locale', 'fcm_device_token']),
            'roles' => $user->getRoleNames(),
            'token' => $token,
        ], 'Login successful.');
    }

    /**
     * Resend OTP
     * POST /api/v1/auth/web-otp/resend
     */
    public function resendOtp(Request $request, OtpDeliveryService $otpDelivery)
    {
        $this->ensureNotRateLimited('web-otp-resend:' . $request->ip(), 3, 60);

        $request->validate([
            'email' => 'required|email|exists:users,email',
        ]);

        $user = User::where('email', $request->email)->firstOrFail();

        $userRoles = $user->getRoleNames()->toArray();
        if (empty(array_intersect($userRoles, self::ALLOWED_ROLES))) {
            return $this->forbidden('OTP login is only available for authorized staff roles.');
        }

        $recent = Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_LOGIN_OTP)
            ->where('created_at', '>', now()->subMinutes(1))
            ->exists();

        if ($recent) {
            return $this->errorResponse('Please wait at least 1 minute before requesting another OTP.', 429);
        }

        Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_LOGIN_OTP)
            ->delete();

        $plainOtp = Otp::generateOtp();

        $otp = Otp::create([
            'email'      => $user->email,
            'otp'        => Hash::make($plainOtp),
            'type'       => Otp::TYPE_LOGIN_OTP,
            'name'       => $user->name,
            'expires_at' => now()->addMinutes(5),
            'is_used'    => false,
            'attempts'   => 0,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $otp->plain_otp = $plainOtp;
        $delivery = $otpDelivery->deliver($user, $otp);

        return $this->successResponse([
            'email'       => $user->email,
            'otp_channel' => $delivery['channel'] ?? 'sms',
            'sent_to'     => $delivery['otp_sent_to'] ?? $user->phone,
        ], 'OTP resent successfully.');
    }

    // ─── Helpers ───────────────────────────────

    private function createSession(User $user, Request $request, string $token): void
    {
        $tokenId = explode('|', $token)[0] ?? null;
        if (!$tokenId) return;

        UserSession::create([
            'user_id'       => $user->id,
            'token'         => $tokenId,
            'ip_address'    => $request->ip(),
            'user_agent'    => $request->userAgent(),
            'device_name'   => $this->getDeviceName($request),
            'last_activity' => now(),
            'expires_at'    => now()->addDays(30),
            'is_active'     => true,
        ]);
    }

    private function getDeviceName(Request $request): string
    {
        $ua = $request->userAgent() ?? '';
        if (str_contains($ua, 'Postman'))  return 'Postman';
        if (str_contains($ua, 'Flutter'))  return 'Mobile App';
        if (str_contains($ua, 'Mozilla'))  return 'Web Browser';
        return 'Unknown';
    }

    private function ensureNotRateLimited(string $key, int $maxAttempts, int $decaySeconds): void
    {
        if (RateLimiter::tooManyAttempts($key, $maxAttempts)) {
            $seconds = RateLimiter::availableIn($key);
            abort(429, "Too many attempts. Please try again in {$seconds} seconds.");
        }
        RateLimiter::hit($key, $decaySeconds);
    }
}