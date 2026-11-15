<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TechnicianLocationHistory extends Model
{
    protected $fillable = [
        'technician_id',
        'latitude',
        'longitude',
    ];

    protected $casts = [
        'latitude'  => 'float',
        'longitude' => 'float',
        'created_at'=> 'datetime',
    ];

    // ============================================================
    // RELATIONSHIPS
    // ============================================================

    public function technician()
    {
        return $this->belongsTo(Technician::class);
    }

    // ============================================================
    // SCOPES
    // ============================================================

    /**
     * Scope to get the most recent location for each technician
     */
    public function scopeLatestForEachTechnician($query)
    {
        return $query->whereIn('id', function ($sub) {
            $sub->select(\DB::raw('MAX(id)'))
                ->from('technician_location_history')
                ->groupBy('technician_id');
        });
    }
}