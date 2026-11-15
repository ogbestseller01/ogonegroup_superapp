<?php

namespace App\Http\Controllers\Api;

use App\Models\SystemUpdate;
use App\Models\User;
use App\Services\SystemUpdateService;
use App\Traits\Auditable;
use DomainException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class SystemUpdateController extends BaseApiController
{
    use Auditable;

    public function __construct(private SystemUpdateService $service) {}

    // ───────────── ADMIN ─────────────

    public function index(Request $request)
    {
        try {
            $q = SystemUpdate::query()
                ->when($request->filled('status'), fn ($q) => $q->where('status', $request->status))
                ->when($request->filled('search'), fn ($q) => $q->where(function ($w) use ($request) {
                    $w->where('title', 'LIKE', "%{$request->search}%")
                      ->orWhere('description', 'LIKE', "%{$request->search}%");
                }))
                ->withCount([
                    'notifications as push_sent'    => fn ($n) => $n->where('channel', 'push')->where('status', 'sent'),
                    'notifications as push_failed'  => fn ($n) => $n->where('channel', 'push')->where('status', 'failed'),
                    'userStates as received_count'  => fn ($n) => $n->whereNotNull('received_at'),
                    'userStates as viewed_count'    => fn ($n) => $n->whereNotNull('viewed_at'),
                    'userStates as dismissed_count' => fn ($n) => $n->whereNotNull('dismissed_at'),
                ])
                ->latest();

            return $this->successResponse($q->paginate((int) $request->input('per_page', 15)));
        } catch (\Exception $e) {
            Log::error('System Update Index Error: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch system updates. ' . $e->getMessage(), 500);
        }
    }

    public function show($id)
    {
        $update = SystemUpdate::find($id);
        return $update ? $this->successResponse($update) : $this->notFound('Update not found.');
    }

    public function store(Request $request)
    {
        $data   = $this->validateContent($request);
        $update = $this->service->createDraft($data, $request->user()->id);

        $this->logAudit('create_system_update', 'system_update', $update->id, "Update created: {$update->title}");

        if ($request->boolean('publish')) {
            try {
                $update = $this->service->publish($update);
                $this->logAudit('publish_system_update', 'system_update', $update->id, 'Update published');
            } catch (\Throwable $e) {
                Log::error('Publish Delivery Error: ' . $e->getMessage());
            }
        }

        return $this->created($update, $request->boolean('publish') ? 'Update published.' : 'Draft saved.');
    }

    public function saveDraft(Request $request)
    {
        $data = $this->validateContent($request);

        if ($request->filled('id')) {
            $update = SystemUpdate::find($request->id);
            if (!$update) return $this->notFound('Update not found.');
            if ($update->status !== SystemUpdate::STATUS_DRAFT) {
                return $this->errorResponse('Only drafts can be saved as draft.', 409);
            }
            $update = $this->service->update($update, $data);
        } else {
            $update = $this->service->createDraft($data, $request->user()->id);
        }

        return $this->successResponse($update, 'Draft saved.');
    }

    public function update(Request $request, $id)
    {
        $update = SystemUpdate::find($id);
        if (!$update) return $this->notFound('Update not found.');

        $data   = $this->validateContent($request, partial: true);
        $update = $this->service->update($update, $data);

        $this->logAudit('update_system_update', 'system_update', $update->id, 'Update edited');

        return $this->successResponse($update, 'Update saved.');
    }

    public function destroy($id)
    {
        $update = SystemUpdate::find($id);
        if (!$update) return $this->notFound('Update not found.');

        $this->service->delete($update);
        $this->logAudit('delete_system_update', 'system_update', (int) $id, 'Update deleted');

        return $this->successResponse(null, 'Update deleted.');
    }

    public function publish($id)
    {
        $update = SystemUpdate::find($id);
        if (!$update) return $this->notFound('Update not found.');

        try {
            $update = $this->service->publish($update);
            $this->logAudit('publish_system_update', 'system_update', $update->id, 'Update published');
            return $this->successResponse($update, 'Update published. Notifications are being sent.');
        } catch (DomainException $e) {
            return $this->errorResponse($e->getMessage(), 409);
        } catch (\Throwable $e) {
            Log::error('Publish Delivery Error: ' . $e->getMessage());
            return $this->successResponse($update, 'Update published, but some notifications failed.');
        }
    }

    public function close($id)
    {
        $update = SystemUpdate::find($id);
        if (!$update) return $this->notFound('Update not found.');

        try {
            $update = $this->service->close($update);
        } catch (DomainException $e) {
            return $this->errorResponse($e->getMessage(), 409);
        }

        $this->logAudit('close_system_update', 'system_update', $update->id, 'Update closed');

        return $this->successResponse($update, 'Update closed.');
    }

    // ───────────── PUBLIC / USER ─────────────

    /**
     * HOME CARD — latest active update (regardless of when it was published).
     * Returns [] if nothing is active/closed.
     */
    public function active(Request $request)
    {
        // Removed whereDate('published_at', today()) so all active updates show
        $latest = SystemUpdate::published()
            ->whereNull('closed_at')
            ->latest('published_at')
            ->first();

        $list = $latest
            ? collect([$this->publicShape($latest)])
            : collect();

        return $this->successResponse($list->values());
    }

    /**
     * LIST SCREEN — ALL published, non-closed updates (any date), newest first.
     * Optional query: ?limit=200 (flat array) | ?page=1&per_page=15 (paginated).
     */
    public function all(Request $request)
    {
        $limit = (int) $request->input('limit', 0);

        $q = SystemUpdate::published()
            ->whereNull('closed_at')
            ->orderByDesc('published_at');

        if ($limit > 0) {
            $list = $q->limit(min($limit, 200))
                ->get()
                ->map(fn ($u) => $this->publicShape($u))
                ->values();

            return $this->successResponse($list);
        }

        return $this->successResponse(
            $q->paginate((int) $request->input('per_page', 15))
              ->through(fn ($u) => $this->publicShape($u))
        );
    }

    public function showPublic($id)
    {
        $update = SystemUpdate::published()
            ->whereNull('closed_at')
            ->find($id);

        return $update
            ? $this->successResponse($this->publicShape($update))
            : $this->notFound('Update not found.');
    }

    public function markViewed($id)
    {
        $update = SystemUpdate::published()
            ->whereNull('closed_at')
            ->find($id);

        if (!$update) return $this->notFound('Update not found.');

        $user = auth('sanctum')->user();
        if ($user instanceof User) {
            $this->service->markViewed($update, $user);
        }

        return $this->successResponse(null, 'Marked as viewed.');
    }

    public function dismiss($id)
    {
        $update = SystemUpdate::published()
            ->whereNull('closed_at')
            ->find($id);

        if (!$update) return $this->notFound('Update not found.');

        $user = auth('sanctum')->user();
        if ($user instanceof User) {
            $this->service->dismiss($update, $user);
        }

        return $this->successResponse(null, 'Update dismissed.');
    }

    // ───────────── helpers ─────────────

    private function validateContent(Request $request, bool $partial = false): array
    {
        $req = $partial ? 'sometimes|required' : 'required';

        return $request->validate([
            'title'       => "{$req}|string|min:3|max:255",
            'description' => "{$req}|string|min:3|max:5000",
            'send_push'   => 'sometimes|boolean',
        ]);
    }

    private function publicShape(SystemUpdate $u): array
    {
        return [
            'id'           => $u->id,
            'title'        => $u->title,
            'description'  => $u->description,
            'published_at' => optional($u->published_at)->toIso8601String(),
        ];
    }
}