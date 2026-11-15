<?php

namespace App\Providers;

use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\ServiceProvider;

class BroadcastServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // ✅ FIX: without this, Broadcast::routes() defaults to the 'web'
        // (session/cookie) guard, which a token-authenticated mobile app can
        // never satisfy — every private-channel subscription would fail with
        // a 401/403. This mounts the auth route at POST /broadcasting/auth
        // (prefix defaults to 'broadcasting' since we didn't override it)
        // and authenticates it the same way as the rest of your API.
        Broadcast::routes([
            'middleware' => ['auth:sanctum', 'active.session'],
        ]);

        require base_path('routes/channels.php');
    }
}