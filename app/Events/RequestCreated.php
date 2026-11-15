<?php
namespace App\Events;

use App\Models\ServiceRequest;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

class RequestCreated implements ShouldBroadcastNow
{
    use InteractsWithSockets;

    public $request;

    public function __construct(ServiceRequest $request)
    {
        $this->request = $request;
    }

    public function broadcastOn()
    {
        return new Channel('technician.' . $this->request->technician_id);
    }

    public function broadcastAs()
    {
        return 'request.created';
    }

    public function broadcastWith()
    {
        return [
            'id'          => $this->request->id,
            'customer'    => $this->request->customer->name,
            'description' => $this->request->description,
            'service'     => $this->request->service->name,
        ];
    }
}