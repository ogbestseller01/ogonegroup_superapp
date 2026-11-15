<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;

class MediaController extends Controller
{
    /**
     * Streams a public-disk file with HTTP Range support (206 Partial Content).
     * Required by iOS AVPlayer; Symfony's BinaryFileResponse handles Range automatically.
     */
    public function stream(string $path)
    {
        $path = ltrim($path, '/');

        // Only allow files inside posts/ and block traversal
        abort_if(str_contains($path, '..') || !str_starts_with($path, 'posts/'), 404);

        $disk = Storage::disk('public');
        abort_unless($disk->exists($path), 404);

        $full = $disk->path($path);

        return response()->file($full, [
            'Content-Type'  => mime_content_type($full) ?: 'video/mp4',
            'Accept-Ranges' => 'bytes',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }
}