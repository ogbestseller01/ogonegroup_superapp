<?php

namespace App\Http\Controllers\Api;

use App\Models\Job;
use App\Models\RequestLog;
use App\Models\ServiceRequest;
use App\Services\JobNotificationService;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class JobController extends BaseApiController
{
    use Auditable;

    private const OTP_TTL_MINUTES  = 10;
    private const OTP_MAX_ATTEMPTS = 5;
    private const OTP_RESEND_SECS  = 60;

    private const WITH = [
        'request.service',
        'request.category',
        'technician.user',
        'customer',
        'tickets',
        'review',
    ];

    public function __construct(protected JobNotificationService $notifier)
    {
    }

    // ============================================================
    // LIST  →  GET /api/v4/admin/jobs
    // ============================================================
    public function index(Request $request)
    {
        $user  = $request->user();
        $query = Job::with(self::WITH);

        // Role scoping
        if ($user->hasRole('CUSTOMER')) {
            $query->where('customer_id', $user->id);
        } elseif ($user->hasRole('FUNDI') && $user->technician) {
            $query->where('technician_id', $user->technician->id);
        } elseif (!$user->hasRole(['ADMIN', 'MANAGER', 'SUPER_ADMIN']) && !$user->can('jobs.view')) {
            return $this->forbidden('You are not allowed to view jobs.');
        }

        // Filters
        if ($request->filled('status') && in_array($request->status, Job::STATUSES, true)) {
            $query->where('status', $request->status);
        }
        if ($request->filled('search')) {
            $s = trim((string) $request->search);
            $query->where(function ($q) use ($s) {
                $q->where('job_number', 'like', "%{$s}%")
                  ->orWhereHas('customer', fn ($c) => $c->where('name', 'like', "%{$s}%"))
                  ->orWhereHas('technician.user', fn ($u) => $u->where('name', 'like', "%{$s}%"))
                  ->orWhereHas('request', fn ($r) => $r->where('description', 'like', "%{$s}%"));
            });
        }
        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->to);
        }

        // Sorting
        $sortable = ['created_at', 'completed_at', 'status', 'job_number'];
        $sort     = in_array($request->input('sort'), $sortable, true) ? $request->input('sort') : 'created_at';
        $order    = $request->input('order') === 'asc' ? 'asc' : 'desc';
        $query->orderBy($sort, $order);

        // Pagination
        $limit = max(1, min((int) $request->input('limit', 50), 200));
        $jobs = $query->paginate($limit);

        return $this->successResponse(
            $jobs->getCollection()->map(fn (Job $j) => $this->format($j))->values(),
            'Jobs retrieved successfully',
            200,
            [
                'current_page' => $jobs->currentPage(),
                'per_page'     => $jobs->perPage(),
                'total'        => $jobs->total(),
                'last_page'    => $jobs->lastPage(),
            ]
        );
    }

    // ============================================================
    // STATS  →  GET /api/v4/admin/jobs/stats
    // ============================================================
    public function stats(Request $request)
    {
        $user = $request->user();
        $base = Job::query();

        if ($user->hasRole('CUSTOMER')) {
            $base->where('customer_id', $user->id);
        } elseif ($user->hasRole('FUNDI') && $user->technician) {
            $base->where('technician_id', $user->technician->id);
        }

        $counts = (clone $base)->selectRaw('status, COUNT(*) as total')->groupBy('status')->pluck('total', 'status')->toArray();

        return $this->successResponse([
            'pending'     => (int) ($counts[Job::STATUS_PENDING]     ?? 0),
            'on_progress' => (int) ($counts[Job::STATUS_ON_PROGRESS] ?? 0),
            'completed'   => (int) ($counts[Job::STATUS_COMPLETED]   ?? 0),
            'total'       => array_sum($counts),
        ], 'Job stats retrieved');
    }

    // ============================================================
    // HISTOGRAM  →  GET /api/v4/admin/jobs/histogram (Line Chart)
    // ============================================================

    public function histogram(Request $request)
    {
        $user = $request->user();
        $base = Job::query();

        if ($user->hasRole('CUSTOMER')) {
            $base->where('customer_id', $user->id);
        } elseif ($user->hasRole('FUNDI') && $user->technician) {
            $base->where('technician_id', $user->technician->id);
        }

        // Apply Date Filters
        if ($request->filled('from')) {
            $base->whereDate('created_at', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $base->whereDate('created_at', '<=', $request->to);
        }

        $period = $request->input('period', 'month');
        $data = [];

        if ($period === 'year') {
            $jobs = (clone $base)->selectRaw('YEAR(created_at) as year, COUNT(*) as count')->groupBy('year')->orderBy('year', 'asc')->get();
            foreach ($jobs as $j) { $data[] = ['name' => (string) $j->year, 'count' => $j->count]; }
        } elseif ($period === 'month') {
            $jobs = (clone $base)->selectRaw('DAY(created_at) as day, COUNT(*) as count')->whereMonth('created_at', now()->month)->whereYear('created_at', now()->year)->groupBy('day')->orderBy('day', 'asc')->get();
            foreach ($jobs as $j) { $data[] = ['name' => (string) $j->day, 'count' => $j->count]; }
        } else {
            $jobs = (clone $base)->selectRaw('DAYNAME(created_at) as day_name, DAYOFWEEK(created_at) as day_num, COUNT(*) as count')->whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()])->groupBy('day_name', 'day_num')->orderBy('day_num', 'asc')->get();
            foreach ($jobs as $j) { $data[] = ['name' => substr($j->day_name, 0, 3), 'count' => $j->count]; }
        }

        return $this->successResponse($data, 'Histogram retrieved successfully');
    }

    // ============================================================
    // CHART DATA  →  GET /api/v4/admin/jobs/chart-data (Bar Chart)
    // ============================================================
    public function chartData(Request $request)
    {
        $user = $request->user();
        $base = Job::query();

        if ($user->hasRole('CUSTOMER')) {
            $base->where('customer_id', $user->id);
        } elseif ($user->hasRole('FUNDI') && $user->technician) {
            $base->where('technician_id', $user->technician->id);
        }

        // Apply Date Filters
        if ($request->filled('from')) {
            $base->whereDate('created_at', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $base->whereDate('created_at', '<=', $request->to);
        }

        $counts = (clone $base)->selectRaw('status, COUNT(*) as count')->groupBy('status')->pluck('count', 'status')->toArray();

        $data = [
            ['name' => 'Pending', 'count' => (int) ($counts[Job::STATUS_PENDING] ?? 0)],
            ['name' => 'On Progress', 'count' => (int) ($counts[Job::STATUS_ON_PROGRESS] ?? 0)],
            ['name' => 'Completed', 'count' => (int) ($counts[Job::STATUS_COMPLETED] ?? 0)],
        ];

        return $this->successResponse($data, 'Chart data retrieved successfully');
    }

    // ============================================================
    // SHOW  →  GET /api/v4/admin/jobs/{id}
    // ============================================================
    public function show(Request $request, $id)
    {
        $job = $this->findForUser($request, $id);
        return $job ? $this->successResponse($this->format($job)) : $this->notFound('Job not found.');
    }

    // ============================================================
    // MARK COMPLETE (SEND OTP)
    // ============================================================
    public function requestCompletion(Request $request, $id)
    {
        $job = $this->findForUser($request, $id, customerOnly: false, allowAdmin: true);

        if (!$job) return $this->notFound('Job not found.');
        if (!$job->canComplete()) return $this->errorResponse('This job can no longer be completed.', 422);

        $customer = $job->customer;
        $phone    = $customer ? $customer->phone : null;

        if (!$phone || !$this->isValidCountryCodePhone($phone)) {
            return $this->errorResponse('A valid phone number with a valid country code format is mandatory.', 422);
        }

        $sentAt = $job->completion_otp_expires_at?->copy()->subMinutes(self::OTP_TTL_MINUTES);
        if ($sentAt && $sentAt->gt(now()->subSeconds(self::OTP_RESEND_SECS))) {
            return $this->successResponse($this->otpPayload($job, alreadySent: true), 'A code was just sent.');
        }

        $plain = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $job->forceFill([
            'completion_otp'            => Hash::make($plain),
            'completion_otp_expires_at' => now()->addMinutes(self::OTP_TTL_MINUTES),
            'completion_otp_attempts'   => 0,
        ])->save();

        $sent = false;
        try {
            $sent = $this->notifier->completionCode($job, $plain);
        } catch (\Throwable $e) {
            Log::error('completionCode notification failed: ' . $e->getMessage());
        }

        if (!$sent) {
            $job->forceFill(['completion_otp' => null, 'completion_otp_expires_at' => null])->save();
            return $this->errorResponse('Mandatory SMS delivery failed.', 502);
        }

        return $this->successResponse($this->otpPayload($job), 'Completion code sent by SMS.');
    }

    // ============================================================
    // ENTER OTP (VERIFY)
    // ============================================================
    public function verifyCompletion(Request $request, $id)
    {
        try {
            $data = $request->validate(['otp' => 'required|digits:6']);
        } catch (ValidationException $e) {
            return $this->validationError($e->errors());
        }

        $user = $request->user();
        $job  = $this->findForUser($request, $id, customerOnly: false, allowAdmin: true);

        if (!$job) return $this->notFound('Job not found.');
        if ($job->isCompleted()) return $this->errorResponse('This job is already completed.', 422);
        if (!$job->completion_otp || !$job->completion_otp_expires_at || $job->completion_otp_expires_at->isPast()) {
            return $this->errorResponse('The code expired. Tap Send OTP to get a new one.', 422);
        }
        if ($job->completion_otp_attempts >= self::OTP_MAX_ATTEMPTS) {
            return $this->errorResponse('Too many wrong attempts.', 429);
        }

        if (!Hash::check($data['otp'], $job->completion_otp)) {
            $job->increment('completion_otp_attempts');
            $left = max(0, self::OTP_MAX_ATTEMPTS - (int) $job->fresh()->completion_otp_attempts);
            return $this->errorResponse("Invalid code. {$left} attempt(s) left.", 422);
        }

        try {
            DB::transaction(function () use ($job, $request, $user) {
                $job->forceFill([
                    'status'                    => Job::STATUS_COMPLETED,
                    'completed_at'              => now(),
                    'completion_otp'            => null,
                    'completion_otp_expires_at' => null,
                ])->save();

                $job->technician?->increment('completed_jobs_count');
                $sr = $job->request;
                $this->logRequestAction($job->request_id, $user->id, 'job_completed', $sr?->status, $sr?->status ?? ServiceRequest::STATUS_ACCEPTED, "Job {$job->job_number} completed", $request->ip());
            });
        } catch (\Throwable $e) {
            return $this->errorResponse('Failed to complete the job.', 500);
        }

        $job->load(self::WITH);

        try { $this->notifier->jobCompleted($job); } catch (\Throwable $e) {}
        $this->logAudit('complete_job', 'job', $job->id, "Job {$job->job_number} completed");

        return $this->successResponse($this->format($job), 'Job completed.');
    }

    // ============================================================
    // HELPERS
    // ============================================================
    private function isValidCountryCodePhone(string $phone): bool
    {
        $clean = preg_replace('/[^0-9+]/', '', trim($phone));
        return preg_match('/^\+?[1-9]\d{6,14}$/', $clean) === 1;
    }

    private function findForUser(Request $request, $id, bool $customerOnly = false, bool $allowAdmin = false): ?Job
    {
        $user = $request->user();
        $job  = Job::with(self::WITH)->find($id);
        if (!$job || !$user) return null;

        $isCustomer = (int) $job->customer_id === (int) $user->id;
        $isFundi    = $user->hasRole('FUNDI') && $user->technician && (int) $user->technician->id === (int) $job->technician_id;
        $isAdmin    = $user->hasRole(['ADMIN', 'MANAGER', 'SUPER_ADMIN']) || $user->can('jobs.view');

        if ($customerOnly) return ($isCustomer || ($allowAdmin && $isAdmin)) ? $job : null;
        return ($isCustomer || $isFundi || $isAdmin) ? $job : null;
    }

    private function otpPayload(Job $job, bool $alreadySent = false): array
    {
        return [
            'job_id'       => $job->id,
            'already_sent' => $alreadySent,
            'channel'      => 'sms',
            'expires_at'   => $job->completion_otp_expires_at?->toIso8601String(),
            'ttl_seconds'  => self::OTP_TTL_MINUTES * 60,
            'resend_after' => self::OTP_RESEND_SECS,
        ];
    }

    private function logRequestAction(int $requestId, int $userId, string $action, ?string $old, string $new, ?string $notes, ?string $ip): void
    {
        try {
            RequestLog::create(['request_id' => $requestId, 'user_id' => $userId, 'action' => $action, 'old_status' => $old, 'new_status' => $new, 'notes' => $notes, 'ip_address' => $ip]);
        } catch (\Throwable $e) {}
    }

    private function format(Job $job): array
    {
        $tech   = $job->technician;
        $sr     = $job->request;
        $ticket = $job->tickets->sortByDesc('id')->first();
        
        return [
            'id'           => $job->id,
            'job_number'   => $job->job_number,
            'status'       => $job->status,
            'started_at'   => $job->started_at,
            'completed_at' => $job->completed_at,
            'notes'        => $job->notes,
            'created_at'   => $job->created_at,
            'request'      => $sr ? [
                'id'          => $sr->id,
                'description' => $sr->description,
                'service'     => $sr->service ? ['id' => $sr->service->id, 'name' => $sr->service->name] : null,
                'category'    => $sr->category ? ['id' => $sr->category->service_categoryID, 'name' => $sr->category->category_name] : null,
            ] : null,
            'technician'   => $tech ? [
                'id'            => $tech->id,
                'user_id'       => $tech->user_id,
                'name'          => $tech->user->name ?? null,
                'phone'         => $tech->user->phone ?? null,
                'email'         => $tech->user->email ?? null,
                'profile_photo' => $tech->profile_photo ? url('storage/' . ltrim($tech->profile_photo, '/')) : null,
                'area'          => $tech->area,
                'rating'        => (float) ($tech->rating ?? 0),
            ] : null,
            'customer'     => $job->customer ? ['id' => $job->customer->id, 'name' => $job->customer->name] : null,
            'ticket'       => $ticket ? [
                'id'            => $ticket->id,
                'ticket_number' => $ticket->ticket_number,
                'status'        => $ticket->status,
                'title'         => $ticket->title,
                'description'   => $ticket->description,
                'completed_at'  => $ticket->completed_at,
            ] : null,
            'review'       => $job->review ? [
                'id'         => $job->review->id,
                'rating'     => (float) $job->review->rating,
                'comment'    => $job->review->comment,
                'created_at' => $job->review->created_at?->toIso8601String(),
            ] : null,
        ];
    }
}