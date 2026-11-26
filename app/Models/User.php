<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;
use Illuminate\Database\Eloquent\SoftDeletes;
use Carbon\Carbon;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles, SoftDeletes;

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'status',
        'is_active',
        'created_by',
        'last_login_ip',
        'last_login_device',
        'last_login_at',
        'locale',
        'email_verified_at',
        'phone_verified_at',
        'subscription_status',
        'subscription_expires_at',
        'current_subscription_id',
        'fcm_device_token',
        'locked_until',
    ];

    // google_id / apple_id are deliberately NOT mass-assignable:
    // SocialAuthController sets them with forceFill() after verifying the token.
    protected $hidden = [
        'password',
        'remember_token',
        'google_id',
    ];

    protected $casts = [
        'email_verified_at'       => 'datetime',
        'phone_verified_at'       => 'datetime',
        'last_login_at'           => 'datetime',
        'locked_until'            => 'datetime',
        'is_active'               => 'boolean',
        'subscription_expires_at' => 'datetime',
    ];

    public function getLocaleAttribute($value)
    {
        return $value ?: 'en';
    }

    // ── Verification helpers ──────────────────────────────
    public function hasVerifiedPhone(): bool
    {
        return !is_null($this->phone_verified_at);
    }

    public function hasVerifiedEmail(): bool
    {
        return !is_null($this->email_verified_at);
    }

    // ── Relationships ─────────────────────────────────────
    public function technician()          { return $this->hasOne(Technician::class); }
    public function customerRequests()    { return $this->hasMany(ServiceRequest::class, 'customer_id'); }
    public function comments()            { return $this->hasMany(Comment::class); }
    public function likes()               { return $this->hasMany(Like::class); }
    public function sessions()            { return $this->hasMany(UserSession::class); }
    public function auditTrails()         { return $this->hasMany(AuditTrail::class); }

    /** Every successful sign-in (see login_histories table). */
    public function loginHistories()
    {
        return $this->hasMany(LoginHistory::class)->orderByDesc('created_at');
    }

    /** "Remember me" tokens (only usable at /v1/auth/quick-login). */
    public function rememberTokens()
    {
        return $this->tokens()->where('name', 'remember_token');
    }

    public function conversationsAsCustomer() { return $this->hasMany(Conversation::class, 'customer_id'); }
    public function conversationsAsFundi()    { return $this->hasMany(Conversation::class, 'fundi_id'); }

    public function allConversations()
    {
        return Conversation::where('customer_id', $this->id)
            ->orWhere('fundi_id', $this->id);
    }

    public function sentMessages()     { return $this->hasMany(Message::class, 'sender_id'); }
    public function receivedMessages() { return $this->hasMany(Message::class, 'receiver_id'); }

    public function getUnreadMessagesCount()
    {
        return Message::where('receiver_id', $this->id)->where('is_read', false)->count();
    }

    public function notifications()       { return $this->hasMany(Notification::class)->orderBy('created_at', 'desc'); }
    public function unreadNotifications() { return $this->hasMany(Notification::class)->where('is_read', false); }

    public function subscriptions()
    {
        return $this->hasMany(Subscription::class)->orderBy('created_at', 'desc');
    }

    public function activeSubscription()
    {
        return $this->hasOne(Subscription::class)
            ->where('status', Subscription::STATUS_ACTIVE)
            ->where(function ($q) {
                $q->whereNull('expiry_date')->orWhere('expiry_date', '>', now());
            })
            ->latest();
    }

    public function currentSubscription() { return $this->belongsTo(Subscription::class, 'current_subscription_id'); }
    public function invoices()            { return $this->hasMany(Invoice::class)->orderBy('created_at', 'desc'); }

    // ── Device token relationships ────────────────────────
    public function deviceTokens()
    {
        return $this->hasMany(UserDeviceToken::class);
    }

    public function superAppDeviceTokens()
    {
        return $this->deviceTokens()->where('app', UserDeviceToken::APP_SUPER);
    }

    /**
     * Most recent super-app FCM token, or null.
     * Used by push (FcmService) — never returns mini-app tokens.
     */
    public function fcmTokenForSuperApp(): ?string
    {
        $tokens = $this->superAppDeviceTokens()
            ->orderByDesc('last_seen_at')
            ->orderByDesc('id')
            ->pluck('token')
            ->all();

        if (!empty($tokens)) {
            return $tokens[0];
        }

        // Legacy fallback: single-token column
        return $this->fcm_device_token ?: null;
    }

    public function allSuperAppTokens(): array
    {
        $tokens = $this->superAppDeviceTokens()
            ->orderByDesc('last_seen_at')
            ->orderByDesc('id')
            ->pluck('token')
            ->all();

        if (empty($tokens) && !empty($this->fcm_device_token)) {
            $tokens = [(string) $this->fcm_device_token];
        }

        return array_values(array_unique(array_filter($tokens)));
    }

    // ── Subscription helpers ──────────────────────────────
    public function hasActiveSubscription(): bool
    {
        if ($this->subscription_status !== 'active') return false;
        if ($this->subscription_expires_at === null) return true;
        return Carbon::now()->lt($this->subscription_expires_at);
    }

    public function isSubscriptionExpired(): bool
    {
        if ($this->subscription_status === 'expired') return true;
        if ($this->subscription_expires_at === null) return false;
        return Carbon::now()->gt($this->subscription_expires_at);
    }

    public function isAccountLocked(): bool
    {
        return in_array($this->subscription_status, ['expired', 'inactive']) ||
               ($this->subscription_status === 'active' && $this->isSubscriptionExpired());
    }

    public function lockAccount(): void
    {
        $this->update(['subscription_status' => 'expired']);
    }

    public function activateSubscription(Subscription $subscription): void
    {
        $this->update([
            'subscription_status'     => 'active',
            'subscription_expires_at' => $subscription->expiry_date,
            'current_subscription_id' => $subscription->id,
        ]);
    }

    public function hasValidSubscription(): bool
    {
        return $this->hasActiveSubscription();
    }

    public function getSubscriptionDaysRemaining(): ?int
    {
        if ($this->subscription_expires_at === null) return null;
        $diff = Carbon::now()->diffInDays($this->subscription_expires_at, false);
        return $diff < 0 ? 0 : $diff;
    }

    public function getFormattedExpiryDate(): ?string
    {
        return $this->subscription_expires_at
            ? Carbon::parse($this->subscription_expires_at)->format('M d, Y')
            : null;
    }
}