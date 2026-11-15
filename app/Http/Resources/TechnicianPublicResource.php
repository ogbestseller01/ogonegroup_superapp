<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class TechnicianPublicResource extends JsonResource
{
    public function toArray($request): array
    {
        $profile = $this->profile_photo
            ? url('storage/' . ltrim($this->profile_photo, '/'))
            : null;

        return [
            'id'            => $this->id,
            'user_id'       => $this->user_id,
            'name'          => $this->user?->name ?? 'Unknown',
            'profile_photo' => $profile,
            'bio'           => $this->bio,
            'experience'    => (int) ($this->experience ?? 0),
            'rating'        => (float) ($this->rating ?? 0),
            'hourly_rate'   => $this->hourly_rate !== null
                ? (float) $this->hourly_rate : null,
            'area'          => $this->area,
            'latitude'      => $this->latitude,
            'longitude'     => $this->longitude,
            'is_online'     => (bool) $this->is_online,
            'verified'      => (bool) $this->verified,

            'completed_jobs_count' => (int) ($this->completed_jobs_count ?? 0),

            'services' => $this->services->map(fn ($s) => [
                'id'   => $s->id,
                'name' => $s->name,
            ])->values(),

            'portfolios' => $this->portfolios->map(fn ($p) => [
                'id'          => $p->id,
                'image_count' => $p->images->count(),
                'created_at'  => $p->created_at?->toIso8601String(),
                'images'      => $p->images
                    ->filter(fn ($i) => !empty($i->image))
                    ->map(fn ($i) => [
                        'id'  => $i->id,
                        'url' => url('storage/' . ltrim($i->image, '/')),
                    ])->values(),
            ])->values(),

            // ❌ NO email, NO phone, NO nida, NO next_of_kin_*, NO social_links
        ];
    }
}