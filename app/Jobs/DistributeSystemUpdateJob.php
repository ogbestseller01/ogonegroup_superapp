<?php

namespace App\Jobs;

use App\Models\SystemUpdate;
use App\Models\User;
use App\Models\UserSystemUpdate;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class DistributeSystemUpdateJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public function __construct(public int $updateId) {}

    public function handle(): void
    {
        $update = SystemUpdate::find($this->updateId);

        if (!$update || $update->status !== SystemUpdate::STATUS_PUBLISHED) {
            return; // drafts, closed or deleted updates never notify
        }

        User::query()
            ->where('is_active', true)
            ->where('status', 'active')
            ->chunkById(500, function ($users) use ($update) {
                $now = now();

                // "Database: update received". Existing rows keep their received_at.
                UserSystemUpdate::upsert(
                    $users->map(fn ($u) => [
                        'system_update_id' => $update->id,
                        'user_id'          => $u->id,
                        'received_at'      => $now,
                        'created_at'       => $now,
                        'updated_at'       => $now,
                    ])->all(),
                    ['system_update_id', 'user_id'],
                    ['updated_at']
                );

                DeliverSystemUpdateChunkJob::dispatch($update->id, $users->pluck('id')->all());
            });
    }
}