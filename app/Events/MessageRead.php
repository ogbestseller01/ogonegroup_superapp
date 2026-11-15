<?php
// app/Events/MessageRead.php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageRead implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $messageId;
    public $userId;
    public $readAt;

    public function __construct($messageId, $userId)
    {
        $this->messageId = $messageId;
        $this->userId = $userId;
        $this->readAt = now()->toDateTimeString();
    }

    public function broadcastOn()
    {
        return [new PrivateChannel('chat.' . $this->userId)];
    }

    public function broadcastAs()
    {
        return 'message-read';
    }

    public function broadcastWith()
    {
        return [
            'message_id' => $this->messageId,
            'read_at' => $this->readAt,
        ];
    }
}