<?php

namespace App\Http\Controllers\Api;

use App\Models\Technician;
use App\Services\GeocodingService;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * Nearby-fundi search: strict radius + weighted ranking.
 *
 * CORE ranking (always used, same idea as before):
 *   rating, completed jobs (jobs.status = 'completed'), proximity.
 *
 * OPTIONAL bonus (only ADDS points when the fundi has them):
 *   accepted requests, reviews, post likes, post comments.
 *   A fundi with none of these is never penalised and never excluded,
 *   they simply do not get the bonus.
 *
 * Radius is hard-capped at 100 km. Far-away fundis are never returned.
 */
class SearchNearbyFundiController extends BaseApiController
{
    // Tanzania bounding box (sanity check only)
    private const MIN_LAT = -11.9;
    private const MAX_LAT = -0.9;
    private const MIN_LNG = 29.2;
    private const MAX_LNG = 40.6;

    // Radius contract
    private const DEFAULT_RADIUS  = 15;
    private const HARD_MAX_RADIUS = 100;
    private const EXPAND_STEPS    = [15, 25, 50, 75, 100];

    private const DEFAULT_PER_PAGE = 30;
    private const MAX_CANDIDATES   = 400;   // safety cap, nearest kept first
    private const CACHE_TTL        = 45;

    // CORE weights (max 85)
    private const W_RATING    = 35;
    private const W_JOBS      = 25;
    private const W_PROXIMITY = 25;

    // OPTIONAL bonus weights (max 15). Never subtract.
    private const B_REQUESTS = 6;
    private const B_REVIEWS  = 3;
    private const B_LIKES    = 3;
    private const B_COMMENTS = 3;

    // "Full marks" caps for log scaling
    private const CAP_JOBS     = 50;
    private const CAP_REQUESTS = 80;
    private const CAP_REVIEWS  = 40;
    private const CAP_LIKES    = 150;
    private const CAP_COMMENTS = 80;

