<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TechnicianPostSeen extends Model
{
    protected $table = 'technician_post_seen';
    protected $fillable = ['user_id', 'technician_id', 'last_seen_post_id', 'seen_at'];

    protected $casts = ['seen_at' => 'datetime'];
}
