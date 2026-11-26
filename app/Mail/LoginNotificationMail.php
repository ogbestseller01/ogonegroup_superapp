<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;

/** "New sign-in" security email. Template: resources/views/emails/login-notification.blade.php */
class LoginNotificationMail extends Mailable
{
    /**
     * @param array{when:string,device:string,ip:string,location:string,method:string} $details
     */
    public function __construct(public string $userName, public array $details)
    {
    }

    public function build()
    {
        return $this->subject('New sign-in to your Nearby Fundi account')
            ->view('emails.login-notification')
            ->with([
                'userName' => $this->userName,
                'details'  => $this->details,
            ]);
    }
}