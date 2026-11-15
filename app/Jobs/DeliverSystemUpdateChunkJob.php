<?php

namespace App\Jobs;

use App\Models\SystemUpdate;
use App\Models\SystemUpdateNotification;
use App\Models\User;
use App\Services\FcmService;
use App\Services\SmsNotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class DeliverSystemUpdateChunkJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [60, 300];

    public function __construct(public int $updateId, public array $userIds) {}

    public function handle(FcmService $fcm, SmsNotificationService $sms): void
    {
        $update = SystemUpdate::find($this->updateId);

        // Closed/deleted while queued: stop sending
        if (!$update || $update->status !== SystemUpdate::STATUS_PUBLISHED) {
            return;
        }

        $retry = false;

        foreach (User::whereIn('id', $this->userIds)->get() as $user) {
            if ($update->send_push) {
                $retry = $this->deliver($update, $user, 'push',
                    fn () => $fcm->sendSystemUpdate($user, $update)) || $retry;
            }

            if ($update->send_sms) {
                $retry = $this->deliver($update, $user, 'sms', fn () => empty($user->phone)
                    ? ['success' => false, 'skipped' => true, 'error' => 'No phone number']
                    : $sms->notifySystemUpdate($user, $update)) || $retry;
            }
        }

        // Rows already 'sent' are skipped on the next pass, so a retry never duplicates
        if ($retry && $this->attempts() < $this->tries) {
            throw new \RuntimeException('Some system-update deliveries failed; retrying.');
        }
    }

    /** @return bool true when this delivery failed and is worth retrying */
    private function deliver(SystemUpdate $update, User $user, string $channel, callable $send): bool
    {
        $row = SystemUpdateNotification::firstOrCreate([
            'system_update_id' => $update->id,
            'user_id'          => $user->id,
            'channel'          => $channel,
        ]);

        if (in_array($row->status, ['sent', 'skipped'], true)) {
            return false;
        }

        try {
            $r = $send();
        } catch (\Throwable $e) {
            $r = ['success' => false, 'error' => $e->getMessage()];
        }

        $ok      = (bool) ($r['success'] ?? false);
        $skipped = (bool) ($r['skipped'] ?? false);

        $row->update([
            'status'              => $ok ? 'sent' : ($skipped ? 'skipped' : 'failed'),
            'attempts'            => $row->attempts + ($skipped ? 0 : 1),
            'provider_message_id' => $r['message_id'] ?? null,
            'error_message'       => $ok ? null : ($r['error'] ?? null),
            'sent_at'             => $ok ? now() : $row->sent_at,
            'last_attempt_at'     => now(),
        ]);

        return !$ok && !$skipped && $row->attempts < $this->tries;
    }
}