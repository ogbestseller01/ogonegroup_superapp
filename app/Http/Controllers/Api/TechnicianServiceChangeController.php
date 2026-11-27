<?php

namespace App\Http\Controllers\Api;

use App\Models\Service;
use App\Models\Technician;
use App\Models\TechnicianBlockedService;
use App\Models\TechnicianServiceChangeRequest as ChangeRequest;
use App\Models\User;
use App\Services\ServiceChangeNotificationService;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Fundi service changes need admin approval. technician_services is only
 * changed inside approve().
 */
class TechnicianServiceChangeController extends BaseApiController
{
    use Auditable;

    private const PERM_VIEW    = 'service-changes.view';
    private const PERM_APPROVE = 'service-changes.approve';
    private const PERM_REJECT  = 'service-changes.reject';

    private const MESSAGES = [
        'no_profile' => [
            'en' => 'Technician profile not found.',
            'sw' => 'Wasifu wa fundi haujapatikana.',
        ],
        'pending_exists' => [
            'en' => 'You already have a service change waiting for approval.',
            'sw' => 'Tayari una ombi la kubadili huduma linalosubiri idhini.',
        ],
        'no_change' => [
            'en' => 'You have not changed any service.',
            'sw' => 'Hujabadilisha huduma yoyote.',
        ],
        'blocked' => [
            'en' => 'These services were rejected for your account and cannot be added: ',
            'sw' => 'Huduma hizi zilikataliwa kwenye akaunti yako na haziwezi kuongezwa: ',
        ],
        'submitted' => [
            'en' => 'Your request was submitted for admin approval.',
            'sw' => 'Ombi lako limetumwa kwa msimamizi kwa idhini.',
        ],
        'reason_required' => [
            'en' => 'Give a reason for the change.',
            'sw' => 'Eleza sababu ya mabadiliko.',
        ],
        'reason_length' => [
            'en' => 'The reason must be 10 to 1000 characters.',
            'sw' => 'Sababu iwe na herufi 10 hadi 1000.',
        ],
        'services_required' => [
            'en' => 'Select at least one valid service.',
            'sw' => 'Chagua angalau huduma moja sahihi.',
        ],
    ];

    // ═══════════════════════════════════════════════════════
    // FUNDI
    // ═══════════════════════════════════════════════════════

    /** GET /v19/technicians/service-changes */
    public function options(Request $request)
    {
        $technician = $request->user()->technician;

        if (!$technician) {
            return $this->notFound($this->msg($request, 'no_profile'));
        }

        $services = Service::with('categories')->orderBy('name')->get();

        $latest = ChangeRequest::where('technician_id', $technician->id)
            ->latest('id')
            ->first();

        return $this->successResponse([
            'services' => $services->map(fn (Service $s) => [
                'id'         => $s->id,
                'name_en'    => $s->name,
                'name_sw'    => $s->swahili_name,
                'categories' => $s->categories->map(fn ($c) => [
                    'id'      => $c->service_categoryID,
                    'name_en' => $c->category_name,
                    'name_sw' => $c->swahili_name,
                ])->values(),
            ])->values(),
            'current_service_ids' => $this->currentServiceIds($technician),
            'blocked_service_ids' => TechnicianBlockedService::idsFor($technician->id),
            'latest_request'      => $latest ? $this->present($latest) : null,
        ]);
    }

