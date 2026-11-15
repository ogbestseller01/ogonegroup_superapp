<?php
// app/Mail/PasswordResetOtpMail.php

namespace App\Mail;

use App\Models\User;
use App\Models\Otp;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class PasswordResetOtpMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public User $user,
        public Otp $otp
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Reset Your Fundi App Password',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.password-reset-otp',
            with: [
                'user' => $this->user,
                'otp' => $this->otp->otp,
                'expiresIn' => $this->otp->expires_at 
                    ? max(1, (int) now()->diffInMinutes($this->otp->expires_at))
                    : 10,
            ],
        );
    }
}