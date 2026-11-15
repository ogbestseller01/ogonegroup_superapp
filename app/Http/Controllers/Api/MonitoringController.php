<?php
// app/Http/Controllers/Api/MonitoringController.php

namespace App\Http\Controllers\Api;

use App\Models\ServiceRequest;
use App\Models\Technician;
use App\Models\RequestLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class MonitoringController extends BaseApiController
{
    const TIMEOUT_MINUTES = 5;
    const PENDING_DAYS_BACK = 3;
    const TIMEZONE = 'Africa/Dar_es_Salaam';
    const AVG_SPEED_KMH = 30;

    // ─── Helpers ──────────────────────────────────────────────
    private function now(): Carbon
    {
        return Carbon::now(self::TIMEZONE);
    }

    private function today(): string
    {
        return $this->now()->toDateString();
    }

    private function formatTanzaniaPhone(string $phone): string
    {
        $clean = preg_replace('/[^0-9]/', '', $phone);
        if (strlen($clean) === 9) return '255' . $clean;
        if (strlen($clean) === 10 && substr($clean, 0, 1) === '0') {
            return '255' . substr($clean, 1);
        }
        return $clean;
    }

    private function checkMonitoringRole(Request $request): void
    {
        $user = $request->user();
        if (!$user) abort(401, 'Not authenticated.');
        if (!$user->hasAnyRole(['ADMINISTRATOR', 'MONITORING_OFFICER'])) {
            abort(403, 'Admin or Monitoring Officer access required.');
        }
    }

    private function logRequestAction(
        int $requestId,
        int $userId,
        string $action,
        ?string $oldStatus,
        string $newStatus,
        ?string $notes = null,
        ?string $ip = null
    ): void {
        RequestLog::create([
            'request_id'  => $requestId,
            'user_id'     => $userId,
            'action'      => $action,
            'old_status'  => $oldStatus,
            'new_status'  => $newStatus,
            'notes'       => $notes,
            'ip_address'  => $ip ?? request()->ip(),
        ]);
    }

    /**
     * Haversine great-circle distance between two lat/lng points, in kilometers.
     */
    private function haversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadiusKm = 6371;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2)
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadiusKm * $c;
    }

    // ─── Formatting Helpers ────────────────────────────────────

    private function formatTechnicianDetails($technician, bool $detailed = false): ?array
    {
        if (!$technician) return null;

        $data = [
            'id'            => $technician->id,
            'name'          => $technician->user->name ?? 'Unknown',
            'phone'         => $technician->user->phone ?? '',
            'email'         => $technician->user->email ?? '',
            'profile_photo' => $technician->profile_photo
                ? url('storage/' . $technician->profile_photo)
                : null,
            'area'          => $technician->area,
            'latitude'      => $technician->latitude ? (float) $technician->latitude : null,
            'longitude'     => $technician->longitude ? (float) $technician->longitude : null,
            'is_online'     => (bool) $technician->is_online,
            'rating'        => (float) ($technician->rating ?? 0),
            'verified'      => (bool) $technician->verified,
            'experience'    => (int) ($technician->experience ?? 0),
            'hourly_rate'   => $technician->hourly_rate ? (float) $technician->hourly_rate : null,
            'services'      => $technician->services->pluck('name')->toArray(),
            'last_activity' => $technician->last_activity_at?->toIso8601String(),
        ];

        if ($detailed) {
            $data['stats'] = [
                'completed'   => ServiceRequest::where('technician_id', $technician->id)->where('status', 'completed')->count(),
                'pending'     => ServiceRequest::where('technician_id', $technician->id)->where('status', 'pending')->count(),
                'accepted'    => ServiceRequest::where('technician_id', $technician->id)->where('status', 'accepted')->count(),
                'in_progress' => ServiceRequest::where('technician_id', $technician->id)->where('status', 'in_progress')->count(),
                'on_the_way'  => ServiceRequest::where('technician_id', $technician->id)->where('status', 'on_the_way')->count(),
                'arrived'     => ServiceRequest::where('technician_id', $technician->id)->where('status', 'arrived')->count(),
                'rejected'    => ServiceRequest::where('technician_id', $technician->id)->where('status', 'rejected')->count(),
                'total'       => ServiceRequest::where('technician_id', $technician->id)->count(),
            ];
            $data['bio'] = $technician->bio;
            $data['created_at'] = $technician->created_at?->toIso8601String();
        }

        return $data;
    }

    private function formatMapRequest($request, $timeoutThreshold, $now): array
    {
        $isTimeout = $request->status === 'pending' && $request->created_at <= $timeoutThreshold;
        $latitude = $request->latitude ?? optional($request->technician)->latitude;
        $longitude = $request->longitude ?? optional($request->technician)->longitude;

        return [
            'id'              => $request->id,
            'description'     => $request->description,
            'status'          => $request->status,
            'is_timeout'      => $isTimeout,
            'minutes_elapsed' => $request->status === 'pending'
                ? round($request->created_at->diffInMinutes($now))
                : null,
            'created_at'      => $request->created_at->toIso8601String(),
            'date'            => $request->created_at->toDateString(),
            'day_ago'         => $request->created_at->diffInDays($now),
            'latitude'        => $latitude !== null ? (float) $latitude : null,
            'longitude'       => $longitude !== null ? (float) $longitude : null,
            'customer'        => $request->customer ? [
                'id'    => $request->customer->id,
                'name'  => $request->customer->name,
                'phone' => $request->customer->phone,
                'area'  => $request->customer->area ?? null,
            ] : null,
            'technician'      => $this->formatTechnicianDetails($request->technician),
            'service'         => $request->service ? [
                'id'       => $request->service->id,
                'name'     => $request->service->name,
                'category' => $request->service->categories->first() ? [
                    'id'   => $request->service->categories->first()->service_categoryID,
                    'name' => $request->service->categories->first()->category_name,
                ] : null,
            ] : null,
            'log_count'       => $request->logs ? $request->logs->count() : 0,
            'latest_log'      => $request->logs && $request->logs->isNotEmpty() ? [
                'action'     => $request->logs->last()->action,
                'created_at' => $request->logs->last()->created_at->toIso8601String(),
            ] : null,
        ];
    }

    // ─── Public Endpoints ─────────────────────────────────────

    public function map(Request $request)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole($request);

        // ✅ Added 'on_the_way' and 'arrived'
        $allowed = ['pending', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'completed', 'rejected', 'cancelled'];
        $statuses = $request->filled('status')
            ? array_values(array_intersect(explode(',', $request->status), $allowed))
            : ['pending', 'accepted', 'on_the_way', 'arrived', 'completed']; // default includes new statuses

        if (empty($statuses)) $statuses = ['pending', 'accepted'];

        $now = $this->now();
        $timeoutThreshold = $now->copy()->subMinutes(self::TIMEOUT_MINUTES);
        $pendingDaysBack = $request->input('pending_days_back', self::PENDING_DAYS_BACK);
        $todayDate = $this->today();

        $query = ServiceRequest::with(['customer', 'technician.user', 'service.categories', 'logs']);

        if (in_array('pending', $statuses)) {
            $startDate = $now->copy()->subDays($pendingDaysBack)->startOfDay();
            $query->where(function ($q) use ($startDate) {
                $q->where('status', 'pending')
                  ->whereDate('created_at', '>=', $startDate->toDateString());
            });
            $otherStatuses = array_diff($statuses, ['pending']);
            if (!empty($otherStatuses)) {
                $query->orWhere(function ($q) use ($todayDate, $otherStatuses) {
                    $q->whereIn('status', $otherStatuses)
                      ->whereDate('created_at', $todayDate);
                });
            }
        } else {
            $query->whereIn('status', $statuses)
                  ->whereDate('created_at', $todayDate);
        }

        $requestModels = $query->orderBy('created_at', 'asc')->get();

        $requests = $requestModels
            ->map(fn($r) => $this->formatMapRequest($r, $timeoutThreshold, $now))
            ->values();

        // Counts – include all statuses
        $todayCounts = [];
        $allStatuses = ['pending', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'completed', 'rejected', 'cancelled'];
        foreach ($allStatuses as $status) {
            $todayCounts[$status] = $requestModels->where('status', $status)->count();
        }
        $todayCounts['timeout'] = $requestModels
            ->filter(fn($r) => $r->status === 'pending' && $r->created_at <= $timeoutThreshold)
            ->count();
        $todayCounts['total'] = $requestModels->count();

        $pendingCounts = [];
        $pendingCounts['today'] = ServiceRequest::whereDate('created_at', $todayDate)
            ->where('status', 'pending')
            ->count();
        for ($i = 1; $i <= $pendingDaysBack; $i++) {
            $date = $now->copy()->subDays($i);
            $pendingCounts['day_' . $i] = [
                'date'  => $date->toDateString(),
                'label' => $date->format('D, M d'),
                'count' => ServiceRequest::whereDate('created_at', $date->toDateString())
                    ->where('status', 'pending')
                    ->count(),
            ];
        }
        $startDate = $now->copy()->subDays($pendingDaysBack)->startOfDay();
        $pendingCounts['total_pending'] = ServiceRequest::where('status', 'pending')
            ->whereDate('created_at', '>=', $startDate->toDateString())
            ->count();

        return $this->successResponse([
            'requests'        => $requests,
            'counts'          => $todayCounts,
            'pending_counts'  => $pendingCounts,
            'pending_days_back' => $pendingDaysBack,
            'timezone'        => self::TIMEZONE,
            'last_updated'    => $now->toIso8601String(),
            'date'            => $todayDate,
        ], 'Map data retrieved');
    }

    public function getNotifications(Request $request)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole($request);

        $now = $this->now();
        $pendingDaysBack = $request->input('days', 1);
        $startDate = $now->copy()->subDays($pendingDaysBack)->startOfDay();

        $notifications = ServiceRequest::where('status', 'pending')
            ->whereDate('created_at', '>=', $startDate->toDateString())
            ->with(['customer', 'service', 'technician.user'])
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(function ($r) use ($now) {
                $minutesElapsed = round($r->created_at->diffInMinutes($now));
                return [
                    'request_id'      => $r->id,
                    'customer_name'   => $r->customer->name ?? 'Unknown',
                    'service_name'    => $r->service->name ?? 'N/A',
                    'minutes_elapsed' => $minutesElapsed,
                    'created_at'      => $r->created_at->toIso8601String(),
                    'date'            => $r->created_at->toDateString(),
                    'is_timeout'      => $minutesElapsed >= self::TIMEOUT_MINUTES,
                    'technician'      => $this->formatTechnicianDetails($r->technician),
                ];
            })
            ->values();

        return $this->successResponse([
            'notifications'  => $notifications,
            'total_pending'  => $notifications->count(),
            'timeout_count'  => $notifications->where('is_timeout', true)->count(),
            'timezone'       => self::TIMEZONE,
            'timestamp'      => $now->toIso8601String(),
            'date'           => $this->today(),
        ], 'Notifications retrieved');
    }

    public function getStatuses(Request $request)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole($request);

        $todayDate = $this->today();
        // ✅ Include all statuses
        $statuses = ['pending', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'completed', 'rejected', 'cancelled'];
        $result = [];

        foreach ($statuses as $status) {
            $result[$status] = [
                'count' => ServiceRequest::whereDate('created_at', $todayDate)
                    ->where('status', $status)
                    ->count(),
                'label' => ucfirst(str_replace('_', ' ', $status)),
                'color' => match($status) {
                    'pending'     => '#f59e0b',
                    'accepted'    => '#10b981',
                    'on_the_way'  => '#f97316', // orange
                    'arrived'     => '#8b5cf6', // purple
                    'rejected'    => '#ef4444',
                    'in_progress' => '#8b5cf6',
                    'completed'   => '#22c55e',
                    'cancelled'   => '#6b7280',
                    default       => '#9aa0a6',
                }
            ];
        }

        return $this->successResponse([
            'statuses' => $result,
            'total'    => ServiceRequest::whereDate('created_at', $todayDate)->count(),
            'timezone' => self::TIMEZONE,
            'date'     => $todayDate,
        ], 'Status counts retrieved');
    }

    public function getPendingHistory(Request $request)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole($request);

        $now = $this->now();
        $daysBack = $request->input('days', self::PENDING_DAYS_BACK);
        $startDate = $now->copy()->subDays($daysBack)->startOfDay();

        $pendingRequests = ServiceRequest::with(['customer', 'service', 'technician.user'])
            ->where('status', 'pending')
            ->whereDate('created_at', '>=', $startDate->toDateString())
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(function ($r) use ($now) {
                return [
                    'id'          => $r->id,
                    'description' => $r->description,
                    'created_at'  => $r->created_at->toIso8601String(),
                    'date'        => $r->created_at->toDateString(),
                    'day_ago'     => $r->created_at->diffInDays($now),
                    'customer'    => $r->customer ? [
                        'id'    => $r->customer->id,
                        'name'  => $r->customer->name,
                        'phone' => $r->customer->phone,
                    ] : null,
                    'service'    => $r->service ? [
                        'id'   => $r->service->id,
                        'name' => $r->service->name,
                    ] : null,
                    'technician' => $this->formatTechnicianDetails($r->technician),
                ];
            });

        $grouped = $pendingRequests->groupBy('date')->map(function ($items, $date) {
            return [
                'date'    => $date,
                'label'   => Carbon::parse($date)->format('D, M d'),
                'count'   => $items->count(),
                'requests' => $items,
            ];
        })->values();

        return $this->successResponse([
            'pending_requests'  => $pendingRequests,
            'grouped_by_date'   => $grouped,
            'total_pending'     => $pendingRequests->count(),
            'days_back'         => $daysBack,
            'timezone'          => self::TIMEZONE,
            'date_range'        => [
                'from' => $startDate->toDateString(),
                'to'   => $this->today(),
            ],
        ], 'Pending history retrieved');
    }

    public function getTechnicians(Request $request)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole($request);

        $query = Technician::with(['user', 'services'])
            ->whereHas('user', fn($q) => $q->where('is_active', true));

        if ($request->filled('online_only')) $query->where('is_online', $request->boolean('online_only'));
        if ($request->filled('verified')) $query->where('verified', $request->boolean('verified'));
        if ($request->filled('area')) $query->where('area', 'like', "%{$request->area}%");
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->whereHas('user', fn($u) => $u->where('name', 'like', "%{$search}%"))
                  ->orWhere('area', 'like', "%{$search}%");
            });
        }

        $sortField = $request->input('sort_by', 'created_at');
        $sortOrder = $request->input('sort_order', 'desc');
        $query->orderBy($sortField, $sortOrder);

        $technicians = $query->get();
        $formatted = $technicians->map(fn($tech) => $this->formatTechnicianDetails($tech, true));

        return $this->successResponse([
            'technicians'  => $formatted,
            'total'        => $formatted->count(),
            'online_count' => $formatted->where('is_online', true)->count(),
            'timezone'     => self::TIMEZONE,
        ], 'Technicians retrieved');
    }

    public function getTechnician($id)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole(request());

        $technician = Technician::with(['user', 'services'])->findOrFail($id);
        return $this->successResponse(
            $this->formatTechnicianDetails($technician, true),
            'Technician details retrieved'
        );
    }

    public function getTechniciansByArea($area)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole(request());

        $technicians = Technician::with(['user', 'services'])
            ->where('area', 'like', "%{$area}%")
            ->whereHas('user', fn($q) => $q->where('is_active', true))
            ->get();

        $formatted = $technicians->map(fn($tech) => $this->formatTechnicianDetails($tech, true));

        return $this->successResponse([
            'technicians' => $formatted,
            'area'        => $area,
            'total'       => $formatted->count(),
            'timezone'    => self::TIMEZONE,
        ], 'Technicians in area retrieved');
    }

    public function getTechnicianCompletedRequests($id)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole(request());

        $technician = Technician::findOrFail($id);

        $requests = ServiceRequest::with(['customer', 'service'])
            ->where('technician_id', $id)
            ->where('status', 'completed')
            ->orderBy('updated_at', 'desc')
            ->get()
            ->map(function ($r) {
                return [
                    'id'           => $r->id,
                    'description'  => $r->description,
                    'created_at'   => $r->created_at->toIso8601String(),
                    'completed_at' => $r->updated_at->toIso8601String(),
                    'customer'     => $r->customer ? [
                        'id'   => $r->customer->id,
                        'name' => $r->customer->name,
                    ] : null,
                    'service' => $r->service ? [
                        'id'   => $r->service->id,
                        'name' => $r->service->name,
                    ] : null,
                ];
            });

        return $this->successResponse([
            'technician_id'   => $technician->id,
            'technician_name' => $technician->user->name ?? 'Unknown',
            'total_completed' => $requests->count(),
            'requests'        => $requests,
            'timezone'        => self::TIMEZONE,
        ], 'Completed requests retrieved');
    }

    public function callTechnician(Request $request, $id)
    {
        $this->checkPermission('monitoring.manage');
        $this->checkMonitoringRole($request);

        $technician = Technician::with('user')->findOrFail($id);
        $requestId = $request->input('request_id');

        if (!$technician->user || !$technician->user->phone) {
            return $this->errorResponse('Technician has no phone number registered.', 422);
        }

        $cleanPhone = $this->formatTanzaniaPhone($technician->user->phone);

        return $this->successResponse([
            'technician_id'   => $technician->id,
            'technician_name' => $technician->user->name,
            'phone_number'    => $technician->user->phone,
            'call_url'        => 'tel:+' . $cleanPhone,
            'whatsapp_url'    => 'https://wa.me/' . $cleanPhone,
            'request_id'      => $requestId,
            'technician'      => $this->formatTechnicianDetails($technician),
            'timezone'        => self::TIMEZONE,
        ], 'Call technician');
    }

    public function getRequestLogs($id)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole(request());

        $logs = RequestLog::where('request_id', $id)
            ->with('user')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($log) {
                return [
                    'id'          => $log->id,
                    'action'      => $log->action,
                    'old_status'  => $log->old_status,
                    'new_status'  => $log->new_status,
                    'notes'       => $log->notes,
                    'created_at'  => $log->created_at->toIso8601String(),
                    'user'        => $log->user ? [
                        'id'   => $log->user->id,
                        'name' => $log->user->name,
                    ] : null,
                ];
            });

        return $this->successResponse($logs, 'Request logs retrieved');
    }

    /**
     * ✅ Live technician tracking – now works for on_the_way and arrived as well.
     */
    public function getRequestTracking($id)
    {
        $this->checkPermission('monitoring.view');
        $this->checkMonitoringRole(request());

        $serviceRequest = ServiceRequest::with(['technician', 'customer'])->findOrFail($id);

        $customerLat = $serviceRequest->latitude;
        $customerLng = $serviceRequest->longitude;
        $techLat = $serviceRequest->technician->latitude ?? null;
        $techLng = $serviceRequest->technician->longitude ?? null;

        $distance = null;
        $eta = null;
        $etaMinutes = null;

        if ($customerLat && $customerLng && $techLat && $techLng) {
            $distance = $this->haversineDistance(
                (float) $customerLat,
                (float) $customerLng,
                (float) $techLat,
                (float) $techLng
            );

            $etaMinutes = round($distance * 2, 1);
            $eta = $this->now()->addMinutes($etaMinutes)->toIso8601String();
        }

        return $this->successResponse([
            'request_id'         => $serviceRequest->id,
            'status'              => $serviceRequest->status,
            'technician_location' => [
                'lat' => $techLat ? (float) $techLat : null,
                'lng' => $techLng ? (float) $techLng : null,
            ],
            'customer_location'   => [
                'lat' => $customerLat ? (float) $customerLat : null,
                'lng' => $customerLng ? (float) $customerLng : null,
            ],
            'technician'          => $this->formatTechnicianDetails($serviceRequest->technician),
            'distance_km'         => $distance ? round($distance, 2) : null,
            'eta_minutes'         => $etaMinutes,
            'eta'                 => $eta,
            'last_updated'        => $serviceRequest->technician->last_activity_at?->toIso8601String(),
            'timezone'            => self::TIMEZONE,
            'server_time'         => $this->now()->toIso8601String(),
        ], 'Tracking data retrieved');
    }

    public function updateStatus(Request $request, $id)
    {
        $this->checkPermission('monitoring.manage');
        $this->checkMonitoringRole($request);

        $validator = Validator::make($request->all(), [
            // ✅ Added on_the_way and arrived
            'status'        => 'required|in:pending,accepted,on_the_way,arrived,rejected,in_progress,completed,cancelled',
            'notes'         => 'nullable|string',
            'technician_id' => 'nullable|exists:technicians,id',
            'rating'        => 'nullable|numeric|min:1|max:5',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors()->first(), 422);
        }

        $serviceRequest = ServiceRequest::with(['technician.user', 'customer', 'service.categories'])->findOrFail($id);
        $oldStatus = $serviceRequest->status;
        $newStatus = $request->status;

        DB::beginTransaction();
        try {
            if ($newStatus === 'accepted' && $request->filled('technician_id')) {
                $serviceRequest->technician_id = $request->technician_id;
            }

            $serviceRequest->status = $newStatus;
            $serviceRequest->save();

            $this->logRequestAction(
                $serviceRequest->id,
                $request->user()->id,
                'status_update',
                $oldStatus,
                $newStatus,
                $request->input('notes') ?? "Status changed from {$oldStatus} to {$newStatus}",
                $request->ip()
            );

            if ($newStatus === 'completed') {
                $this->handleCompletedRequest($serviceRequest, $request);
            }

            DB::commit();

            $serviceRequest->refresh();
            $serviceRequest->load(['technician.user', 'customer', 'service.categories']);

            return $this->successResponse([
                'request'    => $this->formatSingleRequest($serviceRequest),
                'technician' => $this->formatTechnicianDetails($serviceRequest->technician),
                'logs'       => $this->getRequestLogs($serviceRequest->id),
                'message'    => $newStatus === 'completed'
                    ? 'Request marked as completed successfully! Technician stats updated.'
                    : 'Status updated successfully',
            ], 'Status updated successfully');
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Monitoring update status error: ' . $e->getMessage());
            return $this->serverError('Failed to update status: ' . $e->getMessage());
        }
    }

    public function completeRequest(Request $request, $id)
    {
        $this->checkPermission('monitoring.manage');
        $this->checkMonitoringRole($request);

        $validator = Validator::make($request->all(), [
            'notes'  => 'nullable|string',
            'rating' => 'nullable|numeric|min:1|max:5',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors()->first(), 422);
        }

        $serviceRequest = ServiceRequest::with(['technician.user', 'customer', 'service.categories'])->findOrFail($id);

        // ✅ Allow on_the_way and arrived as well
        if (!in_array($serviceRequest->status, ['accepted', 'on_the_way', 'arrived', 'in_progress'])) {
            return $this->errorResponse('Only accepted, on_the_way, arrived, or in-progress requests can be marked as completed.', 422);
        }

        $oldStatus = $serviceRequest->status;
        $newStatus = 'completed';

        DB::beginTransaction();
        try {
            $serviceRequest->status = $newStatus;
            $serviceRequest->save();

            $this->logRequestAction(
                $serviceRequest->id,
                $request->user()->id,
                'completed',
                $oldStatus,
                $newStatus,
                $request->input('notes') ?? 'Request completed by technician',
                $request->ip()
            );

            $this->handleCompletedRequest($serviceRequest, $request);

            DB::commit();

            $serviceRequest->refresh();
            $serviceRequest->load(['technician.user', 'customer', 'service.categories']);

            return $this->successResponse([
                'request'    => $this->formatSingleRequest($serviceRequest),
                'technician' => $this->formatTechnicianDetails($serviceRequest->technician),
                'message'    => 'Request completed successfully!',
            ], 'Request completed successfully');
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Complete request error: ' . $e->getMessage());
            return $this->serverError('Failed to complete request: ' . $e->getMessage());
        }
    }

    // ─── Private handlers ─────────────────────────────────────

    private function handleCompletedRequest(ServiceRequest $request, $httpRequest): void
    {
        $technician = $request->technician;
        if (!$technician) {
            Log::warning('No technician found for completed request', ['request_id' => $request->id]);
            return;
        }

        if ($httpRequest->filled('rating')) {
            $rating = (float) $httpRequest->rating;
            if ($rating >= 1 && $rating <= 5) {
                $totalCompleted = ServiceRequest::where('technician_id', $technician->id)
                    ->where('status', 'completed')
                    ->count();
                $currentRating = (float) ($technician->rating ?? 0);
                $newRating = (($currentRating * ($totalCompleted - 1)) + $rating) / $totalCompleted;
                $technician->rating = round($newRating, 2);
                $technician->save();
            }
        }

        $this->logRequestAction(
            $request->id,
            $httpRequest->user()->id,
            'completed',
            $request->status,
            'completed',
            $httpRequest->input('notes') ?? 'Request completed successfully',
            $httpRequest->ip()
        );
    }

    private function formatSingleRequest($request): array
    {
        return [
            'id'          => $request->id,
            'description' => $request->description,
            'status'      => $request->status,
            'created_at'  => $request->created_at?->toIso8601String(),
            'updated_at'  => $request->updated_at?->toIso8601String(),
            'customer'    => $request->customer ? [
                'id'    => $request->customer->id,
                'name'  => $request->customer->name,
                'phone' => $request->customer->phone,
                'email' => $request->customer->email,
            ] : null,
            'technician'  => $this->formatTechnicianDetails($request->technician),
            'service'     => $request->service ? [
                'id'       => $request->service->id,
                'name'     => $request->service->name,
                'category' => $request->service->categories->first() ? [
                    'id'   => $request->service->categories->first()->service_categoryID,
                    'name' => $request->service->categories->first()->category_name,
                ] : null,
            ] : null,
        ];
    }
}