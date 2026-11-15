<?php
// app/Notifications/SubscriptionApproved.php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;

class SubscriptionApproved extends Notification implements ShouldQueue
{
    use Queueable;

    protected $subscription;

    public function __construct($subscription)
    {
        $this->subscription = $subscription;
    }

    public function via($notifiable)
    {
        return ['mail', 'database'];
    }

    public function toMail($notifiable)
    {
        return (new \Illuminate\Notifications\Messages\MailMessage)
            ->subject('Your Subscription Has Been Approved!')
            ->greeting('Hello ' . $notifiable->name . '!')
            ->line('Your subscription has been approved and your account is now active.')
            ->line('Subscription: ' . $this->subscription->rateCard->name)
            ->line('Expires on: ' . $this->subscription->expiry_date->format('M d, Y'))
            ->action('View Subscription', url('/subscriptions'))
            ->line('Thank you for using our services!');
    }

    public function toArray($notifiable)
    {
        return [
            'subscription_id' => $this->subscription->id,
            'rate_card' => $this->subscription->rateCard->name,
            'expires_at' => $this->subscription->expiry_date,
            'type' => 'subscription_approved',
        ];
    }
}