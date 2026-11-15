<?php

namespace App\Http\Controllers\Api;

use App\Events\RequestCreated;
use App\Events\RequestStatusUpdated;
use App\Models\Job;
use App\Models\RequestLog;
use App\Models\Service;
use App\Models\ServiceRequest;
use App\Models\Technician;
use App\Models\Ticket;
use App\Services\RequestNotificationService;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

/**
 * requests.status enum: pending | accepted | cancelled | rejected
 *
 *   pending  → accepted   (assigned fundi)  ──▶ Job (on-progress) + Ticket (on-progress) created automatically
 *   pending  → rejected   (assigned fundi)
 *   pending  → cancelled  (the customer who created it)
 *   accepted / cancelled / rejected are LOCKED:
 *      an accepted request can no longer be cancelled or rejected.
 */
class RequestController extends BaseApiController
{
    use Auditable;

    public function __construct(protected RequestNotificationService $notifier)
    {
    }

    // ============================================================
    // PRIVATE HELPERS
    // ============================================================

    private function logRequestAction(
        int $requestId,
        int $userId,
        string $action,
        ?string $oldStatus,
        string $newStatus,
        ?string $notes = null,
        ?string $ip = null
    ): void {
        try {
            RequestLog::create([
                'request_id' => $requestId,
                'user_id'    => $userId,
                'action'     => $action,
                'old_status' => $oldStatus,
                'new_status' => $newStatus,
                'notes'      => $notes,
                'ip_address' => $ip ?? request()->ip(),
            ]);
        } catch (\Throwable $e) {
            Log::error('Failed to log request action: ' . $e->getMessage());
        }
    }

    private function afterResponse(callable $callback): void
    {
        app()->terminating(function () use ($callback) {
            try {
                $callback();
            } catch (\Throwable $e) {
                Log::error('After-response task failed: ' . $e->getMessage());
            }
        });
    }

    private function isAssignedFundi($user, ServiceRequest $serviceRequest): bool
    {
        return $user
            && $user->hasRole('FUNDI')
            && $user->technician
            && (int) $user->technician->id === (int) $serviceRequest->technician_id;
    }

