<?php

namespace App\Services;

use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\Storage;

class BiometricService
{
    public function storeFingerprint(string $template): array
    {
        return [
            'template' => Crypt::encryptString($template),
            'hash'     => hash('sha256', $template),
        ];
    }

    public function storeFaceImage($file): string
    {
        return $file->store('technician_faces', 'private');
    }
}