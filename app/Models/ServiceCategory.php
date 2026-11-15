<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class ServiceCategory extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'service_categories';
    protected $primaryKey = 'service_categoryID';

    protected $fillable = [
        'category_name',
        'swahili_name',
        'slug',
        'description',
        'comment',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    protected $hidden = [
        'deleted_at',
    ];

    /**
     * Get the services for this category.
     */
    public function services(): BelongsToMany
    {
        return $this->belongsToMany(
            Service::class,
            'service_category_assignments',
            'service_categoryID',
            'service_id'
        )->withTimestamps();
    }

    /**
     * Get the formatted category name.
     */
    public function getFormattedNameAttribute(): string
    {
        return ucwords(strtolower($this->category_name));
    }

    /**
     * Get category name in the requested language.
     */
    public function getNameForLocale(string $locale = 'en'): string
    {
        if ($locale === 'sw' && $this->swahili_name) {
            return $this->swahili_name;
        }
        return $this->category_name;
    }

    /**
     * Boot the model.
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($category) {
            if (empty($category->slug)) {
                $category->slug = \Illuminate\Support\Str::slug($category->category_name);
            }
        });

        static::updating(function ($category) {
            if ($category->isDirty('category_name') && empty($category->slug)) {
                $category->slug = \Illuminate\Support\Str::slug($category->category_name);
            }
        });
    }
}