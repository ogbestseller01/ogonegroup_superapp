<?php
// app/Http/Middleware/CheckSubscription.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckSubscription
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        // Skip check for subscription routes
        $exemptRoutes = [
            'api/v16/rate-cards',
            'api/v16/payment-methods',
            'api/v16/subscriptions',
            'api/v16/check-subscription',
            'api/v16/my-subscriptions',
            'api/v16/my-invoices',
            'api/v16/invoices/*/download',
            'api/v16/admin/*',
        ];

        $path = $request->path();
        foreach ($exemptRoutes as $exempt) {
            if ($request->is($exempt)) {
                return $next($request);
            }
        }

        // Check if user has active subscription
        if (!$user || !$user->hasActiveSubscription()) {
            // If user is admin, allow access
            if ($user && $user->can('subscriptions.manage')) {
                return $next($request);
            }

            $message = 'Your subscription has expired or is inactive. Please renew to continue.';
            
            return response()->json([
                'success' => false,
                'message' => $message,
                'data' => [
                    'subscription_required' => true,
                    'status' => $user ? $user->subscription_status : 'inactive',
                    'expires_at' => $user ? $user->subscription_expires_at : null,
                    'renew_url' => '/subscriptions',
                ],
                'code' => 403,
            ], 403);
        }

        return $next($request);
    }
}