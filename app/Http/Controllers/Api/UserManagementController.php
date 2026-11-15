<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use App\Models\Otp;
use App\Models\SmsLog;
use App\Traits\Auditable;
use App\Services\OtpDeliveryService;
use App\Services\RafikiSmsService;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use Throwable;
use Exception;

class UserManagementController extends BaseApiController
{
    use Auditable;

    /**
     * Lean technician columns reused across list/detail endpoints
     */
    private function technicianRelation(): array
    {
        return ['technician:id,user_id,verified,verification_status,is_online'];
    }

    // ===== LIST ENDPOINTS =====

    public function index(Request $request)
    {
        $this->checkPermission('users.view');

        $query = User::with(array_merge(['roles'], $this->technicianRelation()));

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%")
                  ->orWhere('phone', 'LIKE', "%{$search}%");
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('role')) {
            $query->whereHas('roles', function ($q) use ($request) {
                $q->where('name', $request->role);
            });
        }

        $perPage = $request->input('per_page', 20);
        $users = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return $this->successResponse([
            'data' => $users->items(),
            'pagination' => [
                'total'        => $users->total(),
                'per_page'     => $users->perPage(),
                'current_page' => $users->currentPage(),
                'last_page'    => $users->lastPage(),
                'from'         => $users->firstItem(),
                'to'           => $users->lastItem(),
            ]
        ], 'Users retrieved successfully');
    }

    public function customers(Request $request)
    {
        $this->checkPermission('users.view');

        $query = User::role('CUSTOMER')->with($this->technicianRelation());

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        $perPage = $request->input('per_page', 20);
        $users = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return $this->successResponse([
            'data' => $users->items(),
            'pagination' => [
                'total'        => $users->total(),
                'per_page'     => $users->perPage(),
                'current_page' => $users->currentPage(),
                'last_page'    => $users->lastPage(),
            ]
        ], 'Customers retrieved successfully');
    }

    public function fundis(Request $request)
    {
        $this->checkPermission('users.view');

        $query = User::role('FUNDI')->with($this->technicianRelation());

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        $perPage = $request->input('per_page', 20);
        $users = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return $this->successResponse([
            'data' => $users->items(),
            'pagination' => [
                'total'        => $users->total(),
                'per_page'     => $users->perPage(),
                'current_page' => $users->currentPage(),
                'last_page'    => $users->lastPage(),
            ]
        ], 'Fundis retrieved successfully');
    }

    public function stats()
    {
        $this->checkPermission('users.view');

        return $this->successResponse([
            'total'        => User::count(),
            'customers'    => User::role('CUSTOMER')->count(),
            'fundis'       => User::role('FUNDI')->count(),
            'admins'       => User::role('ADMINISTRATOR')->count(),
            'monitoring'   => User::role('MONITORING_OFFICER')->count(),
            'active'       => User::where('is_active', true)->count(),
            'inactive'     => User::where('is_active', false)->count(),
            'pending'      => User::where('status', 'pending')->count(),
            'suspended'    => User::where('status', 'suspended')->count(),
            'verified'     => User::whereNotNull('email_verified_at')->count(),
            'unverified'   => User::whereNull('email_verified_at')->count(),
        ]);
    }

    // ===== DROPDOWNS =====

    public function dropdownUsers(Request $request)
    {
        $this->checkPermission('users.view');

        $search = $request->get('search');
        $role   = $request->get('role');

        $query = User::query();

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        if ($role) {
            $query->role($role);
        }

        $users = $query->select('id', 'name', 'email')
            ->orderBy('name')
            ->limit($request->get('limit', 100))
            ->get();

        return $this->successResponse($users);
    }

    public function dropdownCustomers(Request $request)
    {
        $this->checkPermission('users.view');

        $search = $request->get('search');
        $query  = User::role('CUSTOMER');

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        $customers = $query->select('id', 'name', 'email')
            ->orderBy('name')
            ->limit($request->get('limit', 100))
            ->get();

        return $this->successResponse($customers);
    }

    public function dropdownFundis(Request $request)
    {
        $this->checkPermission('users.view');

        $search    = $request->get('search');
        $verified  = $request->get('verified');
        $serviceId = $request->get('service_id');

        $query = User::role('FUNDI')
            ->with(['technician' => function ($q) use ($serviceId) {
                if ($serviceId) {
                    $q->whereHas('services', function ($sq) use ($serviceId) {
                        $sq->where('service_id', $serviceId);
                    });
                }
                $q->select('id', 'user_id', 'profile_photo', 'verified', 'verification_status', 'rating', 'is_online');
            }]);

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        if ($verified !== null) {
            $query->whereHas('technician', function ($q) use ($verified) {
                $q->where('verified', $verified);
            });
        }

        $fundis = $query->select('id', 'name', 'email')
            ->orderBy('name')
            ->limit($request->get('limit', 100))
            ->get();

        $fundis->each(function ($fundi) {
            if ($fundi->technician) {
                $fundi->technician_profile = [
                    'id'                  => $fundi->technician->id,
                    'profile_photo'       => $fundi->technician->profile_photo,
                    'verified'            => $fundi->technician->verified,
                    'verification_status' => $fundi->technician->verification_status,
                    'rating'              => $fundi->technician->rating,
                    'is_online'           => $fundi->technician->is_online,
                ];
            }
        });

        return $this->successResponse($fundis);
    }

    public function dropdownActiveUsers(Request $request)
    {
        $this->checkPermission('users.view');

        $search       = $request->get('search');
        $excludeRoles = $request->get('exclude_roles', []);

        $query = User::where('is_active', true);

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        if (!empty($excludeRoles)) {
            $query->whereDoesntHave('roles', function ($q) use ($excludeRoles) {
                $q->whereIn('name', $excludeRoles);
            });
        }

        $users = $query->select('id', 'name', 'email')
            ->orderBy('name')
            ->limit($request->get('limit', 100))
            ->get();

        return $this->successResponse($users);
    }

    // ===== SHOW, CREATE, UPDATE, DELETE =====

    public function show($id)
    {
        $this->checkPermission('users.view');
        $user = User::with(array_merge(['roles'], $this->technicianRelation()))->findOrFail($id);
        return $this->successResponse($user);
    }

    public function store(Request $request, OtpDeliveryService $otpDelivery)
    {
        $this->checkPermission('users.create');

        $data = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'phone'    => 'nullable|string|max:20',
            'role'     => 'required|exists:roles,name',
            'status'   => 'nullable|in:active,inactive,pending,suspended',
        ]);

        $user = User::create([
            'name'              => $data['name'],
            'email'             => $data['email'],
            'password'          => Hash::make($data['password']),
            'phone'             => $data['phone'] ?? null,
            'status'            => 'pending',
            'is_active'         => false,
            'email_verified_at' => null,
        ]);

        $user->assignRole($data['role']);

        // Generate and deliver OTP
        Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->delete();

        $otp = Otp::create([
            'email'      => $user->email,
            'otp'        => Otp::generateOtp(),
            'token'      => Otp::generateToken(),
            'type'       => Otp::TYPE_EMAIL_VERIFICATION,
            'name'       => $user->name,
            'expires_at' => Carbon::now()->addMinutes(10),
            'is_used'    => false,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $delivery = $otpDelivery->deliver($user, $otp, method_exists($otp, 'getVerificationUrl') ? $otp->getVerificationUrl() : null);

        $this->logAudit('create_user', 'user', $user->id, "User created: {$user->email} (OTP sent via {$delivery['channel']})");

        return $this->created([
            'user'        => $user->load('roles'),
            'otp_channel' => $delivery['channel'],
            'otp_sent_to' => $delivery['otp_sent_to'] ?? ($delivery['channel'] === 'sms' ? $user->phone : $user->email),
        ], 'User created successfully. OTP sent for verification.');
    }

    // ===== USER VERIFICATION METHODS =====

    /**
     * Verify the OTP provided for a user (Admin verification endpoint)
     */
    public function verifyOtp(Request $request, $id)
    {
        $this->checkPermission('users.edit');

        $request->validate([
            'otp' => 'required|string|size:6',
        ]);

        $user = User::findOrFail($id);

        // Check if user is already verified
        if ($user->email_verified_at) {
            return $this->errorResponse('User is already verified.', 422);
        }

        $otpRecord = Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->where('is_used', false)
            ->orderBy('created_at', 'desc')
            ->first();

        if (!$otpRecord) {
            return $this->errorResponse('No valid OTP found. Please request a new one.', 400);
        }

        if ($otpRecord->expires_at->isPast()) {
            return $this->errorResponse('OTP has expired. Please request a new one.', 400);
        }

        if ($otpRecord->otp !== $request->otp) {
            return $this->errorResponse('Invalid OTP code.', 400);
        }

        // Mark OTP as used and activate user
        $otpRecord->update(['is_used' => true]);

        $user->update([
            'status'            => 'active',
            'is_active'         => true,
            'email_verified_at' => Carbon::now(),
        ]);

        $this->logAudit('verify_otp_admin', 'user', $user->id, "User #{$user->id} successfully verified OTP by admin");

        return $this->successResponse([
            'user' => $user->fresh()->load('roles'),
        ], 'User verified and activated successfully.');
    }

    /**
     * Verify user via token URL (Admin can also verify via token)
     */
    public function verifyUserToken(Request $request, $id)
    {
        $this->checkPermission('users.edit');

        $user = User::findOrFail($id);

        if ($user->email_verified_at) {
            return $this->errorResponse('User is already verified.', 422);
        }

        // Find the latest verification token
        $otpRecord = Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->where('is_used', false)
            ->where('expires_at', '>', Carbon::now())
            ->orderBy('created_at', 'desc')
            ->first();

        if (!$otpRecord) {
            return $this->errorResponse('No valid verification token found. Please resend OTP.', 400);
        }

        // Mark OTP as used and activate user
        $otpRecord->update(['is_used' => true]);

        $user->update([
            'status'            => 'active',
            'is_active'         => true,
            'email_verified_at' => Carbon::now(),
        ]);

        $this->logAudit('verify_user_token_admin', 'user', $user->id, "User #{$user->id} verified via token by admin");

        return $this->successResponse([
            'user' => $user->fresh()->load('roles'),
        ], 'User verified successfully.');
    }

    /**
     * Mark user as verified without OTP (Admin override)
     */
    public function markVerified(Request $request, $id)
    {
        $this->checkPermission('users.edit');

        $user = User::findOrFail($id);

        if ($user->email_verified_at) {
            return $this->errorResponse('User is already verified.', 422);
        }

        // Mark all pending OTPs as used
        Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->where('is_used', false)
            ->update(['is_used' => true]);

        $user->update([
            'status'            => 'active',
            'is_active'         => true,
            'email_verified_at' => Carbon::now(),
        ]);

        $this->logAudit('mark_verified_admin', 'user', $user->id, "User #{$user->id} marked as verified by admin override");

        return $this->successResponse([
            'user' => $user->fresh()->load('roles'),
        ], 'User marked as verified successfully.');
    }

    public function update(Request $request, $id)
    {
        $this->checkPermission('users.edit');
        $user = User::findOrFail($id);

        $request->validate([
            'name'   => 'sometimes|string|max:255',
            'email'  => 'sometimes|email|unique:users,email,' . $id,
            'phone'  => 'nullable|string|max:20',
            'role'   => 'sometimes|exists:roles,name',
            'status' => 'sometimes|in:active,inactive,pending,suspended',
        ]);

        $old = $user->toArray();
        $user->update($request->only(['name', 'email', 'phone', 'status']));

        if ($request->has('role')) {
            $user->syncRoles([$request->role]);
        }

        $new = $user->fresh()->load('roles')->toArray();

        $this->logAudit('update_user', 'user', $id, "User #{$id} updated", $old, $new);

        return $this->successResponse($user->load('roles'), 'User updated successfully.');
    }

    public function destroy($id)
    {
        $this->checkPermission('users.delete');
        $user = User::findOrFail($id);
        $user->delete();
        $this->logAudit('delete_user', 'user', $id, "User #{$id} deleted");
        return $this->successResponse(null, 'User deleted successfully.');
    }

    // ===== SOFT DELETE RESTORE & FORCE =====

    public function trashed(Request $request)
    {
        $this->checkPermission('users.view');

        $query = User::onlyTrashed()->with('roles');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        $perPage = $request->input('per_page', 20);
        $users = $query->orderBy('deleted_at', 'desc')->paginate($perPage);

        return $this->successResponse([
            'data' => $users->items(),
            'pagination' => [
                'total'        => $users->total(),
                'per_page'     => $users->perPage(),
                'current_page' => $users->currentPage(),
                'last_page'    => $users->lastPage(),
            ]
        ], 'Deleted users retrieved successfully');
    }

    public function restore($id)
    {
        $this->checkPermission('users.edit');
        $user = User::onlyTrashed()->findOrFail($id);
        $user->restore();
        $this->logAudit('restore_user', 'user', $id, "User #{$id} restored");
        return $this->successResponse(null, 'User restored successfully.');
    }

    public function forceDelete($id)
    {
        $this->checkPermission('users.delete');
        $user = User::onlyTrashed()->findOrFail($id);
        $user->forceDelete();
        $this->logAudit('force_delete_user', 'user', $id, "User #{$id} permanently deleted");
        return $this->successResponse(null, 'User permanently deleted.');
    }

    // ===== ACTIVATE, DEACTIVATE, SUSPEND =====

    public function activate($id)
    {
        $this->checkPermission('users.edit');
        $user = User::findOrFail($id);
        $user->is_active = true;
        $user->status = 'active';
        $user->save();
        $this->logAudit('activate_user', 'user', $id, "User #{$id} activated");
        return $this->successResponse($user->load('roles'), 'User activated.');
    }

    public function deactivate($id)
    {
        $this->checkPermission('users.edit');
        $user = User::findOrFail($id);
        $user->is_active = false;
        $user->status = 'inactive';
        $user->save();
        $this->logAudit('deactivate_user', 'user', $id, "User #{$id} deactivated");
        return $this->successResponse($user->load('roles'), 'User deactivated.');
    }

    public function suspend($id)
    {
        $this->checkPermission('users.edit');
        $user = User::findOrFail($id);
        $user->is_active = false;
        $user->status = 'suspended';
        $user->save();
        $this->logAudit('suspend_user', 'user', $id, "User #{$id} suspended");
        return $this->successResponse($user->load('roles'), 'User suspended.');
    }

    // ===== PASSWORD RESETS =====

    public function resetPassword(Request $request, $id)
    {
        $this->checkPermission('users.edit');

        $request->validate([
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::findOrFail($id);
        $user->password = Hash::make($request->password);
        $user->save();

        $this->logAudit('reset_user_password', 'user', $id, "Password reset for user #{$id}");

        return $this->successResponse([
            'message' => 'Password reset successfully',
            'user_id' => $user->id,
            'email'   => $user->email,
        ], 'Password reset successfully.');
    }

    public function resetPasswordRandom($id)
    {
        $this->checkPermission('users.edit');

        $user = User::findOrFail($id);
        $newPassword = Str::random(10);
        $user->password = Hash::make($newPassword);
        $user->save();

        try {
            Mail::send('emails.password-reset-admin', [
                'user'     => $user,
                'password' => $newPassword,
            ], function ($message) use ($user) {
                $message->to($user->email)
                        ->subject('Your Password Has Been Reset');
            });
        } catch (Exception $e) {
            Log::error('Password reset email failed: ' . $e->getMessage());
        }

        $this->logAudit('reset_user_password_random', 'user', $id, "Password reset for user #{$id}");

        return $this->successResponse([
            'new_password' => $newPassword,
            'user_id'      => $user->id,
            'email'        => $user->email,
        ], 'Password reset successfully.');
    }

    // ===== OTP RESEND =====

    public function resendOtp(Request $request, $id, OtpDeliveryService $otpDelivery)
    {
        $this->checkPermission('users.edit');

        $user = User::findOrFail($id);

        if ($user->email_verified_at) {
            return $this->errorResponse('User is already verified.', 422);
        }

        Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->delete();

        $otp = Otp::create([
            'email'      => $user->email,
            'otp'        => Otp::generateOtp(),
            'token'      => Otp::generateToken(),
            'type'       => Otp::TYPE_EMAIL_VERIFICATION,
            'name'       => $user->name,
            'expires_at' => Carbon::now()->addMinutes(10),
            'is_used'    => false,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $delivery = $otpDelivery->deliver($user, $otp, $otp->getVerificationUrl());

        $this->logAudit(
            'resend_otp',
            'user',
            $user->id,
            "OTP resent to user #{$user->id} (via {$delivery['channel']})"
        );

        if (!$delivery['success']) {
            return $this->errorResponse('Failed to send OTP via SMS or email. Please try again later.', 500);
        }

        return $this->successResponse([
            'otp_expires_at' => $otp->expires_at->toDateTimeString(),
            'otp_channel'    => $delivery['channel'],
            'otp_sent_to'    => $delivery['channel'] === 'sms' ? $user->phone : $user->email,
        ], 'OTP has been resent successfully.');
    }

    public function resendOtpPhone(Request $request, $id, OtpDeliveryService $otpDelivery)
    {
        $this->checkPermission('users.edit');

        $user = User::findOrFail($id);

        if (!$user->phone) {
            return $this->errorResponse('User does not have a phone number.', 422);
        }

        if ($user->email_verified_at) {
            return $this->errorResponse('User is already verified.', 422);
        }

        Otp::where('email', $user->email)
            ->where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->delete();

        $otp = Otp::create([
            'email'      => $user->email,
            'otp'        => Otp::generateOtp(),
            'token'      => Otp::generateToken(),
            'type'       => Otp::TYPE_EMAIL_VERIFICATION,
            'name'       => $user->name,
            'expires_at' => Carbon::now()->addMinutes(10),
            'is_used'    => false,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $delivery = $otpDelivery->deliver($user, $otp, $otp->getVerificationUrl());

        $this->logAudit(
            'resend_otp_phone',
            'user',
            $user->id,
            "OTP resend to phone attempted for user #{$user->id} (actual channel: {$delivery['channel']})"
        );

        if (!$delivery['success']) {
            return $this->errorResponse('Failed to send OTP via SMS or email. Please try again later.', 500);
        }

        return $this->successResponse([
            'otp_expires_at' => $otp->expires_at->toDateTimeString(),
            'otp_channel'    => $delivery['channel'],
            'otp_sent_to'    => $delivery['channel'] === 'sms' ? $user->phone : $user->email,
        ], $delivery['channel'] === 'sms'
            ? 'OTP has been resent to your phone.'
            : 'Could not reach phone via SMS — OTP was sent to email instead.');
    }

    public function sendPasswordResetOtp(Request $request, $id, RafikiSmsService $sms)
    {
        $this->checkPermission('users.edit');

        $user = User::findOrFail($id);

        $token     = Str::random(60);
        $expiresAt = Carbon::now()->addHours(24);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $user->email],
            [
                'token'      => Hash::make($token),
                'created_at' => Carbon::now(),
                'expires_at' => $expiresAt,
            ]
        );

        $resetUrl = rtrim(config('app.frontend_url'), '/') .
            '/reset-password?email=' . urlencode($user->email) . '&token=' . $token;

        $channel  = 'email';
        $smsError = null;

        if (!empty($user->phone)) {
            $messageText = "Reset your password using this link: {$resetUrl} (expires in 24h)";
            try {
                $result     = $sms->sendSms($user->phone, $messageText);
                $httpStatus = $result['http_status'] ?? 500;
                $status     = $result['status'] ?? null;

                $isSuccess = ($httpStatus === 200 || $httpStatus === 201) 
                    && ($status === 'success' || $status === true || isset($result['message_id']));

                SmsLog::create([
                    'user_id'       => $user->id,
                    'recipient'     => $user->phone,
                    'message'       => $messageText,
                    'status'        => $isSuccess ? 'sent' : 'failed',
                    'message_id'    => $result['message_id'] ?? $result['id'] ?? null,
                    'response_data' => $result,
                    'error_message' => $isSuccess ? null : ($result['message'] ?? 'RafikiSMS returned non-success response.'),
                ]);

                if ($isSuccess) {
                    $channel = 'sms';
                } else {
                    $smsError = $result['message'] ?? 'RafikiSMS returned non-success response.';
                }
            } catch (Throwable $e) {
                $smsError = $e->getMessage();

                SmsLog::create([
                    'user_id'       => $user->id,
                    'recipient'     => $user->phone,
                    'message'       => $messageText,
                    'status'        => 'failed',
                    'error_message' => $e->getMessage(),
                ]);
            }

            if ($smsError) {
                Log::warning('Password reset SMS failed, falling back to email', [
                    'user_id' => $user->id,
                    'error'   => $smsError,
                ]);
            }
        }

        if ($channel === 'email') {
            try {
                Mail::send('emails.password-reset', [
                    'user'       => $user,
                    'token'      => $token,
                    'expires_at' => $expiresAt->toDateTimeString()
                ], function ($message) use ($user) {
                    $message->to($user->email)
                            ->subject('Password Reset Request');
                });
            } catch (Throwable $e) {
                Log::error('Password reset email failed: ' . $e->getMessage());
                return $this->errorResponse('Failed to send password reset link via SMS or email.', 500);
            }
        }

        $this->logAudit(
            'send_password_reset',
            'user',
            $user->id,
            "Password reset link sent to user #{$user->id} (via {$channel})"
        );

        return $this->successResponse([
            'reset_token' => $token,
            'expires_at'  => $expiresAt->toDateTimeString(),
            'sent_via'    => $channel,
        ], 'Password reset link has been sent to the user.');
    }
}