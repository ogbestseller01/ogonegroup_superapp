<?php

namespace App\Services;

use App\Models\Job;
use App\Models\Notification;
use Illuminate\Support\Facades\Log;
use Throwable;

class JobNotificationService
{
    public function __construct(
        protected SmsNotificationService $smsNotificationService
    ) {}

    public function jobStarted(Job $job): void
    {
        $job->loadMissing(['technician.user', 'customer', 'request.service']);

        $this->deliver(
            $job->technician?->user?->id,
            'job_started',
            'New job started',
            "{$job->customer?->name} started job {$job->job_number}.",
            $job
        );
    }

    /** Sends 6-digit OTP via SMS with customer name and service name */
    public function completionCode(Job $job, string $plainOtp): bool
    {
        $job->loadMissing(['customer', 'request.service']);

        $customerName = $job->customer->name ?? 'Customer';
        $serviceName  = $job->request->service->name ?? 'Service';
        $jobNumber    = $job->job_number;

        $message = "NearbyFundi: Verification code for {$customerName} and service {$serviceName} (Job #{$jobNumber}) is {$plainOtp}. Valid for 10 minutes. Provide it to your customer for mark job as completed.";

        return $this->deliver(
            $job->customer_id,
            'job_completion_code',
            'Job completion code',
            $message,
            $job,
            sendSms: true
        );
    }

    public function jobCompleted(Job $job): void
    {
        $job->loadMissing(['technician.user', 'customer', 'request.service']);

        $this->deliver(
            $job->technician?->user?->id,
            'job_completed',
            'Job completed',
            "Job {$job->job_number} has been marked as completed.",
            $job
        );

        $this->deliver(
            $job->customer_id,
            'job_completed',
            'Job completed',
            "Job {$job->job_number} has been confirmed complete.",
            $job
        );
    }

    private function deliver(?int $userId, string $type, string $title, string $body, Job $job, bool $sendSms = false): bool
    {
        if (!$userId) {
            return false;
        }

        $success = true;

        try {
            $notification = Notification::create([
                'user_id' => $userId,
                'title'   => $title,
                'body'    => $body,
                'type'    => $type,
                'data'    => json_encode(['job_id' => $job->id, 'job_number' => $job->job_number]),
                'is_read' => false,
            ]);

            app(FcmService::class)->sendFromNotification($notification->fresh('user'));
        } catch (Throwable $e) {
            Log::error('Job in-app/FCM notification failed safely', [
                'user_id' => $userId,
                'error'   => $e->getMessage(),
            ]);
        }

        if ($sendSms) {
            try {
                $user = \App\Models\User::find($userId);
                if ($user) {
                    $smsResult = $this->smsNotificationService->notifyJobCompletionCode($user, $job, $body);
                    $success = (bool) ($smsResult['success'] ?? false);
                }
            } catch (Throwable $e) {
                Log::error('Job SMS notification dispatch failed', [
                    'user_id' => $userId,
                    'error'   => $e->getMessage(),
                ]);
                $success = false;
            }
        }

        return $success;
    }
}