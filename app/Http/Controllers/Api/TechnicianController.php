<?php

namespace App\Http\Controllers\Api;

use App\Jobs\SendAdminNotificationJob;
use App\Models\Otp;
use App\Models\RegistrationDraft;
use App\Models\ServiceRequest;
use App\Models\Technician;
use App\Models\User;
use App\Services\ApprovalNotificationService;
use App\Services\FundiRegistrationNotifier;
use App\Services\GeocodingService;
use App\Services\OtpDeliveryService;
use App\Services\SmsNotificationService;
use App\Traits\Auditable;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Spatie\Permission\Models\Role;

class TechnicianController extends BaseApiController
{
    use Auditable;

    // ═══════════════════════════════════════════════════════
    // STEP 1 — create draft + send OTP (NO User row)
    // Requires: name, email/phone, password, area, service_ids
    // ═══════════════════════════════════════════════════════
    public function registerStep1(
        Request $request,
        OtpDeliveryService $otpDelivery,
        GeocodingService $geocoder
    ) {
        $email = strtolower(trim((string) $request->input('email', '')));
        $request->merge([
            'phone' => $this->normalizePhone((string) $request->input('phone', '')),
            'email' => $email !== '' ? $email : null,
        ]);

        $data = $request->validate([
            'name'             => 'required|string|min:2|max:255',
            'email'            => 'nullable|email:rfc|max:255',
            'password'         => 'required|string|min:8|confirmed',
            'phone'            => [
                'required', 'string',
                function ($attr, $value, $fail) {
                    if (!$this->isValidPhone($value)) {
                        $fail('Enter a valid phone number.');
                    }
                },
            ],
            'profile_photo'    => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'fcm_device_token' => 'nullable|string|max:4096',

            // Location
            'area'             => 'required|string|max:255',
            'latitude'         => 'nullable|numeric|between:-90,90',
            'longitude'        => 'nullable|numeric|between:-180,180',

            // Services the fundi offers — must pick at least one
            'service_ids'      => 'required|array|min:1',
            'service_ids.*'    => 'integer|exists:services,id',
        ]);

        $email = $data['email'] ?? null;

        if (User::whereIn('phone', $this->phoneVariants($data['phone']))->exists()) {
            return $this->errorResponse('This phone number is already registered.', 422);
        }
        if ($email && User::where('email', $email)->exists()) {
            return $this->errorResponse('This email is already registered.', 422);
        }

        $coords = $this->validateAndGeocodeArea(
            $data['area'],
            isset($data['latitude'])  ? (float) $data['latitude']  : null,
            isset($data['longitude']) ? (float) $data['longitude'] : null,
            $geocoder
        );

        // Deduplicate and cast to int
        $serviceIds = collect($data['service_ids'])
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values()
            ->all();

        RegistrationDraft::discardFor($data['phone'], $email);

        $fcmToken = filled($data['fcm_device_token'] ?? null) ? $data['fcm_device_token'] : null;

        DB::beginTransaction();
        try {
            $draft = RegistrationDraft::create([
                'name'              => $data['name'],
                'email'             => $email,
                'password'          => Hash::make($data['password']),
                'phone'             => $data['phone'],
                'fcm_device_token'  => $fcmToken,
                'locale'            => 'en',
                'profile_photo'     => $request->hasFile('profile_photo')
                    ? $request->file('profile_photo')->store('technician_drafts', 'public')
                    : null,
                'registration_step' => 1,

                'area'        => $data['area'],
                'latitude'    => $coords['lat'],
                'longitude'   => $coords['lng'],
                'service_ids' => $serviceIds,
            ]);

            $plainOtp = Otp::generateOtp();
            $otp      = $this->createVerificationOtpForDraft($draft, $plainOtp, $request);

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Technician draft step 1 failed', ['error' => $e->getMessage()]);
            return $this->serverError('Step 1 failed. Please try again.');
        }

        $delivery = $this->deliverVerificationOtpForDraft($draft, $otp, $plainOtp, $otpDelivery);

        return $this->successResponse([
            'draft_id'       => $draft->id,
            'step'           => 1,
            'identifier'     => $draft->phone,
            'otp_channel'    => $delivery['primary_channel'],
            'sent_to'        => $delivery['primary_sent_to'],
            'otp_sent_sms'   => $delivery['sms_sent'],
            'otp_sent_email' => $delivery['email_sent'],
            'fcm_stored'     => !empty($fcmToken),
            'area'           => $draft->area,
            'latitude'       => $draft->latitude,
            'longitude'      => $draft->longitude,
            'service_ids'    => $draft->service_ids,
        ], $delivery['message']);
    }

