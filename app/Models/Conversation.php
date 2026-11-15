<?php
// app/Models/Conversation.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Conversation extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'fundi_id',
        'last_message_at',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'last_message_at' => 'datetime',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function fundi()
    {
        return $this->belongsTo(User::class, 'fundi_id');
    }

    public function messages()
    {
        return $this->hasMany(Message::class)->orderBy('created_at', 'asc');
    }

    public function lastMessage()
    {
        return $this->hasOne(Message::class)->latest();
    }

    public function unreadMessages()
    {
        return $this->hasMany(Message::class)->where('is_read', false);
    }

    public function getOtherUser($userId)
    {
        if ($this->customer_id == $userId) {
            return $this->fundi;
        }
        if ($this->fundi_id == $userId) {
            return $this->customer;
        }
        return null;
    }

    public function getUserRole($userId)
    {
        if ($this->customer_id == $userId) {
            return 'customer';
        }
        if ($this->fundi_id == $userId) {
            return 'fundi';
        }
        return null;
    }

    public function getUnreadCountForUser($userId)
    {
        return Message::where('conversation_id', $this->id)
            ->where('receiver_id', $userId)
            ->where('is_read', false)
            ->count();
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where(function($q) use ($userId) {
            $q->where('customer_id', $userId)
              ->orWhere('fundi_id', $userId);
        });
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}