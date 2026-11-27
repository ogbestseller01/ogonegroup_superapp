<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TechnicianServiceChangeRequest extends Model
{
    public const STATUS_PENDING  = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';

    protected $table = 'technician_service_change_requests';

    protected $fillable = [
        'technician_id',
        'current_service_ids',
        'requested_service_ids',
        'added_service_ids',
        'removed_service_ids',
        'reason',
        'status',
        'reviewed_by',
        'reviewed_at',
        'rejection_reason',
        'admin_notified_at',
    ];

    protected $casts = [
        'current_service_ids'   => 'array',
        'requested_service_ids' => 'array',
        'added_service_ids'     => 'array',
        'removed_service_ids'   => 'array',
        'reviewed_at'           => 'datetime',
        'admin_notified_at'     => 'datetime',
    ];

    public function technician(): BelongsTo
    {
        return $this->belongsTo(Technician::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }
}