    // ═══════════════════════════════════════════════════════
    // VERIFY OTP
    // ═══════════════════════════════════════════════════════
    public function verifyDraftOtp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'identifier'       => 'required|string|max:255',
            'otp'              => 'required|digits:6',
            'draft_id'         => 'nullable|integer',
            'fcm_device_token' => 'nullable|string|max:512',
        ]);

        $draft = $this->resolveDraft($data['identifier'], $data['draft_id'] ?? null);

        if (!$draft) {
            return $this->errorResponse('Registration session not found.', 404);
        }
        if (!$draft->canProceed()) {
            return $this->errorResponse('Registration session expired or already submitted.', 422);
        }

        $otp = Otp::query()
            ->where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->where('phone', $draft->phone)
            ->latest()
            ->first();

        if (!$otp || !$otp->isValid()) {
            return $this->errorResponse('Code expired. Please request a new one.', 422);
        }
        if (!Hash::check($data['otp'], $otp->otp)) {
            $otp->recordFailedAttempt();
            return $this->errorResponse('Invalid code.', 422);
        }

        $otp->markAsUsed();

        $draft->otp_verified_at ??= now();
        if (!empty($data['fcm_device_token'])) {
            $draft->fcm_device_token = $data['fcm_device_token'];
        }
        $draft->save();

        return $this->issueDraftToken($draft, 'Verified. Continue with your registration.');
    }

    // ═══════════════════════════════════════════════════════
    // RESEND OTP
    // ═══════════════════════════════════════════════════════
    public function resendDraftOtp(Request $request, OtpDeliveryService $otpDelivery): JsonResponse
    {
        $data = $request->validate([
            'identifier' => 'required|string|max:255',
            'draft_id'   => 'nullable|integer',
        ]);

        $draft = $this->resolveDraft($data['identifier'], $data['draft_id'] ?? null);

        if (!$draft) {
            return $this->errorResponse('Registration session not found.', 404);
        }
        if (!$draft->canProceed()) {
            return $this->errorResponse('Registration session expired or already submitted.', 422);
        }

        $last = Otp::where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->where('phone', $draft->phone)
            ->latest()
            ->first();

        if ($last && $last->created_at && $last->created_at->gt(now()->subSeconds(60))) {
            return $this->errorResponse('Please wait a minute before requesting another code.', 429);
        }

        $plainOtp = Otp::generateOtp();
        $otp      = $this->createVerificationOtpForDraft($draft, $plainOtp, $request);
        $delivery = $this->deliverVerificationOtpForDraft($draft, $otp, $plainOtp, $otpDelivery);

        return $this->successResponse([
            'draft_id'    => $draft->id,
            'otp_channel' => $delivery['primary_channel'],
            'sent_to'     => $delivery['primary_sent_to'],
        ], $delivery['message']);
    }

    // ═══════════════════════════════════════════════════════
    // STEP 2 — Identity
    // ═══════════════════════════════════════════════════════
    public function registerStep2(Request $request)
    {
        $draft = $this->draftOrFail($request);

        abort_if($draft->registration_step < 1, 422, 'Complete step 1 first.');

        $request->merge([
            'nida' => preg_replace('/\D+/', '', (string) $request->input('nida', '')),
        ]);

        $nidaRule = match ($request->input('id_document_type')) {
            'nida'     => 'digits:20',
            'voter_id' => 'digits:12',
            default    => 'digits_between:10,20',
        };

        $request->validate([
            'id_document_type'  => 'required|in:nida,drivers_license,voter_id',
            'id_document_image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
            'nida'              => [
                'required', $nidaRule,
                function ($attr, $value, $fail) {
                    if (Technician::withTrashed()->where('nida_hash', Technician::nidaHash($value))->exists()) {
                        $fail('This ID number has already been registered.');
                    }
                },
            ],
        ]);

        $update = [
            'nida'              => $request->nida,
            'id_document_type'  => $request->id_document_type,
            'registration_step' => max((int) $draft->registration_step, 2),
        ];

        if ($request->hasFile('id_document_image')) {
            if ($draft->id_document_image && Storage::disk('public')->exists($draft->id_document_image)) {
                Storage::disk('public')->delete($draft->id_document_image);
            }
            $update['id_document_image'] = $request->file('id_document_image')
                ->store('technician_drafts', 'public');
        }

        $draft->update($update);

        return $this->successResponse(['step' => 2], 'Identity saved. Proceed to fingerprint capture.');
    }

    // ═══════════════════════════════════════════════════════
    // STEP 3 — Fingerprint
    // ═══════════════════════════════════════════════════════
    public function registerStep3(Request $request)
    {
        $draft = $this->draftOrFail($request);

        abort_if($draft->registration_step < 2, 422, 'Complete identity verification first.');

        $request->validate(['fingerprint_data' => 'required|string|max:200000']);

        $draft->update([
            'fingerprint_data'     => $request->fingerprint_data,
            'fingerprint_enrolled' => true,
            'registration_step'    => max((int) $draft->registration_step, 3),
        ]);

        return $this->successResponse(['step' => 3], 'Fingerprint captured. Proceed to face capture.');
    }

    // ═══════════════════════════════════════════════════════
    // STEP 4 — Face
    // ═══════════════════════════════════════════════════════
    public function registerStep4(Request $request)
    {
        $draft = $this->draftOrFail($request);

        abort_if($draft->registration_step < 3, 422, 'Complete fingerprint capture first.');

        $request->validate(['face_data' => 'required|string|max:6000000']);

        $draft->update([
            'face_data'         => $request->face_data,
            'face_enrolled'     => true,
            'registration_step' => max((int) $draft->registration_step, 4),
        ]);

        return $this->successResponse(['step' => 4], 'Face captured. Proceed to emergency contact.');
    }

    // ═══════════════════════════════════════════════════════
    // STEP 5 — Next of kin
    // ═══════════════════════════════════════════════════════
    public function registerStep5(Request $request)
    {
        $draft = $this->draftOrFail($request);

        abort_if($draft->registration_step < 4, 422, 'Complete face capture first.');

        $request->validate([
            'next_of_kin_name'         => 'required|string|max:255',
            'next_of_kin_phone'        => 'required|string|max:20',
            'next_of_kin_relationship' => 'required|string|max:100',
        ]);

        $draft->update([
            'next_of_kin_name'         => $request->next_of_kin_name,
            'next_of_kin_phone'        => $request->next_of_kin_phone,
            'next_of_kin_relationship' => $request->next_of_kin_relationship,
            'registration_step'        => max((int) $draft->registration_step, 5),
        ]);

        return $this->successResponse(['step' => 5], 'Emergency contact saved. Proceed to review & submit.');
    }

    // ═══════════════════════════════════════════════════════
    // STEP 6 — Creates User + Technician + services atomically
    //          then emails every ADMINISTRATOR (name, area, services)
    // ═══════════════════════════════════════════════════════
    public function registerStep6(Request $request)
    {
        $draft = $this->draftOrFail($request);

        $request->validate(['fcm_device_token' => 'nullable|string|max:4096']);

        $fcmToken = filled($request->input('fcm_device_token'))
            ? $request->input('fcm_device_token')
            : $draft->fcm_device_token;

        if ($draft->registration_step < 5 || empty($draft->nida) || empty($draft->id_document_type)) {
            return $this->errorResponse('Please complete all registration steps before submitting.', 422);
        }
        if (!$draft->hasCompletedLocation()) {
            return $this->errorResponse('Service area, latitude and longitude are required. Please update step 1.', 422);
        }
        if (!$draft->hasCompletedServices()) {
            return $this->errorResponse('Select at least one service you offer. Please update step 1.', 422);
        }
        if (!$draft->hasCompletedBiometrics()) {
            return $this->errorResponse('Biometrics incomplete. Please complete fingerprint and face capture.', 422);
        }
        if (!$draft->hasCompletedNextOfKin()) {
            return $this->errorResponse('Next of kin details are required.', 422);
        }

        if (User::whereIn('phone', $this->phoneVariants($draft->phone))->exists()) {
            return $this->errorResponse('Phone number already registered.', 422);
        }
        if ($draft->email && User::where('email', $draft->email)->exists()) {
            return $this->errorResponse('Email already registered.', 422);
        }
        if (Technician::withTrashed()->where('nida_hash', Technician::nidaHash($draft->nida))->exists()) {
            return $this->errorResponse('This ID number has already been registered.', 422);
        }

        DB::beginTransaction();
        try {
            $fundiRole = Role::where('name', 'FUNDI')->where('guard_name', 'web')->first();
            if (!$fundiRole) {
                throw new \RuntimeException('The FUNDI role is missing.');
            }

            $user = new User();
            $user->forceFill([
                'name'              => $draft->name,
                'email'             => $draft->email,
                'password'          => $draft->password,
                'phone'             => $draft->phone,
                'status'            => 'pending',
                'is_active'         => false,
                'locale'            => $draft->locale ?: 'en',
                'fcm_device_token'  => $fcmToken,
                'email_verified_at' => null,
                'phone_verified_at' => $draft->otp_verified_at ?? now(),
            ])->save();

            $user->assignRole($fundiRole);

            $technician = Technician::create([
                'user_id'                  => $user->id,
                'profile_photo'            => $draft->profile_photo,
                'nida'                     => $draft->nida,
                'id_document_type'         => $draft->id_document_type,
                'id_document_image'        => $draft->id_document_image,
                'fingerprint_data'         => $draft->fingerprint_data,
                'fingerprint_enrolled'     => true,
                'face_data'                => $draft->face_data,
                'face_enrolled'            => true,
                'next_of_kin_name'         => $draft->next_of_kin_name,
                'next_of_kin_phone'        => $draft->next_of_kin_phone,
                'next_of_kin_relationship' => $draft->next_of_kin_relationship,
                'registration_step'        => 6,
                'registration_completed'   => true,
                'verified'                 => false,
                'verification_status'      => 'pending',
                'area'                     => $draft->area,
                'latitude'                 => $draft->latitude,
                'longitude'                => $draft->longitude,
                'is_online'                => false,
            ]);

            // Attach chosen services to the technician_services pivot
            $technician->services()->sync($draft->service_ids);

            $authToken = $user->createToken('mobile')->plainTextToken;

            $draft->tokens()->delete();
            $draft->forceDelete();

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();

            Log::error('Submit registration failed', [
                'draft_id' => $draft->id,
                'error'    => $e->getMessage(),
                'at'       => $e->getFile() . ':' . $e->getLine(),
            ]);

            if ($e instanceof QueryException && str_contains($e->getMessage(), 'Duplicate entry')) {
                $msg = $e->getMessage();
                return match (true) {
                    str_contains($msg, 'nida_hash') => $this->errorResponse('This ID number has already been registered.', 422),
                    str_contains($msg, 'phone')     => $this->errorResponse('Phone number already registered.', 422),
                    str_contains($msg, 'email')     => $this->errorResponse('Email already registered.', 422),
                    default                         => $this->errorResponse('This registration already exists.', 422),
                };
            }

            return $this->serverError(
                config('app.debug')
                    ? 'Submission failed: ' . $e->getMessage()
                    : 'Submission failed. Please try again.'
            );
        }

        // ── Post-registration side effects (never break the response) ──
        try {
            SendAdminNotificationJob::dispatch(
                $user->name ?? 'Unknown',
                $user->email ?: $user->phone,
                $technician->id
            );
            $this->logAudit('register_step6', 'technician', $technician->id, 'Registration submitted for admin approval');
        } catch (\Throwable $e) {
            Log::warning('Post-registration side effects failed', ['error' => $e->getMessage()]);
        }

        // Email all active ADMINISTRATORs: fundi name, area and services.
        // The notifier catches its own errors, so this can never fail the request.
        FundiRegistrationNotifier::notifyAdministrators($technician);

        return $this->successResponse([
            'user'           => $user->only(['id', 'name', 'email', 'phone', 'status']),
            'technician_id'  => $technician->id,
            'token'          => $authToken,
            'status'         => 'pending_verification',
            'phone_verified' => true,
            'fcm_registered' => !empty($fcmToken),
            'area'           => $technician->area,
            'latitude'       => $technician->latitude,
            'longitude'      => $technician->longitude,
            'services'       => $technician->services()->get(['services.id', 'services.name']),
        ], 'Registration submitted. Waiting for admin approval.');
    }

    // ═══════════════════════════════════════════════════════
    // STATUS — drafts (public)
    // ═══════════════════════════════════════════════════════
    public function registrationStatus($id)
    {
        $draft = RegistrationDraft::find($id);

        if (!$draft) {
            return $this->notFound('Registration not found.');
        }

        return $this->successResponse([
            'draft_id'               => $draft->id,
            'registration_step'      => (int) $draft->registration_step,
            'registration_completed' => false,
            'can_proceed'            => $draft->canProceed(),
            'otp_verified'           => $draft->isOtpVerified(),
            'fingerprint_enrolled'   => (bool) $draft->fingerprint_enrolled,
            'face_enrolled'          => (bool) $draft->face_enrolled,
            'area'                   => $draft->area,
            'latitude'               => $draft->latitude,
            'longitude'              => $draft->longitude,
            'service_ids'            => $draft->service_ids ?? [],
        ]);
    }

    // ═══════════════════════════════════════════════════════
    // STATUS — authenticated technician
    // ═══════════════════════════════════════════════════════
    public function myRegistrationStatus(Request $request)
    {
        $user = $request->user();

        if (!$user instanceof User) {
            return $this->unauthorized('A user session is required.');
        }

        $technician = $user->technician;

        if (!$technician) {
            return $this->notFound('Technician profile not found.');
        }

        return $this->successResponse([
            'user_id'                => $user->id,
            'technician_id'          => $technician->id,
            'registration_step'      => (int) $technician->registration_step,
            'registration_completed' => (bool) $technician->registration_completed,
            'verification_status'    => $technician->verification_status,
            'verified'               => (bool) $technician->verified,
            'phone_verified'         => !empty($user->phone_verified_at),
            'email_verified'         => !empty($user->email_verified_at),
            'account_status'         => $user->status,
            'is_active'              => (bool) $user->is_active,
            'approval_pending'       => $technician->registration_completed
                && $technician->verification_status === 'pending',
            'area'                   => $technician->area,
            'latitude'               => $technician->latitude,
            'longitude'              => $technician->longitude,
            'services'               => $technician->services()->get(['services.id', 'services.name']),
        ], 'Registration status retrieved.');
    }

    // ═══════════════════════════════════════════════════════
    // FCM DEVICE TOKEN
    // ═══════════════════════════════════════════════════════
    public function updateFcmToken(Request $request)
    {
        $request->validate(['fcm_device_token' => 'required|string|max:4096']);

        $user = $request->user();
        if (!$user instanceof User) {
            return $this->unauthorized('A user session is required.');
        }

        $user->update(['fcm_device_token' => $request->fcm_device_token]);

        $this->logAudit('update_fcm_token', 'user', $user->id, 'FCM token refreshed');

        return $this->successResponse(null, 'FCM device token saved.');
    }

    // ═══════════════════════════════════════════════════════
    // ADMIN: APPROVE / VERIFY
    // ═══════════════════════════════════════════════════════
    public function approve($id, ApprovalNotificationService $notifier, SmsNotificationService $sms)
    {
        return $this->approveTechnician(
            $id, $notifier, $sms,
            requireCompleted: true,
            event: 'approved',
            message: 'Technician approved successfully.'
        );
    }

    public function verify($id, ApprovalNotificationService $notifier, SmsNotificationService $sms)
    {
        return $this->approveTechnician(
            $id, $notifier, $sms,
            requireCompleted: false,
            event: 'verified',
            message: 'Technician verified successfully.'
        );
    }

    // ═══════════════════════════════════════════════════════
    // PROFILE MANAGEMENT
    // ═══════════════════════════════════════════════════════
    public function getOwnProfile(Request $request)
    {
        $technician = $request->user()->technician()
            ->with('services', 'portfolios', 'user')
            ->first();

        if (!$technician) {
            return $this->notFound('Technician profile not found.');
        }

        $technician->makeVisible(['nida', 'next_of_kin_name', 'next_of_kin_phone', 'next_of_kin_relationship']);

        return $this->successResponse($technician);
    }

    public function updateProfile(Request $request, GeocodingService $geocoder)
    {
        $technician = $request->user()->technician;

        if (!$technician) {
            return $this->notFound('Technician profile not found.');
        }

        $request->validate([
            'hourly_rate' => 'nullable|numeric|min:0|max:999999.99',
            'area'        => 'nullable|string|max:255',
            'latitude'    => 'nullable|numeric|between:-90,90',
            'longitude'   => 'nullable|numeric|between:-180,180',
        ]);

        $updateData = $request->only(['hourly_rate', 'area', 'latitude', 'longitude']);

        if ($request->filled('area') && !$request->has('latitude') && !$request->has('longitude')) {
            $coords = $geocoder->geocode($request->area);
            if (!$coords) {
                abort(422, "We couldn't locate '{$request->area}'. Please check the spelling or enter a more specific location.");
            }
            $updateData['latitude']  = $coords['lat'];
            $updateData['longitude'] = $coords['lng'];
        }

        $technician->update($updateData);

        $this->logAudit('update_technician_profile', 'technician', $technician->id, 'Profile updated');

        return $this->successResponse($technician->load('services'), 'Profile updated.');
    }

    public function uploadProfilePhoto(Request $request)
    {
        $request->validate([
            'profile_photo' => 'required|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        $technician = $request->user()->technician;

        if (!$technician) {
            return $this->notFound('Technician profile not found.');
        }

        if ($technician->profile_photo && Storage::disk('public')->exists($technician->profile_photo)) {
            Storage::disk('public')->delete($technician->profile_photo);
        }

        $path = $request->file('profile_photo')->store('technicians', 'public');
        $technician->update(['profile_photo' => $path]);

        $this->logAudit('upload_profile_photo', 'technician', $technician->id, 'Profile photo updated');

        return $this->successResponse([
            'profile_photo' => url('storage/' . $path),
        ], 'Profile photo updated successfully.');
    }

    public function updateServices(Request $request)
    {
        $technician = $request->user()->technician;

        if (!$technician) {
            return $this->notFound('Technician not found.');
        }

        $data = $request->validate([
            'services'   => 'required|array|min:1',
            'services.*' => 'exists:services,id',
        ]);

        $technician->services()->sync($data['services']);

        $this->logAudit('update_technician_services', 'technician', $technician->id, 'Services updated');

        return $this->successResponse($technician->load('services'), 'Services updated successfully.');
    }

    // ═══════════════════════════════════════════════════════
    // LOCATION
    // ═══════════════════════════════════════════════════════
    public function updateLocation(Request $request)
    {
        $request->validate([
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $technician = $request->user()->technician;

        if (!$technician) {
            return $this->notFound('Technician profile not found.');
        }

        $technician->update([
            'latitude'            => $request->latitude,
            'longitude'           => $request->longitude,
            'location_updated_at' => now(),
        ]);

        return $this->successResponse(null, 'Location updated.');
    }

    public function heartbeat(Request $request)
    {
        $technician = $request->user()->technician;

        if (!$technician) {
            return $this->notFound('Technician profile not found.');
        }

        $technician->recordHeartbeat(
            $request->input('latitude'),
            $request->input('longitude')
        );

        return $this->successResponse(null, 'Heartbeat recorded.');
    }

    // ═══════════════════════════════════════════════════════
    // PUBLIC ENDPOINTS
    // ═══════════════════════════════════════════════════════
    public function publicIndex(Request $request)
    {
        $query = Technician::with(['user', 'services', 'portfolios'])
            ->where('verified', true)
            ->whereHas('user', fn ($q) => $q->where('is_active', true));

        if ($request->filled('service_id')) {
            $query->whereHas('services', fn ($q) => $q->where('services.id', $request->service_id));
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('area', 'LIKE', "%{$search}%")
                  ->orWhereHas('user', fn ($uq) => $uq->where('name', 'LIKE', "%{$search}%"))
                  ->orWhereHas('services', function ($sq) use ($search) {
                      $sq->where('name', 'LIKE', "%{$search}%")
                         ->orWhere('swahili_name', 'LIKE', "%{$search}%");
                  });
            });
        }

        return $this->successResponse($query->paginate($request->input('per_page', 15)));
    }

    public function show($id)
    {
        $viewer       = auth('sanctum')->user();
        $isPrivileged = $viewer instanceof User && $viewer->can('technicians.view');

        $relations = ['user', 'services', 'portfolios'];
        if ($isPrivileged) {
            $relations[] = 'user.subscriptions.rateCard';
        }

        $technician = Technician::with($relations)->find($id);

        if (!$technician) {
            return $this->notFound('Technician not found.');
        }

        if ($isPrivileged) {
            $technician->makeVisible([
                'nida',
                'id_document_type',
                'id_document_image',
                'registration_step',
                'registration_completed',
                'verification_status',
                'verified',
                'last_activity_at',
                'location_updated_at',
            ]);
        }

        return $this->successResponse($technician);
    }

    // ═══════════════════════════════════════════════════════
    // TRACKING
    // ═══════════════════════════════════════════════════════
    public function getTrackingData(Request $request, $requestId)
    {
        $requestModel = ServiceRequest::with(['technician', 'customer'])->findOrFail($requestId);

        $technician = $requestModel->technician;
        $customer   = $requestModel->customer;

        if (!$technician || !$customer) {
            return $this->notFound('Technician or Customer not found.');
        }

        $techLat = $technician->latitude;
        $techLng = $technician->longitude;
        $custLat = $requestModel->latitude ?? $customer->latitude;
        $custLng = $requestModel->longitude ?? $customer->longitude;

        if (is_null($techLat) || is_null($techLng)) {
            return $this->successResponse([
                'technician_location' => null,
                'customer_location'   => ['lat' => $custLat, 'lng' => $custLng],
                'distance_km'         => null,
                'eta'                 => null,
            ], 'Technician location not available yet.');
        }

        $distance   = $this->haversineGreatCircleDistance($techLat, $techLng, $custLat, $custLng);
        $etaMinutes = $distance > 0 ? ($distance / 30) * 60 : 0;

        return $this->successResponse([
            'technician_location' => ['lat' => (float) $techLat, 'lng' => (float) $techLng],
            'customer_location'   => ['lat' => (float) $custLat, 'lng' => (float) $custLng],
            'distance_km'         => round($distance, 2),
            'eta'                 => now()->addMinutes($etaMinutes)->toIso8601String(),
        ], 'Tracking data retrieved.');
    }

    // ═══════════════════════════════════════════════════════
    // ADMIN — single list (legacy)
    // ═══════════════════════════════════════════════════════
    public function adminIndex(Request $request)
    {
        $this->checkPermission('technicians.view');

        $query = Technician::with(['user', 'services', 'portfolios']);

        $this->applyAdminSearch($query, $request->input('search'));

        return $this->successResponse($query->paginate((int) $request->input('per_page', 15)));
    }

    // ═══════════════════════════════════════════════════════
    // ADMIN — split lists
    // ═══════════════════════════════════════════════════════
    public function adminPendingIndex(Request $request)
    {
        $this->checkPermission('technicians.view');

        $query = Technician::with(['user', 'services', 'portfolios'])
            ->where(function ($q) {
                $q->where('verified', false)
                  ->orWhere('verification_status', '!=', 'approved')
                  ->orWhereNull('verification_status');
            });

        $this->applyAdminSearch($query, $request->input('search'));

        return $this->successResponse(
            $query->latest('created_at')->paginate((int) $request->input('per_page', 15))
        );
    }

    public function adminApprovedIndex(Request $request)
    {
        $this->checkPermission('technicians.view');

        $query = Technician::with(['user.subscriptions.rateCard', 'services', 'portfolios'])
            ->where('verified', true)
            ->where('verification_status', 'approved');

        $this->applyAdminSearch($query, $request->input('search'));

        return $this->successResponse(
            $query->latest('created_at')->paginate((int) $request->input('per_page', 15))
        );
    }

    // ═══════════════════════════════════════════════════════
    // ADMIN — biometrics
    // ═══════════════════════════════════════════════════════
    public function adminBiometrics($id)
    {
        $this->checkPermission('technicians.view');

        $technician = Technician::with(['user', 'services'])->find($id);

        if (!$technician) {
            return $this->notFound('Technician not found.');
        }

        $technician->makeVisible([
            'nida',
            'fingerprint_data',
            'face_data',
            'id_document_image',
        ]);

        $idDocUrl = $technician->id_document_image
            ? url('storage/' . ltrim($technician->id_document_image, '/'))
            : null;

        $profilePhotoUrl = $technician->profile_photo
            ? url('storage/' . ltrim($technician->profile_photo, '/'))
            : null;

        return $this->successResponse([
            'technician_id'         => $technician->id,
            'user'                  => $technician->user?->only(['id', 'name', 'email', 'phone']),
            'profile_photo_url'     => $profilePhotoUrl,

            'nida'                  => $technician->nida,
            'id_document_type'      => $technician->id_document_type,
            'id_document_image_url' => $idDocUrl,

            'fingerprint_enrolled'    => (bool) $technician->fingerprint_enrolled,
            'fingerprint_data'        => $technician->fingerprint_data,
            'fingerprint_captured_at' => $technician->fingerprint_captured_at,
            'fingerprint_hash'        => $technician->fingerprint_hash,
            'fingerprint_template'    => $technician->fingerprint_template,

            'face_enrolled'    => (bool) $technician->face_enrolled,
            'face_data'        => $technician->face_data,
            'face_captured_at' => $technician->face_captured_at,

            'next_of_kin_name'         => $technician->next_of_kin_name,
            'next_of_kin_phone'        => $technician->next_of_kin_phone,
            'next_of_kin_relationship' => $technician->next_of_kin_relationship,

            'area'      => $technician->area,
            'latitude'  => $technician->latitude,
            'longitude' => $technician->longitude,

            'services'  => $technician->services->map(fn ($s) => [
                'id'   => $s->id,
                'name' => $s->name,
            ])->values(),

            'registration_step'      => (int) $technician->registration_step,
            'registration_completed' => (bool) $technician->registration_completed,
            'verification_status'    => $technician->verification_status,
            'verified'               => (bool) $technician->verified,
        ]);
    }

    // ═══════════════════════════════════════════════════════
    // PRIVATE — shared admin search
    // ═══════════════════════════════════════════════════════
    private function applyAdminSearch($query, ?string $search): void
    {
        if (!$search) {
            return;
        }

        $query->where(function ($q) use ($search) {
            $q->where('area', 'LIKE', "%{$search}%")
              ->orWhereHas('user', function ($uq) use ($search) {
                  $uq->where('name', 'LIKE', "%{$search}%")
                     ->orWhere('email', 'LIKE', "%{$search}%")
                     ->orWhere('phone', 'LIKE', "%{$search}%");
              })
              ->orWhereHas('services', function ($sq) use ($search) {
                  $sq->where('name', 'LIKE', "%{$search}%")
                     ->orWhere('swahili_name', 'LIKE', "%{$search}%");
              });
        });
    }

    // ═══════════════════════════════════════════════════════
    // PRIVATE — phone / email helpers
    // ═══════════════════════════════════════════════════════
    private function normalizePhone(string $raw): string
    {
        $digits = preg_replace('/\D+/', '', $raw) ?? '';

        if (str_starts_with($digits, '00')) {
            return substr($digits, 2);
        }
        if (str_starts_with($digits, '0')) {
            return '255' . substr($digits, 1);
        }

        return $digits;
    }

    private function isValidPhone(string $normalized): bool
    {
        if (!preg_match('/^\d{9,15}$/', $normalized)) {
            return false;
        }
        if (str_starts_with($normalized, '255')) {
            return (bool) preg_match('/^255[67]\d{8}$/', $normalized);
        }
        return true;
    }

    private function phoneVariants(string $phone): array
    {
        $n        = $this->normalizePhone($phone);
        $variants = [$n, '+' . $n];

        if (str_starts_with($n, '255')) {
            $variants[] = '0' . substr($n, 3);
        }

        return array_values(array_unique($variants));
    }

    private function resolveDraft(string $identifier, ?int $draftId): ?RegistrationDraft
    {
        $identifier = trim($identifier);
        $query      = RegistrationDraft::query();

        if ($draftId) {
            $query->whereKey($draftId);
        }

        if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
            $query->where('email', strtolower($identifier));
        } else {
            $query->whereIn('phone', $this->phoneVariants($identifier));
        }

        return $query->latest('id')->first();
    }

    // ═══════════════════════════════════════════════════════
    // PRIVATE — draft helpers
    // ═══════════════════════════════════════════════════════
    private function draftOrFail(Request $request): RegistrationDraft
    {
        $subject = $request->user();

        abort_unless(
            $subject instanceof RegistrationDraft,
            403,
            'A registration session token is required.'
        );

        abort_if(
            !$subject->canProceed(),
            422,
            'Registration session expired or already submitted.'
        );

        abort_unless(
            $subject->isOtpVerified(),
            403,
            'Verify your phone/email with OTP before continuing registration.'
        );

        return $subject;
    }

    private function issueDraftToken(RegistrationDraft $draft, string $message): JsonResponse
    {
        $draft->tokens()->delete();
        $token = $draft->createToken('registration')->plainTextToken;

        return $this->successResponse([
            'draft_id'           => $draft->id,
            'registration_token' => $token,
            'step'               => $draft->registration_step,
        ], $message);
    }

    private function createVerificationOtpForDraft(
        RegistrationDraft $draft,
        string $plainOtp,
        Request $request
    ): Otp {
        Otp::where('type', Otp::TYPE_EMAIL_VERIFICATION)
            ->where('phone', $draft->phone)
            ->delete();

        $otp = Otp::create([
            'email'      => $draft->email,
            'phone'      => $draft->phone,
            'otp'        => Hash::make($plainOtp),
            'token'      => Otp::generateToken(),
            'type'       => Otp::TYPE_EMAIL_VERIFICATION,
            'name'       => $draft->name,
            'expires_at' => now()->addMinutes(10),
            'is_used'    => false,
            'attempts'   => 0,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $otp->plain_otp = $plainOtp;

        return $otp;
    }

    private function deliverVerificationOtpForDraft(
        RegistrationDraft $draft,
        Otp $otp,
        string $plainOtp,
        OtpDeliveryService $otpDelivery
    ): array {
        $transient = new User([
            'name'  => $draft->name,
            'email' => $draft->email,
            'phone' => $draft->phone,
        ]);
        $transient->id = null;

        return $this->deliverVerificationOtp($transient, $otp, $plainOtp, $otpDelivery);
    }

    // ═══════════════════════════════════════════════════════
    // PRIVATE — OTP delivery
    // ═══════════════════════════════════════════════════════
    private function deliverVerificationOtp(
        User $user,
        Otp $otp,
        string $plainOtp,
        OtpDeliveryService $otpDelivery
    ): array {
        $smsSent        = false;
        $primaryChannel = 'none';
        $primarySentTo  = null;

        if (!empty($user->phone)) {
            try {
                $result = $otpDelivery->deliver(
                    $user,
                    $otp,
                    method_exists($otp, 'getVerificationUrl') ? $otp->getVerificationUrl() : null
                );

                $reported = $result['channel'] ?? 'sms';

                if ($reported === 'sms') {
                    $smsSent        = true;
                    $primaryChannel = 'sms';
                    $primarySentTo  = $result['otp_sent_to'] ?? $user->phone;
                } elseif ($reported === 'email') {
                    $primaryChannel = 'email';
                    $primarySentTo  = $result['otp_sent_to'] ?? $user->email;
                }
            } catch (\Throwable $e) {
                Log::warning('SMS OTP delivery failed', [
                    'phone' => $user->phone,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        $emailSent = false;
        if (!empty($user->email) && $primaryChannel !== 'email') {
            try {
                $this->sendOtpEmail($user, $plainOtp);
                $emailSent = true;

                if ($primaryChannel === 'none') {
                    $primaryChannel = 'email';
                    $primarySentTo  = $user->email;
                }
            } catch (\Throwable $e) {
                Log::warning('Email OTP delivery failed', [
                    'email' => $user->email,
                    'error' => $e->getMessage(),
                ]);
            }
        } elseif ($primaryChannel === 'email') {
            $emailSent = true;
        }

        return [
            'sms_sent'        => $smsSent,
            'email_sent'      => $emailSent,
            'primary_channel' => $primaryChannel,
            'primary_sent_to' => $primarySentTo,
            'message'         => $this->buildOtpMessage($user, $smsSent, $emailSent),
        ];
    }

    private function sendOtpEmail(User $user, string $plainOtp): void
    {
        Mail::raw(
            "Your Nearby Fundi verification code is: {$plainOtp}\n\n"
            . "This code expires in 10 minutes.\n"
            . "If you didn't request it, please ignore this email.",
            function ($message) use ($user) {
                $message->to($user->email)->subject('Your Nearby Fundi Verification Code');
            }
        );
    }

    private function buildOtpMessage(User $user, bool $sms, bool $email): string
    {
        if ($sms && $email) {
            return 'A verification code has been sent to your phone and email.';
        }
        if ($sms) {
            return "A verification code has been sent via SMS to {$user->phone}.";
        }
        if ($email) {
            return "A verification code has been sent to your email ({$user->email}).";
        }

        return 'We could not deliver the verification code. Please use the resend option.';
    }

    // ═══════════════════════════════════════════════════════
    // PRIVATE — approval (no free trial / no subscription)
    // ═══════════════════════════════════════════════════════
    private function approveTechnician(
        $id,
        ApprovalNotificationService $notifier,
        SmsNotificationService $sms,
        bool $requireCompleted,
        string $event,
        string $message
    ): JsonResponse {
        $technician = Technician::with('user')->find($id);

        if (!$technician) {
            return $this->notFound('Technician not found.');
        }
        if ($requireCompleted && !$technician->registration_completed) {
            return $this->errorResponse('Technician has not completed registration.', 422);
        }
        if ($technician->verified && $technician->verification_status === 'approved') {
            return $this->errorResponse('Technician is already approved.', 422);
        }
        if (!$technician->user) {
            return $this->errorResponse('Technician has no user account.', 422);
        }

        try {
            $this->activateApprovedTechnician($technician);
        } catch (\Throwable $e) {
            Log::error('Technician approval failed', ['technician_id' => $id, 'error' => $e->getMessage()]);
            return $this->serverError('Approval failed: ' . $e->getMessage());
        }

        $notifier->notifyApproved($technician->user, null, $technician->id, $event);
        $sms->notifyFundiApproved($technician->user);

        $this->logAudit("{$event}_technician", 'technician', $technician->id, "Technician #{$technician->id} {$event}");

        return $this->successResponse($technician->fresh()->load('user'), $message);
    }

    private function activateApprovedTechnician(Technician $technician): void
    {
        DB::beginTransaction();
        try {
            $technician->update([
                'verified'            => true,
                'verification_status' => 'approved',
            ]);

            $technician->user->update([
                'status'    => 'active',
                'is_active' => true,
            ]);

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    private function haversineGreatCircleDistance(
        $latitudeFrom, $longitudeFrom,
        $latitudeTo,   $longitudeTo,
        $earthRadius = 6371
    ) {
        $latFrom = deg2rad($latitudeFrom);
        $lonFrom = deg2rad($longitudeFrom);
        $latTo   = deg2rad($latitudeTo);
        $lonTo   = deg2rad($longitudeTo);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $angle = 2 * asin(sqrt(
            pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)
        ));

        return $angle * $earthRadius;
    }

    // ═══════════════════════════════════════════════════════
    // PRIVATE — geocoding helper (used by registerStep1)
    // ═══════════════════════════════════════════════════════
    private function validateAndGeocodeArea(
        string $area,
        ?float $lat,
        ?float $lng,
        GeocodingService $geocoder
    ): array {
        if ($lat !== null && $lng !== null) {
            return ['lat' => $lat, 'lng' => $lng];
        }

        $coords = $geocoder->geocode($area);
        if (!$coords) {
            abort(422, "Could not locate the area '{$area}'. Please check the spelling or provide latitude/longitude.");
        }

        return $coords;
    }
}