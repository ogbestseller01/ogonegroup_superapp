<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Otp extends Model
{
    /**
     * Temporary plain OTP (not persisted). Used by OtpDeliveryService.
     */
    public ?string $plain_otp = null;

    protected $fillable = [
        'email',
        'otp',
        'phone',
        'type',
        'name',
        'token',
        'ip_address',
        'user_agent',
        'expires_at',
        'is_used',
        'attempts',
    ];

    // ─── Types ────────────────────────────────────────────────
    const TYPE_REGISTRATION        = 'registration';
    const TYPE_EMAIL_VERIFICATION  = 'email_verification';
    const TYPE_PASSWORD_RESET      = 'password_reset';
    const TYPE_PHONE_VERIFICATION  = 'phone_verification';
    const TYPE_LOGIN_OTP           = 'login_otp';

    protected $casts = [
        'expires_at' => 'datetime',
        'is_used'    => 'boolean',
        'attempts'   => 'integer',
    ];

    // ─── Helpers ──────────────────────────────────────────────

    /**
     * Check if the OTP is still valid
     */
    public function isValid(): bool
    {
        return !$this->is_used
            && $this->expires_at
            && $this->expires_at->isFuture()
            && $this->attempts < 5;
    }

    /**
     * Mark the OTP as used
     */
    public function markAsUsed(): void
    {
        $this->is_used = true;
        $this->save();
    }

    /**
     * Record a failed attempt
     */
    public function recordFailedAttempt(): void
    {
        $this->increment('attempts');
    }

    /**
     * Check if the OTP has expired
     */
    public function isExpired(): bool
    {
        return $this->expires_at && $this->expires_at->isPast();
    }

    /**
     * Get remaining minutes before expiry
     */
    public function getRemainingMinutes(): int
    {
        if (!$this->expires_at || $this->isExpired()) {
            return 0;
        }
        return max(1, (int) now()->diffInMinutes($this->expires_at));
    }

    /**
     * Generate verification URL for email
     */
    public function getVerificationUrl(): string
    {
        $frontendUrl = config('app.frontend_url', 'https://fundi.app');
        return "{$frontendUrl}/verify-email?email=" . urlencode($this->email) . "&token=" . $this->token;
    }

    /**
     * Generate a 6-digit OTP
     */
    public static function generateOtp(): string
    {
        return str_pad((string) random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
    }

    /**
     * Generate a secure token for email verification links
     */
    public static function generateToken(): string
    {
        return bin2hex(random_bytes(32));
    }

    /**
     * Get human-readable type name
     */
    public function getTypeName(): string
    {
        return match ($this->type) {
            self::TYPE_REGISTRATION       => 'Registration',
            self::TYPE_EMAIL_VERIFICATION => 'Email Verification',
            self::TYPE_PASSWORD_RESET     => 'Password Reset',
            self::TYPE_PHONE_VERIFICATION => 'Phone Verification',
            self::TYPE_LOGIN_OTP          => 'Login OTP',
            default                       => $this->type,
        };
    }

    // ─── Scopes ───────────────────────────────────────────────

    /**
     * Scope for valid (unused, non-expired, within attempt limit) OTPs
     */
    public function scopeValid($query)
    {
        return $query->where('is_used', false)
                     ->where('attempts', '<', 5)
                     ->where('expires_at', '>', Carbon::now());
    }

    /**
     * Scope to filter by OTP type
     */
    public function scopeOfType($query, string $type)
    {
        return $query->where('type', $type);
    }

    /**
     * Scope to filter by email
     */
    public function scopeForEmail($query, string $email)
    {
        return $query->where('email', $email);
    }

    /**
     * Scope to filter recent OTPs (within last minute)
     */
    public function scopeRecent($query, int $minutes = 1)
    {
        return $query->where('created_at', '>', Carbon::now()->subMinutes($minutes));
    }

    /**
     * Clean up expired OTPs (should be run via scheduled job)
     */
    public static function cleanExpired(): int
    {
        return self::where('expires_at', '<', Carbon::now())
            ->where('is_used', false)
            ->delete();
    }

    // ─── Relationships ────────────────────────────────────────

    /**
     * Get the user associated with this OTP
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'email', 'email');
    }

    // ─── Accessors ────────────────────────────────────────────

    /**
     * Check if OTP can be resend (cooldown check)
     */
    public function canResend(): bool
    {
        $recent = self::where('email', $this->email)
            ->where('type', $this->type)
            ->where('created_at', '>', Carbon::now()->subMinutes(1))
            ->exists();
        
        return !$recent;
    }
}