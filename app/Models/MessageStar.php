<?php
// app/Models/MessageStar.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MessageStar extends Model
{
    protected $fillable = ['user_id', 'message_id'];

    public function message() { return $this->belongsTo(Message::class); }
    public function user()    { return $this->belongsTo(User::class); }
}
