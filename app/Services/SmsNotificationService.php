<?php

namespace App\Services;

use App\Models\Job;
use App\Models\ServiceRequest;
use App\Models\SmsLog;
use App\Models\Technician;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Throwable;

class SmsNotificationService
{
    public function __construct(protected RafikiSmsService $smsService)
    {
    }

    /** Send the registration OTP by SMS. */
    public function notifyUserOtp(User $user, string $otp, int $validMinutes = 10): array
    {
        $message = "Nearbyfundi: Your code is {$otp}. "
                 . "It expires in {$validMinutes} minutes. Never share it with anyone.";

        return $this->sendSms($user, $message, 'registration_otp', ['user_id' => $user->id]);
    }

    /** Send the job completion OTP code by SMS to the user/fundi. */
    public function notifyJobCompletionCode(User $user, Job $job, string $message): array
    {
        return $this->sendSms($user, $message, 'job_completion_code', [
            'job_id'     => $job->id,
            'job_number' => $job->job_number,
        ]);
    }

    /**
     * Notify every active ADMINISTRATOR (with a phone) that a fundi
     * has submitted a registration for approval.
     */
    public function notifyAdminsNewFundiRegistration(string $fundiName, ?string $fundiContact, int $technicianId): array
    {
        $admins = User::role('ADMINISTRATOR', 'web')
            ->where('is_active', true)
            ->whereNotNull('phone')
            ->where('phone', '!=', '')
            ->get()
            ->unique('phone');

        if ($admins->isEmpty()) {
            Log::warning('No active administrators with a phone number to notify', [
                'technician_id' => $technicianId,
            ]);
            return [];
        }

        $contact = $fundiContact ?: 'N/A';
        $message = "Nearbyfundi: New fundi {$fundiName} ({$contact}) is waiting for approval. "
                 . "Open the admin panel to review.";

        $results = [];
        foreach ($admins as $admin) {
            $results[] = $this->sendSms($admin, $message, 'admin_new_fundi_registration', [
                'technician_id' => $technicianId,
                'admin_id'      => $admin->id,
                'fundi_name'    => $fundiName,
            ]);
        }

        return $results;
    }

    /** Tell a fundi their account is approved. */
    public function notifyFundiApproved(User $user, int $trialDays = 1): array
    {
        $message = "Nearbyfundi: Congratulations {$user->name}! Your account is approved. "
                 . "Enjoy your {$trialDays}-day free trial. Open the app to start getting jobs.";

        return $this->sendSms($user, $message, 'fundi_approved', ['user_id' => $user->id]);
    }

    /** Customer sent a request → SMS to the fundi. */
    public function notifyTechnicianNewRequest(ServiceRequest $request, Technician $technician): array
    {
        $customerName = $request->customer->name ?? 'Customer';
        $serviceName  = $request->service->name ?? 'a service';

        $message = "Nearbyfundi: New {$serviceName} request from {$customerName}. "
                 . "Open the app to view and accept.";

        return $this->sendSms($technician->user, $message, 'technician_new_request', [
            'request_id'    => $request->id,
            'customer_id'   => $request->customer->id ?? null,
            'technician_id' => $technician->id,
            'service_name'  => $serviceName,
        ]);
    }

    /**
     * Fundi accepted → SMS to the customer.
     * A Job is already created automatically, so we tell the customer where to
     * find it: Jobs section → "Contact Fundi" or in-app chat.
     */
    public function notifyCustomerRequestAccepted(ServiceRequest $request, Technician $technician): array
    {
        $customer       = $request->customer;
        $technicianName = $technician->user->name ?? 'Technician';
        $serviceName    = $request->service->name ?? 'your service';

        $message = "Nearbyfundi: {$technicianName} accepted your {$serviceName} request. "
                 . "Log in to the app, open the Jobs section and tap Contact Fundi, "
                 . "or chat with the fundi inside the app.";

        return $this->sendSms($customer, $message, 'request_accepted', [
            'request_id'      => $request->id,
            'technician_id'   => $technician->id,
            'customer_id'     => $customer->id ?? null,
            'technician_name' => $technicianName,
            'service_name'    => $serviceName,
        ]);
    }