    private function haversineDistance($lat1, $lon1, $lat2, $lon2): float
    {
        $r    = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a    = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;

        return $r * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    private function transitionError($user, ServiceRequest $sr, string $new): ?array
    {
        if (!$user) {
            return [403, 'User not authenticated.'];
        }

        // LOCK: only a pending request can change
        if ($sr->status !== ServiceRequest::STATUS_PENDING) {
            return $sr->status === ServiceRequest::STATUS_ACCEPTED
                ? [422, 'An accepted request can no longer be cancelled or rejected.']
                : [422, "This request is already {$sr->status} and can no longer be changed."];
        }

        if ($new === ServiceRequest::STATUS_PENDING) {
            return [422, 'A request cannot be moved back to pending.'];
        }

        if ($user->hasRole('FUNDI')) {
            if (!$this->isAssignedFundi($user, $sr)) {
                return [403, 'This request belongs to another fundi.'];
            }
            return in_array($new, [ServiceRequest::STATUS_ACCEPTED, ServiceRequest::STATUS_REJECTED], true)
                ? null
                : [403, 'A fundi can only accept or reject a pending request.'];
        }

        if ($user->hasRole('CUSTOMER')) {
            if ((int) $user->id !== (int) $sr->customer_id) {
                return [403, 'You can only manage your own requests.'];
            }
            return $new === ServiceRequest::STATUS_CANCELLED
                ? null
                : [403, 'A customer can only cancel a pending request.'];
        }

        if ($user->can('requests.status.update')) {
            return null;
        }

        return [403, 'You are not allowed to change this request.'];
    }

    private function applyTransition(ServiceRequest $sr, string $new, $user, ?string $ip): void
    {
        $old = $sr->status;
        $job = null;

        DB::beginTransaction();
        try {
            $sr->status = $new;
            $sr->save();

            if ($new === ServiceRequest::STATUS_ACCEPTED) {
                $job = $this->createJobForAcceptedRequest($sr);
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        try {
            event(new RequestStatusUpdated($sr));
        } catch (\Throwable $e) {
            Log::error('RequestStatusUpdated event failed: ' . $e->getMessage());
        }

        $this->logRequestAction(
            $sr->id, $user->id, $new, $old, $new,
            "Status changed from {$old} to {$new}", $ip
        );

        if ($job) {
            $this->logRequestAction(
                $sr->id, $user->id, 'job_created', $new, $new,
                "Job {$job->job_number} created automatically (on-progress)", $ip
            );
        }

        match ($new) {
            ServiceRequest::STATUS_ACCEPTED  => $this->afterResponse(fn () => $this->notifier->notifyCustomerAccepted($sr)),
            ServiceRequest::STATUS_REJECTED  => $this->afterResponse(fn () => $this->notifier->notifyCustomerRejected($sr)),
            ServiceRequest::STATUS_CANCELLED => $this->afterResponse(fn () => $this->notifier->notifyFundiCancelled($sr)),
            default                          => null,
        };

        $this->logAudit('update_request_status', 'request', $sr->id, "Status changed to {$new}");
    }

    private function createJobForAcceptedRequest(ServiceRequest $sr): Job
    {
        $existing = Job::where('request_id', $sr->id)->first();
        if ($existing) {
            return $existing;
        }

        $job = Job::create([
            'request_id'    => $sr->id,
            'technician_id' => $sr->technician_id,
            'customer_id'   => $sr->customer_id,
            'status'        => Job::STATUS_ON_PROGRESS,
            'started_at'    => now(),
        ]);

        Ticket::create([
            'job_id'      => $job->id,
            'status'      => Ticket::STATUS_ON_PROGRESS,
            'title'       => ($sr->service->name ?? 'Service') . ' — ' . $job->job_number,
            'description' => $sr->description,
        ]);

        return $job;
    }

    // ============================================================
    // LOOKUPS
    // ============================================================

    public function getServicesWithCategories(Request $request)
    {
        try {
            $services = Service::with(['categories' => function ($query) {
                $query->select('service_categories.service_categoryID', 'category_name', 'slug')
                      ->orderBy('category_name', 'asc');
            }])
            ->select('id', 'name', 'swahili_name')
            ->orderBy('name', 'asc')
            ->get();

            $data = $services->map(fn ($service) => [
                'id'      => $service->id,
                'name'    => $service->name,
                'name_en' => $service->name,
                'name_sw' => $service->swahili_name,
                'categories' => $service->categories->map(fn ($c) => [
                    'id'   => $c->service_categoryID,
                    'name' => $c->category_name,
                    'slug' => $c->slug,
                ]),
            ]);

            return $this->successResponse($data, 'Services with categories retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching services with categories: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch services. Please try again.', 500);
        }
    }

    public function getTechniciansByServiceCategory(Request $request)
    {
        try {
            $validated = $request->validate([
                'service_id'  => 'required|exists:services,id',
                'category_id' => 'nullable|exists:service_categories,service_categoryID',
            ]);

            $query = Technician::with(['user', 'services'])
                ->whereHas('user', fn ($q) => $q->where('is_active', true))
                ->where('verified', true)
                ->whereHas('services', fn ($q) => $q->where('services.id', $validated['service_id']));

            if (!empty($validated['category_id'])) {
                $query->whereHas('services.categories', fn ($q) =>
                    $q->where('service_categoryID', $validated['category_id'])
                );
            }

            $data = $query->get()->map(fn ($t) => [
                'id'            => $t->id,
                'name'          => $t->user->name ?? 'Unknown',
                'profile_photo' => $t->profile_photo ? url('storage/' . ltrim($t->profile_photo, '/')) : null,
                'area'          => $t->area,
                'rating'        => (float) ($t->rating ?? 0),
                'services'      => $t->services->map(fn ($s) => ['id' => $s->id, 'name' => $s->name]),
            ]);

            return $this->successResponse($data, 'Technicians retrieved successfully');
        } catch (ValidationException $e) {
            return $this->validationError($e->errors());
        } catch (\Exception $e) {
            Log::error('Error fetching technicians by service/category: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch technicians. Please try again.', 500);
        }
    }

    // ============================================================
    // CREATE
    // ============================================================

    public function store(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user || !$user->hasRole('CUSTOMER')) {
                return $this->forbidden('Only customers can create requests.');
            }

            $data = $request->validate([
                'technician_id' => 'required|exists:technicians,id',
                'service_id'    => 'required|exists:services,id',
                'category_id'   => 'nullable|exists:service_categories,service_categoryID',
                'description'   => 'required|string|min:5|max:1000',
                'latitude'      => 'nullable|numeric|between:-90,90',
                'longitude'     => 'nullable|numeric|between:-180,180',
            ]);

            $technician = Technician::with('user')->findOrFail($data['technician_id']);

            if (!$technician->verified || !$technician->user || !$technician->user->is_active) {
                return $this->errorResponse('This fundi is not available right now.', 422);
            }

            if ((int) $technician->user_id === (int) $user->id) {
                return $this->errorResponse('You cannot send a request to yourself.', 422);
            }

            if (!$technician->services()->where('services.id', $data['service_id'])->exists()) {
                return $this->errorResponse('This fundi does not offer the selected service.', 422);
            }

            if (!empty($data['category_id'])) {
                $service = Service::find($data['service_id']);
                if (!$service || !$service->hasCategory($data['category_id'])) {
                    return $this->errorResponse('The selected category is not associated with this service.', 422);
                }
            }

            $alreadyPending = ServiceRequest::where('customer_id', $user->id)
                ->where('technician_id', $technician->id)
                ->where('status', ServiceRequest::STATUS_PENDING)
                ->exists();

            if ($alreadyPending) {
                return $this->errorResponse(
                    'You already have a pending request with this fundi. Wait for a response or cancel it first.',
                    422
                );
            }

            DB::beginTransaction();

            $serviceRequest = ServiceRequest::create([
                'customer_id'   => $user->id,
                'technician_id' => $technician->id,
                'service_id'    => $data['service_id'],
                'category_id'   => $data['category_id'] ?? null,
                'description'   => $data['description'],
                'latitude'      => $data['latitude'] ?? null,
                'longitude'     => $data['longitude'] ?? null,
                'status'        => ServiceRequest::STATUS_PENDING,
            ]);

            $this->logRequestAction(
                $serviceRequest->id, $user->id, 'created', null, ServiceRequest::STATUS_PENDING,
                "Request created by customer {$user->id}"
            );

            DB::commit();

            $serviceRequest->load(['customer', 'technician.user', 'service', 'category', 'job']);

            try {
                event(new RequestCreated($serviceRequest));
            } catch (\Throwable $e) {
                Log::error('RequestCreated event failed: ' . $e->getMessage());
            }

            $this->afterResponse(fn () => $this->notifier->notifyFundiNewRequest($serviceRequest));

            $this->logAudit('create_request', 'request', $serviceRequest->id, "Customer {$user->id} created request");

            return $this->created($this->formatSingleRequest($serviceRequest), 'Request submitted successfully.');
        } catch (ValidationException $e) {
            return $this->validationError($e->errors());
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Fundi not found.');
        } catch (\Throwable $e) {
            if (DB::transactionLevel() > 0) {
                DB::rollBack();
            }
            Log::error('Error creating request: ' . $e->getMessage(), ['user_id' => $request->user()->id ?? 'unknown']);
            return $this->errorResponse('Failed to create request. Please try again.', 500);
        }
    }

    // ============================================================
    // STATUS & CANCEL
    // ============================================================

    public function updateStatus(Request $request, $id)
    {
        try {
            // Only valid for these statuses
            $newStatus = $request->validate([
                'status' => 'required|string|in:pending,accepted,cancelled,rejected',
            ])['status'];

            $serviceRequest = ServiceRequest::with(['technician.user', 'customer', 'service', 'category'])->findOrFail($id);
            $user           = $request->user();

            if ($error = $this->transitionError($user, $serviceRequest, $newStatus)) {
                [$code, $message] = $error;
                return $code === 403 ? $this->forbidden($message) : $this->errorResponse($message, $code);
            }

            $this->applyTransition($serviceRequest, $newStatus, $user, $request->ip());

            return $this->successResponse(
                $this->formatSingleRequest($serviceRequest->fresh(['customer', 'technician.user', 'service', 'category', 'job'])),
                'Status updated successfully.'
            );
        } catch (ValidationException $e) {
            return $this->validationError($e->errors());
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Request not found.');
        } catch (\Throwable $e) {
            Log::error('Error updating request status: ' . $e->getMessage(), [
                'request_id' => $id,
                'at'         => $e->getFile() . ':' . $e->getLine(),
            ]);

            return $this->errorResponse(
                config('app.debug')
                    ? 'Failed to update status: ' . $e->getMessage()
                    : 'Failed to update status. Please try again.',
                500
            );
        }
    }

    public function cancel($id, Request $request)
    {
        try {
            $serviceRequest = ServiceRequest::with(['technician.user', 'customer', 'service', 'category'])->findOrFail($id);
            $user           = $request->user();

            if ($error = $this->transitionError($user, $serviceRequest, ServiceRequest::STATUS_CANCELLED)) {
                [$code, $message] = $error;
                return $code === 403 ? $this->forbidden($message) : $this->errorResponse($message, $code);
            }

            $this->applyTransition($serviceRequest, ServiceRequest::STATUS_CANCELLED, $user, $request->ip());

            return $this->successResponse(
                $this->formatSingleRequest($serviceRequest->fresh(['customer', 'technician.user', 'service', 'category', 'job'])),
                'Request cancelled successfully.'
            );
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Request not found.');
        } catch (\Throwable $e) {
            Log::error('Error cancelling request: ' . $e->getMessage());
            return $this->errorResponse('Failed to cancel request. Please try again.', 500);
        }
    }

    // ============================================================
    // LISTS
    // ============================================================

    public function myRequests(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return $this->forbidden('User not authenticated.');
            }

            $perPage = (int) $request->input('per_page', 50);

            if ($user->hasRole('CUSTOMER')) {
                $requests = ServiceRequest::with(['technician.user', 'service', 'category', 'job'])
                    ->where('customer_id', $user->id)
                    ->latest()->paginate($perPage);
            } elseif ($user->hasRole('FUNDI')) {
                $technician = $user->technician;
                if (!$technician) {
                    return $this->successResponse($this->emptyPage($perPage), 'No requests found');
                }
                $requests = ServiceRequest::with(['customer', 'service', 'category', 'job'])
                    ->where('technician_id', $technician->id)
                    ->latest()->paginate($perPage);
            } else {
                if (!$user->can('requests.view')) {
                    return $this->forbidden('Unauthorized. You need requests.view permission.');
                }
                $requests = ServiceRequest::with(['customer', 'technician.user', 'service', 'category', 'job'])
                    ->latest()->paginate($perPage);
            }

            return $this->successResponse($this->formatRequests($requests), 'Requests retrieved successfully');
        } catch (\Throwable $e) {
            Log::error('Error fetching my requests: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch requests. Please try again.', 500);
        }
    }

    public function customerRequests(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user || !$user->hasRole('CUSTOMER')) {
                return $this->forbidden('Only customers can view their requests.');
            }

            $query = ServiceRequest::with(['technician.user', 'service', 'category', 'job'])
                ->where('customer_id', $user->id);

            if ($request->filled('status') && in_array($request->status, ServiceRequest::STATUSES, true)) {
                $query->where('status', $request->status);
            }

            $requests = $query->latest()->paginate((int) $request->input('per_page', 15));

            return $this->successResponse($this->formatRequests($requests), 'Customer requests retrieved successfully');
        } catch (\Throwable $e) {
            Log::error('Error fetching customer requests: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch requests. Please try again.', 500);
        }
    }

    public function technicianRequests(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user || !$user->hasRole('FUNDI')) {
                return $this->forbidden('Only technicians can view their requests.');
            }

            $perPage    = (int) $request->input('per_page', 15);
            $technician = $user->technician;

            if (!$technician) {
                return $this->successResponse($this->emptyPage($perPage), 'No requests found');
            }

            $query = ServiceRequest::with(['customer', 'service', 'category', 'job'])
                ->where('technician_id', $technician->id);

            if ($request->filled('status') && in_array($request->status, ServiceRequest::STATUSES, true)) {
                $query->where('status', $request->status);
            }

            $requests = $query->latest()->paginate($perPage);

            return $this->successResponse($this->formatRequests($requests), 'Technician requests retrieved successfully');
        } catch (\Throwable $e) {
            Log::error('Error fetching technician requests: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch requests. Please try again.', 500);
        }
    }

    // ============================================================
    // ADMIN
    // ============================================================

    public function index(Request $request)
    {
        try {
            if (!$request->user()->can('requests.view')) {
                return $this->forbidden('Unauthorized. You need requests.view permission.');
            }

            $query = ServiceRequest::with([
                'customer', 'technician.user', 'service', 'category', 'job',
                'logs' => fn ($q) => $q->latest()->limit(5),
            ]);

            if ($request->filled('status'))        $query->where('status', $request->status);
            if ($request->filled('customer_id'))   $query->where('customer_id', $request->customer_id);
            if ($request->filled('technician_id')) $query->where('technician_id', $request->technician_id);
            if ($request->filled('service_id'))    $query->where('service_id', $request->service_id);
            if ($request->filled('category_id'))   $query->where('category_id', $request->category_id);
            if ($request->filled('date_from'))     $query->whereDate('created_at', '>=', $request->date_from);
            if ($request->filled('date_to'))       $query->whereDate('created_at', '<=', $request->date_to);

            if ($request->filled('search')) {
                $search = $request->search;
                $query->where(function ($q) use ($search) {
                    $q->where('description', 'like', "%{$search}%")
                      ->orWhereHas('customer', fn ($cq) => $cq->where('name', 'like', "%{$search}%")
                          ->orWhere('email', 'like', "%{$search}%")
                          ->orWhere('phone', 'like', "%{$search}%"))
                      ->orWhereHas('technician.user', fn ($tq) => $tq->where('name', 'like', "%{$search}%")
                          ->orWhere('email', 'like', "%{$search}%")
                          ->orWhere('phone', 'like', "%{$search}%"));
                });
            }

            $sortField = in_array($request->input('sort_by'), ['id', 'created_at', 'updated_at', 'status', 'customer_id', 'technician_id'], true)
                ? $request->input('sort_by') : 'created_at';
            $sortOrder = $request->input('sort_order') === 'asc' ? 'asc' : 'desc';
            $query->orderBy($sortField, $sortOrder);

            $requests = $query->paginate((int) $request->input('per_page', 20));

            return $this->successResponse($this->formatRequests($requests), 'Requests retrieved successfully');
        } catch (\Throwable $e) {
            Log::error('Error fetching requests: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch requests. Please try again.', 500);
        }
    }

    public function show($id, Request $request)
    {
        try {
            if (!$request->user()->can('requests.view')) {
                return $this->forbidden('Unauthorized. You need requests.view permission.');
            }

            $serviceRequest = ServiceRequest::with([
                'customer', 'technician.user', 'service', 'category', 'job', 'logs.user',
            ])->findOrFail($id);

            return $this->successResponse($this->formatSingleRequest($serviceRequest), 'Request retrieved successfully');
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Request not found.');
        } catch (\Throwable $e) {
            Log::error('Error fetching request: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch request. Please try again.', 500);
        }
    }

    public function destroy($id, Request $request)
    {
        try {
            if (!$request->user()->can('requests.delete')) {
                return $this->forbidden('Unauthorized. You need requests.delete permission.');
            }

            $serviceRequest = ServiceRequest::findOrFail($id);

            DB::beginTransaction();
            RequestLog::where('request_id', $id)->delete();
            $serviceRequest->delete();
            DB::commit();

            $this->logAudit('delete_request', 'request', $id, "Deleted request ID: $id");

            return $this->successResponse(null, 'Request deleted successfully.');
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Request not found.');
        } catch (\Throwable $e) {
            if (DB::transactionLevel() > 0) {
                DB::rollBack();
            }
            Log::error('Error deleting request: ' . $e->getMessage());
            return $this->errorResponse('Failed to delete request. Please try again.', 500);
        }
    }

    public function logs($requestId, Request $request)
    {
        try {
            if (!$request->user()->can('requests.view')) {
                return $this->forbidden('Unauthorized. You need requests.view permission.');
            }

            $logs = RequestLog::where('request_id', $requestId)->with('user')->orderBy('created_at', 'desc')->get();

            return $this->successResponse($logs, 'Request logs retrieved successfully');
        } catch (\Throwable $e) {
            Log::error('Error fetching request logs: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch logs. Please try again.', 500);
        }
    }

    public function stats(Request $request)
    {
        try {
            if (!$request->user()->can('requests.view')) {
                return $this->forbidden('Unauthorized. You need requests.view permission.');
            }

            return $this->successResponse([
                'total'      => ServiceRequest::count(),
                'pending'    => ServiceRequest::where('status', ServiceRequest::STATUS_PENDING)->count(),
                'accepted'   => ServiceRequest::where('status', ServiceRequest::STATUS_ACCEPTED)->count(),
                'cancelled'  => ServiceRequest::where('status', ServiceRequest::STATUS_CANCELLED)->count(),
                'rejected'   => ServiceRequest::where('status', ServiceRequest::STATUS_REJECTED)->count(),
                'today'      => ServiceRequest::whereDate('created_at', today())->count(),
                'this_week'  => ServiceRequest::whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()])->count(),
                'this_month' => ServiceRequest::whereYear('created_at', now()->year)->whereMonth('created_at', now()->month)->count(),
            ], 'Request statistics retrieved successfully');
        } catch (\Throwable $e) {
            Log::error('Error fetching request stats: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch statistics. Please try again.', 500);
        }
    }

    // ============================================================
    // TRACKING / LOCATION
    // ============================================================

    public function trackingData(Request $request, $id)
    {
        try {
            $serviceRequest = ServiceRequest::with('technician')->findOrFail($id);
            $user           = $request->user();

            $isCustomer = $user && (int) $user->id === (int) $serviceRequest->customer_id;
            if (!$isCustomer && !$this->isAssignedFundi($user, $serviceRequest) && !$user?->can('requests.view')) {
                return $this->forbidden('You are not allowed to view this request.');
            }

            $custLat = $serviceRequest->latitude;
            $custLng = $serviceRequest->longitude;
            $techLat = $serviceRequest->technician->latitude ?? null;
            $techLng = $serviceRequest->technician->longitude ?? null;

            $distance = null;
            $eta      = null;

            if ($custLat && $custLng && $techLat && $techLng) {
                $distance = $this->haversineDistance($custLat, $custLng, $techLat, $techLng);
                $eta      = now()->addMinutes(($distance / 30) * 60)->toIso8601String(); // ~30 km/h
            }

            return $this->successResponse([
                'technician_location' => [
                    'lat' => $techLat !== null ? (float) $techLat : null,
                    'lng' => $techLng !== null ? (float) $techLng : null,
                ],
                'customer_location' => [
                    'lat' => $custLat !== null ? (float) $custLat : null,
                    'lng' => $custLng !== null ? (float) $custLng : null,
                ],
                'status'       => $serviceRequest->status,
                'distance_km'  => $distance !== null ? round($distance, 2) : null,
                'eta'          => $eta,
                'last_updated' => $serviceRequest->technician->location_updated_at?->toIso8601String(),
            ], 'Tracking data retrieved.');
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Request not found.');
        } catch (\Throwable $e) {
            Log::error('Error fetching tracking data: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch tracking data.', 500);
        }
    }

    public function updateLocation(Request $request, $id)
    {
        try {
            $serviceRequest = ServiceRequest::findOrFail($id);
            $user           = $request->user();

            if (!$user || (int) $user->id !== (int) $serviceRequest->customer_id) {
                return $this->forbidden('You can only update location for your own requests.');
            }

            $data = $request->validate([
                'latitude'  => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
            ]);

            $serviceRequest->latitude  = $data['latitude'];
            $serviceRequest->longitude = $data['longitude'];
            $serviceRequest->save();

            return $this->successResponse([
                'request_id' => (int) $id,
                'latitude'   => (float) $serviceRequest->latitude,
                'longitude'  => (float) $serviceRequest->longitude,
            ], 'Location updated successfully.');
        } catch (ModelNotFoundException $e) {
            return $this->notFound('Request not found.');
        } catch (ValidationException $e) {
            return $this->validationError($e->errors());
        } catch (\Throwable $e) {
            Log::error('Error updating location: ' . $e->getMessage());
            return $this->errorResponse('Failed to update location. Please try again.', 500);
        }
    }

    // ============================================================
    // FORMATTERS
    // ============================================================

    private function emptyPage(int $perPage): array
    {
        return [
            'data'       => [],
            'pagination' => ['total' => 0, 'per_page' => $perPage, 'current_page' => 1, 'last_page' => 1],
        ];
    }

    private function formatRequests($requests): array
    {
        return [
            'data'       => $requests->map(fn ($r) => $this->formatSingleRequest($r)),
            'pagination' => [
                'total'        => $requests->total(),
                'per_page'     => $requests->perPage(),
                'current_page' => $requests->currentPage(),
                'last_page'    => $requests->lastPage(),
            ],
        ];
    }

    private function formatSingleRequest($request): array
    {
        $request->loadMissing('job');

        $tech     = $request->technician;
        $accepted = $request->status === ServiceRequest::STATUS_ACCEPTED;
        $job      = $request->job;

        return [
            'id'          => $request->id,
            'description' => $request->description,
            'status'      => $request->status,
            'can_cancel'  => $request->status === ServiceRequest::STATUS_PENDING,
            'has_job'     => (bool) $job,
            'job'         => $job ? [
                'id'         => $job->id,
                'job_number' => $job->job_number,
                'status'     => $job->status, // pending | on-progress | completed
            ] : null,
            'created_at'  => $request->created_at,
            'updated_at'  => $request->updated_at,
            'customer'    => $request->customer ? [
                'id'    => $request->customer->id,
                'name'  => $request->customer->name,
                'email' => $request->customer->email,
                'phone' => $accepted ? $request->customer->phone : null,
            ] : null,
            'technician_id' => $request->technician_id,
            'technician'  => $tech ? [
                'id'            => $tech->id,
                'name'          => $tech->user->name ?? null,
                'email'         => $tech->user->email ?? null,
                'phone'         => $accepted ? ($tech->user->phone ?? null) : null,
                'profile_photo' => $tech->profile_photo ? url('storage/' . ltrim($tech->profile_photo, '/')) : null,
                'area'          => $tech->area,
                'rating'        => (float) ($tech->rating ?? 0),
            ] : null,
            'service'     => $request->service ? ['id' => $request->service->id, 'name' => $request->service->name] : null,
            'category'    => $request->category ? [
                'id'   => $request->category->service_categoryID,
                'name' => $request->category->category_name,
                'slug' => $request->category->slug,
            ] : null,
            'latitude'    => $request->latitude ? (float) $request->latitude : null,
            'longitude'   => $request->longitude ? (float) $request->longitude : null,
            'logs'        => $request->relationLoaded('logs')
                ? $request->logs->map(fn ($log) => [
                    'id'         => $log->id,
                    'action'     => $log->action,
                    'old_status' => $log->old_status,
                    'new_status' => $log->new_status,
                    'notes'      => $log->notes,
                    'created_at' => $log->created_at,
                    'user'       => $log->user ? ['id' => $log->user->id, 'name' => $log->user->name] : null,
                ])
                : [],
        ];
    }
}