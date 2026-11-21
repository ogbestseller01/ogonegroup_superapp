<?php

namespace App\Services;

use App\Models\Otp;
use App\Models\SmsLog;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

/**
 * Delivers an OTP over SMS and/or email.
 *
 * Rules:
 *   • Phone present  → SMS first.
 *   • SMS fails and email present → email fallback.
 *   • No phone, email present → email.
 *   • Nothing available → returns success=false (never throws).
 *
 * Never calls a missing method. Never throws.
 */
class OtpDeliveryService
{
    public function __construct(protected RafikiSmsService $smsService)
    {
    }

    /**
     * @return array{
     *   success: bool,
     *   channel: 'sms'|'email'|'failed',
     *   otp_channel: 'sms'|'email'|'failed',
     *   otp_sent_to: ?string,
     *   sms_sent: bool,
     *   email_sent: bool,
     *   message: string
     * }
     */
    public function deliver(User $user, Otp $otp, ?string $verificationUrl = null): array
    {
        $smsSent   = false;
        $emailSent = false;

        // ── 1) Try SMS first when a phone exists ────────────────
        if (!empty($user->phone)) {
            $smsError = $this->trySms($user, $otp);

            if ($smsError === null) {
                $smsSent = true;
            } else {
                Log::warning('OTP SMS delivery failed, will try email fallback', [
                    'user_id' => $user->id,
                    'phone'   => $user->phone,
                    'error'   => $smsError,
                ]);
            }
        }

        // ── 2) Email if SMS did not go out (or no phone) ────────
        if (!$smsSent && !empty($user->email)) {
            $emailSent = $this->tryEmail($user, $otp, $verificationUrl);
        }

        // ── 3) Optional: also email as a backup when both channels exist ──
        if ($smsSent && !empty($user->email)) {
            $this->tryEmail($user, $otp, $verificationUrl);
            $emailSent = true; // secondary, doesn't override channel
        }

        // ── 4) Build result ─────────────────────────────────────
        if ($smsSent) {
            return [
                'success'     => true,
                'channel'     => 'sms',
                'otp_channel' => 'sms',
                'otp_sent_to' => $user->phone,
                'sms_sent'    => true,
                'email_sent'  => $emailSent,
                'message'     => $emailSent
                    ? 'A verification code has been sent to your phone and email.'
                    : "A verification code has been sent via SMS to {$user->phone}.",
            ];
        }

        if ($emailSent) {
            return [
                'success'     => true,
                'channel'     => 'email',
                'otp_channel' => 'email',
                'otp_sent_to' => $user->email,
                'sms_sent'    => false,
                'email_sent'  => true,
                'message'     => "A verification code has been sent to your email ({$user->email}).",
            ];
        }

        return [
            'success'     => false,
            'channel'     => 'failed',
            'otp_channel' => 'failed',
            'otp_sent_to' => null,
            'sms_sent'    => false,
            'email_sent'  => false,
            'message'     => 'We could not deliver the verification code. Please use the resend option.',
        ];
    }

    // ────────────────────────────────────────────────────────
    // SMS
    // ────────────────────────────────────────────────────────

    /** @return string|null null on success, error message on failure */
    protected function trySms(User $user, Otp $otp): ?string
    {
        $phone = $this->formatPhoneNumber($user->phone);

        if (!$phone) {
            return 'Invalid phone number format';
        }

        $message = $this->buildSmsMessage($otp);

        try {
            $result = $this->smsService->sendSms($phone, $message);

            $isSuccess = ($result['success'] ?? false) === true
                || ($result['status'] ?? '') === 'success'
                || !empty($result['message_id'])
                || !empty($result['id']);

            try {
                SmsLog::create([
                    'user_id'       => $user->id,
                    'recipient'     => $phone,
                    'message'       => in_array($otp->type, [Otp::TYPE_EMAIL_VERIFICATION, Otp::TYPE_REGISTRATION], true)
                        ? '[OTP hidden]'
                        : $message,
                    'status'        => $isSuccess ? 'sent' : 'failed',
                    'message_id'    => $result['message_id'] ?? $result['id'] ?? null,
                    'response_data' => $result,
                    'error_message' => $isSuccess ? null : ($result['message'] ?? 'SMS dispatch failed.'),
                ]);
            } catch (Throwable $logEx) {
                Log::warning('SmsLog write failed (SMS attempt already done)', [
                    'user_id' => $user->id,
                    'error'   => $logEx->getMessage(),
                ]);
            }

            if ($isSuccess) {
                Log::info('OTP SMS sent', ['user_id' => $user->id, 'phone' => $phone, 'type' => $otp->type]);
                return null;
            }

            return $result['message'] ?? 'SMS dispatch failed.';
        } catch (Throwable $e) {
            try {
                SmsLog::create([
                    'user_id'       => $user->id,
                    'recipient'     => $phone,
                    'message'       => '[OTP hidden]',
                    'status'        => 'failed',
                    'error_message' => $e->getMessage(),
                ]);
            } catch (Throwable $logEx) {
                Log::warning('SmsLog write failed on SMS exception', [
                    'user_id' => $user->id,
                    'error'   => $logEx->getMessage(),
                ]);
            }

            return $e->getMessage();
        }
    }

