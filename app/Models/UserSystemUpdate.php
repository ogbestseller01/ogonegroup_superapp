<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserSystemUpdate extends Model
{
    protected $fillable = ['system_update_id', 'user_id', 'received_at', 'viewed_at', 'dismissed_at'];

    protected $casts = [
        'received_at'  => 'datetime',
        'viewed_at'    => 'datetime',
        'dismissed_at' => 'datetime',
    ];

    public function systemUpdate() { return $this->belongsTo(SystemUpdate::class); }
    public function user()         { return $this->belongsTo(User::class); }
}