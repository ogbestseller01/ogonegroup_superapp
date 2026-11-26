<?php

namespace App\Services;

use App\Mail\LoginNotificationMail;
use App\Models\LoginHistory;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

/**
 * Login detection: after every successful sign-in it
 *   1) records a row in login_histories, and
 *   2) emails the user (Blade view emails.login-notification).
 * Runs AFTER the HTTP response and never breaks a login.
 */
class LoginNotificationService
{
    private const TZ = 'Africa/Dar_es_Salaam';

    /** Call right after a successful sign-in. $method: password|google|apple|otp|quick-login */
    public static function dispatch(User $user, Request $request, string $method = 'password'): void
    {
        $ctx = [
            'user_id' => $user->id,
            'ip'      => (string) $request->ip(),
            'ua'      => (string) $request->userAgent(),
            'device'  => self::deviceFrom($request),
            'method'  => $method,
            'at'      => now()->toIso8601String(),
        ];

        try {
            dispatch(function () use ($ctx) {
                app(LoginNotificationService::class)->handle($ctx);
            })->afterResponse();
        } catch (Throwable $e) {
            Log::warning('Login notification dispatch failed', ['error' => $e->getMessage()]);
        }
    }

    public function handle(array $ctx): void
    {
        try {
            $user = User::find($ctx['user_id']);
            if (!$user) {
                return;
            }

            $location = $this->locate($ctx['ip']);

            $history = null;
            try {
                $history = LoginHistory::create([
                    'user_id'    => $user->id,
                    'method'     => $ctx['method'],
                    'ip_address' => $ctx['ip'] ?: null,
                    'device'     => mb_substr($ctx['device'], 0, 150),
                    'user_agent' => mb_substr($ctx['ua'], 0, 500),
                    'location'   => $location,
                ]);
            } catch (Throwable $e) {
                Log::warning('Login history write failed', ['error' => $e->getMessage()]);
            }

            if (empty($user->email)) {
                return;
            }

            $details = [
                'when'     => \Carbon\Carbon::parse($ctx['at'])->timezone(self::TZ)->format('d M Y, H:i') . ' (EAT)',
                'device'   => $ctx['device'] ?: 'Unknown',
                'ip'       => $ctx['ip'] ?: 'Unknown',
                'location' => $location ?: 'Unknown',
                'method'   => $this->methodLabel($ctx['method']),
            ];

            Mail::to($user->email)->send(new LoginNotificationMail($user->name, $details));

            $history?->update(['email_sent_at' => now()]);
        } catch (Throwable $e) {
            Log::warning('Login notification email failed', ['error' => $e->getMessage()]);
        }
    }

    /** Human device label: app header first, user-agent as fallback. */
    public static function deviceFrom(Request $request): string
    {
        return self::deviceLabel(
            (string) $request->header('X-Client-Device', ''),
            (string) $request->userAgent()
        );
    }

    public static function deviceLabel(string $clientDevice, string $ua): string
    {
        if ($clientDevice !== '') {
            return mb_substr($clientDevice, 0, 120);
        }

        $os = match (true) {
            str_contains($ua, 'Android')                           => 'Android',
            str_contains($ua, 'iPhone'), str_contains($ua, 'iPad') => 'iOS',
            str_contains($ua, 'Windows')                           => 'Windows',
            str_contains($ua, 'Mac OS')                            => 'macOS',
            str_contains($ua, 'Linux')                             => 'Linux',
            default                                                => null,
        };

        $browser = match (true) {
            str_contains($ua, 'Edg')     => 'Edge',
            str_contains($ua, 'Firefox') => 'Firefox',
            str_contains($ua, 'Chrome')  => 'Chrome',
            str_contains($ua, 'Safari')  => 'Safari',
            str_contains($ua, 'Dart')    => 'NearbyFundi app',
            default                      => null,
        };

        return trim(($browser ?? 'Unknown app') . ($os ? " on {$os}" : ''));
    }

    private function methodLabel(string $method): string
    {
        return match ($method) {
            'google'      => 'Google sign-in',
            'apple'       => 'Apple sign-in',
            'otp'         => 'Account verification',
            'quick-login' => 'One-tap login (remembered device)',
            default       => 'Password',
        };
    }

    private function locate(string $ip): ?string
    {
        if (!filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
            return null;
        }

        return Cache::remember("ip-geo:{$ip}", now()->addDay(), function () use ($ip) {
            try {
                $r = Http::timeout(2)->get("http://ip-api.com/json/{$ip}", ['fields' => 'status,country,city']);
                if ($r->ok() && $r->json('status') === 'success') {
                    return trim(implode(', ', array_filter([$r->json('city'), $r->json('country')])));
                }
            } catch (Throwable $e) {
                // location is best-effort only
            }
            return null;
        });
    }
}