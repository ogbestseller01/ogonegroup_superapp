<?php

namespace App\Events;

use App\Models\Technician;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

class TechnicianStatusChanged implements ShouldBroadcastNow
{
    use InteractsWithSockets;

    public $technician;

    public function __construct(Technician $technician)
    {
        $this->technician = $technician;
    }

    public function broadcastOn()
    {
        return new Channel('technician.' . $this->technician->id);
    }

    public function broadcastAs()
    {
        return 'status.changed';
    }

    public function broadcastWith()
    {
        return [
            'technician_id' => $this->technician->id,
            'is_online'     => $this->technician->is_online,
        ];
    }
}