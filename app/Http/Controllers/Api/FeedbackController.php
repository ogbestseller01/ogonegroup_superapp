<?php

namespace App\Http\Controllers\Api;

use App\Models\Feedback;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FeedbackController extends BaseApiController
{
    use Auditable;

    // =========================================================
    // PUBLIC (mobile app) — SEND ONLY
    // POST /api/v23/feedback
    // No login needed: the sender just enters name, email, etc.
    // =========================================================
    public function store(Request $request)
    {
        $data = $request->validate([
            'name'    => 'required|string|max:120',
            'email'   => 'required|email|max:190',
            'type'    => ['required', Rule::in(Feedback::TYPES)],
            'rating'  => 'nullable|integer|min:1|max:5',
            'message' => 'required|string|min:5|max:5000',
        ]);

        $feedback = Feedback::create([
            'name'       => $data['name'],
            'email'      => $data['email'],
            'type'       => $data['type'],
            'rating'     => $data['rating'] ?? null,
            'message'    => $data['message'],
            'status'     => Feedback::STATUS_NEW,
            'ip_address' => $request->ip(),
        ]);

        return $this->successResponse(
            ['id' => $feedback->id],
            'Thank you! Your feedback has been sent.'
        );
    }

    // =========================================================
    // ADMIN — INDEX
    // GET /api/v23/admin/feedback
    // ?status=new|reviewed|resolved &type= &rating= &search= &per_page=
    // =========================================================
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->query('per_page', 15), 1), 100);

        $feedbacks = Feedback::query()
            ->status($request->query('status'))
            ->type($request->query('type'))
            ->when($request->filled('rating'), fn ($q) => $q->where('rating', (int) $request->query('rating')))
            ->search($request->query('search'))
            ->latest()
            ->paginate($perPage);

        return $this->successResponse($feedbacks, 'Feedback retrieved successfully.');
    }

    // =========================================================
    // ADMIN — STATS
    // GET /api/v23/admin/feedback/stats
    // =========================================================
    public function stats()
    {
        $byStatus = Feedback::selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        $byType = Feedback::selectRaw('type, COUNT(*) as total')
            ->groupBy('type')
            ->pluck('total', 'type');

        return $this->successResponse([
            'total'          => Feedback::count(),
            'average_rating' => round((float) Feedback::whereNotNull('rating')->avg('rating'), 2),
            'by_status'      => $byStatus,
            'by_type'        => $byType,
        ], 'Feedback stats retrieved successfully.');
    }

    // =========================================================
    // ADMIN — SHOW
    // GET /api/v23/admin/feedback/{id}
    // =========================================================
    public function show($id)
    {
        $feedback = Feedback::with('repliedBy:id,name')->findOrFail($id);

        return $this->successResponse($feedback, 'Feedback retrieved successfully.');
    }

    // =========================================================
    // ADMIN — EDIT (status and/or reply)
    // PUT /api/v23/admin/feedback/{id}
    // =========================================================
    public function update(Request $request, $id)
    {
        $feedback = Feedback::findOrFail($id);

        $data = $request->validate([
            'status'      => ['sometimes', 'required', Rule::in(Feedback::STATUSES)],
            'admin_reply' => 'sometimes|nullable|string|max:5000',
        ]);

        if (array_key_exists('admin_reply', $data)) {
            $reply = trim((string) $data['admin_reply']);
            $data['admin_reply'] = $reply !== '' ? $reply : null;

            if ($data['admin_reply'] !== $feedback->admin_reply) {
                $data['replied_by'] = $request->user()->id;
                $data['replied_at'] = $data['admin_reply'] ? now() : null;
            }
        }

        $feedback->update($data);

        $this->logAudit(
            'update_feedback',
            'feedback',
            $feedback->id,
            "User {$request->user()->id} updated feedback {$feedback->id}"
        );

        return $this->successResponse(
            $feedback->fresh('repliedBy:id,name'),
            'Feedback updated successfully.'
        );
    }

    // =========================================================
    // ADMIN — DELETE (soft delete)
    // DELETE /api/v23/admin/feedback/{id}
    // =========================================================
    public function destroy(Request $request, $id)
    {
        $feedback = Feedback::findOrFail($id);
        $feedback->delete();

        $this->logAudit(
            'delete_feedback',
            'feedback',
            $feedback->id,
            "User {$request->user()->id} deleted feedback {$feedback->id}"
        );

        return $this->successResponse(null, 'Feedback deleted successfully.');
    }
}