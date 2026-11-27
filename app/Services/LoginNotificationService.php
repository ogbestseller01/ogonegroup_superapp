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
        // Everything that depends on the request is read HERE, before the
        // response is sent: the queued closure only gets plain values.
        $ctx = [
            'user_id' => $user->id,
            'ip'      => (string) $request->ip(),
            'ua'      => (string) $request->userAgent(),
            'device'  => self::deviceFrom($request),
            'app'     => self::appNameFrom($request),
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
                'app'      => $ctx['app'] ?? 'Nearby Fundi',
                'when'     => \Carbon\Carbon::parse($ctx['at'])->timezone(self::TZ)->format('d M Y, H:i') . ' (EAT)',
                'device'   => $ctx['device'] ?: 'Unknown device',
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

    // ──────────────────────────────────────────────
    // DEVICE / APP DETECTION
    // ──────────────────────────────────────────────

    /** Brand shown in the email: "Fundi App" or "Nearby Fundi". */
    public static function appNameFrom(Request $request): string
    {
        $app = strtolower(trim((string) $request->header('X-App', '')));
        $ua  = (string) $request->userAgent();

        return match (true) {
            $app === 'fundi'    || str_contains($ua, 'FundiApp') => 'Fundi App',
            default                                              => 'Nearby Fundi',
        };
    }

    /**
     * Human device label for the email, login history and sessions list.
     * Priority: exact device sent by the app -> user-agent guess.
     */
    public static function deviceFrom(Request $request): string
    {
        return self::deviceLabel(
            (string) $request->header('X-Client-Device', ''),
            (string) $request->userAgent(),
            self::clean($request->header('X-Device-Model')),
            self::clean($request->header('X-Device-OS')),
            strtolower(self::clean($request->header('X-App'), 20))
        );
    }

    public static function deviceLabel(
        string $clientDevice,
        string $ua,
        string $model = '',
        string $os = '',
        string $app = ''
    ): string {
        // 0) Legacy header, kept for any client that already sends it.
        if ($clientDevice !== '') {
            return mb_substr(self::clean($clientDevice, 120), 0, 120);
        }

        $appName = match (true) {
            $app === 'fundi'    || str_contains($ua, 'FundiApp')    => 'Fundi App',
            $app === 'customer' || str_contains($ua, 'NearbyFundi') => 'Nearby Fundi app',
            default => null,
        };

        // 1) Best case: the app told us the exact device.
        if ($model !== '') {
            $device = self::friendlyModel($model);
            $label  = $os !== '' ? "{$device} ({$os})" : $device;

            return $appName ? "{$appName} · {$label}" : $label;
        }

        // 2) Native-app user-agents without model info.
        if (str_contains($ua, 'Postman')) {
            return 'Postman';
        }

        if (preg_match('/\((ios|android)\)/i', $ua, $m)) {
            $platform = strtolower($m[1]) === 'ios' ? 'iPhone / iPad' : 'Android phone';
            return $appName ? "{$appName} · {$platform}" : $platform;
        }

        if (str_contains($ua, 'okhttp'))           return 'Android phone';
        if (preg_match('/CFNetwork|Darwin/', $ua)) return 'iPhone / iPad';
        if (str_starts_with($ua, 'Dart/'))         return $appName ?? 'Mobile app';

        // 3) Browsers.
        if (str_contains($ua, 'Mozilla')) {
            $browser = match (true) {
                str_contains($ua, 'Edg/')    => 'Edge',
                str_contains($ua, 'OPR/')    => 'Opera',
                str_contains($ua, 'Firefox') => 'Firefox',
                str_contains($ua, 'Chrome')  => 'Chrome',
                str_contains($ua, 'Safari')  => 'Safari',
                default                      => 'Browser',
            };

            // Order matters: iPhone UAs contain "Mac OS X", Android UAs "Linux".
            $system = match (true) {
                str_contains($ua, 'iPhone') || str_contains($ua, 'iPad') => 'iOS',
                str_contains($ua, 'Android')   => 'Android',
                str_contains($ua, 'Windows')   => 'Windows',
                str_contains($ua, 'Macintosh') => 'macOS',
                str_contains($ua, 'Linux')     => 'Linux',
                default => null,
            };

            return $system ? "{$browser} on {$system}" : $browser;
        }

        return 'Unknown device';
    }

    /** Header values come from the client: strip odd characters, cap length. */
    private static function clean(?string $value, int $max = 60): string
    {
        $v = preg_replace('/[^\p{L}\p{N} ,._\-\(\)\/·]/u', '', (string) $value) ?? '';

        return trim(mb_substr($v, 0, $max));
    }

    /** iOS sends a code like "iPhone17,3"; show a name people recognise. */
    private static function friendlyModel(string $model): string
    {
        static $iphones = [
            'iPhone14,7' => 'iPhone 14',      'iPhone14,8' => 'iPhone 14 Plus',
            'iPhone15,2' => 'iPhone 14 Pro',  'iPhone15,3' => 'iPhone 14 Pro Max',
            'iPhone15,4' => 'iPhone 15',      'iPhone15,5' => 'iPhone 15 Plus',
            'iPhone16,1' => 'iPhone 15 Pro',  'iPhone16,2' => 'iPhone 15 Pro Max',
            'iPhone17,1' => 'iPhone 16 Pro',  'iPhone17,2' => 'iPhone 16 Pro Max',
            'iPhone17,3' => 'iPhone 16',      'iPhone17,4' => 'iPhone 16 Plus',
            'iPhone17,5' => 'iPhone 16e',
        ];

        if (isset($iphones[$model]))           return $iphones[$model];
        if (str_starts_with($model, 'iPhone')) return 'iPhone';   // newer / unmapped
        if (str_starts_with($model, 'iPad'))   return 'iPad';

        return $model; // Android: "Samsung SM-A546E"
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

    // ──────────────────────────────────────────────
    // LOCATION
    // ──────────────────────────────────────────────

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