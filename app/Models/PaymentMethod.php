<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage; 

class PaymentMethod extends Model
{
    use SoftDeletes;

    protected $table = 'payment_methods';

    protected $fillable = [
        'name', 'slug', 'phone_number', 'account_name',
        'logo', 'is_active', 'display_order'
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'display_order' => 'integer',
    ];

    protected $appends = ['logo_url', 'formatted_phone'];

    // ============================================================
    // SCOPES
    // ============================================================

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('display_order');
    }

    // ============================================================
    // ACCESSORS
    // ============================================================

    public function getFormattedPhoneAttribute(): string
    {
        $phone = $this->phone_number ?? '';
        if (strlen($phone) > 10) {
            return substr($phone, 0, 3) . ' ' . substr($phone, 3, 3) . ' ' . substr($phone, 6, 3) . ' ' . substr($phone, 9);
        } elseif (strlen($phone) == 10) {
            return substr($phone, 0, 3) . ' ' . substr($phone, 3, 3) . ' ' . substr($phone, 6);
        }
        return $phone;
    }

    public function getLogoUrlAttribute(): ?string
    {
        return $this->logo ? url('storage/' . $this->logo) : null;
    }

    // ============================================================
    // MUTATORS
    // ============================================================

    public function setNameAttribute($value)
    {
        $this->attributes['name'] = $value;
        $this->attributes['slug'] = Str::slug($value);
    }

    // ============================================================
    // RELATIONSHIPS
    // ============================================================

    /**
     * Get the subscriptions using this payment method.
     * Uses 'payment_method' column as string matching by name
     */
    public function subscriptions()
    {
        return $this->hasMany(Subscription::class, 'payment_method', 'name');
    }

    // ============================================================
    // HELPERS
    // ============================================================

    public function isActive(): bool
    {
        return $this->is_active;
    }

    public function getDisplayNameAttribute(): string
    {
        return $this->name . ' (' . $this->formatted_phone . ')';
    }

    public function deleteLogo(): bool
    {
        if ($this->logo && Storage::disk('public')->exists($this->logo)) {
            return Storage::disk('public')->delete($this->logo);
        }
        return true;
    }
}