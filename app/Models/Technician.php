<?php

namespace App\Models;

use App\Casts\EncryptedOrPlaintext;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Technician extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id',
        'profile_photo',

        // Identity
        'nida',
        'nida_hash',
        'id_document_type',
        'id_document_image',

        // Professional
        'experience',
        'hourly_rate',
        'area',
        'latitude',
        'longitude',

        // Verification
        'rating',
        'verified',
        'verification_status',

        // Activity
        'last_activity_at',
        'location_updated_at',
        'is_online',

        // Registration
        'registration_step',
        'registration_completed',

        // Biometrics
        'fingerprint_enrolled',
        'face_enrolled',
        'fingerprint_data',
        'face_data',
        'fingerprint_template',
        'fingerprint_hash',
        'fingerprint_captured_at',
        'face_image',
        'face_embedding',
        'face_captured_at',

        // Next of Kin
        'next_of_kin_name',
        'next_of_kin_phone',
        'next_of_kin_relationship',
    ];

    protected $hidden = [
        'nida',
        'nida_hash',
        'id_document_image',
        'fingerprint_data',
        'face_data',
        'fingerprint_template',
        'fingerprint_hash',
        'face_image',
        'face_embedding',
    ];

    protected function casts(): array
    {
        return [
            // tolerate plaintext AND encrypted reads; always write encrypted
            'nida'             => EncryptedOrPlaintext::class,
            'fingerprint_data' => EncryptedOrPlaintext::class,
            'face_data'        => EncryptedOrPlaintext::class,

            'verified'               => 'boolean',
            'registration_completed' => 'boolean',
            'fingerprint_enrolled'   => 'boolean',
            'face_enrolled'          => 'boolean',
            'is_online'              => 'boolean',

            'rating'                => 'float',
            'completed_jobs_count'  => 'integer',
            'hourly_rate'           => 'decimal:2',

            'latitude'  => 'float',
            'longitude' => 'float',

            'registration_step' => 'integer',

            'last_activity_at'        => 'datetime',
            'location_updated_at'     => 'datetime',
            'fingerprint_captured_at' => 'datetime',
            'face_captured_at'        => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::saving(function (Technician $tech) {
            if ($tech->isDirty('nida')) {
                $plain = $tech->nida; // decrypted by cast
                $tech->nida_hash = empty($plain)
                    ? null
                    : hash('sha256', trim((string) $plain));
            }
        });
    }

    public static function nidaHash(string $plain): string
    {
        return hash('sha256', trim($plain));
    }

    // ── Relationships ─────────────────────────────────────
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function services(): BelongsToMany
    {
        return $this->belongsToMany(Service::class, 'technician_services')->withTimestamps();
    }

    public function portfolios(): HasMany
    {
        return $this->hasMany(Portfolio::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class, 'technician_id');
    }

    public function jobs(): HasMany
    {
        return $this->hasMany(Job::class, 'technician_id');
    }

    // ── Rating ────────────────────────────────────────────
    /** Average of all customer reviews. Called from Review::saved / deleted. */
    public function recalculateRating(): void
    {
        $avg = $this->reviews()->avg('rating');

        $this->forceFill([
            'rating' => $avg === null ? 0 : round((float) $avg, 2),
        ])->saveQuietly();
    }

    // ── Activity tracking ─────────────────────────────────
    public function recordHeartbeat(?float $lat = null, ?float $lng = null): void
    {
        $this->last_activity_at = now();
        $this->is_online        = true;

        if ($lat !== null && $lng !== null) {
            $this->latitude            = $lat;
            $this->longitude           = $lng;
            $this->location_updated_at = now();
        }

        $this->save();
    }
}