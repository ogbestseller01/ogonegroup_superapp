<?php
// app/Services/ConversationPresenter.php  (NEW)
// Builds the conversation list payload in a fixed number of queries.

namespace App\Services;

use App\Models\ConversationUserState;
use App\Models\Message;
use App\Models\Post;
use App\Models\Technician;
use App\Models\TechnicianPostSeen;
use App\Models\User;
use Illuminate\Support\Collection;

class ConversationPresenter
{
    public static function photoUrl(?string $path): ?string
    {
        return $path ? url('storage/' . ltrim($path, '/')) : null;
    }

    /** @param Collection<int,\App\Models\Conversation> $convs */
    public function present(Collection $convs, User $me): array
    {
        if ($convs->isEmpty()) return [];

        $meId = (int) $me->id;
        $ids  = $convs->pluck('id');

        $lastIds = Message::whereIn('conversation_id', $ids)->visibleTo($meId)
            ->selectRaw('MAX(id) as id')->groupBy('conversation_id')->pluck('id');
        $last = Message::with('sender:id,name')->whereIn('id', $lastIds)->get()->keyBy('conversation_id');

        $unread = Message::whereIn('conversation_id', $ids)
            ->where('receiver_id', $meId)->where('is_read', false)
            ->whereNull('deleted_for_everyone_at')->visibleTo($meId)
            ->selectRaw('conversation_id, COUNT(*) as c')->groupBy('conversation_id')
            ->pluck('c', 'conversation_id');

        $states = ConversationUserState::where('user_id', $meId)->whereIn('conversation_id', $ids)
            ->get()->keyBy('conversation_id');

        $otherId = fn ($c) => (int) $c->customer_id === $meId ? (int) $c->fundi_id : (int) $c->customer_id;
        $otherIds = $convs->map($otherId)->unique()->values();

        $users = User::whereIn('id', $otherIds)->get(['id', 'name', 'email', 'phone', 'profile_photo'])->keyBy('id');
        $techs = Technician::whereIn('user_id', $otherIds)->get(['id', 'user_id', 'profile_photo', 'is_online'])->keyBy('user_id');

        $latestPost = Post::whereIn('technician_id', $techs->pluck('id'))
            ->selectRaw('technician_id, MAX(id) as pid')->groupBy('technician_id')->pluck('pid', 'technician_id');
        $seen = TechnicianPostSeen::where('user_id', $meId)->pluck('last_seen_post_id', 'technician_id');

        $rows = $convs->map(function ($c) use ($meId, $last, $unread, $states, $otherId, $users, $techs, $latestPost, $seen) {
            $isCustomer = (int) $c->customer_id === $meId;
            $oid   = $otherId($c);
            $u     = $users->get($oid);
            $t     = $techs->get($oid);
            $state = $states->get($c->id);

            $hasNew = $t && isset($latestPost[$t->id]) && (int) $latestPost[$t->id] > (int) ($seen[$t->id] ?? 0);

            return [
                'id'              => $c->id,
                'customer_id'     => $c->customer_id,
                'fundi_id'        => $c->fundi_id,
                'user_role'       => $isCustomer ? 'customer' : 'fundi',
                'other_party'     => [
                    'id'            => $oid,
                    'name'          => $u->name ?? 'Unknown User',
                    'email'         => $u->email ?? '',
                    'phone'         => $u->phone ?? null,
                    'profile_photo' => self::photoUrl($t?->profile_photo ?: $u?->profile_photo),
                    'is_online'     => (bool) ($t->is_online ?? false),
                    'technician_id' => $t?->id,
                ],
                'last_message'    => ($m = $last->get($c->id)) ? $m->getFormattedMessage() : null,
                'unread_count'    => (int) ($unread[$c->id] ?? 0),
                'last_message_at' => $c->last_message_at?->toIso8601String(),
                'is_active'       => (bool) $c->is_active,
                'is_pinned'       => (bool) ($state->is_pinned ?? false),
                'is_archived'     => (bool) ($state->is_archived ?? false),
                'pinned_at'       => $state?->pinned_at?->toIso8601String(),
                'has_new_post'    => (bool) $hasNew,
                'technician_id'   => $t?->id,
            ];
        });

        // pinned first (most recently pinned on top), then newest activity
        return $rows->sort(function ($a, $b) {
            if ($a['is_pinned'] !== $b['is_pinned']) return $a['is_pinned'] ? -1 : 1;
            if ($a['is_pinned']) return strcmp((string) $b['pinned_at'], (string) $a['pinned_at']);
            return strcmp((string) $b['last_message_at'], (string) $a['last_message_at']);
        })->values()->all();
    }
}
