<?php
// app/Models/MessagePin.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MessagePin extends Model
{
    protected $fillable = ['conversation_id', 'message_id', 'pinned_by'];

    public function message()      { return $this->belongsTo(Message::class); }
    public function conversation() { return $this->belongsTo(Conversation::class); }
}
