<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Portfolio extends Model
{
    protected $fillable = [
        'technician_id',
    ];

    public function technician()
    {
        return $this->belongsTo(Technician::class);
    }

    public function images(): HasMany
    {
        return $this->hasMany(PortfolioImage::class);
    }
}