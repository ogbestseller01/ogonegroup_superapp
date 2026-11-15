<?php

namespace App\Services;

use App\Jobs\DistributeSystemUpdateJob;
use App\Models\SystemUpdate;
use App\Models\User;
use App\Models\UserSystemUpdate;
use DomainException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class SystemUpdateService
{
    /** Create as DRAFT. Never notifies anyone. */
    public function createDraft(array $data, ?int $adminId): SystemUpdate
    {
        return SystemUpdate::create([
            'title'       => $data['title'],
            'description' => $data['description'],
            'send_push'   => $data['send_push'] ?? true,
            'send_sms'    => $data['send_sms'] ?? true,
            'status'      => SystemUpdate::STATUS_DRAFT,
            'created_by'  => $adminId,
        ]);
    }

    /** Edit content only. Never changes status and never sends notifications. */
    public function update(SystemUpdate $update, array $data): SystemUpdate
    {
        $update->fill(collect($data)->only(['title', 'description', 'send_push', 'send_sms'])->all());
        $update->save();

        return $update->fresh();
    }

    /**
     * Publish. Safe to call repeatedly: the row is locked and `dispatched_at`
     * guarantees the distribution job is queued at most once per update.
     */
    public function publish(SystemUpdate $update): SystemUpdate
    {
        $shouldDispatch = false;

        $update = DB::transaction(function () use ($update, &$shouldDispatch) {
            $locked = SystemUpdate::whereKey($update->id)->lockForUpdate()->firstOrFail();

            if ($locked->status === SystemUpdate::STATUS_CLOSED) {
                throw new DomainException('A closed update cannot be published again.');
            }

            if ($locked->status === SystemUpdate::STATUS_DRAFT) {
                $locked->status       = SystemUpdate::STATUS_PUBLISHED;
                $locked->published_at = now();
            }

            if ($locked->dispatched_at === null) {
                $locked->dispatched_at = now();
                $shouldDispatch = true;
            }

            $locked->save();

            return $locked;
        });

        if ($shouldDispatch) {
            DistributeSystemUpdateJob::dispatch($update->id);
        }

        return $update->fresh();
    }

    public function close(SystemUpdate $update): SystemUpdate
    {
        if ($update->status !== SystemUpdate::STATUS_PUBLISHED) {
            throw new DomainException('Only published updates can be closed.');
        }

        $update->update(['status' => SystemUpdate::STATUS_CLOSED, 'closed_at' => now()]);

        return $update->fresh();
    }

    public function delete(SystemUpdate $update): void
    {
        $update->delete(); // soft delete: hidden from admin list and from users
    }

    /** Published updates the user has NOT dismissed (guests see all published). */
    public function activeFor(?User $user, int $limit = 10): Collection
    {
        $q = SystemUpdate::published()->orderByDesc('published_at')->limit($limit);

        if ($user) {
            $q->whereDoesntHave('userStates', fn ($s) => $s
                ->where('user_id', $user->id)
                ->whereNotNull('dismissed_at'));
        }

        return $q->get();
    }

    public function markViewed(SystemUpdate $update, User $user): void
    {
        $state = UserSystemUpdate::firstOrCreate(
            ['system_update_id' => $update->id, 'user_id' => $user->id],
            ['received_at' => now()]
        );

        if (!$state->viewed_at) {
            $state->update(['viewed_at' => now()]);
        }
    }

    public function dismiss(SystemUpdate $update, User $user): void
    {
        $state = UserSystemUpdate::firstOrCreate(
            ['system_update_id' => $update->id, 'user_id' => $user->id],
            ['received_at' => now()]
        );

        if (!$state->dismissed_at) {
            $state->update(['dismissed_at' => now(), 'viewed_at' => $state->viewed_at ?? now()]);
        }
    }
}