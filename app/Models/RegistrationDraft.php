<?php

namespace App\Models;

use App\Casts\EncryptedOrPlaintext;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\HasApiTokens;

class RegistrationDraft extends Model
{
    use HasApiTokens, SoftDeletes;

    public const TTL_DAYS = 7;

    protected $fillable = [
        'name', 'email', 'password', 'phone',
        'fcm_device_token', 'locale', 'profile_photo',
        'registration_step', 'expires_at', 'otp_verified_at', 'submitted_at',

        // Location
        'area', 'latitude', 'longitude',

        // Services selected at step 1
        'service_ids',

        // Identity
        'id_document_type', 'id_document_image',
        'nida',

        // Biometrics
        'fingerprint_data', 'fingerprint_enrolled',
        'face_data', 'face_enrolled',

        // Next of kin
        'next_of_kin_name', 'next_of_kin_phone', 'next_of_kin_relationship',
    ];

    protected $hidden = [
        'password',
        'nida',
        'id_document_image',
        'fingerprint_data',
        'face_data',
    ];

    protected $casts = [
        'nida'             => EncryptedOrPlaintext::class,
        'fingerprint_data' => EncryptedOrPlaintext::class,
        'face_data'        => EncryptedOrPlaintext::class,

        'fingerprint_enrolled' => 'boolean',
        'face_enrolled'        => 'boolean',
        'registration_step'    => 'integer',
        'expires_at'           => 'datetime',
        'otp_verified_at'      => 'datetime',
        'submitted_at'         => 'datetime',

        'latitude'    => 'float',
        'longitude'   => 'float',
        'service_ids' => 'array',   // JSON <-> PHP array
    ];

    protected static function booted(): void
    {
        static::creating(function (self $draft) {
            $draft->expires_at ??= now()->addDays(self::TTL_DAYS);
        });
    }

    // ── State ─────────────────────────────────────────────
    public function canProceed(): bool
    {
        if ($this->submitted_at !== null) return false;
        return $this->expires_at === null || now()->lt($this->expires_at);
    }

    public function isOtpVerified(): bool
    {
        return $this->otp_verified_at !== null;
    }

    public function hasCompletedLocation(): bool
    {
        return !empty($this->area)
            && $this->latitude  !== null
            && $this->longitude !== null;
    }

    public function hasCompletedServices(): bool
    {
        return is_array($this->service_ids)
            && count(array_filter($this->service_ids)) > 0;
    }

    public function hasCompletedBiometrics(): bool
    {
        return (bool) $this->fingerprint_enrolled
            && (bool) $this->face_enrolled
            && !empty($this->fingerprint_data)
            && !empty($this->face_data);
    }

    public function hasCompletedNextOfKin(): bool
    {
        return !empty($this->next_of_kin_name)
            && !empty($this->next_of_kin_phone)
            && !empty($this->next_of_kin_relationship);
    }

    // ── Cleanup ───────────────────────────────────────────
    public function purge(): void
    {
        foreach ([$this->profile_photo, $this->id_document_image] as $path) {
            if ($path && Storage::disk('public')->exists($path)) {
                Storage::disk('public')->delete($path);
            }
        }

        $this->tokens()->delete();
        $this->forceDelete();
    }

    public static function discardFor(?string $phone, ?string $email): void
    {
        if (!$phone && !$email) return;

        static::withTrashed()
            ->where(function ($q) use ($phone, $email) {
                if ($phone) $q->where('phone', $phone);
                if ($email) $q->orWhere('email', $email);
            })
            ->get()
            ->each(fn (self $draft) => $draft->purge());
    }
}