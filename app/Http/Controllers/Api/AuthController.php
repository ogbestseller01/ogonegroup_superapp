<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use App\Models\Otp;
use App\Models\FailedLoginAttempt;
use App\Models\UserSession;
use App\Models\Technician;
use App\Traits\Auditable;
use App\Services\OtpDeliveryService;
use App\Services\GeocodingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Google_Client;
use Spatie\Permission\Models\Role;
use Laravel\Socialite\Facades\Socialite;

class AuthController extends BaseApiController
{
    use Auditable;

    // ──────────────────────────────────────────────
    // REGISTRATION
    // ──────────────────────────────────────────────

    public function register(Request $request, OtpDeliveryService $otpDelivery)
    {
        $data = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => ['required', 'confirmed', Password::min(8)->letters()->mixedCase()->numbers()],
            'phone'    => 'required|string|unique:users,phone|max:20',
            'role'     => 'nullable|string|in:CUSTOMER,FUNDI',
        ]);

        $user = User::create([
            'name'              => $data['name'],
            'email'             => $data['email'],
            'phone'             => $data['phone'],
            'password'          => Hash::make($data['password']),
            'status'            => 'pending',
            'is_active'         => false,
            'email_verified_at' => null,
        ]);

        $role = $data['role'] ?? 'CUSTOMER';
        $user->assignRole($role);

        $delivery = $this->issueVerificationOtp($user, $request, $otpDelivery);

        return $this->created([
            'user'        => $user->only(['id', 'name', 'email', 'phone']),
            'otp_channel' => $delivery['channel'] ?? 'email',
            'sent_to'     => ($delivery['channel'] ?? 'email') === 'sms' ? $user->phone : $user->email,
        ], 'Registration successful. Please enter the OTP sent to verify your account.');
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
        $this->ensureNotRateLimited('resend-otp:' . $request->ip(), 3, 60);

        $request->validate([
            'identifier' => 'required_without:email|string',
            'email'      => 'required_without:identifier|string',
        ]);

        $identifier = $request->input('identifier', $request->input('email'));
        $user = User::where('email', $identifier)->orWhere('phone', $identifier)->first();

        // Same response whether or not the user exists (no account enumeration)
        if (!$user) {
            return $this->successResponse(null, 'If the account exists, a new OTP was sent.');
        }

        // ✅ FIX: Check both email and phone verified status
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
        $this->ensureNotRateLimited('verify-otp:' . $request->ip(), 10, 60);

        $request->validate([
            'identifier' => 'required_without:email|string',
            'email'      => 'required_without:identifier|string',
            'otp'        => 'required|string|size:6',
            'fcm_token'  => 'nullable|string|max:255',
        ]);

        $identifier = $request->input('identifier', $request->input('email'));

        $user = User::where('email', $identifier)->orWhere('phone', $identifier)->first();
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

        // ✅ FIX: Detect if identifier was an email or phone and update the correct column
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
            $token = $user->createToken('auth_token')->plainTextToken;
            $this->createSession($user, $request, $token);
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
    // LOGIN
    // ──────────────────────────────────────────────

    public function login(Request $request)
    {
        $this->ensureNotRateLimited('login:' . $request->ip(), 10, 60);

        $request->validate([
            'email'    => 'required|string',
            'password' => 'required|string',
        ]);

        $login = $request->email;
        $user  = User::where('email', $login)->first()
              ?? User::where('phone', $login)->first();

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
                    Log::warning('Account locked due to failed logins', ['user_id' => $user->id]);
                }
            }

            $this->logAudit('login_failed', 'auth', null, "Failed login for: {$login}");
            return $this->unauthorized('Invalid credentials.');
        }

        if ($user->locked_until) {
            $user->update(['locked_until' => null]);
        }

        // ✅ FIX: Allow login if EITHER email OR phone is verified
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

        $token = $user->createToken('auth_token')->plainTextToken;
        $this->createSession($user, $request, $token);

        $user->update([
            'last_login_at' => now(),
            'last_login_ip' => $request->ip(),
        ]);

        if ($request->filled('fcm_token')) {
            $this->storeFcmToken($user, $request->fcm_token);
        }

        $this->logAudit('login', 'auth', $user->id, 'User logged in: ' . ($user->email ?? $user->phone));

        return $this->successResponse([
            'user'  => $user->only(['id', 'name', 'email', 'phone', 'locale', 'fcm_device_token']),
            'roles' => $user->getRoleNames(),
            'token' => $token,
        ], 'Login successful.');
    }

    // ──────────────────────────────────────────────
    // GOOGLE LOGIN
    // ──────────────────────────────────────────────

    public function googleLogin(Request $request)
    {
        $this->ensureNotRateLimited('google-login:' . $request->ip(), 10, 60);

        $request->validate([
            'id_token'  => 'required|string',
            'fcm_token' => 'nullable|string|min:10',
        ]);

        try {
            $client  = new Google_Client(['client_id' => config('services.google.client_id')]);
            $payload = $client->verifyIdToken($request->id_token);

            if (!$payload || empty($payload['email'])) {
                return $this->unauthorized('Invalid Google token.');
            }

            $email    = $payload['email'];
            $name     = $payload['name'] ?? 'Google User';
            $googleId = $payload['sub'];

            $user = User::where('email', $email)->first();

            if (!$user) {
                $user = User::create([
                    'name'              => $name,
                    'email'             => $email,
                    'google_id'         => $googleId,
                    'password'          => Hash::make(Str::random(32)),
                    'email_verified_at' => now(),
                    'status'            => 'active',
                    'is_active'         => true,
                ]);
                $user->assignRole('CUSTOMER');
                $this->logAudit('register_google', 'auth', $user->id, "Customer registered via Google: {$email}");
            } else {
                if (empty($user->google_id)) {
                    $user->update(['google_id' => $googleId]);
                }

                if (!$user->email_verified_at) {
                    $user->update(['email_verified_at' => now()]);
                }

                if ($user->status !== 'active' || !$user->is_active) {
                    if ($user->hasRole('FUNDI')) {
                        return $this->forbidden('Your technician account requires admin approval.');
                    }
                    $user->update(['status' => 'active', 'is_active' => true]);
                }
            }

            $token = $user->createToken('auth_token')->plainTextToken;
            $this->createSession($user, $request, $token);

            if ($request->filled('fcm_token')) {
                $this->storeFcmToken($user, $request->fcm_token);
            }

            $this->logAudit('login_google', 'auth', $user->id, "User logged in via Google: {$email}");

            return $this->successResponse([
                'user'  => $user->only(['id', 'name', 'email', 'phone', 'locale', 'fcm_device_token']),
                'roles' => $user->getRoleNames(),
                'token' => $token,
            ], 'Google login successful.');
        } catch (\Throwable $e) {
            Log::error('Google ID token authentication failed', ['error' => $e->getMessage()]);
            return $this->serverError('Google authentication failed.');
        }
    }

    public function redirectToGoogle()
    {
        return response()->json([
            'url' => Socialite::driver('google')->stateless()->redirect()->getTargetUrl(),
        ]);
    }

    public function handleGoogleCallback(Request $request)
    {
        try {
            $code = $request->input('code');
            if (!$code) {
                return $this->errorResponse('No authorization code provided.', 422);
            }

            $response = Socialite::driver('google')->getAccessTokenResponse($code);
            $token    = $response['access_token'] ?? null;

            if (!$token) {
                return $this->errorResponse('Failed to retrieve access token from Google.', 401);
            }

            $googleUser = Socialite::driver('google')->userFromToken($token);

            $user = User::where('email', $googleUser->getEmail())->first();

            if (!$user) {
                $user = User::create([
                    'name'              => $googleUser->getName(),
                    'email'             => $googleUser->getEmail(),
                    'google_id'         => $googleUser->getId(),
                    'password'          => Hash::make(Str::random(32)),
                    'email_verified_at' => now(),
                    'status'            => 'active',
                    'is_active'         => true,
                ]);
                $user->assignRole('CUSTOMER');
                $this->logAudit('register_google', 'auth', $user->id, 'Customer registered via Google callback');
            } else {
                if (empty($user->google_id)) {
                    $user->update(['google_id' => $googleUser->getId()]);
                }
                if (!$user->email_verified_at) {
                    $user->update(['email_verified_at' => now()]);
                }
                if ($user->hasRole('FUNDI') && ($user->status !== 'active' || !$user->is_active)) {
                    return $this->forbidden('Your technician account requires admin approval.');
                }
                if ($user->status !== 'active') {
                    $user->update(['status' => 'active', 'is_active' => true]);
                }
            }

            $sanctumToken = $user->createToken('auth_token')->plainTextToken;
            $this->createSession($user, $request, $sanctumToken);

            if ($request->filled('fcm_token')) {
                $this->storeFcmToken($user, $request->fcm_token);
            }

            $this->logAudit('login_google', 'auth', $user->id, 'User logged in via Google callback');

            return $this->successResponse([
                'user'  => $user->only(['id', 'name', 'email', 'phone', 'locale', 'fcm_device_token']),
                'roles' => $user->getRoleNames(),
                'token' => $sanctumToken,
            ], 'Google login successful.');
        } catch (\Throwable $e) {
            Log::error('Google callback failed', ['error' => $e->getMessage()]);
            return $this->errorResponse('Google authentication failed.', 500);
        }
    }

    // ──────────────────────────────────────────────
    // LOGOUT & SESSIONS
    // ──────────────────────────────────────────────

    public function logout(Request $request)
    {
        $user    = $request->user();
        $tokenId = $user->currentAccessToken()->id;

        $user->currentAccessToken()->delete();

        UserSession::where('user_id', $user->id)
            ->where('token', $tokenId)
            ->update(['is_active' => false]);

        $this->logAudit('logout', 'auth', $user->id, 'User logged out: ' . ($user->email ?? $user->phone));

        return $this->successResponse(null, 'Logged out.');
    }

    public function logoutAll(Request $request)
    {
        $user = $request->user();

        $user->tokens()->delete();
        UserSession::where('user_id', $user->id)->update(['is_active' => false]);

        $this->logAudit('logout_all', 'auth', $user->id, 'User logged out from all devices: ' . ($user->email ?? $user->phone));

        return $this->successResponse(null, 'Logged out from all devices.');
    }

    // ──────────────────────────────────────────────
    // PROFILE
    // ──────────────────────────────────────────────

    public function me(Request $request)
    {
        $user = $request->user()->load('technician.services');

        if ($user->technician) {
            $user->technician->makeVisible('nida');
        }

        return $this->successResponse([
            'user'       => $user->only(['id', 'name', 'email', 'phone', 'status', 'locale', 'fcm_device_token']),
            'roles'      => $user->getRoleNames(),
            'technician' => $user->technician,
        ]);
    }

    public function updateProfile(Request $request)
    {
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

        $user->tokens()->delete();
        UserSession::where('user_id', $user->id)->update(['is_active' => false]);

        $this->logAudit('reset_password', 'auth', $user->id, "Password reset for {$user->email}");

        return $this->successResponse(null, 'Password reset successfully. Please log in again.');
    }

    public function changePassword(Request $request)
    {
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
        $request->validate(['locale' => 'required|in:en,sw']);

        $user = $request->user();
        $old  = $user->locale;

        $user->locale = $request->locale;
        $user->save();

        $this->logAudit('update_locale', 'user', $user->id, "Locale changed from {$old} to {$request->locale}");

        return $this->successResponse(null, 'Locale updated.');
    }

    // ──────────────────────────────────────────────
    // FCM
    // ──────────────────────────────────────────────

    public function updateDeviceToken(Request $request)
{
    $request->validate([
        'token'    => 'required|string|min:10',
        'app'      => 'nullable|string|in:og_one_super,fundi,nearby',
        'platform' => 'nullable|string|in:android,ios',
    ]);

    $user = $request->user();
    $app  = $request->input('app', \App\Models\UserDeviceToken::APP_SUPER);

    try {
        \App\Models\UserDeviceToken::updateOrCreate(
            ['token' => $request->token, 'app' => $app],
            [
                'user_id'      => $user->id,
                'platform'     => $request->input('platform', 'android'),
                'last_seen_at' => now(),
            ]
        );

        if ($app === \App\Models\UserDeviceToken::APP_SUPER) {
            $user->forceFill(['fcm_device_token' => $request->token])->save();
        }

        $this->logAudit('update_device_token', 'user', $user->id, "FCM token updated for app={$app}");

        return $this->successResponse(
            ['message' => 'Device token updated successfully.'],
            'Device token updated.'
        );
    } catch (\Throwable $e) {
        \Log::error('updateDeviceToken failed: ' . $e->getMessage());
        return $this->errorResponse('Could not update device token.', 500);
    }
}

   

    public function getDeviceToken(Request $request)
    {
        $user = $request->user();

        return $this->successResponse([
            'fcm_device_token' => $user->fcm_device_token,
            'has_token'        => !empty($user->fcm_device_token),
        ]);
    }

   public function deleteDeviceToken(Request $request)
{
    $request->validate([
        'app' => 'nullable|string|in:og_one_super,fundi,nearby',
    ]);

    $user = $request->user();
    $app  = $request->input('app', \App\Models\UserDeviceToken::APP_SUPER);

    try {
        \App\Models\UserDeviceToken::where('user_id', $user->id)
            ->where('app', $app)
            ->delete();

        if ($app === \App\Models\UserDeviceToken::APP_SUPER) {
            $user->forceFill(['fcm_device_token' => null])->save();
        }

        $this->logAudit('delete_device_token', 'user', $user->id, "FCM token deleted for app={$app}");

        return $this->successResponse(null, 'Device token deleted.');
    } catch (\Throwable $e) {
        \Log::error('deleteDeviceToken failed: ' . $e->getMessage());
        return $this->errorResponse('Could not delete device token.', 500);
    }
}

    // ──────────────────────────────────────────────
    // ACCOUNT DELETION
    // ──────────────────────────────────────────────

    public function deleteAccount(Request $request)
    {
        $user = $request->user();

        DB::beginTransaction();
        try {
            $user->tokens()->delete();
            UserSession::where('user_id', $user->id)->delete();

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
        return $this->successResponse([
            'permissions' => $request->user()->getAllPermissions()->pluck('name'),
        ]);
    }

    // ──────────────────────────────────────────────
    // PRIVATE HELPERS
    // ──────────────────────────────────────────────

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
            $user->fcm_device_token = $token;
            $user->save();
        } catch (\Throwable $e) {
            Log::error('Failed to store FCM token', [
                'user_id' => $user->id,
                'error'   => $e->getMessage(),
            ]);
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

    private function ensureNotRateLimited(string $key, int $maxAttempts, int $decaySeconds): void
    {
        if (RateLimiter::tooManyAttempts($key, $maxAttempts)) {
            $seconds = RateLimiter::availableIn($key);
            abort(429, "Too many attempts. Please try again in {$seconds} seconds.");
        }

        RateLimiter::hit($key, $decaySeconds);
    }
}