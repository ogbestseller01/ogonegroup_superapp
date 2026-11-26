<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use App\Models\Otp;
use App\Models\FailedLoginAttempt;
use App\Models\RegistrationDraft;
use App\Models\UserSession;
use App\Models\Technician;
use App\Models\UserDeviceToken;
use App\Traits\Auditable;
use App\Services\OtpDeliveryService;
use App\Services\GeocodingService;
use App\Services\LoginNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Google\Client as GoogleClient;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Spatie\Permission\Models\Role;

class AuthController extends BaseApiController
{
    use Auditable;

    /** Lifetime of the "remember me" token used for one-tap login. */
    private const REMEMBER_DAYS = 30;

    // ──────────────────────────────────────────────
    // REGISTRATION
    // ──────────────────────────────────────────────

    /**
     * Customer registration.
     * An earlier UNVERIFIED customer sign-up with the same email/phone is
     * reused (details updated, fresh OTP sent) so users are never locked out
     * of their own email/phone after an abandoned attempt.
     */
    public function register(Request $request, OtpDeliveryService $otpDelivery)
    {
        $this->ensureNotRateLimited('register:' . $request->ip(), 10, 60);

        // Normalise BEFORE validating so "0712…", "+255712…" and "255712…"
        // are all stored (and later matched) as "255712…".
        $request->merge([
            'email' => strtolower(trim((string) $request->input('email', ''))),
            'phone' => $this->normalizePhone($request->input('phone')),
        ]);

        // Clear message for soft-deleted accounts (unique rule still counts them).
        if ($msg = $this->deletedAccountConflict($request->input('email'), $request->input('phone'))) {
            return $this->errorResponse($msg, 422);
        }

        $role = $request->input('role') ?: 'CUSTOMER';

        $abandoned = $role === 'CUSTOMER'
            ? $this->findAbandonedCustomer($request->input('email'), $request->input('phone'))
            : null;

        // Same number typed in another format.
        if (!$abandoned
            && $request->filled('phone')
            && $this->findUserByIdentifier((string) $request->input('phone'))) {
            return $this->errorResponse(
                'This phone number is already registered. Please log in or use a different number.',
                422
            );
        }

        $data = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => ['required', 'email', Rule::unique('users', 'email')->ignore($abandoned?->id)],
            'password' => ['required', 'confirmed', Password::min(8)->letters()->mixedCase()->numbers()],
            'phone'    => ['required', 'string', 'max:20', 'regex:/^\d{9,15}$/',
                           Rule::unique('users', 'phone')->ignore($abandoned?->id)],
            'role'     => 'nullable|string|in:CUSTOMER,FUNDI',
        ]);

        DB::beginTransaction();
        try {
            if ($abandoned) {
                $abandoned->forceFill([
                    'name'     => $data['name'],
                    'email'    => $data['email'],
                    'phone'    => $data['phone'],
                    'password' => Hash::make($data['password']),
                ])->save();

                $user = $abandoned;
            } else {
                $user = User::create([
                    'name'              => $data['name'],
                    'email'             => $data['email'],
                    'phone'             => $data['phone'],
                    'password'          => Hash::make($data['password']),
                    'status'            => 'pending',
                    'is_active'         => false,
                    'email_verified_at' => null,
                ]);

                $user->assignRole($data['role'] ?? 'CUSTOMER');
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Register failed', ['error' => $e->getMessage()]);
            return $this->serverError('Registration failed. Please try again.');
        }

        // OTP delivery must never break or hang the registration.
        try {
            $delivery = $this->issueVerificationOtp($user, $request, $otpDelivery);
        } catch (\Throwable $e) {
            Log::error('Register OTP delivery failed', [
                'user_id' => $user->id,
                'error'   => $e->getMessage(),
            ]);
            $delivery = ['channel' => 'failed', 'success' => false];
        }

        $channel = $delivery['channel'] ?? 'failed';
        $sent    = $channel !== 'failed' && ($delivery['success'] ?? true) !== false;

        return $this->created([
            'user'        => $user->only(['id', 'name', 'email', 'phone']),
            'otp_sent'    => $sent,
            'otp_channel' => $sent ? $channel : 'none',
            'sent_to'     => $sent ? ($channel === 'sms' ? $user->phone : $user->email) : null,
        ], $sent
            ? 'Registration successful. Please enter the OTP sent to verify your account.'
            : 'Account created, but we could not send the code. Tap "Resend code".');
    }

    public function registerFundi(Request $request, GeocodingService $geocoder, OtpDeliveryService $otpDelivery)
    {
        $data = $request->validate([
            'name'          => 'required|string|max:255',
            'email'         => 'required|email|unique:users,email',
            'password'      => ['required', 'confirmed', Password::min(8)->letters()->mixedCase()->numbers()],
            'phone'         => 'nullable|string|max:20|unique:users,phone',
            'bio'           => 'nullable|string',
            'nida'          => 'required|string|size:20|unique:technicians,nida',
            'experience'    => 'nullable|integer|min:0',
            'hourly_rate'   => 'nullable|numeric|min:0|max:999999.99',
            'area'          => 'required|string|max:255',
            'latitude'      => 'nullable|numeric|between:-90,90',
            'longitude'     => 'nullable|numeric|between:-180,180',
            'service_ids'   => 'required|array|min:1',
            'service_ids.*' => 'exists:services,id',
            'profile_photo' => 'required|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        $coords = $this->validateAndGeocodeArea(
            $data['area'],
            $data['latitude'] ?? null,
            $data['longitude'] ?? null,
            $geocoder
        );

        DB::beginTransaction();
        try {
            $role = Role::where('name', 'FUNDI')->firstOrFail();

            $user = User::create([
                'name'      => $data['name'],
                'email'     => $data['email'],
                'password'  => Hash::make($data['password']),
                'phone'     => $data['phone'] ?? null,
                'status'    => 'pending',
                'is_active' => false,
                'locale'    => 'en',
            ]);

            $user->assignRole($role);

            $technicianData = [
                'user_id'             => $user->id,
                'bio'                 => $data['bio'] ?? null,
                'nida'                => $data['nida'],
                'experience'          => $data['experience'] ?? 0,
                'hourly_rate'         => $data['hourly_rate'] ?? null,
                'area'                => $data['area'],
                'latitude'            => $coords['lat'],
                'longitude'           => $coords['lng'],
                'verified'            => false,
                'verification_status' => 'pending',
                'is_online'           => false,
            ];

            if ($request->hasFile('profile_photo')) {
                $technicianData['profile_photo'] = $request->file('profile_photo')->store('technicians', 'public');
            }

            $technician = Technician::create($technicianData);
            $technician->services()->sync($data['service_ids']);

            $delivery = $this->issueVerificationOtp($user, $request, $otpDelivery);

            DB::commit();

            $this->logAudit('register_fundi', 'auth', $user->id, "Fundi registered: {$user->email}");

            return $this->created([
                'email'       => $user->email,
                'otp_channel' => $delivery['channel'] ?? 'email',
            ], 'Fundi registered. Verify your email/phone and wait for admin approval.');
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Fundi registration failed', ['error' => $e->getMessage()]);
            return $this->serverError('Registration failed. Please try again.');
        }
    }

    // ──────────────────────────────────────────────
    // OTP
    // ──────────────────────────────────────────────

    public function resendOtp(Request $request, OtpDeliveryService $otpDelivery)
    {
        $this->ensureNotRateLimited('resend-otp:' . $request->ip() . ':' . $this->rateKey($request), 3, 60);

        $request->validate([
            'identifier' => 'required_without:email|string',
            'email'      => 'required_without:identifier|string',
        ]);

        $identifier = $request->input('identifier', $request->input('email'));
        $user = $this->findUserByIdentifier((string) $identifier);

        // Same response whether or not the user exists (no account enumeration)
        if (!$user) {
            return $this->successResponse(null, 'If the account exists, a new OTP was sent.');
        }

        // Check both email and phone verified status
        if ($user->email_verified_at || $user->phone_verified_at) {
            return $this->errorResponse('Account is already verified.', 422);
        }

        $recent = $this->verificationOtps($user)
            ->where('created_at', '>', now()->subMinute())
            ->exists();

        if ($recent) {
            return $this->errorResponse('Please wait at least 1 minute before requesting another OTP.', 429);
        }

        $delivery = $this->issueVerificationOtp($user, $request, $otpDelivery);

        $this->logAudit('resend_otp', 'auth', $user->id, 'OTP resent');

        return $this->successResponse([
            'otp_channel' => $delivery['channel'] ?? 'sms',
        ], 'OTP resent successfully.');
    }

    public function verifyOtp(Request $request)
    {
        $this->ensureNotRateLimited('verify-otp:' . $request->ip() . ':' . $this->rateKey($request), 10, 60);

        $request->validate([
            'identifier' => 'required_without:email|string',
            'email'      => 'required_without:identifier|string',
            'otp'        => 'required|string|size:6',
            'fcm_token'  => 'nullable|string|max:255',
        ]);

        $identifier = $request->input('identifier', $request->input('email'));

        $user = $this->findUserByIdentifier((string) $identifier);
        if (!$user) {
            return $this->errorResponse('Invalid or expired OTP code.', 422);
        }

        $otpRecord = $this->verificationOtps($user)
            ->where('is_used', false)
            ->where('expires_at', '>', now())
            ->latest()
            ->first();

        if (!$otpRecord || !$this->otpMatches($request->otp, $otpRecord->otp)) {
            if ($otpRecord) {
                $otpRecord->increment('attempts');
                if ($otpRecord->attempts >= 5) {
                    $otpRecord->update(['is_used' => true]);
                }
            }
            return $this->errorResponse('Invalid or expired OTP code.', 422);
        }

        $otpRecord->update(['is_used' => true, 'attempts' => $otpRecord->attempts + 1]);

        $isFundi = $user->hasRole('FUNDI');

        // Detect if identifier was an email or phone and update the correct column
        $isEmail = filter_var($identifier, FILTER_VALIDATE_EMAIL) || $identifier === $user->email;

        $updateData = [
            'status'    => $isFundi ? 'pending' : 'active',
            'is_active' => !$isFundi,
        ];

        if ($isEmail) {
            $updateData['email_verified_at'] = now();
        } else {
            $updateData['phone_verified_at'] = now();
        }

        $user->update($updateData);

        // Persist FCM token arriving with verification
        if ($request->filled('fcm_token') && empty($user->fcm_device_token)) {
            $user->update(['fcm_device_token' => $request->fcm_token]);
        }

        $token = null;
        if (!$isFundi) {
            $token = $this->issueToken($user);
            $this->createSession($user, $request, $token);

            // Login detection: verification signs the customer in
            LoginNotificationService::dispatch($user, $request, 'otp');
        }

        return $this->successResponse([
            'user'  => $user->load('roles'),
            'token' => $token,
        ], $isFundi
            ? 'Verified. Please complete registration and wait for admin approval.'
            : 'Account verified and activated successfully.');
    }

    public function verifyToken(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
        ]);

        $otp = Otp::where('email', $request->email)
            ->where('token', $request->token)
            ->where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->where('is_used', false)
            ->where('expires_at', '>', now())
            ->latest()
            ->first();

        if (!$otp) {
            return view('emails.verify-result', [
                'success' => false,
                'message' => 'Invalid or expired verification link. Please request a new one.',
            ]);
        }

        $user = User::where('email', $request->email)->firstOrFail();

        if ($user->email_verified_at) {
            return view('emails.verify-result', [
                'success' => true,
                'message' => 'Your email is already verified. You can now log in.',
            ]);
        }

        $isFundi = $user->hasRole('FUNDI');

        $user->update([
            'email_verified_at' => now(),
            'status'            => $isFundi ? 'pending' : 'active',
            'is_active'         => !$isFundi,
        ]);

        $otp->update(['is_used' => true]);

        $this->logAudit('verify_email_token', 'auth', $user->id, "Email verified via token: {$user->email}");

        return view('emails.verify-result', [
            'success' => true,
            'message' => $isFundi
                ? 'Email verified. Please wait for admin approval.'
                : 'Your email has been successfully verified! You can now log in.',
        ]);
    }

    // ──────────────────────────────────────────────
    // LOGIN  (clear message for Google-linked accounts)
    // ──────────────────────────────────────────────

    public function login(Request $request)
    {
        // Broad per-IP ceiling (shared mobile-carrier IPs) + strict per IP+account limit.
        $this->ensureNotRateLimited('login-ip:' . $request->ip(), 120, 60);
        $this->ensureNotRateLimited('login:' . $request->ip() . ':' . $this->rateKey($request), 10, 60);

        $request->validate([
            'email'       => 'required|string',
            'password'    => 'required|string',
            'remember_me' => 'nullable|boolean',
        ]);

        $login = trim($request->email);
        $user  = $this->findUserByIdentifier($login);

        if ($user && $user->locked_until && $user->locked_until->isFuture()) {
            $minutes = now()->diffInMinutes($user->locked_until) + 1;
            return $this->errorResponse("Account temporarily locked. Try again in {$minutes} minute(s).", 429);
        }

        if (!$user || !Hash::check($request->password, $user->password)) {

            // Fundi who verified the phone but never finished the 6-step
            // registration has no user row yet: say so instead of
            // "Invalid credentials".
            if (!$user && $this->pendingDraftFor($login, (string) $request->password)) {
                return $this->errorResponse(
                    'Your fundi registration is not finished yet. Please continue the registration steps, '
                    . 'or start again with the same phone number.',
                    422
                );
            }

            // Google-linked account: the password may never have been set.
            // Give a helpful message instead of a generic "Invalid credentials".
            // These attempts are NOT counted toward the lockout.
            if ($user && !empty($user->google_id)) {
                $this->logAudit(
                    'login_failed_google_account',
                    'auth',
                    $user->id,
                    "Password login on Google-linked account: {$login}"
                );

                return $this->unauthorized(
                    'This account uses Google sign-in. Tap "Continue with Google", '
                    . 'or use "Forgot password" to create a password for email login.'
                );
            }

            FailedLoginAttempt::record($login, $request->ip());

            if ($user) {
                $failures = FailedLoginAttempt::where('login', $login)
                    ->where('created_at', '>', now()->subMinutes(30))
                    ->count();

                if ($failures >= 5) {
                    $user->update(['locked_until' => now()->addMinutes(30)]);
                    Log::warning('Account locked due to failed logins', ['user_id' => $user->id]);
                }
            }

            $this->logAudit('login_failed', 'auth', null, "Failed login for: {$login}");
            return $this->unauthorized('Invalid credentials.');
        }

        if ($user->locked_until) {
            $user->update(['locked_until' => null]);
        }

        // Allow login if EITHER email OR phone is verified
        if (is_null($user->email_verified_at) && is_null($user->phone_verified_at)) {
            return $this->forbidden('Please verify your account first.');
        }

        if (!$user->is_active || $user->status !== 'active') {
            return $this->forbidden('Account is not active.');
        }

        if ($user->hasRole('FUNDI')) {
            $technician = Technician::where('user_id', $user->id)->first();
            if (!$technician || !$technician->verified || $technician->verification_status !== 'approved') {
                return $this->forbidden('Your technician account is not verified. Please wait for admin approval.');
            }
        }

        $token = $this->issueToken($user);
        $this->createSession($user, $request, $token);

        $user->update([
            'last_login_at'     => now(),
            'last_login_ip'     => $request->ip(),
            'last_login_device' => LoginNotificationService::deviceFrom($request),
        ]);

        if ($request->filled('fcm_token')) {
            $this->storeFcmToken($user, $request->fcm_token);
        }

        $this->logAudit('login', 'auth', $user->id, 'User logged in: ' . ($user->email ?? $user->phone));

        $payload = [
            'user'  => $user->only(['id', 'name', 'email', 'phone', 'locale', 'fcm_device_token']),
            'roles' => $user->getRoleNames(),
            'token' => $token,
        ];

        // "Remember me": separate long-lived token used ONLY for one-tap login
        if ($request->boolean('remember_me')) {
            $payload['remember_token'] = $this->issueRememberToken($user);
        }

        // Login detection: history row + email (after the response is sent)
        LoginNotificationService::dispatch($user, $request, 'password');

        return $this->successResponse($payload, 'Login successful.');
    }

    // ──────────────────────────────────────────────
    // REMEMBER ME / ONE-TAP LOGIN
    // ──────────────────────────────────────────────

    /**
     * POST /v1/auth/quick-login   (Authorization: Bearer <remember_token>)
     * Exchanges the remembered token for a fresh session token.
     * The remember token is rotated (sliding 30 days).
     */
    public function quickLogin(Request $request)
    {
        $this->ensureNotRateLimited('quick-login:' . $request->ip(), 30, 60);

        $request->validate(['fcm_token' => 'nullable|string|max:255']);

        $user    = $request->user();
        $current = $user?->currentAccessToken();

        // Only a token minted by "remember me" may be used here.
        if (!$user || !$current || $current->name !== 'remember_token' || !$current->can('quick-login')) {
            return $this->unauthorized('Saved login is no longer valid. Please sign in again.');
        }

        if ($user->locked_until && $user->locked_until->isFuture()) {
            return $this->errorResponse('Account temporarily locked. Try again later.', 429);
        }

        if (!$user->is_active || $user->status !== 'active') {
            return $this->forbidden('Account is not active.');
        }

        if ($user->hasRole('FUNDI')) {
            $technician = Technician::where('user_id', $user->id)->first();
            if (!$technician || !$technician->verified || $technician->verification_status !== 'approved') {
                return $this->forbidden('Your technician account is not verified. Please wait for admin approval.');
            }
        }

        // Rotate: old remember token out, new one in
        $current->delete();
        $rememberToken = $this->issueRememberToken($user);

        $token = $this->issueToken($user);
        $this->createSession($user, $request, $token);

        $user->update([
            'last_login_at'     => now(),
            'last_login_ip'     => $request->ip(),
            'last_login_device' => LoginNotificationService::deviceFrom($request),
        ]);

        if ($request->filled('fcm_token')) {
            $this->storeFcmToken($user, $request->fcm_token);
        }

        $this->logAudit('quick_login', 'auth', $user->id, 'One-tap login: ' . ($user->email ?? $user->phone));

        LoginNotificationService::dispatch($user, $request, 'quick-login');

        return $this->successResponse([
            'user'           => $user->only(['id', 'name', 'email', 'phone', 'locale', 'fcm_device_token']),
            'roles'          => $user->getRoleNames(),
            'token'          => $token,
            'remember_token' => $rememberToken,
        ], 'Login successful.');
    }

    /** POST /v1/auth/quick-login/forget  ("Switch account": revoke the remember token). */
    public function forgetRemembered(Request $request)
    {
        $current = $request->user()?->currentAccessToken();

        if ($current && $current->name === 'remember_token') {
            $current->delete();
        }

        return $this->successResponse(null, 'Saved login removed.');
    }

    // ──────────────────────────────────────────────
    // LOGOUT & SESSIONS
    // ──────────────────────────────────────────────

    public function logout(Request $request)
    {
        $this->rejectRememberToken($request);

        $request->validate(['fcm_token' => 'nullable|string|max:255']);

        $user  = $request->user();
        $token = $user->currentAccessToken();

        UserSession::where('user_id', $user->id)
            ->where('token', $token->id)
            ->update(['is_active' => false]);

        // Stop pushes for this user on this device
        if ($request->filled('fcm_token')) {
            $this->releaseDeviceToken($request->fcm_token);
        }

        // Only the session token is deleted: the remember token (saved
        // account for one-tap login) is kept on a normal logout.
        $token->delete();

        $this->logAudit('logout', 'auth', $user->id, 'User logged out: ' . ($user->email ?? $user->phone));

        return $this->successResponse(null, 'Logged out.');
    }

    public function logoutAll(Request $request)
    {
        $this->rejectRememberToken($request);

        $user = $request->user();

        $user->tokens()->delete();
        UserSession::where('user_id', $user->id)->update(['is_active' => false]);

        // Disconnect FCM tokens associated with the user
        UserDeviceToken::where('user_id', $user->id)->delete();
        $user->forceFill(['fcm_device_token' => null])->save();

        $this->logAudit('logout_all', 'auth', $user->id, 'User logged out from all devices: ' . ($user->email ?? $user->phone));

        return $this->successResponse(null, 'Logged out from all devices.');
    }

    // ──────────────────────────────────────────────
    // PROFILE
    // ──────────────────────────────────────────────

    public function me(Request $request)
    {
        $this->rejectRememberToken($request);

        $user = $request->user()->load('technician.services');

        if ($user->technician) {
            $user->technician->makeVisible('nida');
        }

        $userData = $user->only(['id', 'name', 'email', 'phone', 'status', 'locale', 'fcm_device_token']);
        // Keeps the Google photo after an app restart / profile refresh.
        $userData['profile_photo'] = $user->google_avatar;

        return $this->successResponse([
            'user'       => $userData,
            'roles'      => $user->getRoleNames(),
            'technician' => $user->technician,
        ]);
    }

    public function updateProfile(Request $request)
    {
        $this->rejectRememberToken($request);

        $request->validate([
            'name'   => 'sometimes|string|max:255',
            'phone'  => 'nullable|string|max:20|unique:users,phone,' . $request->user()->id,
            'locale' => 'sometimes|string|in:en,sw',
        ]);

        $user = $request->user();
        $old  = $user->only(['name', 'phone', 'locale']);

        $user->update($request->only(['name', 'phone', 'locale']));

        $this->logAudit('update_profile', 'user', $user->id, 'Profile updated', $old, $user->only(['name', 'phone', 'locale']));

        return $this->successResponse(
            $user->only(['id', 'name', 'email', 'phone', 'locale', 'fcm_device_token']),
            'Profile updated.'
        );
    }

    // ──────────────────────────────────────────────
    // PASSWORD
    // ──────────────────────────────────────────────

    public function forgotPassword(Request $request, OtpDeliveryService $otpDelivery)
    {
        $this->ensureNotRateLimited('forgot-password:' . $request->ip(), 5, 60);

        $request->validate(['email' => 'required|email|exists:users,email']);

        $user = User::where('email', $request->email)->firstOrFail();

        Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_PASSWORD_RESET)
            ->delete();

        $plainOtp = Otp::generateOtp();

        $otp = Otp::create([
            'email'      => $user->email,
            'otp'        => Hash::make($plainOtp),
            'type'       => Otp::TYPE_PASSWORD_RESET,
            'name'       => $user->name,
            'expires_at' => now()->addMinutes(10),
            'is_used'    => false,
            'attempts'   => 0,
        ]);

        $otp->plain_otp = $plainOtp;
        $delivery = $otpDelivery->deliver($user, $otp);

        $this->logAudit('forgot_password', 'auth', $user->id, "Password reset OTP sent to {$user->email}");

        return $this->successResponse([
            'otp_channel' => $delivery['channel'] ?? 'email',
        ], 'OTP sent successfully.');
    }

    public function resetPassword(Request $request)
    {
        $this->ensureNotRateLimited('reset-password:' . $request->ip(), 5, 60);

        $request->validate([
            'email'    => 'required|email',
            'otp'      => 'required|string|size:6',
            'password' => ['required', 'confirmed', Password::min(8)->letters()->mixedCase()->numbers()],
        ]);

        $otp = Otp::where('email', $request->email)
            ->where('type', Otp::TYPE_PASSWORD_RESET)
            ->where('is_used', false)
            ->latest()
            ->first();

        if (!$otp || !$this->otpMatches($request->otp, $otp->otp)) {
            if ($otp) {
                $otp->increment('attempts');
                if ($otp->attempts >= 5) {
                    $otp->update(['is_used' => true]);
                }
            }
            return $this->errorResponse('Invalid or expired OTP.', 422);
        }

        if ($otp->expires_at->isPast()) {
            return $this->errorResponse('OTP has expired. Please request a new one.', 422);
        }

        $user = User::where('email', $request->email)->firstOrFail();
        $user->password = Hash::make($request->password);
        $user->save();

        $otp->update(['is_used' => true]);

        // Also revokes remember tokens: a new password invalidates saved logins.
        $user->tokens()->delete();
        UserSession::where('user_id', $user->id)->update(['is_active' => false]);

        $this->logAudit('reset_password', 'auth', $user->id, "Password reset for {$user->email}");

        return $this->successResponse(null, 'Password reset successfully. Please log in again.');
    }

    public function changePassword(Request $request)
    {
        $this->rejectRememberToken($request);

        $request->validate([
            'current_password' => 'required|string',
            'password'         => ['required', 'confirmed', Password::min(8)->letters()->mixedCase()->numbers()],
        ]);

        $user = $request->user();

        if (!Hash::check($request->current_password, $user->password)) {
            return $this->badRequest('Current password is incorrect.');
        }

        $user->password = Hash::make($request->password);
        $user->save();

        $currentTokenId = $user->currentAccessToken()->id;
        $user->tokens()->where('id', '!=', $currentTokenId)->delete();
        UserSession::where('user_id', $user->id)
            ->where('token', '!=', $currentTokenId)
            ->update(['is_active' => false]);

        $this->logAudit('change_password', 'auth', $user->id, 'Password changed for ' . ($user->email ?? $user->phone));

        return $this->successResponse(null, 'Password changed successfully.');
    }

    // ──────────────────────────────────────────────
    // LOCALE
    // ──────────────────────────────────────────────

    public function updateLocale(Request $request)
    {
        $this->rejectRememberToken($request);

        $request->validate(['locale' => 'required|in:en,sw']);

        $user = $request->user();
        $old  = $user->locale;

        $user->locale = $request->locale;
        $user->save();

        $this->logAudit('update_locale', 'user', $user->id, "Locale changed from {$old} to {$request->locale}");

        return $this->successResponse(null, 'Locale updated.');
    }

    // ──────────────────────────────────────────────
    // FCM / DEVICE TOKENS
    // ──────────────────────────────────────────────

    public function updateDeviceToken(Request $request)
    {
        $this->rejectRememberToken($request);

        $request->validate([
            'token'    => 'required|string|min:10',
            'app'      => 'nullable|string|in:og_one_super,fundi,nearby',
            'platform' => 'nullable|string|in:android,ios',
        ]);

        $user = $request->user();
        $app  = $request->input('app', UserDeviceToken::APP_SUPER);

        $this->releaseDeviceToken($request->token, $user->id);

        try {
            UserDeviceToken::updateOrCreate(
                ['token' => $request->token, 'app' => $app],
                [
                    'user_id'      => $user->id,
                    'platform'     => $request->input('platform', 'android'),
                    'last_seen_at' => now(),
                ]
            );

            if ($app === UserDeviceToken::APP_SUPER) {
                $user->forceFill(['fcm_device_token' => $request->token])->save();
            }

            $this->logAudit('update_device_token', 'user', $user->id, "FCM token updated for app={$app}");

            return $this->successResponse(
                ['message' => 'Device token updated successfully.'],
                'Device token updated.'
            );
        } catch (\Throwable $e) {
            Log::error('updateDeviceToken failed: ' . $e->getMessage());
            return $this->errorResponse('Could not update device token.', 500);
        }
    }

    public function getDeviceToken(Request $request)
    {
        $this->rejectRememberToken($request);

        $user = $request->user();

        return $this->successResponse([
            'fcm_device_token' => $user->fcm_device_token,
            'has_token'        => !empty($user->fcm_device_token),
        ]);
    }

    public function deleteDeviceToken(Request $request)
    {
        $this->rejectRememberToken($request);

        $request->validate([
            'app' => 'nullable|string|in:og_one_super,fundi,nearby',
        ]);

        $user = $request->user();
        $app  = $request->input('app', UserDeviceToken::APP_SUPER);

        try {
            UserDeviceToken::where('user_id', $user->id)
                ->where('app', $app)
                ->delete();

            if ($app === UserDeviceToken::APP_SUPER) {
                $user->forceFill(['fcm_device_token' => null])->save();
            }

            $this->logAudit('delete_device_token', 'user', $user->id, "FCM token deleted for app={$app}");

            return $this->successResponse(null, 'Device token deleted.');
        } catch (\Throwable $e) {
            Log::error('deleteDeviceToken failed: ' . $e->getMessage());
            return $this->errorResponse('Could not delete device token.', 500);
        }
    }

    // ──────────────────────────────────────────────
    // ACCOUNT DELETION
    // ──────────────────────────────────────────────

    public function deleteAccount(Request $request)
    {
        $this->rejectRememberToken($request);

        $user = $request->user();

        DB::beginTransaction();
        try {
            $user->tokens()->delete();
            UserSession::where('user_id', $user->id)->delete();

            UserDeviceToken::where('user_id', $user->id)->delete();
            $user->forceFill(['fcm_device_token' => null])->save();

            if ($user->technician) {
                $technician = $user->technician;
                $technician->services()->detach();

                if (method_exists($technician, 'portfolios')) {
                    foreach ($technician->portfolios as $portfolio) {
                        if ($portfolio->image && file_exists(public_path($portfolio->image))) {
                            @unlink(public_path($portfolio->image));
                        }
                        $portfolio->delete();
                    }
                }
                if (method_exists($technician, 'posts')) {
                    foreach ($technician->posts as $post) {
                        if ($post->image && file_exists(public_path($post->image))) {
                            @unlink(public_path($post->image));
                        }
                        $post->delete();
                    }
                }
                $technician->delete();
            }

            if (class_exists(\App\Models\ServiceRequest::class)) {
                \App\Models\ServiceRequest::where('customer_id', $user->id)
                    ->update(['customer_id' => null]);
            }

            $user->delete();

            DB::commit();

            $this->logAudit('delete_account', 'auth', $user->id, 'User deleted own account');

            return $this->successResponse(null, 'Account deleted.');
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Account deletion failed', ['error' => $e->getMessage()]);
            return $this->serverError('Delete failed. Please contact support.');
        }
    }

    public function myPermissions(Request $request)
    {
        $this->rejectRememberToken($request);

        return $this->successResponse([
            'permissions' => $request->user()->getAllPermissions()->pluck('name'),
        ]);
    }

    // ──────────────────────────────────────────────
    // GOOGLE SIGN-IN (mobile ID-token flow)
    // ──────────────────────────────────────────────

    public function googleLogin(Request $request)
    {
        $request->validate([
            'id_token'  => 'required|string|max:4096',
            'fcm_token' => 'nullable|string|max:255',
        ]);

        $payload = $this->verifyGoogleIdToken($request->id_token);

        if (!$payload) {
            $this->logAudit('google_login_failed', 'auth', null, 'Invalid Google token');
            return $this->unauthorized('Invalid Google sign-in. Please try again.');
        }

        $googleId = (string) $payload['sub'];
        $email    = strtolower(trim($payload['email'] ?? ''));
        $name     = trim($payload['name'] ?? '') ?: Str::before($email, '@');
        $picture  = $payload['picture'] ?? null;

        if ($email === '' || empty($payload['email_verified'])) {
            return $this->errorResponse('Your Google email is not verified.', 422);
        }

        // 1) match by google_id  2) match by email (links an existing account)
        $user = User::withTrashed()->where('google_id', $googleId)->first()
             ?? User::withTrashed()->where('email', $email)->first();

        if ($user && $user->trashed()) {
            return $this->forbidden('This account has been deleted. Please contact support.');
        }

        // Prevent a different Google account taking over this email
        if ($user && $user->google_id && $user->google_id !== $googleId) {
            return $this->forbidden('This email is linked to a different Google account.');
        }

        if ($user && $user->locked_until && $user->locked_until->isFuture()) {
            return $this->errorResponse('Account temporarily locked. Try again later.', 429);
        }

        $isNew = false;

        DB::beginTransaction();
        try {
            if (!$user) {
                $isNew = true;

                $user = User::create([
                    'name'              => $name,
                    'email'             => $email,
                    'password'          => Hash::make(Str::random(40)), // unused; column is NOT NULL
                    'status'            => 'active',
                    'is_active'         => true,
                    'email_verified_at' => now(),
                    'locale'            => 'en',
                ]);

                $user->forceFill([
                    'google_id'     => $googleId,
                    'google_avatar' => $picture,
                    'auth_provider' => 'google',
                ])->save();

                $user->assignRole('CUSTOMER');
            } else {
                $neverVerified = is_null($user->email_verified_at)
                    && is_null($user->phone_verified_at)
                    && empty($user->google_id);

                if ($neverVerified) {
                    // Someone may have pre-registered this email with a password.
                    // Google proves the real owner, so kill that credential.
                    $user->forceFill(['password' => Hash::make(Str::random(40))]);
                    $user->tokens()->delete();
                    UserSession::where('user_id', $user->id)->update(['is_active' => false]);
                }

                $user->forceFill([
                    'google_id'         => $user->google_id ?: $googleId,
                    'google_avatar'     => $picture ?: $user->google_avatar,
                    'email_verified_at' => $user->email_verified_at ?: now(),
                ]);

                // Email is now proven: activate customers still waiting on
                // verification. Only 'pending' is touched, so admin-suspended
                // accounts stay suspended. Fundis still need admin approval.
                if ($user->status === 'pending' && !$user->hasRole('FUNDI')) {
                    $user->forceFill(['status' => 'active', 'is_active' => true]);
                }

                $user->save();
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Google login failed', ['error' => $e->getMessage()]);
            return $this->serverError('Google sign-in failed. Please try again.');
        }

        // Same gates as password login
        if (!$user->is_active || $user->status !== 'active') {
            return $this->forbidden('Account is not active.');
        }

        if ($user->hasRole('FUNDI')) {
            $technician = Technician::where('user_id', $user->id)->first();
            if (!$technician || !$technician->verified || $technician->verification_status !== 'approved') {
                return $this->forbidden('Your technician account is not verified. Please wait for admin approval.');
            }
        }

        $token = $this->issueToken($user);
        $this->createSession($user, $request, $token);

        $user->update([
            'last_login_at'     => now(),
            'last_login_ip'     => $request->ip(),
            'last_login_device' => LoginNotificationService::deviceFrom($request),
            'locked_until'      => null,
        ]);

        if ($request->filled('fcm_token')) {
            $this->storeFcmToken($user, $request->fcm_token);
        }

        $this->logAudit(
            $isNew ? 'google_register' : 'google_login',
            'auth',
            $user->id,
            'Google sign-in: ' . $user->email
        );

        LoginNotificationService::dispatch($user, $request, 'google');

        $userData = $user->only(['id', 'name', 'email', 'phone', 'locale', 'fcm_device_token']);
        $userData['profile_photo'] = $user->google_avatar;

        return $this->successResponse([
            'user'        => $userData,
            'roles'       => $user->getRoleNames(),
            'token'       => $token,
            'is_new_user' => $isNew,
        ], $isNew ? 'Account created with Google.' : 'Login successful.');
    }

    // ──────────────────────────────────────────────
    // PRIVATE HELPERS
    // ──────────────────────────────────────────────

    /**
     * Reject a remember_token on any endpoint that is not quick-login / forget.
     * Remember tokens must only be exchangeable at /auth/quick-login.
     */
    private function rejectRememberToken(Request $request): void
    {
        $current = $request->user()?->currentAccessToken();
        if ($current && $current->name === 'remember_token') {
            abort(401, 'Saved login token cannot be used here. Please complete sign-in first.');
        }
    }

    /** Sanctum token with a real expiry (matches UserSession expires_at). */
    private function issueToken(User $user): string
    {
        return $user->createToken('auth_token', ['*'], now()->addDays(30))->plainTextToken;
    }

    /** Long-lived token that can ONLY be exchanged at /auth/quick-login. */
    private function issueRememberToken(User $user): string
    {
        return $user->createToken('remember_token', ['quick-login'], now()->addDays(self::REMEMBER_DAYS))->plainTextToken;
    }

    /**
     * Normalise a phone to digits-only international form (Tanzania default):
     *   0712345678 / +255712345678 / 255712345678 / 2550712345678 -> 255712345678
     */
    private function normalizePhone(?string $raw): ?string
    {
        $digits = preg_replace('/\D+/', '', (string) $raw) ?? '';

        if ($digits === '') {
            return null;
        }

        if (str_starts_with($digits, '00')) {
            $digits = substr($digits, 2);
        }
        // "255" + leading 0 typed by mistake (Tanzanian mobiles never start 2550…)
        if (str_starts_with($digits, '2550')) {
            return '255' . substr($digits, 4);
        }
        if (str_starts_with($digits, '0')) {
            return '255' . substr($digits, 1);
        }

        return $digits;
    }

    /** Every format a phone may already be stored in (incl. legacy broken rows). */
    private function phoneVariants(string $raw): array
    {
        $raw = trim($raw);
        $n   = $this->normalizePhone($raw) ?? '';

        $variants = [$n, '+' . $n, $raw];

        if (str_starts_with($n, '255')) {
            $variants[] = '0' . substr($n, 3);      // 0712…
            $variants[] = '2550' . substr($n, 3);   // legacy broken rows
        }

        return array_values(array_unique(array_filter(
            array_map('trim', $variants),
            fn ($v) => $v !== ''
        )));
    }

    /** Find a user by email (case-insensitive) or by phone in ANY format. */
    private function findUserByIdentifier(string $identifier): ?User
    {
        $identifier = trim($identifier);

        if ($identifier === '') {
            return null;
        }

        if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
            return User::whereRaw('LOWER(email) = ?', [strtolower($identifier)])->first();
        }

        return User::whereIn('phone', $this->phoneVariants($identifier))->first();
    }

    /**
     * The single customer account matching this email/phone that was never
     * verified (no email/phone verification, no Google link, still pending).
     * Null if nothing matches, if email and phone belong to DIFFERENT users,
     * or if the matching account is real/active.
     */
    private function findAbandonedCustomer(?string $email, ?string $phone): ?User
    {
        $matches = collect();

        if ($email) {
            $u = User::whereRaw('LOWER(email) = ?', [strtolower($email)])->first();
            if ($u) {
                $matches->push($u);
            }
        }

        if ($phone) {
            $u = User::whereIn('phone', $this->phoneVariants($phone))->first();
            if ($u) {
                $matches->push($u);
            }
        }

        $unique = $matches->unique('id');
        if ($unique->count() !== 1) {
            return null;
        }

        $u = $unique->first();

        $abandoned = is_null($u->email_verified_at)
            && is_null($u->phone_verified_at)
            && empty($u->google_id)
            && $u->status === 'pending'
            && $u->hasRole('CUSTOMER');

        return $abandoned ? $u : null;
    }

    /** Message when the email/phone belongs to a soft-deleted account. */
    private function deletedAccountConflict(?string $email, ?string $phone): ?string
    {
        if ($email && User::onlyTrashed()->whereRaw('LOWER(email) = ?', [strtolower($email)])->exists()) {
            return 'This email belongs to a previously deleted account. '
                 . 'Please contact support to restore it, or use a different email.';
        }

        if ($phone && User::onlyTrashed()->whereIn('phone', $this->phoneVariants($phone))->exists()) {
            return 'This phone number belongs to a previously deleted account. '
                 . 'Please contact support to restore it, or use a different number.';
        }

        return null;
    }

    /**
     * A fundi who verified their phone but has not finished step 6 only exists
     * as a draft. Reveal it only when the password matches (no enumeration).
     */
    private function pendingDraftFor(string $login, string $password): ?RegistrationDraft
    {
        try {
            $query = RegistrationDraft::query();

            if (filter_var($login, FILTER_VALIDATE_EMAIL)) {
                $query->where('email', strtolower($login));
            } else {
                $query->whereIn('phone', $this->phoneVariants($login));
            }

            $draft = $query->latest('id')->first();

            return ($draft && $draft->canProceed() && Hash::check($password, (string) $draft->password))
                ? $draft
                : null;
        } catch (\Throwable $e) {
            Log::warning('pendingDraftFor failed', ['error' => $e->getMessage()]);
            return null;
        }
    }

    /** Per-account part of a rate-limit key (shared carrier IPs must not block everyone). */
    private function rateKey(Request $request): string
    {
        return strtolower(trim((string) (
            $request->input('identifier') ?? $request->input('email') ?? ''
        )));
    }

    /**
     * A device FCM token may belong to ONE user at a time. Release it from
     * everyone else (or from everyone if $exceptUserId is null).
     */
    private function releaseDeviceToken(string $token, ?int $exceptUserId = null): void
    {
        UserDeviceToken::where('token', $token)
            ->when($exceptUserId, fn ($q) => $q->where('user_id', '!=', $exceptUserId))
            ->delete();

        User::where('fcm_device_token', $token)
            ->when($exceptUserId, fn ($q) => $q->where('id', '!=', $exceptUserId))
            ->update(['fcm_device_token' => null]);
    }

    /**
     * Verification OTPs belonging to THIS user only (by phone and/or email).
     * Null phone/email are skipped so we never match other users' null rows.
     */
    private function verificationOtps(User $user)
    {
        $query = Otp::where('type', Otp::TYPE_EMAIL_VERIFICATION);

        if (empty($user->phone) && empty($user->email)) {
            return $query->whereRaw('1 = 0');
        }

        return $query->where(function ($q) use ($user) {
            if (!empty($user->phone)) {
                $q->where('phone', $user->phone);
            }
            if (!empty($user->email)) {
                $q->orWhere('email', $user->email);
            }
        });
    }

    /**
     * Safe OTP check. Old rows stored as plain text would make Hash::check()
     * throw "This password does not use the Bcrypt algorithm"; treat as no match.
     */
    private function otpMatches(string $plain, ?string $stored): bool
    {
        if (empty($stored)) {
            return false;
        }

        try {
            return Hash::check($plain, $stored);
        } catch (\Throwable $e) {
            return false;
        }
    }

    private function issueVerificationOtp(User $user, Request $request, OtpDeliveryService $otpDelivery): array
    {
        $this->verificationOtps($user)->delete();

        $plainOtp = Otp::generateOtp();

        $otp = Otp::create([
            'email'      => $user->email,
            'phone'      => $user->phone,
            'otp'        => Hash::make($plainOtp),
            'token'      => Otp::generateToken(),
            'type'       => Otp::TYPE_EMAIL_VERIFICATION,
            'name'       => $user->name,
            'expires_at' => now()->addMinutes(10),
            'is_used'    => false,
            'attempts'   => 0,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $otp->plain_otp = $plainOtp;

        return $otpDelivery->deliver(
            $user,
            $otp,
            method_exists($otp, 'getVerificationUrl') ? $otp->getVerificationUrl() : null
        );
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
            'device_name'   => $this->getDeviceName($request),
            'last_activity' => now(),
            'expires_at'    => now()->addDays(30),
            'is_active'     => true,
        ]);
    }

    private function getDeviceName(Request $request): string
    {
        $ua = $request->userAgent() ?? '';

        if (str_contains($ua, 'Postman')) return 'Postman';
        if (str_contains($ua, 'Flutter')) return 'Mobile App';
        if (str_contains($ua, 'Mozilla')) return 'Web Browser';

        return 'Unknown';
    }

    private function storeFcmToken(User $user, string $token): void
    {
        if (empty($token)) {
            return;
        }

        try {
            $this->releaseDeviceToken($token, $user->id);   // no more ghost pushes
            $user->fcm_device_token = $token;
            $user->save();
        } catch (\Throwable $e) {
            Log::error('Failed to store FCM token', ['user_id' => $user->id, 'error' => $e->getMessage()]);
        }
    }

    private function validateAndGeocodeArea(string $area, ?float $lat, ?float $lng, GeocodingService $geocoder): array
    {
        if ($lat !== null && $lng !== null) {
            return ['lat' => $lat, 'lng' => $lng];
        }

        $coords = $geocoder->geocode($area);
        if (!$coords) {
            abort(422, "Could not locate the area '{$area}'. Please check the spelling or provide latitude/longitude.");
        }

        return $coords;
    }

    /**
     * Verifies a Google ID token (signature, expiry, issuer, audience).
     * Returns the payload, or null if invalid.
     */
    private function verifyGoogleIdToken(string $idToken): ?array
    {
        $clientIds = config('services.google.client_ids', []);

        if (empty($clientIds)) {
            Log::error('GOOGLE_CLIENT_IDS is not configured');
            return null;
        }

        foreach ($clientIds as $clientId) {
            try {
                $client  = new GoogleClient(['client_id' => $clientId]);
                $payload = $client->verifyIdToken($idToken);

                if (is_array($payload) && !empty($payload['sub'])) {
                    return $payload;
                }
            } catch (\Throwable $e) {
                Log::warning('Google token verify error', ['error' => $e->getMessage()]);
            }
        }

        return null;
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