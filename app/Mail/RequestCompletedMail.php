<?php
// app/Mail/RequestCompletedMail.php

namespace App\Mail;

use App\Models\ServiceRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class RequestCompletedMail extends Mailable
{
    use Queueable, SerializesModels;

    public ServiceRequest $request;

    public function __construct(ServiceRequest $request)
    {
        $this->request = $request;
    }

    public function build()
    {
        return $this->subject('Request Completed - Nearby Fundi')
                    ->view('emails.request-completed')
                    ->with([
                        'request' => $this->request,
                        'customerName' => $this->request->customer->name,
                        'technicianName' => $this->request->technician->user->name,
                        'serviceName' => $this->request->service->name,
                    ]);
    }
}