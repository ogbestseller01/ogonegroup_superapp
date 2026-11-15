<?php
// app/Http/Controllers/Api/ChatExtrasController.php

namespace App\Http\Controllers\Api;

use App\Models\Conversation;
use App\Models\ConversationUserState;
use App\Models\Message;
use App\Models\MessagePin;
use App\Models\MessageReaction;
use App\Models\MessageStar;
use App\Models\MessageDeletion;
use App\Models\Post;
use App\Models\Technician;
use App\Models\TechnicianPostSeen;
use App\Models\User;
use App\Models\UserE2eeKey;
use App\Services\ConversationPresenter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ChatExtrasController extends BaseApiController
{
    private const EVERYONE_WINDOW_HOURS = 48;
    private const MAX_PINNED_CHATS      = 3;

    // ── helpers ─────────────────────────────────────────────
    private function conversationFor(Request $r, $id): ?Conversation
    {
        $c = Conversation::find($id);
        return ($c && in_array((int) $r->user()->id, [(int) $c->customer_id, (int) $c->fundi_id], true)) ? $c : null;
    }

    private function dropFile(?string $path): void
    {
        if (!$path || str_contains($path, '..')) return;
        foreach (['local', 'public'] as $disk) {
            if (Storage::disk($disk)->exists($path)) Storage::disk($disk)->delete($path);
        }
    }

    // ============================================================
    // 1. DELETE  (scope = me | everyone) — single or bulk
    // POST /v14/chat/messages/delete {message_ids:[], scope}
    // ============================================================
    public function deleteMessages(Request $request)
    {
        $v = Validator::make($request->all(), [
            'message_ids'   => 'required|array|min:1|max:100',
            'message_ids.*' => 'integer',
            'scope'         => 'required|in:me,everyone',
        ]);
        if ($v->fails()) return $this->errorResponse($v->errors()->first(), 422);

        $user     = $request->user();
        $everyone = $request->scope === 'everyone';
        $deleted  = [];
        $skipped  = [];

        $messages = Message::with('conversation')->whereIn('id', $request->message_ids)->get();

        DB::transaction(function () use ($messages, $user, $everyone, &$deleted, &$skipped, $request) {
            foreach ($messages as $m) {
                $c = $m->conversation;
                $isParticipant = $c && in_array((int) $user->id, [(int) $c->customer_id, (int) $c->fundi_id], true);
                if (!$isParticipant) { $skipped[] = $m->id; continue; }

                if (!$everyone) {
                    MessageDeletion::firstOrCreate(['message_id' => $m->id, 'user_id' => $user->id]);
                    MessagePin::where('message_id', $m->id)->delete(); // a hidden message cannot stay pinned
                    $deleted[] = $m->id;
                    continue;
                }

                $tooOld = $m->created_at && $m->created_at->lt(now()->subHours(self::EVERYONE_WINDOW_HOURS));
                if ((int) $m->sender_id !== (int) $user->id || $m->is_deleted || $tooOld) {
                    $skipped[] = $m->id;
                    continue;
                }

                $this->dropFile($m->file_path);
                MessagePin::where('message_id', $m->id)->delete();
                MessageStar::where('message_id', $m->id)->delete();
                MessageReaction::where('message_id', $m->id)->delete();

                $m->forceFill([
                    'content' => null, 'file_path' => null, 'file_name' => null, 'file_size' => null,
                    'file_mime_type' => null, 'file_extension' => null, 'has_link' => false,
                    'deleted_for_everyone_at' => now(), 'deleted_by' => $user->id,
                    'meta_updated_at' => now(),   // makes the other phone pick it up through "updates"
                ])->save();
                $deleted[] = $m->id;
            }
        });

        return $this->successResponse([
            'deleted' => $deleted, 'skipped' => $skipped,
            'scope' => $request->scope, 'window_hours' => self::EVERYONE_WINDOW_HOURS,
        ], count($deleted) ? 'Deleted.' : 'Nothing was deleted.');
    }

    // ============================================================
    // 2. CHAT STATE (pin chat / archive)
    // POST /v14/chat/conversations/{id}/state {pinned?, archived?}
    // ============================================================
    public function conversationState(Request $request, $id)
    {
        $v = Validator::make($request->all(), ['pinned' => 'sometimes|boolean', 'archived' => 'sometimes|boolean']);
        if ($v->fails()) return $this->errorResponse($v->errors()->first(), 422);

        $c = $this->conversationFor($request, $id);
        if (!$c) return $this->forbidden('Unauthorized.');

        $uid   = $request->user()->id;
        $state = ConversationUserState::firstOrNew(['conversation_id' => $c->id, 'user_id' => $uid]);

        if ($request->has('pinned')) {
            $want = $request->boolean('pinned');
            if ($want && !$state->is_pinned &&
                ConversationUserState::where('user_id', $uid)->where('is_pinned', true)->count() >= self::MAX_PINNED_CHATS) {
                return $this->errorResponse('You can pin up to ' . self::MAX_PINNED_CHATS . ' chats.', 422);
            }
            $state->is_pinned = $want;
            $state->pinned_at = $want ? now() : null;
            if ($want) $state->is_archived = false;
        }
        if ($request->has('archived')) {
            $state->is_archived = $request->boolean('archived');
            if ($state->is_archived) { $state->is_pinned = false; $state->pinned_at = null; }
        }
        $state->save();

        return $this->successResponse([
            'conversation_id' => $c->id, 'is_pinned' => (bool) $state->is_pinned, 'is_archived' => (bool) $state->is_archived,
        ], 'Saved.');
    }

    // ============================================================
    // 3. MEDIA / DOCS / LINKS
    // GET /v14/chat/conversations/{id}/media?tab=media|docs|links&before_id=&limit=
    // ============================================================
    public function media(Request $request, $id)
    {
        $c = $this->conversationFor($request, $id);
        if (!$c) return $this->forbidden('Unauthorized.');

        $tab   = $request->input('tab', 'media');
        $limit = max(1, min((int) $request->input('limit', 40), 100));

        $q = Message::with('sender:id,name')
            ->where('conversation_id', $c->id)
            ->whereNull('deleted_for_everyone_at')
            ->visibleTo($request->user()->id);

        match ($tab) {
            'docs'  => $q->where('message_type', Message::TYPE_FILE),
            'links' => $q->where('has_link', true),
            default => $q->whereIn('message_type', [Message::TYPE_IMAGE, Message::TYPE_VIDEO]),
        };
        if ($request->filled('before_id')) $q->where('id', '<', (int) $request->before_id);

        $rows = $q->orderByDesc('id')->limit($limit + 1)->get();

        return $this->successResponse([
            'tab'      => $tab,
            'has_more' => $rows->count() > $limit,
            'messages' => $rows->take($limit)->map(fn ($m) => $m->getFormattedMessage())->values(),
        ], 'Media retrieved.');
    }

    // ============================================================
    // 4. UPDATES TAB + DP STATUS RING
    // GET  /v14/chat/updates
    // POST /v14/chat/status/{technicianId}/seen
    // ============================================================
    public function updates(Request $request)
    {
        $me = $request->user();

        $otherIds = Conversation::forUser($me->id)->get(['customer_id', 'fundi_id'])
            ->flatMap(fn ($c) => [(int) $c->customer_id, (int) $c->fundi_id])
            ->reject(fn ($id) => $id === (int) $me->id)->unique()->values();

        $techs = Technician::with('user:id,name,profile_photo')
            ->where(fn ($q) => $q->whereIn('user_id', $otherIds)->orWhere('user_id', $me->id))
            ->get()->keyBy('id');

        if ($techs->isEmpty()) return $this->successResponse([], 'No updates.');

        $posts = Post::whereIn('technician_id', $techs->keys())
            ->where('created_at', '>=', now()->subDays(30))
            ->orderByDesc('id')->get()->groupBy('technician_id');

        $seen = TechnicianPostSeen::where('user_id', $me->id)->pluck('last_seen_post_id', 'technician_id');

        $out = $techs->map(function ($t) use ($posts, $seen) {
            $list = $posts->get($t->id);
            if (!$list || $list->isEmpty()) return null;
            $latest = $list->first();
            $thumb  = collect($latest->image_urls)->filter()->first();
            return [
                'technician_id'  => $t->id,
                'user_id'        => $t->user_id,
                'name'           => $t->user->name ?? 'Fundi',
                'profile_photo'  => ConversationPresenter::photoUrl($t->profile_photo ?: $t->user?->profile_photo),
                'posts_count'    => $list->count(),
                'new_count'      => $list->where('id', '>', (int) ($seen[$t->id] ?? 0))->count(),
                'latest_post_id' => $latest->id,
                'latest_at'      => $latest->created_at?->toIso8601String(),
                'thumb'          => $thumb,
                'has_video'      => !empty($latest->video),
                'has_new'        => (int) $latest->id > (int) ($seen[$t->id] ?? 0),
            ];
        })->filter()->sortByDesc('latest_post_id')->values();

        return $this->successResponse($out, 'Updates retrieved.');
    }

    public function markStatusSeen(Request $request, $technicianId)
    {
        $latest = (int) Post::where('technician_id', (int) $technicianId)->max('id');
        TechnicianPostSeen::updateOrCreate(
            ['user_id' => $request->user()->id, 'technician_id' => (int) $technicianId],
            ['last_seen_post_id' => $latest, 'seen_at' => now()]
        );
        return $this->successResponse(['technician_id' => (int) $technicianId, 'last_seen_post_id' => $latest], 'ok');
    }

    // ============================================================
    // 5. CUSTOMER PROFILE PICTURE (fundis keep using technicians.profile_photo)
    // POST /v14/chat/me/avatar  (multipart: photo)
    // ============================================================
    public function uploadAvatar(Request $request)
    {
        $request->validate(['photo' => 'required|image|mimes:jpg,jpeg,png,webp|max:2048']);
        $user = $request->user();

        if ($user->profile_photo && Storage::disk('public')->exists($user->profile_photo)) {
            Storage::disk('public')->delete($user->profile_photo);
        }
        $path = $request->file('photo')->store('avatars', 'public');
        $user->forceFill(['profile_photo' => $path])->save();

        return $this->successResponse(['profile_photo' => ConversationPresenter::photoUrl($path)], 'Photo updated.');
    }

    // ============================================================
    // 6. E2EE PUBLIC KEYS
    // POST /v14/chat/e2ee/key        {identity_key}
    // GET  /v14/chat/e2ee/key/{userId}
    // ============================================================
    public function publishKey(Request $request)
    {
        $data = $request->validate(['identity_key' => ['required', 'string', 'max:128', 'regex:/^[A-Za-z0-9+\/=_-]{40,128}$/']]);
        $k = UserE2eeKey::updateOrCreate(['user_id' => $request->user()->id], ['identity_key' => $data['identity_key'], 'key_version' => 1]);
        return $this->successResponse(['key_version' => $k->key_version], 'Key saved.');
    }

    public function fetchKey(Request $request, $userId)
    {
        $me = (int) $request->user()->id;
        $shareChat = Conversation::where(fn ($q) => $q->where('customer_id', $me)->where('fundi_id', (int) $userId))
            ->orWhere(fn ($q) => $q->where('fundi_id', $me)->where('customer_id', (int) $userId))->exists();
        if (!$shareChat) return $this->forbidden('Unauthorized.');

        $k = UserE2eeKey::where('user_id', (int) $userId)->first();
        if (!$k) return $this->notFound('This user has not enabled secure chat yet.');

        return $this->successResponse(['user_id' => (int) $userId, 'identity_key' => $k->identity_key, 'key_version' => $k->key_version]);
    }
}