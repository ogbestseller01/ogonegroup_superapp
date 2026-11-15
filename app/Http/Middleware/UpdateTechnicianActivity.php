<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Auth;

class UpdateTechnicianActivity
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);
        
        $user = Auth::user();
        if ($user && $user->technician) {
            $technician = $user->technician;
            // Update only if the request is not a GET? Better to update on every request.
            $technician->last_activity_at = now();
            $technician->is_online = true;
            $technician->save();
        }
        
        return $response;
    }
}