    /** Fundi rejected → SMS to the customer. */
    public function notifyCustomerRequestRejected(ServiceRequest $request, Technician $technician): array
    {
        $customer       = $request->customer;
        $technicianName = $technician->user->name ?? 'The fundi';
        $serviceName    = $request->service->name ?? 'your service';

        $message = "Nearbyfundi: {$technicianName} could not take your {$serviceName} request. "
                 . "Open the app to choose another fundi.";

        return $this->sendSms($customer, $message, 'request_rejected', [
            'request_id'      => $request->id,
            'technician_id'   => $technician->id,
            'customer_id'     => $customer->id ?? null,
            'technician_name' => $technicianName,
            'service_name'    => $serviceName,
        ]);
    }

    /** Customer cancelled a pending request → SMS to the fundi. */
    public function notifyTechnicianRequestCancelled(ServiceRequest $request, Technician $technician): array
    {
        $customerName = $request->customer->name ?? 'The customer';
        $serviceName  = $request->service->name ?? 'a service';

        $message = "Nearbyfundi: {$customerName} cancelled the {$serviceName} request. "
                 . "No action is needed.";

        return $this->sendSms($technician->user, $message, 'request_cancelled', [
            'request_id'    => $request->id,
            'technician_id' => $technician->id,
            'customer_id'   => $request->customer->id ?? null,
            'service_name'  => $serviceName,
        ]);
    }

    public function notifyMultipleTechnicians(ServiceRequest $request, array $technicianIds): array
    {
        $results = [];

        foreach ($technicianIds as $technicianId) {
            $technician = Technician::with('user')->find($technicianId);
            if ($technician?->user) {
                $results[] = $this->notifyTechnicianNewRequest($request, $technician);
            }
        }

        return $results;
    }

    /**
     * SMS delivery for System Updates has been DISABLED.
     * 
     * This method is kept only as a safety stub. If an old queued job 
     * tries to fire an SMS for a system update, it will immediately return
     * a "skipped" success state without sending an SMS or throwing an error.
     */
    public function notifySystemUpdate(User $user, \App\Models\SystemUpdate $update): array
    {
        return [
            'success' => false, 
            'skipped' => true, 
            'error'   => 'SMS delivery for system updates is disabled.'
        ];
    }

    protected function sendSms(User $user, string $message, string $type, array $metadata = []): array
    {
        if (empty($user->phone)) {
            Log::warning('SMS not sent: user has no phone number', ['user_id' => $user->id, 'type' => $type]);
            return ['success' => false, 'error' => 'User has no phone number', 'type' => $type];
        }

        $logMessage = in_array($type, ['registration_otp', 'job_completion_code']) 
            ? 'OG SUPER APP: [OTP hidden]' 
            : $message;

        try {
            $result = $this->smsService->sendSms($user->phone, $message);

            $isSuccess = ($result['success'] ?? false) === true
                || ($result['status'] ?? '') === 'success'
                || !empty($result['message_id']);

            SmsLog::create([
                'user_id'       => $user->id,
                'recipient'     => $user->phone,
                'message'       => $logMessage,
                'status'        => $isSuccess ? 'sent' : 'failed',
                'message_id'    => $result['message_id'] ?? $result['id'] ?? null,
                'response_data' => array_merge($result, ['type' => $type, 'metadata' => $metadata]),
                'error_message' => $isSuccess ? null : ($result['message'] ?? 'SMS dispatch failed'),
            ]);

            return [
                'success'    => $isSuccess,
                'message_id' => $result['message_id'] ?? null,
                'type'       => $type,
                'recipient'  => $user->phone,
            ];
        } catch (Throwable $e) {
            Log::error('SMS notification failed', ['user_id' => $user->id, 'type' => $type, 'error' => $e->getMessage()]);

            SmsLog::create([
                'user_id'       => $user->id,
                'recipient'     => $user->phone,
                'message'       => $logMessage,
                'status'        => 'failed',
                'error_message' => $e->getMessage(),
                'response_data' => ['type' => $type, 'metadata' => $metadata],
            ]);

            return ['success' => false, 'error' => $e->getMessage(), 'type' => $type];
        }
    }
}