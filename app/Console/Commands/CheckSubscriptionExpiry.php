<?php
// app/Console/Commands/CheckSubscriptionExpiry.php

namespace App\Console\Commands;

use App\Models\Subscription;
use App\Models\User;
use Illuminate\Console\Command;
use Carbon\Carbon;

class CheckSubscriptionExpiry extends Command
{
    protected $signature = 'subscriptions:check-expiry';
    protected $description = 'Check and handle subscription expirations';

    public function handle()
    {
        // Find active subscriptions that have expired
        $expiredSubscriptions = Subscription::where('status', 'active')
            ->where('expiry_date', '<=', now())
            ->get();

        foreach ($expiredSubscriptions as $subscription) {
            // Mark as expired
            $subscription->status = 'expired';
            $subscription->save();

            // Lock the user account
            $user = $subscription->user;
            if ($user) {
                $user->subscription_status = 'expired';
                $user->save();

                $this->info("User {$user->email} subscription expired and account locked.");
            }

            // Send notification (implement this)
            // $this->sendExpiryNotification($user, $subscription);
        }

        // Also check for users with expired subscriptions that might not be marked
        $expiredUsers = User::where('subscription_status', 'active')
            ->where('subscription_expires_at', '<=', now())
            ->get();

        foreach ($expiredUsers as $user) {
            $user->subscription_status = 'expired';
            $user->save();
            
            $this->info("User {$user->email} marked as expired.");
        }

        $this->info('Subscription expiry check completed.');
    }
}