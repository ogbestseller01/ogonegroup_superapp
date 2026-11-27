<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

// Deliberately NOT ShouldQueue: the OTP must go out immediately.
class RegistrationOtpMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $name,
        public string $code,
        public int $expiresInMinutes = 10,
    ) {
    }

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Your verification code / Namba yako ya uthibitisho');
    }

    public function content(): Content
    {
        return new Content(view: 'emails.registration-otp');
    }
}
