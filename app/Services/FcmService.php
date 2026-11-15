<?php

namespace App\Services;

use App\Models\Notification as NotificationModel;
use App\Models\User;
use App\Models\UserDeviceToken;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Exception\Messaging\NotFound;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FcmService
{
    public const SILENT_TYPES = ['chat_message'];

    protected $messaging = null;
    protected bool $enabled = false;

    public function __construct()
    {
        $this->enabled = (bool) config('firebase.send_notifications', true);

        if (!$this->enabled) {
            Log::debug('FCM notifications disabled in config.');
            return;
        }

        $credentialsPath = config('firebase.credentials');
        if (!$credentialsPath) {
            Log::warning('FCM credentials path not set in config.');
            return;
        }

        $credentials = str_starts_with($credentialsPath, '/')
            ? $credentialsPath
            : storage_path('app/' . $credentialsPath);

        if (!file_exists($credentials)) {
            Log::warning("FCM credentials file not found at: {$credentials}");
            return;
        }

        try {
            $this->messaging = (new Factory)->withServiceAccount($credentials)->createMessaging();
            Log::debug('FCM service initialized.');
        } catch (\Throwable $e) {
            Log::error('FCM initialization failed: ' . $e->getMessage());
            $this->messaging = null;
        }
    }

    public function isReady(): bool
    {
        return $this->enabled && $this->messaging !== null;
    }

    // ================================================================
    // SYSTEM UPDATE — SUPER APP ONLY
    // ================================================================

    public function sendSystemUpdate(User $user, \App\Models\SystemUpdate $update): array
    {
        if (!$this->isReady()) {
            return [
                'success' => false,
                'skipped' => true,
                'error'   => 'FCM disabled or not configured',
                'sent'    => 0,
                'failed'  => 0,
            ];
        }

        $tokens = $user->allSuperAppTokens();

        if (empty($tokens)) {
            return [
                'success' => false,
                'skipped' => true,
                'error'   => 'No super-app FCM token',
                'sent'    => 0,
                'failed'  => 0,
            ];
        }

        $title = trim((string) $update->title);
        $body  = \Illuminate\Support\Str::limit(trim((string) $update->description), 140);
        $ttl   = 60 * 60 * 24 * 28;

        $data = [
            'type'         => 'system_update',
            'update_id'    => (string) $update->id,
            'title'        => $title,
            'body'         => $body,
            'description'  => \Illuminate\Support\Str::limit(trim((string) $update->description), 500),
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ];

        $sent   = 0;
        $failed = 0;

        foreach ($tokens as $token) {
            $message = CloudMessage::new()
                ->withToken($token)
                ->withNotification(Notification::create($title, $body))
                ->withAndroidConfig([
                    'priority' => 'high',
                    'ttl'      => "{$ttl}s",
                    'notification' => [
                        'sound'        => 'default',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'channel_id'   => 'fundi_channel',
                    ],
                ])
                ->withApnsConfig([
                    'headers' => [
                        'apns-priority'   => '10',
                        'apns-push-type'  => 'alert',
                        'apns-expiration' => (string) (time() + $ttl),
                    ],
                    'payload' => ['aps' => [
                        'alert' => ['title' => $title, 'body' => $body],
                        'sound' => 'default',
                        'badge' => $this->unreadCountFor($user) + 1,
                    ]],
                ])
                ->withData($this->sanitizeData($data));

            if ($this->dispatch($message, $token)) {
                $sent++;
            } else {
                $failed++;
            }
        }

        return [
            'success' => $sent > 0,
            'skipped' => false,
            'sent'    => $sent,
            'failed'  => $failed,
            'error'   => $sent === 0 ? 'All super-app FCM sends failed' : null,
        ];
    }

    // ================================================================
    // CHAT — SUPER APP ONLY
    // ================================================================

    public function sendChatNotification($receiver, $sender, $message, $conversationId): bool
    {
        if (!$receiver || !$sender || !$message) {
            Log::warning('Missing data for chat notification');
            return false;
        }

        $tokens = $receiver instanceof User
            ? $receiver->allSuperAppTokens()
            : [];

        if (empty($tokens)) {
            return false;
        }

        $senderName = trim((string) ($sender->name ?? ''));
        $title      = $senderName !== '' ? $senderName : 'New Message';
        $body       = trim($this->getNotificationBody($message));

        $data = [
            'type'            => 'chat_message',
            'title'           => $title,
            'body'            => $body,
            'conversation_id' => (string) $conversationId,
            'message_id'      => (string) ($message->id ?? ''),
            'sender_id'       => (string) ($sender->id ?? ''),
            'sender_name'     => $senderName !== '' ? $senderName : 'Unknown',
            'msg_type'        => $message->message_type ?? 'text',
            'unread_count'    => (string) ($this->unreadCountFor($receiver) + 1),
            'timestamp'       => now()->toIso8601String(),
            'priority'        => 'high',
        ];

        $any = false;
        foreach ($tokens as $token) {
            if ($this->sendSilentDataToDevice($token, $data)) {
                $any = true;
            }
        }
        return $any;
    }

    // ================================================================
    // NOTIFICATION ROW — SUPER APP ONLY
    // ================================================================

    public function sendFromNotification(NotificationModel $notification): bool
    {
        $user = $notification->user;
        if (!$user) {
            Log::warning('Notification has no user', ['id' => $notification->id]);
            return false;
        }

        $tokens = $user->allSuperAppTokens();
        if (empty($tokens)) {
            Log::info('User has no super-app FCM token', ['user_id' => $user->id]);
            return false;
        }

        $title = trim((string) $notification->title);
        $body  = trim((string) $notification->body);

        if (!$this->isValidText($title) || !$this->isValidText($body)) {
            Log::error('Notification row has invalid title/body — push skipped', [
                'id'   => $notification->id,
                'type' => $notification->type,
            ]);
            return false;
        }

        $type = (string) ($notification->type ?? 'general');

        $data = array_merge(
            is_array($notification->data) ? $notification->data : [],
            [
                'type'            => $type,
                'notification_id' => (string) $notification->id,
                'title'           => $title,
                'body'            => $body,
                'click_action'    => 'FLUTTER_NOTIFICATION_CLICK',
            ]
        );

        $any = false;
        foreach ($tokens as $token) {
            $ok = in_array($type, self::SILENT_TYPES, true)
                ? $this->sendSilentDataToDevice($token, $data)
                : $this->sendVisible($token, $title, $body, $data, $this->unreadCountFor($user));

            if ($ok) {
                $any = true;
            }
        }
        return $any;
    }

    // ================================================================
    // LOW-LEVEL
    // ================================================================

    protected function sendVisible(
        string $deviceToken,
        string $title,
        string $body,
        array $data,
        int $badge
    ): bool {
        if (!$this->ready($deviceToken)) {
            return false;
        }

        $message = CloudMessage::new()
            ->withToken($deviceToken)
            ->withNotification(Notification::create($title, $body))
            ->withAndroidConfig([
                'priority'     => 'high',
                'notification' => [
                    'sound'                   => 'default',
                    'click_action'            => 'FLUTTER_NOTIFICATION_CLICK',
                    'channel_id'              => 'fundi_channel',
                    'notification_priority'   => 'PRIORITY_MAX',
                    'default_vibrate_timings' => true,
                ],
            ])
            ->withApnsConfig([
                'headers' => [
                    'apns-priority'  => '10',
                    'apns-push-type' => 'alert',
                ],
                'payload' => [
                    'aps' => [
                        'alert' => ['title' => $title, 'body' => $body],
                        'sound' => 'default',
                        'badge' => $badge,
                    ],
                ],
            ])
            ->withData($this->sanitizeData($data));

        return $this->dispatch($message, $deviceToken);
    }

    public function sendSilentDataToDevice(string $deviceToken, array $data = []): bool
    {
        if (!$this->ready($deviceToken)) {
            return false;
        }

        $message = CloudMessage::new()
            ->withToken($deviceToken)
            ->withAndroidConfig(['priority' => 'high'])
            ->withApnsConfig([
                'headers' => [
                    'apns-priority'  => '5',
                    'apns-push-type' => 'background',
                ],
                'payload' => ['aps' => ['content-available' => 1]],
            ])
            ->withData($this->sanitizeData($data));

        return $this->dispatch($message, $deviceToken);
    }

    protected function dispatch(CloudMessage $message, string $deviceToken): bool
    {
        try {
            $this->messaging->send($message);
            return true;
        } catch (NotFound $e) {
            Log::warning('FCM token invalid — deleting', ['suffix' => substr($deviceToken, -8)]);
            UserDeviceToken::where('token', $deviceToken)->delete();
            User::where('fcm_device_token', $deviceToken)->update(['fcm_device_token' => null]);
            return false;
        } catch (\Throwable $e) {
            Log::error('FCM send failed: ' . $e->getMessage());
            return false;
        }
    }

    protected function ready(string $deviceToken): bool
    {
        return $this->isReady() && $deviceToken !== '';
    }

    protected function isValidText(string $value): bool
    {
        return $value !== '' && !is_numeric($value);
    }

    protected function unreadCountFor($user): int
    {
        try {
            return (int) $user->notifications()
                ->where('is_read', false)
                ->where('type', '!=', 'chat_message')
                ->count();
        } catch (\Throwable $e) {
            return 0;
        }
    }

    protected function sanitizeData(array $data): array
    {
        $out = [];
        foreach ($data as $k => $v) {
            $out[$k] = match (true) {
                $v === null                     => '',
                is_bool($v)                     => $v ? 'true' : 'false',
                is_array($v), is_object($v)     => json_encode($v),
                default                         => (string) $v,
            };
        }
        return $out;
    }

    protected function getNotificationBody($message): string
    {
        if (empty($message) || !is_object($message)) {
            return 'New message';
        }
        return trim((string) ($message->content ?? 'New message'));
    }
}