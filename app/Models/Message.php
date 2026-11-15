<?php
// app/Models/Message.php  (REPLACES the old file)

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    use HasFactory;

    const TYPE_TEXT  = 'text';
    const TYPE_IMAGE = 'image';
    const TYPE_FILE  = 'file';
    const TYPE_VIDEO = 'video';

    protected $fillable = [
        'conversation_id', 'sender_id', 'receiver_id', 'sender_type', 'message_type',
        'content', 'file_name', 'file_path', 'file_size', 'file_mime_type', 'file_extension',
        'is_read', 'read_at', 'is_delivered', 'delivered_at',
        'reply_to_id', 'is_forwarded', 'meta_updated_at',
        'deleted_for_everyone_at', 'deleted_by', 'has_link', 'is_encrypted', 'encryption_version',
    ];

    protected $casts = [
        'is_read' => 'boolean', 'is_delivered' => 'boolean', 'is_forwarded' => 'boolean',
        'has_link' => 'boolean', 'is_encrypted' => 'boolean',
        'read_at' => 'datetime', 'delivered_at' => 'datetime', 'meta_updated_at' => 'datetime',
        'deleted_for_everyone_at' => 'datetime',
        'file_size' => 'integer',
    ];

    // ── Relationships ─────────────────────────────────────
    public function conversation() { return $this->belongsTo(Conversation::class); }
    public function sender()       { return $this->belongsTo(User::class, 'sender_id'); }
    public function receiver()     { return $this->belongsTo(User::class, 'receiver_id'); }
    public function reactions()    { return $this->hasMany(MessageReaction::class); }
    public function stars()        { return $this->hasMany(MessageStar::class); }
    public function pin()          { return $this->hasOne(MessagePin::class); }
    public function deletions()    { return $this->hasMany(MessageDeletion::class); }

    public function replyTo(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reply_to_id');
    }

    // ── Accessors ─────────────────────────────────────────
    public function getFileUrlAttribute(): ?string
    {
        return $this->file_path ? url('/api/v14/chat/messages/' . $this->id . '/file') : null;
    }

    public function getIsDeletedAttribute(): bool
    {
        return $this->deleted_for_everyone_at !== null;
    }

    /** True if the text contains an http(s) link. */
    public static function containsLink(?string $text): bool
    {
        return $text !== null && (bool) preg_match('~https?://[^\s]+~i', $text);
    }

    // ── Helpers ───────────────────────────────────────────
    public function markAsRead(): void
    {
        if (!$this->is_read) $this->update(['is_read' => true, 'read_at' => now()]);
    }

    public function getFormattedMessage(): array
    {
        $deleted = $this->is_deleted;

        $data = [
            'id'              => $this->id,
            'conversation_id' => $this->conversation_id,
            'sender_id'       => $this->sender_id,
            'sender_name'     => $this->sender->name ?? 'Unknown',
            'sender_type'     => $this->sender_type,
            'receiver_id'     => $this->receiver_id,
            'message_type'    => $this->message_type,
            'content'         => $deleted ? null : $this->content,
            'is_deleted'      => $deleted,
            'is_encrypted'    => (bool) $this->is_encrypted,
            'is_read'         => (bool) $this->is_read,
            'is_forwarded'    => (bool) $this->is_forwarded,
            'read_at'         => $this->read_at?->toIso8601String(),
            'created_at'      => $this->created_at?->toIso8601String(),
        ];

        if (!$deleted && $this->file_path) {
            $data['file'] = [
                'url' => $this->file_url, 'name' => $this->file_name, 'size' => $this->file_size,
                'mime_type' => $this->file_mime_type, 'extension' => $this->file_extension,
            ];
        }
        return $data;
    }

    // ── Scopes ────────────────────────────────────────────
    public function scopeUnread($q) { return $q->where('is_read', false); }

    public function scopeForUser($q, $userId)
    {
        return $q->where(fn ($x) => $x->where('sender_id', $userId)->orWhere('receiver_id', $userId));
    }

    /** Hides messages the user deleted "for me". */
    public function scopeVisibleTo($q, $userId)
    {
        return $q->whereNotExists(function ($sub) use ($userId) {
            $sub->selectRaw('1')->from('message_deletions')
                ->whereColumn('message_deletions.message_id', 'messages.id')
                ->where('message_deletions.user_id', $userId);
        });
    }
}
