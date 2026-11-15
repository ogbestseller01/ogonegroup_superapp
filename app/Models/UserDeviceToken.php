<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserDeviceToken extends Model
{
    public const APP_SUPER  = 'og_one_super';
    public const APP_FUNDI  = 'fundi';
    public const APP_NEARBY = 'nearby';

    protected $fillable = [
        'user_id',
        'token',
        'platform',
        'app',
        'device_id',
        'user_agent',
        'last_seen_at',
    ];

    protected $casts = [
        'last_seen_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}