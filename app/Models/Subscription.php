<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Carbon\Carbon;

class Subscription extends Model
{
    use SoftDeletes;

    protected $table = 'subscriptions';

    protected $fillable = [
        'user_id', 'rate_card_id', 'status', 'start_date', 'expiry_date',
        'amount_paid', 'currency', 'payment_method', 'payment_reference',
        'payment_proof', 'approved_at', 'approved_by', 'admin_notes'
    ];

    protected $casts = [
        'start_date' => 'datetime',
        'expiry_date' => 'datetime',
        'approved_at' => 'datetime',
        'amount_paid' => 'decimal:2',
    ];

    // Status constants
    const STATUS_PENDING = 'pending';
    const STATUS_APPROVED = 'approved';
    const STATUS_ACTIVE = 'active';
    const STATUS_EXPIRED = 'expired';
    const STATUS_CANCELLED = 'cancelled';

    // ============================================================
    // RELATIONSHIPS
    // ============================================================

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function rateCard()
    {
        return $this->belongsTo(RateCard::class);
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function invoice()
    {
        return $this->hasOne(Invoice::class);
    }

    public function paymentMethod()
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method', 'name');
    }

    // ============================================================
    // STATUS HELPERS - FIXED
    // ============================================================

    /**
     * ✅ FIXED: Check if subscription is active and not expired
     */
    public function isActive(): bool
    {
        if ($this->status !== self::STATUS_ACTIVE) {
            return false;
        }
        
        // ✅ If expiry_date is null, consider it active
        if ($this->expiry_date === null) {
            return true;
        }
        
        // ✅ Ensure expiry_date is a Carbon instance
        $expiry = $this->expiry_date;
        if ($expiry instanceof \DateTime) {
            return $expiry->isFuture();
        }
        
        return false;
    }

    /**
     * ✅ FIXED: Check if subscription is expired
     */
    public function isExpired(): bool
    {
        if ($this->status === self::STATUS_EXPIRED) {
            return true;
        }
        
        if ($this->expiry_date === null) {
            return false;
        }
        
        $expiry = $this->expiry_date;
        if ($expiry instanceof \DateTime) {
            return $expiry->isPast();
        }
        
        return false;
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function isApproved(): bool
    {
        return $this->status === self::STATUS_APPROVED;
    }

    public function isCancelled(): bool
    {
        return $this->status === self::STATUS_CANCELLED;
    }

    // ============================================================
    // ACCESSORS
    // ============================================================

    /**
     * ✅ FIXED: Get days remaining safely
     */
    public function getDaysRemainingAttribute(): ?int
    {
        if (!$this->expiry_date) {
            return null;
        }
        
        $expiry = $this->expiry_date;
        if ($expiry instanceof \DateTime) {
            if ($expiry->isPast()) {
                return 0;
            }
            return $expiry->diffInDays(now());
        }
        
        return null;
    }

    public function getStatusLabelAttribute(): string
    {
        return match($this->status) {
            self::STATUS_PENDING => 'Pending Approval',
            self::STATUS_APPROVED => 'Approved',
            self::STATUS_ACTIVE => 'Active',
            self::STATUS_EXPIRED => 'Expired',
            self::STATUS_CANCELLED => 'Cancelled',
            default => ucfirst($this->status),
        };
    }

    // ============================================================
    // SCOPES
    // ============================================================

    public function scopeActive($query)
    {
        return $query->where('status', self::STATUS_ACTIVE)
                     ->where(function($q) {
                         $q->whereNull('expiry_date')
                           ->orWhere('expiry_date', '>', now());
                     });
    }

    public function scopeExpired($query)
    {
        return $query->where('status', self::STATUS_EXPIRED)
                     ->orWhere(function($q) {
                         $q->where('status', self::STATUS_ACTIVE)
                           ->where('expiry_date', '<=', now());
                     });
    }

    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    public function scopeApproved($query)
    {
        return $query->where('status', self::STATUS_APPROVED);
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', self::STATUS_CANCELLED);
    }

    // ============================================================
    // EVENTS
    // ============================================================

    protected static function booted()
    {
        static::saving(function ($subscription) {
            if ($subscription->expiry_date && $subscription->expiry_date->isPast()) {
                $subscription->status = self::STATUS_EXPIRED;
            }
        });
    }
}