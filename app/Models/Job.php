<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class Job extends Model
{
    protected $table = 'jobs';

    public const STATUS_PENDING     = 'pending';
    public const STATUS_ON_PROGRESS = 'on-progress';
    public const STATUS_COMPLETED   = 'completed';

    public const STATUSES = [
        self::STATUS_PENDING,
        self::STATUS_ON_PROGRESS,
        self::STATUS_COMPLETED,
    ];

    protected $fillable = [
        'job_number',
        'request_id',
        'technician_id',
        'customer_id',
        'contract_file',
        'other_documents',
        'status',
        'started_at',
        'completed_at',
        'notes',
    ];

    protected $hidden = [
        'completion_otp',
        'completion_otp_expires_at',
        'completion_otp_attempts',
    ];

    protected $casts = [
        'other_documents'           => 'array',
        'started_at'                => 'datetime',
        'completed_at'              => 'datetime',
        'completion_otp_expires_at' => 'datetime',
        'completion_otp_attempts'   => 'integer',
        'created_at'                => 'datetime',
        'updated_at'                => 'datetime',
    ];

    // ── Boot: auto-generate job_number + cascade completion to tickets ──
    protected static function booted(): void
    {
        static::creating(function (Job $job) {
            if (empty($job->job_number)) {
                $job->job_number = self::generateJobNumber();
            }
        });

        static::updated(function (Job $job) {
            // Job becomes completed → complete all still-open tickets
            if ($job->wasChanged('status') && $job->status === self::STATUS_COMPLETED) {
                $job->tickets()
                    ->whereIn('status', Ticket::OPEN_STATUSES)
                    ->update([
                        'status'       => Ticket::STATUS_COMPLETED,
                        'completed_at' => now(),
                    ]);

                if (!$job->completed_at) {
                    $job->completed_at = now();
                    $job->saveQuietly(); // avoid loops
                }
            }
        });
    }

    public static function generateJobNumber(): string
    {
        do {
            $number = 'JOB-' . now()->format('Ymd') . '-' . strtoupper(Str::random(6));
        } while (self::where('job_number', $number)->exists());

        return $number;
    }

    // ── Relationships ─────────────────────────────────────
    public function request(): BelongsTo
    {
        return $this->belongsTo(ServiceRequest::class, 'request_id');
    }

    public function technician(): BelongsTo
    {
        return $this->belongsTo(Technician::class, 'technician_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function tickets(): HasMany
    {
        return $this->hasMany(Ticket::class, 'job_id');
    }

    public function review(): HasOne
    {
        return $this->hasOne(Review::class, 'job_id');
    }

    // ── Scopes ────────────────────────────────────────────
    public function scopePending($q)    { return $q->where('status', self::STATUS_PENDING); }
    public function scopeOnProgress($q) { return $q->where('status', self::STATUS_ON_PROGRESS); }
    public function scopeCompleted($q)  { return $q->where('status', self::STATUS_COMPLETED); }

    // ── Helpers ───────────────────────────────────────────
    public function isPending(): bool    { return $this->status === self::STATUS_PENDING; }
    public function isOnProgress(): bool { return $this->status === self::STATUS_ON_PROGRESS; }
    public function isCompleted(): bool  { return $this->status === self::STATUS_COMPLETED; }

    /** A job can be completed (OTP flow) while pending or on-progress. */
    public function canComplete(): bool
    {
        return $this->isPending() || $this->isOnProgress();
    }
}