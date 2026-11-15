<?php

namespace App\Http\Middleware;

use App\Models\UserSession;
use Closure;
use Illuminate\Http\Request;

class EnforceActiveSession
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $tokenId = $user->currentAccessToken()->id;

        $session = UserSession::where('user_id', $user->id)
            ->where('token', $tokenId)
            ->where('is_active', true)
            ->first();

        if (!$session) {
            // Token exists but session was killed (force-logout)
            $user->currentAccessToken()->delete();
            return response()->json(['message' => 'Session expired. Please log in again.'], 401);
        }

        // Keep last_activity fresh (like Instagram's "active now")
        $session->update(['last_activity' => now()]);

        return $next($request);
    }
}