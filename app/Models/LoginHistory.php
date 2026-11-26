<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LoginHistory extends Model
{
    const UPDATED_AT = null; // table only has created_at

    protected $fillable = [
        'user_id',
        'method',
        'ip_address',
        'device',
        'user_agent',
        'location',
        'email_sent_at',
    ];

    protected $casts = [
        'email_sent_at' => 'datetime',
        'created_at'    => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}