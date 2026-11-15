<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Throwable;

class RafikiSmsService
{
    protected string $baseUrl;
    protected string $apiKey;
    protected ?string $senderId;
    protected int $timeout;

    public function __construct()
    {
        $this->baseUrl  = rtrim(
            config('services.rafikisms.base_url') ?? config('rafikisms.base_url', 'https://api.rafikisms.com'),
            '/'
        );
        $this->apiKey   = config('services.rafikisms.api_key') ?? config('rafikisms.api_key', '');
        $this->senderId = config('services.rafikisms.sender_id') ?? config('rafikisms.sender_id', 'NearbyFundi');
        $this->timeout  = (int) (config('services.rafikisms.timeout') ?? config('rafikisms.timeout', 15));
    }

    /**
     * Send standard transactional SMS message.
     */
    public function sendSms(string $phone, string $message, ?string $senderId = null): array
    {
        $this->assertApiKey();

        $payload = [
            'phone'     => $this->normalizePhone($phone),
            'message'   => $message,
            'sender_id' => $senderId ?? $this->senderId,
        ];

        return $this->post('/v1/vendor/send-sms', $payload);
    }

    /**
     * Generate and send a native RafikiSMS OTP.
     */
    public function generateOtp(string $phone, ?string $senderId = null): array
    {
        $this->assertApiKey();

        $payload = [
            'phone_number' => $this->normalizePhone($phone),
            'sender_id'    => $senderId ?? $this->senderId,
        ];

        return $this->post('/v1/vendor/otp/generate', $payload);
    }

    /**
     * Verify a native RafikiSMS OTP.
     */
    public function verifyOtp(string $referenceId, string $pin): array
    {
        $this->assertApiKey();

        $payload = [
            'reference_id' => $referenceId,
            'pin'          => $pin,
        ];

        return $this->post('/v1/vendor/otp/verify', $payload);
    }

    /**
     * Common HTTP POST handler for RafikiSMS API calls.
     */
    protected function post(string $endpoint, array $payload): array
    {
        try {
            $response = Http::withHeaders([
                'X-API-Key'    => $this->apiKey,
                'Content-Type' => 'application/json',
                'Accept'       => 'application/json',
            ])
            ->connectTimeout(5)
            ->timeout($this->timeout)
            ->post("{$this->baseUrl}{$endpoint}", $payload);

            $body = $response->json() ?? [];

            return array_merge($body, [
                'http_status' => $response->status(),
                'success'     => $response->successful() && (($body['status'] ?? '') === 'success' || ($body['success'] ?? false) === true),
            ]);
        } catch (Throwable $e) {
            Log::error("RafikiSMS Request Failed [{$endpoint}]: " . $e->getMessage(), [
                'payload' => $payload,
            ]);

            return [
                'success'     => false,
                'message'     => $e->getMessage(),
                'http_status' => 500,
            ];
        }
    }

    /**
     * Format phone number to international format (255XXXXXXXXX) without leading plus sign.
     */
    protected function normalizePhone(string $phone): string
    {
        $cleaned = preg_replace('/[^0-9]/', '', $phone);

        // If starts with 0, replace with 255 (Tanzania country code)
        if (str_starts_with($cleaned, '0')) {
            return '255' . substr($cleaned, 1);
        }

        // If starts with 255, keep as is
        if (str_starts_with($cleaned, '255')) {
            return $cleaned;
        }

        // If starts with +255, remove the +
        if (str_starts_with($phone, '+255')) {
            return substr($cleaned, 1);
        }

        // Default: assume it's already in correct format
        return $cleaned;
    }

    /**
     * Ensure API Key configuration exists.
     */
    protected function assertApiKey(): void
    {
        if (empty($this->apiKey)) {
            throw new RuntimeException('RafikiSMS API key is not configured in .env');
        }
    }
}