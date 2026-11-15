<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Review extends Model
{
    protected $fillable = [
        'request_id',
        'job_id',
        'customer_id',
        'technician_id',
        'rating',
        'comment',
    ];

    protected $casts = [
        'rating' => 'float',
    ];

    // ─── Events ───────────────────────────────────────────
    protected static function booted()
    {
        static::saved(function ($review) {
            $review->technician?->recalculateRating();
        });

        static::deleted(function ($review) {
            $review->technician?->recalculateRating();
        });
    }

    // ─── Relationships ────────────────────────────────────
    public function technician(): BelongsTo
    {
        return $this->belongsTo(Technician::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function job(): BelongsTo
    {
        return $this->belongsTo(Job::class, 'job_id');
    }

    public function serviceRequest(): BelongsTo
    {
        return $this->belongsTo(ServiceRequest::class, 'request_id');
    }
}