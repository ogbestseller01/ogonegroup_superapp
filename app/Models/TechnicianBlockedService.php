<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TechnicianBlockedService extends Model
{
    protected $table = 'technician_blocked_services';

    protected $fillable = ['technician_id', 'service_id', 'change_request_id'];

    /** @return array<int> */
    public static function idsFor(int $technicianId): array
    {
        return static::where('technician_id', $technicianId)
            ->pluck('service_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }
}
