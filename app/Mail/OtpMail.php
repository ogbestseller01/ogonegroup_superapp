<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class OtpMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $otp;
    public string $email;
    public string $name;
    public string $type;
    public ?string $url;
    public ?string $resetUrl;

    public function __construct(
        string $otp,
        string $email,
        string $name,
        string $type,
        ?string $url = null
    ) {
        $this->otp = $otp;
        $this->email = $email;
        $this->name = $name;
        $this->type = $type;
        $this->url = $url;

        if ($type === 'password_reset') {
            $this->resetUrl = config('app.frontend_url') . '/reset-password?email=' . urlencode($email);
        }
    }

    public function build()
    {
        $subject = $this->type === 'email_verification'
            ? 'Verify Your Email - NearbyFundi'
            : 'Password Reset OTP - NearbyFundi';

        return $this->subject($subject)->view('emails.otp');
    }
}