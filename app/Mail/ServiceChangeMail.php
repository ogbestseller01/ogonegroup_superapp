<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;

/** Template: resources/views/emails/service-change.blade.php */
class ServiceChangeMail extends Mailable
{
    // "mailSubject" and "content" avoid clashing with Mailable's own properties.
    public function __construct(public string $mailSubject, public array $content)
    {
    }

    public function build()
    {
        return $this->subject($this->mailSubject)
            ->view('emails.service-change')
            ->with(['m' => $this->content]);
    }
}
