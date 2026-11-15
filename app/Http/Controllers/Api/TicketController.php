<?php
// app/Http/Controllers/Api/TicketController.php

namespace App\Http\Controllers\Api;

use App\Models\Ticket;
use Illuminate\Http\Request;

/**
 * Read-only ticket listing for the logged-in FUNDI (their jobs' tickets)
 * or CUSTOMER (tickets of their own jobs).
 *
 * Query params on index():
 *   ?status=completed
 *   ?search=capacitor
 *   ?sort=created_at|completed_at|status|title|ticket_number
 *   ?order=asc|desc
 *   ?limit=1..200   (default 50)
 */
class TicketController extends BaseApiController
{
    private const WITH = ['job.request.service', 'job.customer'];

    private const DEFAULT_LIMIT = 50;
    private const MAX_LIMIT     = 200;

    public function index(Request $request)
    {
        $user  = $request->user();
        $query = Ticket::with(self::WITH);

        // ── Role scoping ─────────────────────────────────
        if ($user->hasRole('CUSTOMER')) {
            $query->whereHas('job', fn ($q) => $q->where('customer_id', $user->id));
        } elseif ($user->hasRole('FUNDI') && $user->technician) {
            $query->whereHas('job', fn ($q) => $q->where('technician_id', $user->technician->id));
        } else {
            return $this->forbidden('You are not allowed to view tickets.');
        }

        // ── Status filter ────────────────────────────────
        if ($request->filled('status')
            && in_array($request->status, Ticket::STATUSES, true)) {
            $query->where('status', $request->status);
        }

        // ── Search (title, ticket_number, description) ───
        if ($request->filled('search')) {
            $term = '%' . $request->string('search')->trim() . '%';
            $query->where(function ($q) use ($term) {
                $q->where('ticket_number', 'like', $term)
                  ->orWhere('title', 'like', $term)
                  ->orWhere('description', 'like', $term);
            });
        }

        // ── Sort (whitelisted) ───────────────────────────
        $sort  = in_array($request->sort, Ticket::SORTABLE, true)
            ? $request->sort
            : 'created_at';
        $order = strtolower((string) $request->order) === 'asc' ? 'asc' : 'desc';
        $query->orderBy($sort, $order);

        // ── Limit (clamped) ──────────────────────────────
        $limit = (int) $request->integer('limit', self::DEFAULT_LIMIT);
        $limit = max(1, min($limit, self::MAX_LIMIT));

        return $this->successResponse(
            $query->limit($limit)->get()->map(fn (Ticket $t) => $this->format($t)),
            'Tickets retrieved successfully'
        );
    }

    public function show(Request $request, $id)
    {
        $user   = $request->user();
        $ticket = Ticket::with(self::WITH)->find($id);

        if (!$ticket || !$ticket->job) {
            return $this->notFound('Ticket not found.');
        }

        $job        = $ticket->job;
        $isCustomer = (int) $job->customer_id === (int) $user->id;
        $isFundi    = $user->hasRole('FUNDI') && $user->technician
            && (int) $user->technician->id === (int) $job->technician_id;

        if (!$isCustomer && !$isFundi) {
            return $this->notFound('Ticket not found.');
        }

        return $this->successResponse($this->format($ticket));
    }

    /**
     * `created_at` is intentionally NOT exposed — the ticket UI no longer
     * shows it. Use `?sort=created_at` if you need server-side ordering.
     */
    private function format(Ticket $t): array
    {
        $job     = $t->job;
        $service = $job?->request?->service;

        return [
            'id'            => $t->id,
            'ticket_number' => $t->ticket_number,
            'status'        => $t->status,
            'title'         => $t->title,
            'description'   => $t->description,
            'completed_at'  => $t->completed_at,
            'job'           => $job ? [
                'id'         => $job->id,
                'job_number' => $job->job_number,
                'status'     => $job->status,
            ] : null,
            'customer'      => $job?->customer
                ? ['id' => $job->customer->id, 'name' => $job->customer->name]
                : null,
            'service'       => $service
                ? ['id' => $service->id, 'name' => $service->name]
                : null,
        ];
    }
}