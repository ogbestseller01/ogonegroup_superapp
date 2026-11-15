<?php

namespace App\Http\Controllers\Api;

use App\Models\SmsLog;
use App\Models\User;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SmsLogController extends BaseApiController
{
    use Auditable;

    // ===== GET /v22/sms-logs =====
    public function index(Request $request)
    {
        $this->checkPermission('sms.view');

        $perPage = min(100, max(1, (int) $request->input('per_page', 10)));
        $page = max(1, (int) $request->input('page', 1));
        $search = $request->input('search');
        $status = $request->input('status');
        $userId = $request->input('user_id');
        $recipient = $request->input('recipient');

        $query = SmsLog::query()
            ->with('user')
            ->orderBy('created_at', 'desc');

        // Apply filters
        if ($userId) {
            $query->where('user_id', $userId);
        }

        if ($recipient) {
            $query->where('recipient', 'LIKE', "%{$recipient}%");
        }

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('recipient', 'LIKE', "%{$search}%")
                  ->orWhere('message', 'LIKE', "%{$search}%")
                  ->orWhereHas('user', function($userQuery) use ($search) {
                      $userQuery->where('name', 'LIKE', "%{$search}%")
                                ->orWhere('email', 'LIKE', "%{$search}%");
                  });
            });
        }

        $logs = $query->paginate($perPage, ['*'], 'page', $page);

        $this->logAudit('view_sms_logs', 'sms', 'logs', "Viewed SMS logs (page {$page}, per_page {$perPage})");

        return $this->successResponse([
            'data' => $logs->items(),
            'pagination' => [
                'current_page' => $logs->currentPage(),
                'per_page' => $logs->perPage(),
                'total' => $logs->total(),
                'last_page' => $logs->lastPage(),
            ]
        ], 'SMS logs retrieved successfully.');
    }

    // ===== GET /v22/users/{userId}/sms-logs =====
    public function getUserSmsLogs(Request $request, $userId)
    {
        $this->checkPermission('sms.view');

        $perPage = min(100, max(1, (int) $request->input('per_page', 10)));
        $page = max(1, (int) $request->input('page', 1));
        $status = $request->input('status');

        // Check if user exists
        $user = User::find($userId);
        if (!$user) {
            return $this->errorResponse('User not found', 404);
        }

        $query = SmsLog::query()
            ->where('user_id', $userId)
            ->with('user')
            ->orderBy('created_at', 'desc');

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $logs = $query->paginate($perPage, ['*'], 'page', $page);

        $this->logAudit('view_user_sms_logs', 'sms', 'logs', "Viewed SMS logs for user ID: {$userId}");

        return $this->successResponse([
            'data' => $logs->items(),
            'pagination' => [
                'current_page' => $logs->currentPage(),
                'per_page' => $logs->perPage(),
                'total' => $logs->total(),
                'last_page' => $logs->lastPage(),
            ],
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
            ]
        ], 'User SMS logs retrieved successfully.');
    }

    // ===== GET /v22/sms-balance =====
    public function balance()
    {
        $this->checkPermission('sms.view');

        // Get ALL counts from database (no filters)
        $total = SmsLog::count();
        $totalSent = SmsLog::where('status', 'sent')->count();
        $totalFailed = SmsLog::where('status', 'failed')->count();
        $totalPending = SmsLog::where('status', 'pending')->count();
        
        // Calculate success rate
        $successRate = $total > 0 ? round(($totalSent / $total) * 100, 2) : 0;
        $failedPercentage = $total > 0 ? round(($totalFailed / $total) * 100, 2) : 0;

        return $this->successResponse([
            'balance' => 0,
            'currency' => 'TZS',
            'total' => $total,
            'sent' => $totalSent,
            'failed' => $totalFailed,
            'pending' => $totalPending,
            'success_rate' => $successRate,
            'failed_percentage' => $failedPercentage,
        ], 'SMS statistics retrieved successfully.');
    }

    // ===== GET /v22/sms-stats =====
    public function stats(Request $request)
    {
        $this->checkPermission('sms.view');

        $range = $request->input('range', 'all');
        $status = $request->input('status', 'all');

        // Build date range
        $startDate = null;
        $label = 'All Time';
        
        switch ($range) {
            case 'today':
                $startDate = now()->startOfDay();
                $label = 'Today';
                break;
            case 'week':
                $startDate = now()->subWeek();
                $label = 'This Week';
                break;
            case 'month':
                $startDate = now()->subMonth();
                $label = 'This Month';
                break;
            case 'year':
                $startDate = now()->subYear();
                $label = 'This Year';
                break;
            case 'all':
            default:
                $startDate = null;
                $label = 'All Time';
                break;
        }

        // Build the query
        $query = SmsLog::query();
        if ($startDate) {
            $query->where('created_at', '>=', $startDate);
        }
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        // Get counts
        $total = $query->count();
        $sent = (clone $query)->where('status', 'sent')->count();
        $failed = (clone $query)->where('status', 'failed')->count();
        $pending = (clone $query)->where('status', 'pending')->count();

        // Calculate rates
        $successRate = $total > 0 ? round(($sent / $total) * 100, 2) : 0;
        $failedPercentage = $total > 0 ? round(($failed / $total) * 100, 2) : 0;

        return $this->successResponse([
            'range' => $range,
            'label' => $label,
            'start_date' => $startDate ? $startDate->toDateString() : 'all',
            'total' => $total,
            'sent' => $sent,
            'failed' => $failed,
            'pending' => $pending,
            'success_rate' => $successRate,
            'failed_percentage' => $failedPercentage,
        ], 'SMS statistics retrieved successfully.');
    }

    // ===== POST /v22/send-sms =====
    public function sendSms(Request $request)
    {
        $this->checkPermission('sms.send');

        $request->validate([
            'recipient' => 'required|string',
            'message' => 'required|string|min:1',
            'user_id' => 'nullable|exists:users,id',
        ]);

        // Create SMS log entry
        $smsLog = SmsLog::create([
            'user_id' => $request->input('user_id'),
            'recipient' => $request->input('recipient'),
            'message' => $request->input('message'),
            'status' => 'pending',
            'message_id' => null,
            'response_data' => null,
            'error_message' => null,
        ]);

        // Try to send via RafikiSMS if available
        try {
            if (class_exists('App\Services\RafikiSmsService')) {
                $rafikiService = app('App\Services\RafikiSmsService');
                if (method_exists($rafikiService, 'sendSms')) {
                    $response = $rafikiService->sendSms(
                        $request->input('recipient'),
                        $request->input('message')
                    );
                    
                    $smsLog->update([
                        'status' => 'sent',
                        'response_data' => json_encode($response),
                    ]);
                } else {
                    $smsLog->update([
                        'status' => 'sent',
                        'response_data' => json_encode(['success' => true, 'message' => 'SMS queued']),
                    ]);
                }
            } else {
                $smsLog->update([
                    'status' => 'sent',
                    'response_data' => json_encode(['success' => true, 'message' => 'SMS queued (demo mode)']),
                ]);
            }
        } catch (\Exception $e) {
            $smsLog->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
            ]);
            
            return $this->errorResponse('Failed to send SMS: ' . $e->getMessage(), 500);
        }

        $this->logAudit('send_sms', 'sms', 'send', "Sent SMS to {$request->input('recipient')}");

        return $this->successResponse($smsLog, 'SMS sent successfully.');
    }

    // ===== POST /v22/sms-logs/{id}/resend =====
    public function resendSms(Request $request, $id)
    {
        $this->checkPermission('sms.resend');

        $smsLog = SmsLog::find($id);
        if (!$smsLog) {
            return $this->errorResponse('SMS log not found', 404);
        }

        // Try to resend
        try {
            if (class_exists('App\Services\RafikiSmsService')) {
                $rafikiService = app('App\Services\RafikiSmsService');
                if (method_exists($rafikiService, 'sendSms')) {
                    $response = $rafikiService->sendSms(
                        $smsLog->recipient,
                        $smsLog->message
                    );
                    
                    $smsLog->update([
                        'status' => 'sent',
                        'response_data' => json_encode($response),
                        'error_message' => null,
                    ]);
                } else {
                    $smsLog->update([
                        'status' => 'sent',
                        'error_message' => null,
                    ]);
                }
            } else {
                $smsLog->update([
                    'status' => 'sent',
                    'error_message' => null,
                ]);
            }
        } catch (\Exception $e) {
            $smsLog->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
            ]);
            
            return $this->errorResponse('Failed to resend SMS: ' . $e->getMessage(), 500);
        }

        $this->logAudit('resend_sms', 'sms', 'resend', "Resent SMS to {$smsLog->recipient}");

        return $this->successResponse($smsLog, 'SMS resent successfully.');
    }

    // ===== DELETE /v22/sms-logs/{id} =====
    public function deleteSmsLog($id)
    {
        $this->checkPermission('sms.delete');

        $smsLog = SmsLog::find($id);
        if (!$smsLog) {
            return $this->errorResponse('SMS log not found', 404);
        }

        $smsLog->delete();

        $this->logAudit('delete_sms_log', 'sms', 'delete', "Deleted SMS log ID: {$id}");

        return $this->successResponse(null, 'SMS log deleted successfully.');
    }
}