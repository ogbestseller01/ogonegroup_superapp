<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemUpdateNotification extends Model
{
    protected $fillable = [
        'system_update_id', 'user_id', 'channel', 'status', 'attempts',
        'provider_message_id', 'error_message', 'sent_at', 'last_attempt_at',
    ];

    protected $casts = [
        'sent_at'         => 'datetime',
        'last_attempt_at' => 'datetime',
    ];

    public function systemUpdate() { return $this->belongsTo(SystemUpdate::class); }
    public function user()         { return $this->belongsTo(User::class); }
}