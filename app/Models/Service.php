<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Service extends Model
{
    protected $fillable = ['name', 'swahili_name'];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the technicians for this service.
     */
    public function technicians(): BelongsToMany
    {
        return $this->belongsToMany(Technician::class, 'technician_services');
    }

    /**
     * Get the requests for this service.
     */
    public function requests()
    {
        return $this->hasMany(ServiceRequest::class);
    }

    /**
     * Get the categories for this service.
     */
    public function categories(): BelongsToMany
    {
        return $this->belongsToMany(
            ServiceCategory::class,
            'service_category_assignments',
            'service_id',
            'service_categoryID'
        )->withTimestamps();
    }

    /**
     * Get service name in the requested language.
     */
    public function getNameForLocale(string $locale = 'en'): string
    {
        if ($locale === 'sw' && $this->swahili_name) {
            return $this->swahili_name;
        }
        return $this->name;
    }

    /**
     * Check if service has a specific category.
     * FIXED: Explicitly reference pivot table column to avoid ambiguity.
     */
    public function hasCategory($categoryId): bool
    {
        return $this->categories()
            ->where('service_category_assignments.service_categoryID', $categoryId)
            ->exists();
    }

    /**
     * Get category IDs as array.
     * FIXED: Explicitly reference pivot table column to avoid ambiguity.
     */
    public function getCategoryIdsAttribute(): array
    {
        return $this->categories()
            ->pluck('service_category_assignments.service_categoryID')
            ->toArray();
    }

    /**
     * Get category names as array.
     */
    public function getCategoryNamesAttribute(): array
    {
        return $this->categories()->pluck('category_name')->toArray();
    }

    /**
     * Sync categories for this service.
     */
    public function syncCategories(array $categoryIds): void
    {
        $this->categories()->sync($categoryIds);
    }

    /**
     * Attach a category to this service.
     */
    public function attachCategory($categoryId): void
    {
        if (!$this->hasCategory($categoryId)) {
            $this->categories()->attach($categoryId);
        }
    }

    /**
     * Detach a category from this service.
     */
    public function detachCategory($categoryId): void
    {
        $this->categories()->detach($categoryId);
    }
}