<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class FailedLoginAttempt extends Model
{
    protected $table = 'failed_login_attempts';

    protected $fillable = ['login', 'email', 'ip_address', 'attempt_count', 'last_attempt_at'];

    protected $casts = [
        'last_attempt_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'attempt_count' => 'integer',
    ];

    /**
     * Record a failed login attempt
     */
    public static function record(string $login, string $ip): self
    {
        $attempt = static::where('login', $login)
            ->where('ip_address', $ip)
            ->first();

        if ($attempt) {
            $attempt->increment('attempt_count');
            $attempt->last_attempt_at = Carbon::now();
            $attempt->save();
            
            return $attempt;
        }

        return static::create([
            'login' => $login,
            'email' => $login, // Set email same as login for compatibility
            'ip_address' => $ip,
            'attempt_count' => 1,
            'last_attempt_at' => Carbon::now(),
        ]);
    }

    /**
     * Get total attempts for a login within time window
     */
    public static function getAttempts(string $login, int $minutes = 30): int
    {
        return static::where('login', $login)
            ->where('last_attempt_at', '>', Carbon::now()->subMinutes($minutes))
            ->sum('attempt_count');
    }

    /**
     * Check if account should be locked
     */
    public static function isLocked(string $login, int $maxAttempts = 5, int $minutes = 30): bool
    {
        return static::getAttempts($login, $minutes) >= $maxAttempts;
    }

    /**
     * Clear all attempts for a login
     */
    public static function clearAttempts(string $login): void
    {
        static::where('login', $login)->delete();
    }

    /**
     * Get recent attempts for a login
     */
    public static function getRecentAttempts(string $login, int $minutes = 30): int
    {
        return static::getAttempts($login, $minutes);
    }

    /**
     * Scope for recent attempts
     */
    public function scopeRecent($query, int $minutes = 30)
    {
        return $query->where('last_attempt_at', '>', Carbon::now()->subMinutes($minutes));
    }

    /**
     * Scope for a specific login
     */
    public function scopeForLogin($query, string $login)
    {
        return $query->where('login', $login);
    }
}