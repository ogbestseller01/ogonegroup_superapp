<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ConversationUserState extends Model
{
    protected $table = 'conversation_user_states';
    protected $fillable = ['conversation_id', 'user_id', 'is_pinned', 'pinned_at', 'is_archived'];

    protected $casts = ['is_pinned' => 'boolean', 'is_archived' => 'boolean', 'pinned_at' => 'datetime'];
}
