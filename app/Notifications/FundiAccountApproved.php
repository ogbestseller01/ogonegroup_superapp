<?php
// app/Notifications/FundiAccountApproved.php

namespace App\Notifications;

use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Email sent to a fundi when an admin approves their account.
 *
 * Mail only, on purpose:
 *  - SMS is sent by SmsNotificationService (so it is logged in sms_logs).
 *  - The in-app row + FCM push use your own App\Models\Notification model.
 *    Laravel's built-in 'database' channel is NOT used because User::notifications()
 *    is overridden to point at that custom model.
 *
 * Not queued: it runs inline after the approval commit, so it works without
 * a queue worker. To queue it, add "implements ShouldQueue" (and run a worker).
 */
class FundiAccountApproved extends Notification
{
    use Queueable;

    public function __construct(
        protected int $trialDays,
        protected Carbon $expiresAt
    ) {
    }

    public function via($notifiable): array
    {
        // Email is optional for fundis; no address, no mail channel.
        return empty($notifiable->email) ? [] : ['mail'];
    }

    public function toMail($notifiable): MailMessage
    {
        $appName = config('app.name', 'Nearbyfundi');

        return (new MailMessage)
            ->subject("Your {$appName} account is approved")
            ->view('emails.fundi-approved', [
                'name'      => $notifiable->name,
                'appName'   => $appName,
                'trialDays' => $this->trialDays,
                'expiresAt' => $this->expiresAt,
                'appUrl'    => config('app.frontend_url'),
            ]);
    }
}