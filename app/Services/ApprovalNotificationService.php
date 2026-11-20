<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\Subscription;
use App\Models\User;
use App\Notifications\FundiAccountApproved;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Sends the "your fundi account is approved" message on every channel:
 *   1. In-app notification (notifications table) + FCM push
 *   2. SMS   (via SmsNotificationService → RafikiSMS, logged in sms_logs)
 *   3. Email (via the FundiAccountApproved notification + Blade view)
 *
 * Call it AFTER the approval transaction has committed. Every channel is
 * wrapped in its own try/catch, so one failing channel never blocks the
 * others and never undoes the approval.
 *
 * NOTE: Subscription is now OPTIONAL. Approval no longer requires a trial
 * / subscription row to exist. Pass null (or omit) and the service will
 * simply notify without any trial wording.
 */
class ApprovalNotificationService
{
    public function __construct(protected SmsNotificationService $sms)
    {
    }

    /**
     * @param string|null $context 'approved' (approve endpoint) or 'verified' (verify endpoint).
     * @param Subscription|null $subscription Optional. When null, no trial wording is sent.
     *
     * @return array{in_app: bool, sms: bool, email: bool}
     */
    public function notifyApproved(
        User $user,
        ?Subscription $subscription = null,
        ?int $technicianId = null,
        string $context = 'approved'
    ): array {
        $trialDays = $this->trialDays($subscription);   // 0 when null
        $verified  = $context === 'verified';

        $title = $verified ? 'Account Verified 🎉' : 'Account Approved 🎉';
        $type  = $verified ? 'technician_verified' : 'technician_approved';

        // Only mention a trial when one actually exists.
        $verb = $verified ? 'verified' : 'approved';
        $body = $trialDays > 0
            ? "Your fundi account has been {$verb}! You now have a {$trialDays}-day free trial."
            : "Your fundi account has been {$verb}! Open the app to start getting jobs.";

        $data = ['technician_id' => $technicianId];
        if ($subscription && $subscription->expiry_date) {
            $data['trial_expires'] = $subscription->expiry_date->toIso8601String();
        }

        $result = [
            'in_app' => $this->sendInApp($user, $title, $body, $type, $data),
            'sms'    => $this->sendSms($user, $trialDays),
            'email'  => $this->sendEmail($user, $trialDays, $subscription),
        ];

        Log::info('Approval notifications dispatched', ['user_id' => $user->id] + $result);

        return $result;
    }

    // ──────────────────────────────────────────────
    // CHANNELS
    // ──────────────────────────────────────────────

    /** In-app row + FCM push. Title/body are sanitized: never empty or numeric. */
    protected function sendInApp(User $user, string $title, string $body, string $type, array $data): bool
    {
        try {
            $cleanTitle = (trim($title) !== '' && !is_numeric($title))
                ? trim($title) : config('app.name', 'NearbyFundi');

            $cleanBody = (trim($body) !== '' && !is_numeric($body))
                ? trim($body) : 'You have a new update';

            $notification = Notification::create([
                'user_id' => $user->id,
                'title'   => $cleanTitle,
                'body'    => $cleanBody,
                'type'    => $type,
                'data'    => json_encode($data),
                'is_read' => false,
            ]);

            app(FcmService::class)->sendFromNotification($notification->fresh('user'));

            return true;
        } catch (Throwable $e) {
            Log::error('Approval in-app/FCM notification failed', [
                'user_id' => $user->id,
                'error'   => $e->getMessage(),
            ]);
            return false;
        }
    }

    protected function sendSms(User $user, int $trialDays): bool
    {
        try {
            $result = $this->sms->notifyFundiApproved($user, $trialDays);
            $ok     = (bool) ($result['success'] ?? false);

            if (!$ok) {
                Log::warning('Approval SMS not delivered', ['user_id' => $user->id, 'result' => $result]);
            }

            return $ok;
        } catch (Throwable $e) {
            Log::error('Approval SMS failed', ['user_id' => $user->id, 'error' => $e->getMessage()]);
            return false;
        }
    }

    /** Email is optional at registration, so skip quietly when there is none. */
    protected function sendEmail(User $user, int $trialDays, ?Subscription $subscription): bool
    {
        if (empty($user->email)) {
            return false;
        }

        try {
            $user->notify(new FundiAccountApproved($trialDays, $subscription?->expiry_date));
            return true;
        } catch (Throwable $e) {
            Log::error('Approval email failed', ['user_id' => $user->id, 'error' => $e->getMessage()]);
            return false;
        }
    }

    // ──────────────────────────────────────────────
    // HELPERS
    // ──────────────────────────────────────────────

    /** Trial length in whole days; 0 when no subscription / expiry exists. */
    protected function trialDays(?Subscription $subscription): int
    {
        if (!$subscription || !$subscription->expiry_date) {
            return 0;
        }

        $days = (int) now()->startOfDay()->diffInDays(
            $subscription->expiry_date->copy()->startOfDay()
        );

        return max(0, $days);
    }
}