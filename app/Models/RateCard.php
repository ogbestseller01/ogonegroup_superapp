<?php
// app/Models/RateCard.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class RateCard extends Model
{
    use SoftDeletes;

    protected $table = 'rate_cards';

    protected $fillable = [
        'name', 'slug', 'price', 'duration_days', 'currency',
        'description', 'is_active', 'display_order'
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'is_active' => 'boolean',
        'display_order' => 'integer',
        'duration_days' => 'integer',
    ];

    public function subscriptions()
    {
        return $this->hasMany(Subscription::class);
    }

    public function invoices()
    {
        return $this->hasMany(Invoice::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function getFormattedPriceAttribute()
    {
        return number_format($this->price, 0, '.', ',') . ' ' . $this->currency;
    }

    public function getDurationLabelAttribute()
    {
        $days = $this->duration_days;
        if ($days == 1) return 'Daily';
        if ($days == 7) return 'Weekly';
        if ($days == 30) return 'Monthly';
        if ($days == 90) return 'Quarterly';
        if ($days == 365) return 'Yearly';
        return $days . ' Days';
    }
}