    /** POST /v19/technicians/services   { services: [ids], reason: "..." } */
    public function store(Request $request)
    {
        $technician = $request->user()->technician;

        if (!$technician) {
            return $this->notFound($this->msg($request, 'no_profile'));
        }

        $request->merge(['reason' => trim((string) $request->input('reason', ''))]);

        $data = $request->validate([
            'services'   => 'required|array|min:1|max:50',
            'services.*' => 'required|integer|distinct|exists:services,id',
            'reason'     => 'required|string|min:10|max:1000',
        ], [
            'services.required'   => $this->msg($request, 'services_required'),
            'services.min'        => $this->msg($request, 'services_required'),
            'services.*.exists'   => $this->msg($request, 'services_required'),
            'reason.required'     => $this->msg($request, 'reason_required'),
            'reason.min'          => $this->msg($request, 'reason_length'),
            'reason.max'          => $this->msg($request, 'reason_length'),
        ]);

        $requested = collect($data['services'])
            ->map(fn ($id) => (int) $id)
            ->sort()->values()->all();

        $result = DB::transaction(function () use ($technician, $requested, $data, $request) {
            // Row lock: two quick taps cannot create two pending requests.
            Technician::whereKey($technician->id)->lockForUpdate()->first();

            $pending = ChangeRequest::where('technician_id', $technician->id)
                ->where('status', ChangeRequest::STATUS_PENDING)
                ->exists();

            if ($pending) {
                return ['error' => $this->msg($request, 'pending_exists'), 'code' => 409];
            }

            $current = $this->currentServiceIds($technician);
            $added   = array_values(array_diff($requested, $current));
            $removed = array_values(array_diff($current, $requested));

            if (!$added && !$removed) {
                return ['error' => $this->msg($request, 'no_change'), 'code' => 422];
            }

            $blocked = array_values(array_intersect(
                $added,
                TechnicianBlockedService::idsFor($technician->id)
            ));

            if ($blocked) {
                $locale = $this->locale($request);
                $names  = Service::whereIn('id', $blocked)->get()
                    ->map(fn (Service $s) => $s->getNameForLocale($locale))
                    ->implode(', ');

                return ['error' => $this->msg($request, 'blocked') . $names, 'code' => 422];
            }

            return ['change' => ChangeRequest::create([
                'technician_id'         => $technician->id,
                'current_service_ids'   => $current,
                'requested_service_ids' => $requested,
                'added_service_ids'     => $added,
                'removed_service_ids'   => $removed,
                'reason'                => $data['reason'],
                'status'                => ChangeRequest::STATUS_PENDING,
            ])];
        });

        if (isset($result['error'])) {
            return $this->errorResponse($result['error'], $result['code']);
        }

        $change = $result['change'];

        $this->logAudit(
            'request_service_change',
            'technician',
            $technician->id,
            "Service change request #{$change->id} submitted"
        );

        // Email everyone who is allowed to approve (after the response).
        ServiceChangeNotificationService::dispatchSubmitted($change->id);

        return $this->successResponse(
            $this->present($change),
            $this->msg($request, 'submitted')
        );
    }

    // ═══════════════════════════════════════════════════════
    // ADMIN
    // ═══════════════════════════════════════════════════════

