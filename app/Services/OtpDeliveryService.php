<?php

namespace App\Services;

use App\Models\User;
use App\Models\Otp;
use App\Models\SmsLog;
use App\Mail\OtpVerificationMail;
use App\Mail\PasswordResetOtpMail;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Throwable;

class OtpDeliveryService
{
    public function __construct(
        protected RafikiSmsService $smsService
    ) {}

    public function deliver(User $user, Otp $otp, ?string $verificationUrl = null): array
    {
        $message = $this->getOtpMessage($otp);

        // 1. Prefer SMS when phone exists
        if (!empty($user->phone)) {
            $smsError = $this->trySms($user, $otp, $message);

            if ($smsError === null) {
                return [
                    'success'     => true,
                    'channel'     => 'sms',
                    'otp_channel' => 'sms',
                    'otp_sent_to' => $user->phone,
                ];
            }

            Log::warning('OTP SMS delivery failed, falling back to email', [
                'user_id' => $user->id,
                'phone'   => $user->phone,
                'error'   => $smsError,
            ]);
        }

        // 2. Email fallback
        try {
            $this->sendEmail($user, $otp);

            return [
                'success'     => true,
                'channel'     => 'email',
                'otp_channel' => 'email',
                'otp_sent_to' => $user->email,
            ];
        } catch (Throwable $e) {
            Log::error('OTP Email delivery failed', [
                'user_id' => $user->id,
                'email'   => $user->email,
                'error'   => $e->getMessage(),
            ]);

            return [
                'success'     => false,
                'channel'     => 'failed',
                'otp_channel' => 'failed',
                'otp_sent_to' => null,
            ];
        }
    }

    protected function getOtpMessage(Otp $otp): string
    {
        // Always prefer the temporary plain OTP
        $code = $otp->plain_otp ?? '******';
        $minutes = $otp->getRemainingMinutes();

        return match ($otp->type) {
            Otp::TYPE_EMAIL_VERIFICATION,
            Otp::TYPE_REGISTRATION =>
                "Your NearbyFundi verification code is: {$code}. It expires in {$minutes} minutes.",

            Otp::TYPE_PASSWORD_RESET =>
                "Your NearbyFundi password reset code is: {$code}. It expires in {$minutes} minutes.",

            Otp::TYPE_PHONE_VERIFICATION =>
                "Your NearbyFundi phone verification code is: {$code}. It expires in {$minutes} minutes.",

            Otp::TYPE_LOGIN_OTP =>
                "Your NearbyFundi login code is: {$code}. It expires in {$minutes} minutes. Do not share this code.",

            default =>
                "Your NearbyFundi OTP code is: {$code}. It expires in {$minutes} minutes.",
        };
    }

    protected function trySms(User $user, Otp $otp, string $message): ?string
    {
        $phone = $this->formatPhoneNumber($user->phone);

        if (!$phone) {
            return 'Invalid phone number format';
        }

        try {
            $result = $this->smsService->sendSms($phone, $message);

            $isSuccess = ($result['success'] ?? false) === true
                || ($result['status'] ?? '') === 'success'
                || !empty($result['message_id'])
                || !empty($result['id']);

            SmsLog::create([
                'user_id'       => $user->id,
                'recipient'     => $phone,
                'message'       => $message,
                'status'        => $isSuccess ? 'sent' : 'failed',
                'message_id'    => $result['message_id'] ?? $result['id'] ?? null,
                'response_data' => $result,
                'error_message' => $isSuccess ? null : ($result['message'] ?? 'SMS dispatch failed.'),
            ]);

            if ($isSuccess) {
                Log::info('OTP SMS sent successfully', [
                    'user_id'  => $user->id,
                    'phone'    => $phone,
                    'otp_type' => $otp->type,
                ]);
                return null;
            }

            return $result['message'] ?? 'SMS dispatch failed.';
        } catch (Throwable $e) {
            SmsLog::create([
                'user_id'       => $user->id,
                'recipient'     => $phone,
                'message'       => $message,
                'status'        => 'failed',
                'error_message' => $e->getMessage(),
            ]);

            Log::error('SMS sending exception', [
                'user_id' => $user->id,
                'phone'   => $phone,
                'error'   => $e->getMessage(),
            ]);

            return $e->getMessage();
        }
    }

    protected function formatPhoneNumber(?string $phone): ?string
{
    if (empty($phone)) {
        return null;
    }

    // 1. Strip spaces, dashes, parentheses, keeping digits and leading '+'
    $phone = preg_replace('/[^0-9+]/', '', trim($phone));

    // 2. Remove leading '+' for clean manipulation
    $cleanPhone = ltrim($phone, '+');

    // 3. Handle local Tanzanian numbers starting with local '0' (e.g. 0679117297 -> 255679117297)
    if (str_starts_with($cleanPhone, '0')) {
        $cleanPhone = '255' . substr($cleanPhone, 1);
    } 
    // 4. Handle raw local subscriber numbers missing '255' (e.g. 679117297 -> 255679117297)
    elseif (strlen($cleanPhone) === 9 && (str_starts_with($cleanPhone, '6') || str_starts_with($cleanPhone, '7'))) {
        $cleanPhone = '255' . $cleanPhone;
    }

    // 5. E.164 Validation: Must be 7 to 15 digits long globally (covers all country codes worldwide)
    if (strlen($cleanPhone) < 7 || strlen($cleanPhone) > 15) {
        Log::warning('Invalid international phone number length', [
            'original' => $phone,
            'formatted' => $cleanPhone,
            'length'   => strlen($cleanPhone),
        ]);
        return null;
    }

    // Return pure digits (e.g., 255679117297 or 14155552671 for US) suitable for SMS gateways
    return $cleanPhone;
}
}