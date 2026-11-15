<?php
namespace App\Events;

use App\Models\ServiceRequest;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

class RequestStatusUpdated implements ShouldBroadcastNow
{
    use InteractsWithSockets;

    public $request;

    public function __construct(ServiceRequest $request)
    {
        $this->request = $request;
    }

    public function broadcastOn()
    {
        return [
            new Channel('customer.' . $this->request->customer_id),
            new Channel('technician.' . $this->request->technician_id),
        ];
    }

    public function broadcastAs()
    {
        return 'request.status.updated';
    }

    public function broadcastWith()
    {
        return [
            'id'     => $this->request->id,
            'status' => $this->request->status,
        ];
    }
}