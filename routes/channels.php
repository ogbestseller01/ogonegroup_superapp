<?php

use Illuminate\Support\Facades\Broadcast;
use App\Models\Conversation;
use App\Models\Technician;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

// Personal channel — Laravel's automatic model-channel naming convention.
// This is what a `new PrivateChannel($this->receiver)` call (passing a
// User model instance) resolves to on the wire: "private-App.Models.User.5".
// Used for NewMessage / MessageRead events targeted at a specific user.
Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// ✅ ADDED: per-conversation channel — needed for UserTyping broadcasts,
// which are scoped to a conversation rather than a single user. Only the
// two participants (customer or fundi) on that conversation may subscribe.
Broadcast::channel('conversation.{conversationId}', function ($user, $conversationId) {
    $conversation = Conversation::find($conversationId);

    if (!$conversation) {
        return false;
    }

    return (int) $user->id === (int) $conversation->customer_id
        || (int) $user->id === (int) $conversation->fundi_id;
});

Broadcast::channel('presence-technicians', function ($user) {
    if ($user->technician) {
        return [
            'id'   => $user->technician->id,
            'name' => $user->name,
        ];
    }
    return false;
});