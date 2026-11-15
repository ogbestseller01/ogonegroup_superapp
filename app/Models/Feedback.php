<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Feedback extends Model
{
    use HasFactory, SoftDeletes;

    // "Feedback" is an uncountable word, so Eloquent would guess the table
    // name "feedback". Our table is "feedbacks", so we set it explicitly.
    protected $table = 'feedbacks';

    public const TYPES = ['suggestion', 'bug', 'compliment', 'other'];
    public const STATUSES = ['new', 'reviewed', 'resolved'];

    public const STATUS_NEW = 'new';

    protected $fillable = [
        'name',
        'email',
        'type',
        'rating',
        'message',
        'status',
        'admin_reply',
        'replied_by',
        'replied_at',
        'ip_address',
    ];

    protected $casts = [
        'rating'     => 'integer',
        'replied_at' => 'datetime',
    ];

    public function repliedBy()
    {
        return $this->belongsTo(User::class, 'replied_by');
    }

    // ---------- scopes ----------
    public function scopeStatus($query, ?string $status)
    {
        return $status ? $query->where('status', $status) : $query;
    }

    public function scopeType($query, ?string $type)
    {
        return $type ? $query->where('type', $type) : $query;
    }

    public function scopeSearch($query, ?string $term)
    {
        if (!$term) {
            return $query;
        }

        return $query->where(function ($q) use ($term) {
            $q->where('name', 'like', "%{$term}%")
              ->orWhere('email', 'like', "%{$term}%")
              ->orWhere('message', 'like', "%{$term}%");
        });
    }
}