    protected function buildSmsMessage(Otp $otp): string
    {
        $code    = $otp->plain_otp ?? '******';
        $minutes = method_exists($otp, 'getRemainingMinutes') ? $otp->getRemainingMinutes() : 10;

        return match ($otp->type) {
            Otp::TYPE_EMAIL_VERIFICATION,
            Otp::TYPE_REGISTRATION =>
                "Nearbyfundi: Your verification code is {$code}. It expires in {$minutes} minutes. Never share it.",

            Otp::TYPE_PASSWORD_RESET =>
                "Nearbyfundi: Your password reset code is {$code}. It expires in {$minutes} minutes.",

            Otp::TYPE_PHONE_VERIFICATION =>
                "Nearbyfundi: Your phone verification code is {$code}. It expires in {$minutes} minutes.",

            Otp::TYPE_LOGIN_OTP =>
                "Nearbyfundi: Your login code is {$code}. It expires in {$minutes} minutes.",

            default =>
                "Nearbyfundi: Your code is {$code}. It expires in {$minutes} minutes.",
        };
    }

    // ────────────────────────────────────────────────────────
    // Email
    // ────────────────────────────────────────────────────────

    /**
     * Sends the OTP code by email.
     *
     * NOTE: $verificationUrl is still accepted so existing callers keep
     * working, but the "verify via link" line is intentionally no longer
     * included in the email body: the email now contains the code only.
     */
    protected function tryEmail(User $user, Otp $otp, ?string $verificationUrl = null): bool
    {
        if (empty($user->email)) {
            return false;
        }

        try {
            $code    = $otp->plain_otp ?? '******';
            $minutes = method_exists($otp, 'getRemainingMinutes') ? $otp->getRemainingMinutes() : 10;

            Mail::raw(
                "Your Nearby Fundi verification code is: {$code}\n\n"
                . "This code expires in {$minutes} minutes.\n\n"
                . "If you didn't request it, please ignore this email.",
                function ($message) use ($user) {
                    $message->to($user->email)
                        ->subject('Your Nearby Fundi Verification Code');
                }
            );

            Log::info('OTP email sent', ['user_id' => $user->id, 'email' => $user->email]);
            return true;
        } catch (Throwable $e) {
            Log::error('OTP email delivery failed', [
                'user_id' => $user->id,
                'email'   => $user->email,
                'error'   => $e->getMessage(),
            ]);
            return false;
        }
    }

    // ────────────────────────────────────────────────────────
    // Phone normalization (kept from your version)
    // ────────────────────────────────────────────────────────

    protected function formatPhoneNumber(?string $phone): ?string
    {
        if (empty($phone)) {
            return null;
        }

        $phone      = preg_replace('/[^0-9+]/', '', trim($phone));
        $cleanPhone = ltrim($phone, '+');

        if (str_starts_with($cleanPhone, '0')) {
            $cleanPhone = '255' . substr($cleanPhone, 1);
        } elseif (strlen($cleanPhone) === 9
            && (str_starts_with($cleanPhone, '6') || str_starts_with($cleanPhone, '7'))) {
            $cleanPhone = '255' . $cleanPhone;
        }

        if (strlen($cleanPhone) < 7 || strlen($cleanPhone) > 15) {
            Log::warning('Invalid international phone number length', [
                'original'  => $phone,
                'formatted' => $cleanPhone,
                'length'    => strlen($cleanPhone),
            ]);
            return null;
        }

        return $cleanPhone;
    }
}