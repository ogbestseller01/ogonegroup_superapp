<?php
// app/Jobs/CheckPendingRequestsJob.php

namespace App\Jobs;

use App\Models\ServiceRequest;
use App\Models\RequestLog;
use App\Models\User;
use App\Notifications\PendingRequestAlert;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;

class CheckPendingRequestsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    const PENDING_THRESHOLD_MINUTES = 5;

    public function handle(): void
    {
        $threshold = now()->subMinutes(self::PENDING_THRESHOLD_MINUTES);

        // Get pending requests that have been waiting more than threshold
        $pendingRequests = ServiceRequest::with(['customer', 'service'])
            ->where('status', 'pending')
            ->where('created_at', '<=', $threshold)
            ->get();

        if ($pendingRequests->isEmpty()) {
            Log::info('No pending requests requiring attention at ' . now());
            return;
        }

        Log::info('Found ' . $pendingRequests->count() . ' pending requests requiring attention');

        // Get monitoring officers and admins to notify
        $recipients = User::role(['ADMINISTRATOR', 'MONITORING_OFFICER'])->get();

        if ($recipients->isEmpty()) {
            Log::warning('No monitoring officers or admins found to notify');
            return;
        }

        // Send notifications for each pending request
        foreach ($pendingRequests as $request) {
            Notification::send($recipients, new PendingRequestAlert($request));
        }

        // Log alerts for dashboard
        foreach ($pendingRequests as $request) {
            RequestLog::create([
                'request_id' => $request->id,
                'user_id' => null,
                'action' => 'pending_alert',
                'old_status' => 'pending',
                'new_status' => 'pending',
                'notes' => 'Pending request flagged after ' . 
                    round($request->created_at->diffInMinutes(now())) . ' minutes',
                'ip_address' => 'system',
            ]);
        }
    }
}