<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class MiniAppQr extends Model
{
    public const VALIDITIES = ['week', 'month', 'half_year', 'year', 'never'];

    protected $fillable = [
        'mini_app_id', 'label', 'token', 'validity', 'expires_at',
        'is_active', 'scans_count', 'last_scanned_at', 'created_by',
    ];

    protected $casts = [
        'is_active'       => 'boolean',
        'scans_count'     => 'integer',
        'expires_at'      => 'datetime',
        'last_scanned_at' => 'datetime',
    ];

    public function miniApp()
    {
        return $this->belongsTo(MiniApp::class);
    }

    // ── Helpers ─────────────────────────────────────────

    /** Expiry date counted from now. null = never expires. */
    public static function expiryFor(string $validity): ?Carbon
    {
        return match ($validity) {
            'week'      => now()->addWeek(),
            'month'     => now()->addMonth(),
            'half_year' => now()->addMonths(6),
            'year'      => now()->addYear(),
            default     => null,
        };
    }

    public static function newToken(): string
    {
        do {
            $token = Str::random(40);
        } while (static::where('token', $token)->exists());

        return $token;
    }

    // ── Accessors ───────────────────────────────────────

    public function getIsExpiredAttribute(): bool
    {
        return $this->expires_at !== null && $this->expires_at->isPast();
    }

    /** revoked > expired > active */
    public function getStatusAttribute(): string
    {
        if (!$this->is_active) return 'revoked';
        if ($this->is_expired) return 'expired';
        return 'active';
    }

    public function getDaysLeftAttribute(): ?int
    {
        if ($this->expires_at === null) return null;
        $seconds = now()->diffInSeconds($this->expires_at, false);
        return max(0, (int) ceil($seconds / 86400));
    }

    /** Text encoded inside the QR image. */
    public function getQrPayloadAttribute(): string
    {
        return $this->miniApp->qr_payload . '?t=' . $this->token;
    }

    // ── Scopes ──────────────────────────────────────────

    public function scopeValid($q)
    {
        return $q->where('is_active', true)
            ->where(fn ($w) => $w->whereNull('expires_at')->orWhere('expires_at', '>', now()));
    }

    public function scopeExpired($q)
    {
        return $q->where('is_active', true)
            ->whereNotNull('expires_at')
            ->where('expires_at', '<=', now());
    }

    public function scopeRevoked($q)
    {
        return $q->where('is_active', false);
    }
}