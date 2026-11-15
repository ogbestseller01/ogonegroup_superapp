<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Sanctum\HasApiTokens;

/**
 * A pre-user registration attempt.
 *
 * ── Why this table exists ──────────────────────────────────────────
 * The old flow inserted a `users` row at step 1 (status=pending,
 * is_active=0), which meant every abandoned signup left an orphan
 * "pending" user in the DB. This model replaces that: OTP and steps
 * 2-5 write ONLY to `registration_drafts`. The `users` row is created
 * exactly once, inside registerStep6(), after all 6 steps pass.
 *
 * ── Lifecycle ─────────────────────────────────────────────────────
 *  step 1   → row created, `expires_at` = now + 7 days
 *  verify   → `otp_verified_at` set, draft token issued
 *  steps 2-5→ columns filled in
 *  step 6   → `submitted_at` set (optional), User + Technician created,
 *             draft row force-deleted, mobile auth token returned
 *  never    → row auto-purged by `drafts:purge` command after `expires_at`
 *
 * ── Token model ───────────────────────────────────────────────────
 * Because this model uses HasApiTokens, `/v19/technicians/register/*`
 * routes wrapped in `auth:sanctum` resolve `$request->user()` to a
 * RegistrationDraft (not a User). Controllers guard with
 * `instanceof RegistrationDraft` to keep user endpoints safe.
 */
class RegistrationDraft extends Model
{
    use SoftDeletes, HasApiTokens;

    protected $fillable = [
        // Step 1
        'name', 'email', 'phone', 'password', 'profile_photo',
        'fcm_device_token', 'locale', 'otp_verified_at',

        // Step 2
        'nida', 'id_document_type', 'id_document_image',

        // Steps 3 & 4
        'fingerprint_data', 'fingerprint_enrolled',
        'face_data', 'face_enrolled',

        // Step 5
        'next_of_kin_name', 'next_of_kin_phone', 'next_of_kin_relationship',

        // Progress
        'registration_step', 'submitted_at', 'expires_at',
    ];

    protected $hidden = [
        'password',
        'fingerprint_data',
        'face_data',
    ];

    protected $casts = [
        'otp_verified_at'      => 'datetime',
        'submitted_at'         => 'datetime',
        'expires_at'           => 'datetime',
        'fingerprint_enrolled' => 'boolean',
        'face_enrolled'        => 'boolean',
        'registration_step'    => 'integer',
    ];

    // ══════════════════════════════════════════════════════
    // State helpers
    // ══════════════════════════════════════════════════════

    public function isExpired(): bool
    {
        return $this->expires_at !== null && $this->expires_at->isPast();
    }

    public function isSubmitted(): bool
    {
        return $this->submitted_at !== null;
    }

    public function isOtpVerified(): bool
    {
        return $this->otp_verified_at !== null;
    }

    public function hasCompletedBiometrics(): bool
    {
        return $this->fingerprint_enrolled && $this->face_enrolled;
    }

    public function hasCompletedNextOfKin(): bool
    {
        return !empty($this->next_of_kin_name) && !empty($this->next_of_kin_phone);
    }

    /** Draft can still be advanced (OTP sent but not submitted, not expired). */
    public function canProceed(): bool
    {
        return !$this->isSubmitted() && !$this->isExpired();
    }

    /** All prerequisites met → step 6 will succeed. */
    public function canSubmit(): bool
    {
        return $this->canProceed()
            && $this->isOtpVerified()
            && $this->hasCompletedBiometrics()
            && $this->hasCompletedNextOfKin();
    }

    // ══════════════════════════════════════════════════════
    // Scopes — used by the `drafts:purge` scheduled command
    // ══════════════════════════════════════════════════════

    /** Drafts still usable (not submitted, not expired). */
    public function scopeActive(Builder $q): Builder
    {
        return $q->whereNull('submitted_at')
                 ->where(function (Builder $inner) {
                     $inner->whereNull('expires_at')
                           ->orWhere('expires_at', '>', now());
                 });
    }

    /** Drafts that should be purged (past expiry, never submitted). */
    public function scopePurgeable(Builder $q): Builder
    {
        return $q->whereNull('submitted_at')
                 ->whereNotNull('expires_at')
                 ->where('expires_at', '<=', now());
    }

    /** Drafts that were never OTP-verified and are >1h old — usually abandoned. */
    public function scopeAbandoned(Builder $q): Builder
    {
        return $q->whereNull('otp_verified_at')
                 ->where('created_at', '<=', now()->subHour());
    }
}