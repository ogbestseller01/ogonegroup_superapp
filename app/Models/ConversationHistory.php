<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ConversationHistory extends Model
{
    protected $table = 'conversation_histories';
    protected $fillable = ['conversation_id','customer_id','fundi_id','deleted_by','deleted_by_role','message_count','media_count','first_message_at','last_message_at','conversation_created_at','deleted_at','ip_address','user_agent'];

    protected $casts = ['deleted_at' => 'datetime', 'first_message_at' => 'datetime', 'last_message_at' => 'datetime', 'conversation_created_at' => 'datetime'];
}
