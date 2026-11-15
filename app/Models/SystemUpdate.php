<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SystemUpdate extends Model
{
    use SoftDeletes;

    public const STATUS_DRAFT     = 'draft';
    public const STATUS_PUBLISHED = 'published';
    public const STATUS_CLOSED    = 'closed';

    protected $fillable = [
        'title', 'description', 'status', 'created_by',
        'send_push', 'send_sms',
        'published_at', 'closed_at', 'dispatched_at',
    ];

    protected $casts = [
        'send_push'     => 'boolean',
        'send_sms'      => 'boolean',
        'published_at'  => 'datetime',
        'closed_at'     => 'datetime',
        'dispatched_at' => 'datetime',
    ];

    public function scopePublished($q)
    {
        return $q->where('status', self::STATUS_PUBLISHED);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function userStates(): HasMany
    {
        return $this->hasMany(UserSystemUpdate::class);
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(SystemUpdateNotification::class);
    }
}