<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class NewActivityNotification extends Notification
{
    use Queueable;

    /** Types that must never trigger a system tray banner. */
    public const SILENT_TYPES = ['chat_message'];

    protected string $title;
    protected string $body;
    protected string $type;
    protected int $unreadCount;
    protected array $extraData;
    protected bool $isSilent;

    public function __construct(
        string $title,
        string $body,
        string $type = 'general',
        int $unreadCount = 0,
        array $extraData = []
    ) {
        $this->type     = $type !== '' ? $type : 'general';
        $this->isSilent = in_array($this->type, self::SILENT_TYPES, true);

        $safeTitle = trim($title);
        $safeBody  = trim($body);

        $this->title = ($safeTitle !== '' && !is_numeric($safeTitle))
            ? $safeTitle
            : config('app.name', 'NearbyFundi');

        $this->body = ($safeBody !== '' && !is_numeric($safeBody))
            ? $safeBody
            : 'You have a new update';

        $this->unreadCount = max(0, $unreadCount);

        unset($extraData['unread_count']);
        $this->extraData = $extraData;
    }

    /**
     * Only the database channel — FCM is handled separately by FcmService,
     * which uses the already-installed `kreait/firebase-php` package.
     */
    public function via($notifiable): array
    {
        return ['database'];
    }

    public function toArray($notifiable): array
    {
        return [
            'title' => $this->title,
            'body'  => $this->body,
            'type'  => $this->type,
            'data'  => $this->extraData,
        ];
    }
}