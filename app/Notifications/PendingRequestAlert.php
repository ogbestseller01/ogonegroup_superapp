<?php
// app/Notifications/PendingRequestAlert.php

namespace App\Notifications;

use App\Models\ServiceRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Notification;

/**
 * Internal admin/monitoring alert — a pending service request has
 * exceeded the expected assignment time. Delivered via mail,
 * broadcast (e.g. admin dashboard websocket) and Laravel's own
 * polymorphic `notifications` table.
 *
 * NOTE: This is NOT the same `notifications` table the mobile app
 * reads from (App\Models\Notification: user_id/title/body/type/data).
 * This uses Laravel's built-in Notifiable database channel
 * (notifiable_type/notifiable_id/data). It does not reach the
 * mobile app and has no FCM channel — it's admin-only.
 */
class PendingRequestAlert extends Notification implements ShouldQueue
{
    use Queueable;

    protected ServiceRequest $serviceRequest;

    public function __construct(ServiceRequest $serviceRequest)
    {
        $this->serviceRequest = $serviceRequest;
    }

    public function via($notifiable)
    {
        return ['mail', 'broadcast', 'database'];
    }

    public function toMail($notifiable)
    {
        $minutes = $this->minutesElapsed();

        return (new MailMessage)
            ->subject('🚨 Pending Request Alert #' . $this->serviceRequest->id)
            ->greeting('Hello ' . $notifiable->name . '!')
            ->line('A service request has been pending for ' . $minutes . ' minutes.')
            ->line('Request Details:')
            ->line('- Customer: ' . $this->customerName())
            ->line('- Service: ' . $this->serviceName())
            ->line('- Description: ' . $this->description())
            ->action('View Request', url('/monitoring/requests/' . $this->serviceRequest->id))
            ->line('Please assign a technician or take appropriate action.');
    }

    public function toBroadcast($notifiable)
    {
        return new BroadcastMessage($this->payload());
    }

    public function toDatabase($notifiable)
    {
        return $this->payload();
    }

    /**
     * Shared payload for broadcast + database channels.
     * Explicit title/body kept alongside the structured fields so any
     * dashboard or future consumer can rely on the same title/body
     * convention used everywhere else in the app.
     */
    protected function payload(): array
    {
        $minutes  = $this->minutesElapsed();
        $customer = $this->customerName();
        $service  = $this->serviceName();

        $title = 'Request #' . $this->serviceRequest->id . ' pending';
        $body  = "Pending {$minutes} min — {$customer} needs \"{$service}\"";

        return [
            'type'            => 'pending_alert',
            'title'           => $title,
            'body'            => $body,
            'request_id'      => $this->serviceRequest->id,
            'customer_name'   => $customer,
            'service_name'    => $service,
            'description'     => $this->description(),
            'minutes_elapsed' => $minutes,
            'created_at'      => $this->serviceRequest->created_at->toIso8601String(),
        ];
    }

    protected function minutesElapsed(): int
    {
        return (int) round($this->serviceRequest->created_at->diffInMinutes(now()));
    }

    protected function customerName(): string
    {
        $name = trim((string) ($this->serviceRequest->customer->name ?? ''));
        return $name !== '' ? $name : 'Unknown customer';
    }

    protected function serviceName(): string
    {
        $name = trim((string) ($this->serviceRequest->service->name ?? ''));
        return $name !== '' ? $name : 'Unspecified service';
    }

    protected function description(): string
    {
        $description = trim((string) ($this->serviceRequest->description ?? ''));
        return $description !== '' ? $description : 'No description provided.';
    }
}