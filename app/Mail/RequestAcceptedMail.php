<?php
namespace App\Mail;

use App\Models\ServiceRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class RequestAcceptedMail extends Mailable
{
    use Queueable, SerializesModels;

    public $request;

    public function __construct(ServiceRequest $request)
    {
        $this->request = $request;
    }

    public function build()
    {
        return $this->subject('Your Request was Accepted')
                    ->view('emails.request_accepted')
                    ->with([
                        'technicianName' => $this->request->technician->user->name,
                        'service'        => $this->request->service->name,
                    ]);
    }
}