    /** GET /v20/admin/service-changes?status=pending|approved|rejected|all */
    public function adminIndex(Request $request)
    {
        $this->checkPermission(self::PERM_VIEW);

        $request->validate([
            'status'   => 'nullable|in:pending,approved,rejected,all',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $status = $request->input('status', ChangeRequest::STATUS_PENDING);

        $page = ChangeRequest::with(['technician.user', 'reviewer'])
            ->when($status !== 'all', fn ($q) => $q->where('status', $status))
            ->latest('id')
            ->paginate((int) $request->input('per_page', 15));

        $page->through(fn (ChangeRequest $c) => $this->presentForAdmin($c));

        return $this->successResponse($page);
    }

    /** GET /v20/admin/service-changes/{id} */
    public function adminShow($id)
    {
        $this->checkPermission(self::PERM_VIEW);

        $change = ChangeRequest::with(['technician.user', 'reviewer'])->find($id);

        if (!$change) {
            return $this->notFound('Service change request not found.');
        }

        return $this->successResponse($this->presentForAdmin($change));
    }

    /** POST /v20/admin/service-changes/{id}/approve */
    public function approve(Request $request, $id)
    {
        $this->checkPermission(self::PERM_APPROVE);

        $result = DB::transaction(function () use ($request, $id) {
            [$change, $error] = $this->lockReviewable($request, $id);
            if ($error) {
                return $error;
            }

            $technician = $change->technician;
            $added      = array_map('intval', $change->added_service_ids ?? []);
            $removed    = array_map('intval', $change->removed_service_ids ?? []);

            if (Service::whereIn('id', $added)->count() !== count($added)) {
                return ['error' => 'A requested service no longer exists. Reject this request.', 'code' => 422];
            }

            // Apply only the difference, so other changes made meanwhile survive.
            $final = array_unique(array_merge(
                array_diff($this->currentServiceIds($technician), $removed),
                $added
            ));

            if (!$final) {
                return ['error' => 'Approval would leave the Fundi with no services. Reject this request.', 'code' => 422];
            }

            if ($removed) {
                $technician->services()->detach($removed);
            }
            if ($added) {
                $technician->services()->syncWithoutDetaching($added);
            }

            $change->update([
                'status'      => ChangeRequest::STATUS_APPROVED,
                'reviewed_by' => $request->user()->id,
                'reviewed_at' => now(),
            ]);

            return ['change' => $change];
        });

        return $this->finishReview($result, 'approve_service_change', 'Service change approved.');
    }

    /** POST /v20/admin/service-changes/{id}/reject   { rejection_reason: "..." } */
    public function reject(Request $request, $id)
    {
        $this->checkPermission(self::PERM_REJECT);

        $request->merge(['rejection_reason' => trim((string) $request->input('rejection_reason', ''))]);
        $data = $request->validate(['rejection_reason' => 'required|string|min:5|max:1000']);

        $result = DB::transaction(function () use ($request, $id, $data) {
            [$change, $error] = $this->lockReviewable($request, $id);
            if ($error) {
                return $error;
            }

            $change->update([
                'status'           => ChangeRequest::STATUS_REJECTED,
                'rejection_reason' => $data['rejection_reason'],
                'reviewed_by'      => $request->user()->id,
                'reviewed_at'      => now(),
            ]);

            // Rejected additions can no longer be set on this Fundi.
            $existing = Service::whereIn('id', $change->added_service_ids ?? [])->pluck('id');

            foreach ($existing as $serviceId) {
                TechnicianBlockedService::updateOrCreate(
                    ['technician_id' => $change->technician_id, 'service_id' => $serviceId],
                    ['change_request_id' => $change->id]
                );
            }

            return ['change' => $change];
        });

        return $this->finishReview($result, 'reject_service_change', 'Service change rejected.');
    }

    // ═══════════════════════════════════════════════════════
    // PRIVATE
    // ═══════════════════════════════════════════════════════

    /** Must run inside a transaction. Returns [change, null] or [null, error]. */
    private function lockReviewable(Request $request, $id): array
    {
        $change = ChangeRequest::whereKey($id)->lockForUpdate()->first();

        if (!$change) {
            return [null, ['error' => 'Service change request not found.', 'code' => 404]];
        }
        if (!$change->isPending()) {
            return [null, ['error' => 'This request has already been reviewed.', 'code' => 409]];
        }
        if (!$change->technician) {
            return [null, ['error' => 'The technician no longer exists.', 'code' => 422]];
        }
        if ((int) $change->technician->user_id === (int) $request->user()->id) {
            return [null, ['error' => 'You cannot review your own request.', 'code' => 403]];
        }

        return [$change, null];
    }

    private function finishReview(array $result, string $action, string $message)
    {
        if (isset($result['error'])) {
            return $this->errorResponse($result['error'], $result['code']);
        }

        $change = $result['change'];

        $this->logAudit($action, 'technician', $change->technician_id, "{$message} Request #{$change->id}");

        ServiceChangeNotificationService::dispatchDecision($change->id);

        return $this->successResponse(
            $this->presentForAdmin($change->fresh(['technician.user', 'reviewer'])),
            $message
        );
    }

    /** @return array<int> */
    private function currentServiceIds(Technician $technician): array
    {
        return $technician->services()
            ->pluck('services.id')
            ->map(fn ($id) => (int) $id)
            ->sort()->values()->all();
    }

    private function present(ChangeRequest $c): array
    {
        return [
            'id'                  => $c->id,
            'status'              => $c->status,
            'reason'              => $c->reason,
            'rejection_reason'    => $c->rejection_reason,
            'added_service_ids'   => $c->added_service_ids ?? [],
            'removed_service_ids' => $c->removed_service_ids ?? [],
            'created_at'          => $c->created_at?->toIso8601String(),
            'reviewed_at'         => $c->reviewed_at?->toIso8601String(),
        ];
    }

    private function presentForAdmin(ChangeRequest $c): array
    {
        $ids = array_merge($c->added_service_ids ?? [], $c->removed_service_ids ?? []);

        /** @var Collection<int, Service> $services */
        $services = Service::with('categories')->whereIn('id', $ids)->get()->keyBy('id');

        $describe = fn (array $list) => collect($list)->map(fn ($id) => [
            'id'         => (int) $id,
            'name'       => $services->get($id)?->name,
            'categories' => $services->get($id)?->categories->pluck('category_name')->values() ?? [],
        ])->values();

        $user = $c->technician?->user;

        return $this->present($c) + [
            'technician' => [
                'id'    => $c->technician_id,
                'name'  => $user?->name,
                'phone' => $user?->phone,
                'email' => $user?->email,
            ],
            'added_services'   => $describe($c->added_service_ids ?? []),
            'removed_services' => $describe($c->removed_service_ids ?? []),
            'reviewed_by'      => $c->reviewer?->only(['id', 'name']),
        ];
    }

    private function locale(Request $request): string
    {
        $user   = $request->user();
        $header = strtolower(substr((string) $request->header('Accept-Language', ''), 0, 2));

        if (in_array($header, ['en', 'sw'], true)) {
            return $header;
        }

        return $user instanceof User && $user->locale === 'sw' ? 'sw' : 'en';
    }

    private function msg(Request $request, string $key): string
    {
        return self::MESSAGES[$key][$this->locale($request)];
    }
}
