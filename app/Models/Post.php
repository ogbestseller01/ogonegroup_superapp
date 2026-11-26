<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Post extends Model
{
    protected $fillable = [
        'technician_id',
        'images',
    ];

    protected $casts = [
        'images' => 'array',
    ];

    // Full public URLs for all images
    public function getImageUrlsAttribute(): array
    {
        if (empty($this->images) || !is_array($this->images)) {
            return [];
        }
        return array_map(fn($path) => $path ? url('storage/' . $path) : null, $this->images);
    }

    // Delete physical files when post is deleted
    protected static function booted()
    {
        static::deleting(function (Post $post) {
            if (!empty($post->images) && is_array($post->images)) {
                foreach ($post->images as $path) {
                    if ($path && Storage::disk('public')->exists($path)) {
                        Storage::disk('public')->delete($path);
                    }
                }
            }
        });
    }

    public function technician()
    {
        return $this->belongsTo(Technician::class);
    }

    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    public function likes()
    {
        return $this->hasMany(Like::class);
    }
}