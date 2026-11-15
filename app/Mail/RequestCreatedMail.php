<?php
namespace App\Mail;

use App\Models\ServiceRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class RequestCreatedMail extends Mailable
{
    use Queueable, SerializesModels;

    public $request;

    public function __construct(ServiceRequest $request)
    {
        $this->request = $request;
    }

    public function build()
    {
        return $this->subject('New Service Request')
                    ->view('emails.request_created')
                    ->with([
                        'customerName' => $this->request->customer->name,
                        'service'      => $this->request->service->name,
                        'description'  => $this->request->description,
                        'requestId'    => $this->request->id,
                    ]);
    }
}