<?php

namespace App\Http\Controllers\Api;

use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class NotificationController extends BaseApiController
{
    use Auditable;

    /**
     * Get notifications for the authenticated user.
     */
    public function index(Request $request)
    {
        $query = $request->user()->notifications();

        if ($request->filled('exclude_type')) {
            $query->excludeType($request->query('exclude_type'));
        }

        if ($request->filled('type')) {
            $query->type($request->query('type'));
        }

        $paginator = $query->latest()->paginate($request->integer('per_page', 20));

        $paginator->getCollection()->transform(function ($notification) {
            return $this->formatNotification($notification);
        });

        return $this->successResponse($paginator, 'Notifications retrieved successfully.');
    }

    /**
     * Get unread count + the real title/body of the latest unread row.
     */
    public function unreadCount(Request $request)
    {
        $query = $request->user()->notifications()->unread();

        if ($request->filled('exclude_type')) {
            $query->excludeType($request->query('exclude_type'));
        }

        $count  = (clone $query)->count();
        $latest = (clone $query)->latest()->first();

        return $this->successResponse([
            'count'  => $count,
            'latest' => $latest ? $this->formatNotification($latest) : null,
        ], 'Unread count retrieved.');
    }

    public function markAsRead(Request $request, $id)
    {
        $notification = $request->user()->notifications()->where('id', $id)->first();

        if (!$notification) {
            return $this->notFound('Notification not found.');
        }

        $notification->markAsRead();

        $this->logAudit(
            'mark_notification_read',
            'notification',
            $id,
            "Notification #{$id} marked as read"
        );

        return $this->successResponse([
            'id'      => (string) $notification->id,
            'is_read' => true,
            'read_at' => $notification->read_at?->toIso8601String()
                ?? now()->toIso8601String(),
        ], 'Notification marked as read.');
    }

    public function markAllAsRead(Request $request)
    {
        $query = $request->user()->notifications()->unread();

        if ($request->filled('exclude_type')) {
            $query->excludeType($request->query('exclude_type'));
        }

        $count = $query->update([
            'is_read' => true,
            'read_at' => now(),
        ]);

        $this->logAudit(
            'mark_all_notifications_read',
            'notification',
            null,
            "All notifications marked as read ({$count} updated)"
        );

        return $this->successResponse(
            ['updated_count' => (int) $count],
            'All notifications marked as read.'
        );
    }

    public function destroy(Request $request, $id)
    {
        $notification = $request->user()->notifications()->where('id', $id)->first();

        if (!$notification) {
            return $this->notFound('Notification not found.');
        }

        $notification->delete();

        $this->logAudit(
            'delete_notification',
            'notification',
            $id,
            "Notification #{$id} deleted"
        );

        return $this->successResponse(null, 'Notification deleted.');
    }

    public function clearAll(Request $request)
    {
        $query = $request->user()->notifications();

        if ($request->filled('exclude_type')) {
            $query->excludeType($request->query('exclude_type'));
        }

        $count = $query->delete();

        $this->logAudit(
            'clear_all_notifications',
            'notification',
            null,
            "All notifications cleared ({$count} deleted)"
        );

        return $this->successResponse(
            ['deleted_count' => (int) $count],
            'All notifications cleared.'
        );
    }

    // ============================================================
    // HELPERS
    // ============================================================

    protected function formatNotification($notification): array
    {
        $dataPayload = $notification->data;

        if (is_string($dataPayload)) {
            $decoded = json_decode($dataPayload, true);
            $dataPayload = json_last_error() === JSON_ERROR_NONE ? $decoded : [];
        }

        if (is_array($dataPayload)) {
            $dataPayload = array_map(
                fn ($value) => is_numeric($value) ? (string) $value : $value,
                $dataPayload
            );
        }

        $title = trim((string) $notification->title);
        $body  = trim((string) $notification->body);

        if (!$this->isValidText($title) || !$this->isValidText($body)) {
            Log::warning('Notification row has invalid title/body', [
                'id'    => $notification->id,
                'type'  => $notification->type,
                'title' => $title,
                'body'  => $body,
            ]);
        }

        return [
            'id'         => (string) $notification->id,
            'user_id'    => (string) $notification->user_id,
            'title'      => $title,
            'body'       => $body,
            'type'       => (string) ($notification->type ?? 'general'),
            'data'       => $dataPayload ?? [],
            'is_read'    => (bool) $notification->is_read,
            'read_at'    => $notification->read_at?->toIso8601String(),
            'created_at' => $notification->created_at?->toIso8601String(),
            'updated_at' => $notification->updated_at?->toIso8601String(),
        ];
    }

    protected function isValidText(string $value): bool
    {
        return $value !== '' && !is_numeric($value);
    }
}