    private const DISTANCE_SQL = '(6371 * acos(LEAST(1.0, GREATEST(-1.0,
        cos(radians(?)) * cos(radians(technicians.latitude)) *
        cos(radians(technicians.longitude) - radians(?)) +
        sin(radians(?)) * sin(radians(technicians.latitude))
    ))))';

    // GET /v1/technicians/nearby?lat=&lng=
    public function nearby(Request $request)
    {
        $data = $request->validate(array_merge([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ], $this->filterRules()));

        $lat = (float) $data['lat'];
        $lng = (float) $data['lng'];

        if (!$this->insideTanzania($lat, $lng)) {
            return $this->errorResponse(
                'This location is outside Tanzania. Please choose a place in Tanzania.',
                422
            );
        }

        return $this->search($data, $lat, $lng, null);
    }

    // GET /v1/technicians/nearby-by-place?place=
    public function nearbyByPlace(Request $request, GeocodingService $geocoder)
    {
        $data = $request->validate(array_merge([
            'place' => 'required|string|max:255',
        ], $this->filterRules()));

        $coords = $geocoder->geocode($data['place']);
        if (!$coords) {
            return $this->errorResponse(
                "Could not locate '{$data['place']}'. Check the spelling or pick it on the map.",
                422
            );
        }

        if (!$this->insideTanzania($coords['lat'], $coords['lng'])) {
            return $this->errorResponse("'{$data['place']}' is outside Tanzania.", 422);
        }

        return $this->search($data, (float) $coords['lat'], (float) $coords['lng'], $data['place']);
    }

    // Core
    private function search(array $data, float $lat, float $lng, ?string $place)
    {
        $radius     = min((int) ($data['radius'] ?? self::DEFAULT_RADIUS), self::HARD_MAX_RADIUS);
        $perPage    = (int) ($data['per_page'] ?? self::DEFAULT_PER_PAGE);
        $page       = max(1, (int) request()->input('page', 1));
        $autoExpand = filter_var($data['auto_expand'] ?? true, FILTER_VALIDATE_BOOLEAN);
        // Optional bonus signals. On by default, can be switched off with extras=0
        $extras     = filter_var($data['extras'] ?? true, FILTER_VALIDATE_BOOLEAN);

        $filters = [
            'service_id'  => $data['service_id'] ?? null,
            'category_id' => $data['category_id'] ?? null,
            'search'      => $data['search'] ?? null,
        ];
        $hasFilters = !empty(array_filter($filters));

        $cacheKey = 'nearby:v6:' . md5(json_encode([
            round($lat, 4), round($lng, 4), $radius, $perPage, $page,
            $autoExpand, $extras, $filters,
        ]));

        $payload = Cache::remember($cacheKey, self::CACHE_TTL, function () use (
            $lat, $lng, $radius, $perPage, $page, $autoExpand, $extras, $filters
        ) {
            $used   = $radius;
            $ranked = $this->rankedCandidates($lat, $lng, $used, $filters, $extras);

            // Widen step by step, never beyond HARD_MAX_RADIUS
            if ($autoExpand && $ranked->isEmpty()) {
                foreach (self::EXPAND_STEPS as $step) {
                    if ($step <= $radius || $step > self::HARD_MAX_RADIUS) {
                        continue;
                    }
                    $used   = $step;
                    $ranked = $this->rankedCandidates($lat, $lng, $used, $filters, $extras);
                    if ($ranked->isNotEmpty()) {
                        break;
                    }
                }
            }

            $total    = $ranked->count();
            $lastPage = max(1, (int) ceil($total / $perPage));
            $offset   = ($page - 1) * $perPage;

            $items = $ranked->slice($offset, $perPage)->values()
                ->map(fn ($row, $i) => $this->format($row, $offset + $i + 1))
                ->all();

            return [
                'items'        => $items,
                'current_page' => $page,
                'last_page'    => $lastPage,
                'per_page'     => $perPage,
                'total'        => $total,
                'radius_used'  => $used,
            ];
        });

        $message = $payload['total'] > 0
            ? 'Fundis retrieved successfully.'
            : 'No fundis found within ' . self::HARD_MAX_RADIUS . ' km of this location.';

        return $this->successResponse([
            'data' => $payload['items'],
            'meta' => [
                'current_page'  => $payload['current_page'],
                'last_page'     => $payload['last_page'],
                'per_page'      => $payload['per_page'],
                'total'         => $payload['total'],
                'has_filters'   => $hasFilters,
                'max_radius_km' => self::HARD_MAX_RADIUS,
                'sorted_by'     => 'rank_score',
                'extras'        => $extras,
            ],
            'search' => [
                'latitude'         => $lat,
                'longitude'        => $lng,
                'place'            => $place,
                'radius'           => $payload['radius_used'],
                'requested_radius' => $radius,
                'expanded'         => $payload['radius_used'] > $radius,
            ],
            'filters' => $filters,
        ], $message);
    }

    // candidates -> stats -> score -> sort
    private function rankedCandidates(
        float $lat,
        float $lng,
        int $radius,
        array $filters,
        bool $extras
    ): Collection {
        $candidates = $this->candidates($lat, $lng, $radius, $filters);
        if ($candidates->isEmpty()) {
            return collect();
        }

        $ids   = $candidates->pluck('id')->all();
        $stats = $this->loadStats($ids, $extras);

        return $candidates
            ->map(function (Technician $t) use ($stats, $radius, $extras) {
                // CORE
                $t->jobs_completed = (int) ($stats['jobs'][$t->id] ?? 0);

                // OPTIONAL (0 when missing, never an error)
                $t->requests_count = (int) ($stats['requests'][$t->id] ?? 0);
                $t->reviews_count  = (int) ($stats['reviews'][$t->id] ?? 0);
                $t->post_likes     = (int) ($stats['likes'][$t->id] ?? 0);
                $t->post_comments  = (int) ($stats['comments'][$t->id] ?? 0);

                $t->rank_score = $this->score($t, $radius, $extras);
                return $t;
            })
            ->sort(function ($a, $b) {
                // higher score first; closer wins ties
                return [$b->rank_score, $a->distance] <=> [$a->rank_score, $b->distance];
            })
            ->values();
    }

    // Candidates: strict radius, verified + active, filters
    private function candidates(float $lat, float $lng, int $radius, array $filters): Collection
    {
        // Bounding box (cheap, index friendly), then the exact circle
        $padLat = ($radius * 1.05) / 111.0;
        $padLng = ($radius * 1.05) / (111.0 * max(cos(deg2rad($lat)), 0.01));

        $query = Technician::query()
            ->select([
                'technicians.id',
                'technicians.user_id',
                'technicians.profile_photo',
                'technicians.area',
                'technicians.latitude',
                'technicians.longitude',
                'technicians.hourly_rate',
                'technicians.experience',
                'technicians.rating',
                'technicians.verified',
            ])
            ->selectRaw(self::DISTANCE_SQL . ' AS distance', [$lat, $lng, $lat])
            ->where('technicians.verified', true)
            ->whereNotNull('technicians.latitude')
            ->whereNotNull('technicians.longitude')
            ->whereBetween('technicians.latitude',  [$lat - $padLat, $lat + $padLat])
            ->whereBetween('technicians.longitude', [$lng - $padLng, $lng + $padLng])
            ->whereRaw(self::DISTANCE_SQL . ' <= ?', [$lat, $lng, $lat, $radius]) // HARD distance ceiling
            ->whereHas('user', fn ($q) => $q->where('is_active', true));

        if (!empty($filters['service_id'])) {
            $query->whereHas('services', fn ($q) => $q->where('services.id', $filters['service_id']));
        }
        if (!empty($filters['category_id'])) {
            $query->whereHas('services.categories', fn ($q) =>
                $q->where('service_categories.service_categoryID', $filters['category_id'])
            );
        }
        if (!empty($filters['search'])) {
            $term = $filters['search'];
            $query->where(function ($w) use ($term) {
                $w->whereHas('services', function ($q) use ($term) {
                        $q->where('name', 'LIKE', "%{$term}%")
                          ->orWhere('swahili_name', 'LIKE', "%{$term}%");
                    })
                  ->orWhereHas('user', fn ($q) => $q->where('name', 'LIKE', "%{$term}%"))
                  ->orWhere('technicians.area', 'LIKE', "%{$term}%");
            });
        }

        return $query
            ->with(['user:id,name', 'services:id,name'])
            ->orderBy('distance')            // cap keeps the NEAREST ones
            ->limit(self::MAX_CANDIDATES)
            ->get();
    }

    // Stats only for the candidate ids
    private function loadStats(array $ids, bool $extras): array
    {
        // CORE: completed jobs (jobs.status = 'completed' only)
        $jobs = DB::table('jobs')
            ->whereIn('technician_id', $ids)
            ->where('status', 'completed')
            ->selectRaw('technician_id AS tid, COUNT(*) AS c')
            ->groupBy('technician_id')
            ->pluck('c', 'tid');

        $out = [
            'jobs'     => $jobs->all(),
            'requests' => [],
            'reviews'  => [],
            'likes'    => [],
            'comments' => [],
        ];

        // OPTIONAL signals: skipped completely when extras are off
        if (!$extras) {
            return $out;
        }

        $out['requests'] = DB::table('requests')
            ->whereIn('technician_id', $ids)
            ->where('status', 'accepted')
            ->whereNull('deleted_at')
            ->selectRaw('technician_id AS tid, COUNT(*) AS c')
            ->groupBy('technician_id')
            ->pluck('c', 'tid')
            ->all();

        $out['reviews'] = DB::table('reviews')
            ->whereIn('technician_id', $ids)
            ->selectRaw('technician_id AS tid, COUNT(*) AS c')
            ->groupBy('technician_id')
            ->pluck('c', 'tid')
            ->all();

        // FIXED: join using technician_id instead of user_id
        $out['likes'] = DB::table('likes AS l')
            ->join('posts AS p', 'p.id', '=', 'l.post_id')
            ->join('technicians AS t', 't.id', '=', 'p.technician_id')
            ->whereIn('t.id', $ids)
            ->selectRaw('t.id AS tid, COUNT(l.id) AS c')
            ->groupBy('t.id')
            ->pluck('c', 'tid')
            ->all();

        // FIXED: join using technician_id instead of user_id
        $out['comments'] = DB::table('comments AS c')
            ->join('posts AS p', 'p.id', '=', 'c.post_id')
            ->join('technicians AS t', 't.id', '=', 'p.technician_id')
            ->whereIn('t.id', $ids)
            ->selectRaw('t.id AS tid, COUNT(c.id) AS c')
            ->groupBy('t.id')
            ->pluck('c', 'tid')
            ->all();

        return $out;
    }

    // Score (0..100) = CORE (max 85) + OPTIONAL bonus (max 15)
    private function score(Technician $t, int $radius, bool $extras): float
    {
        $norm = fn (int $v, int $cap) => $v <= 0
            ? 0.0
            : min(1.0, log(1 + $v) / log(1 + $cap));

        // CORE: uses the stored rating as-is (no dependence on review count)
        $ratingN   = max(0.0, min(1.0, ((float) $t->rating) / 5.0));
        $proximity = 1.0 - min(1.0, ((float) $t->distance) / max($radius, 1));

        $score =
              self::W_RATING    * $ratingN
            + self::W_JOBS      * $norm($t->jobs_completed, self::CAP_JOBS)
            + self::W_PROXIMITY * $proximity;

        // OPTIONAL: adds only, zero values add nothing
        if ($extras) {
            $score +=
                  self::B_REQUESTS * $norm($t->requests_count, self::CAP_REQUESTS)
                + self::B_REVIEWS  * $norm($t->reviews_count,  self::CAP_REVIEWS)
                + self::B_LIKES    * $norm($t->post_likes,     self::CAP_LIKES)
                + self::B_COMMENTS * $norm($t->post_comments,  self::CAP_COMMENTS);
        }

        return round($score, 2);
    }

    // Formatter (no is_online)
    private function format(Technician $t, int $position): array
    {
        return [
            'id'                   => $t->id,
            'user_id'              => $t->user_id,
            'name'                 => $t->user->name ?? 'Unknown',
            'profile_photo'        => $t->profile_photo ? url('storage/' . ltrim($t->profile_photo, '/')) : null,
            'area'                 => $t->area,
            'latitude'             => $t->latitude !== null ? (float) $t->latitude : null,
            'longitude'            => $t->longitude !== null ? (float) $t->longitude : null,
            'hourly_rate'          => $t->hourly_rate !== null ? (float) $t->hourly_rate : null,
            'experience'           => (int) $t->experience,
            'rating'               => (float) $t->rating,
            'verified'             => (bool) $t->verified,

            // CORE
            'completed_jobs_count' => $t->jobs_completed,

            // OPTIONAL (0 when the fundi has none)
            'requests_count'       => $t->requests_count,
            'reviews_count'        => $t->reviews_count,
            'post_likes'           => $t->post_likes,
            'post_comments'        => $t->post_comments,

            'distance_km'          => round((float) $t->distance, 2),
            'rank_score'           => $t->rank_score,
            'rank_position'        => $position,

            'services'             => $t->services->map(fn ($s) => ['id' => $s->id, 'name' => $s->name])->values(),
        ];
    }

    private function filterRules(): array
    {
        return [
            'radius'      => 'nullable|integer|min:1|max:' . self::HARD_MAX_RADIUS,
            'service_id'  => 'nullable|exists:services,id',
            'category_id' => 'nullable|exists:service_categories,service_categoryID',
            'search'      => 'nullable|string|max:100',
            'per_page'    => 'nullable|integer|min:5|max:50',
            'auto_expand' => 'nullable|boolean',
            'extras'      => 'nullable|boolean',
        ];
    }

    private function insideTanzania(float $lat, float $lng): bool
    {
        return $lat >= self::MIN_LAT && $lat <= self::MAX_LAT
            && $lng >= self::MIN_LNG && $lng <= self::MAX_LNG;
    }
}