<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SmsLog extends Model
{
    
    protected $table = 'sms_logs';

    protected $fillable = [
        'user_id',
        'recipient',
        'message',
        'status',
        'message_id',
        'response_data',
        'error_message',
    ];

    protected $casts = [
        'response_data' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ============================================================
    // RELATIONSHIPS
    // ============================================================

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // ============================================================
    // SCOPES
    // ============================================================

    public function scopeSent($query)
    {
        return $query->where('status', 'sent');
    }

    public function scopeFailed($query)
    {
        return $query->where('status', 'failed');
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeWithRecipient($query, $recipient)
    {
        return $query->where('recipient', 'LIKE', "%{$recipient}%");
    }

    // ============================================================
    // ACCESSORS
    // ============================================================

    public function getStatusLabelAttribute()
    {
        $labels = [
            'sent' => 'Sent',
            'failed' => 'Failed',
            'pending' => 'Pending',
            'queued' => 'Queued',
        ];
        return $labels[$this->status] ?? ucfirst($this->status);
    }

    public function getIsSuccessfulAttribute()
    {
        return $this->status === 'sent';
    }

    public function getIsFailedAttribute()
    {
        return $this->status === 'failed';
    }

    public function getMessagePreviewAttribute()
    {
        if (strlen($this->message) <= 50) {
            return $this->message;
        }
        return substr($this->message, 0, 50) . '...';
    }
}