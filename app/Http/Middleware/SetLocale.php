<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Auth;

class SetLocale
{
    public function handle($request, Closure $next)
    {
        // 1. Check if authenticated user has a saved locale
        if (Auth::check() && Auth::user()->locale) {
            App::setLocale(Auth::user()->locale);
        }
        // 2. Fallback to Accept-Language header from request
        elseif ($request->hasHeader('Accept-Language')) {
            $locale = $request->header('Accept-Language');
            if (in_array($locale, ['en', 'sw'])) {
                App::setLocale($locale);
            }
        }
        // 3. Default to English
        else {
            App::setLocale('en');
        }

        return $next($request);
    }
}