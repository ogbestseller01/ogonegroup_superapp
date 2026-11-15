<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MiniApp extends Model
{
    /** Must match QrService.scheme / QrService.host in Flutter. */
    public const QR_SCHEME = 'ogone';
    public const QR_HOST   = 'app';

    protected $fillable = [
        'slug', 'name', 'subtitle', 'is_coming_soon', 'is_active', 'sort_order',
    ];

    protected $casts = [
        'is_coming_soon' => 'boolean',
        'is_active'      => 'boolean',
        'sort_order'     => 'integer',
    ];

    /** Text encoded inside the QR image, e.g. ogone://app/nearbyfundi */
    public function getQrPayloadAttribute(): string
    {
        return self::QR_SCHEME . '://' . self::QR_HOST . '/' . $this->slug;
    }

    public function scopeActive($q)
    {
        return $q->where('is_active', true);
    }

    public function scopeOrdered($q)
    {
        return $q->orderBy('sort_order')->orderBy('id');
    }

    public function qrCodes()
    {
        return $this->hasMany(MiniAppQr::class);
    }
}