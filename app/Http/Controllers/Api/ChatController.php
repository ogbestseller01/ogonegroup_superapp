<?php
// app/Http/Controllers/Api/ChatController.php  (COMPLETE – replaces the old file)

namespace App\Http\Controllers\Api;

use App\Models\Conversation;
use App\Models\ConversationHistory;
use App\Models\ConversationUserState;
use App\Models\Message;
use App\Models\MessagePin;
use App\Models\MessageReaction;
use App\Models\MessageStar;
use App\Models\Notification;
use App\Models\User;
use App\Services\ConversationPresenter;
use App\Services\FcmService;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class ChatController extends BaseApiController
{
    private const MAX_IMAGE_KB = 5120;    // 5 MB
    private const MAX_VIDEO_KB = 20480;   // 20 MB
    private const MAX_FILE_KB  = 15360;   // 15 MB
    private const MAX_PINS     = 3;

    /** Any file is allowed except executables / scripts. Keep in sync with the app. */
    private const BLOCKED_EXTENSIONS = [
        'php', 'phtml', 'phar', 'exe', 'bat', 'cmd', 'com', 'sh', 'js',
        'html', 'htm', 'svg', 'jar', 'apk', 'msi', 'dll', 'vbs', 'ps1', 'py',
    ];

    private const IMAGE_MIMES = [
        'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif',
    ];

    public function __construct(
        protected FcmService $fcmService,
        protected ConversationPresenter $presenter
    ) {
    }

    // ============================================================
    // CONVERSATIONS
    // ============================================================

    public function getOrCreateConversation(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_id' => 'required|integer|exists:users,id',
            'fundi_id'    => 'required|integer|exists:users,id|different:customer_id',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors()->first(), 422);
        }

        $user = $request->user();

        if ((int) $user->id !== (int) $request->customer_id && (int) $user->id !== (int) $request->fundi_id) {
            return $this->forbidden('Unauthorized to access this conversation.');
        }
        if ($user->hasRole('CUSTOMER') && (int) $user->id !== (int) $request->customer_id) {
            return $this->forbidden('Customers can only open chats as the customer.');
        }
        if ($user->hasRole('FUNDI') && (int) $user->id !== (int) $request->fundi_id) {
            return $this->forbidden('Fundis can only open chats as the fundi.');
        }

        $conversation = Conversation::firstOrCreate(
            ['customer_id' => $request->customer_id, 'fundi_id' => $request->fundi_id],
            ['is_active' => true]
        );

        return $this->successResponse(
            $this->presenter->present(collect([$conversation]), $user)[0],
            'Conversation retrieved.'
        );
    }

    public function getConversations(Request $request)
    {
        $user = $request->user();

        $conversations = Conversation::forUser($user->id)
            ->has('messages')
            ->get();

        return $this->successResponse(
            $this->presenter->present($conversations, $user),
            'Conversations retrieved.'
        );
    }

    public function deleteConversation(Request $request, $conversationId)
    {
        $user         = $request->user();
        $conversation = Conversation::find($conversationId);

        if (!$conversation) {
            return $this->notFound('Conversation not found.');
        }
        if (!$this->isParticipant($conversation, $user)) {
            return $this->forbidden('Unauthorized to delete this conversation.');
        }

        DB::transaction(function () use ($conversation, $user, $request) {
            $q = Message::where('conversation_id', $conversation->id);

            // Audit row first (metadata only, never message content)
            ConversationHistory::create([
                'conversation_id'         => $conversation->id,
                'customer_id'             => $conversation->customer_id,
                'fundi_id'                => $conversation->fundi_id,
                'deleted_by'              => $user->id,
                'deleted_by_role'         => (int) $user->id === (int) $conversation->customer_id ? 'customer' : 'fundi',
                'message_count'           => (clone $q)->count(),
                'media_count'             => (clone $q)->whereIn('message_type', ['image', 'video', 'file'])->count(),
                'first_message_at'        => (clone $q)->min('created_at'),
                'last_message_at'         => $conversation->last_message_at,
                'conversation_created_at' => $conversation->created_at,
                'deleted_at'              => now(),
                'ip_address'              => $request->ip(),
                'user_agent'              => Str::limit((string) $request->userAgent(), 250, ''),
            ]);

            $ids = Message::where('conversation_id', $conversation->id)->pluck('id');

            Message::where('conversation_id', $conversation->id)
                ->whereNotNull('file_path')
                ->get()
                ->each(fn ($m) => $this->deleteStoredFile($m->file_path));

            ConversationUserState::where('conversation_id', $conversation->id)->delete();
            MessagePin::where('conversation_id', $conversation->id)->delete();
            MessageStar::whereIn('message_id', $ids)->delete();
            MessageReaction::whereIn('message_id', $ids)->delete();

            Message::where('conversation_id', $conversation->id)->delete();
            $conversation->delete();
        });

        return $this->successResponse(['conversation_id' => (int) $conversationId, 'deleted' => true], 'Conversation deleted.');
    }

    // ============================================================
    // MESSAGES
    // ============================================================

    /**
     * Query params:
     *   after_id  -> only messages newer than this id (polling)
     *   since     -> (with after_id) also return older messages changed after this time
     *                (reactions, delete-for-everyone)
     *   before_id -> older page (scroll up)
     *   until_id  -> (with before_id) load EVERYTHING from until_id up to before_id
     *   limit     -> page size (default 30, max 100)
     * Messages are always returned oldest -> newest.
     * Also returns: peer_typing, peer_read_upto, pins, updates, server_time.
     */
    public function getMessages(Request $request, $conversationId)
    {
        $user         = $request->user();
        $conversation = Conversation::find($conversationId);

        if (!$conversation) {
            return $this->notFound('Conversation not found.');
        }
        if (!$this->isParticipant($conversation, $user)) {
            return $this->forbidden('Unauthorized to view this conversation.');
        }

        $meId  = (int) $user->id;
        $limit = max(1, min((int) $request->input('limit', 30), 100));

        $query = Message::with(['sender:id,name', 'replyTo.sender:id,name'])
            ->where('conversation_id', $conversation->id)
            ->visibleTo($meId); // hides messages I deleted "for me"
        $hasMore = false;

        if ($request->filled('after_id')) {
            $messages = $query->where('id', '>', (int) $request->after_id)
                ->orderBy('id')->limit(100)->get();
        } elseif ($request->filled('until_id') && $request->filled('before_id')) {
            $messages = $query->where('id', '<', (int) $request->before_id)
                ->where('id', '>=', (int) $request->until_id)
                ->orderByDesc('id')->limit(500)->get()->reverse()->values();

            $minId   = $messages->first()?->id ?? (int) $request->before_id;
            $hasMore = Message::where('conversation_id', $conversation->id)
                ->visibleTo($meId)
                ->where('id', '<', $minId)->exists();
        } else {
            if ($request->filled('before_id')) {
                $query->where('id', '<', (int) $request->before_id);
            }
            $rows     = $query->orderByDesc('id')->limit($limit + 1)->get();
            $hasMore  = $rows->count() > $limit;
            $messages = $rows->take($limit)->reverse()->values();
        }

        // Older messages that changed since the last poll (reactions / deleted for everyone)
        $updates = [];
        if ($request->filled('after_id') && $request->filled('since')) {
            try {
                $since   = Carbon::parse($request->since);
                $changed = Message::with(['sender:id,name', 'replyTo.sender:id,name'])
                    ->where('conversation_id', $conversation->id)
                    ->visibleTo($meId)
                    ->where('meta_updated_at', '>', $since)
                    ->limit(100)->get();
                $updates = $this->presentMany($changed, $meId, $conversation->id);
            } catch (\Throwable $e) {
                $updates = [];
            }
        }

        // Everything the current user received is now read
        Message::where('conversation_id', $conversation->id)
            ->where('receiver_id', $user->id)
            ->where('is_read', false)
            ->update([
                'is_read'      => true,
                'read_at'      => now(),
                'is_delivered' => true,
                'delivered_at' => now(),
            ]);

        // Highest id of MY messages that the other person has read (for ✓✓)
        $peerReadUpTo = (int) Message::where('conversation_id', $conversation->id)
            ->where('sender_id', $user->id)
            ->where('is_read', true)
            ->max('id');

        $peerId = (int) $conversation->customer_id === $meId
            ? (int) $conversation->fundi_id
            : (int) $conversation->customer_id;

        return $this->successResponse([
            'messages'       => $this->presentMany($messages, $meId, $conversation->id),
            'has_more'       => $hasMore,
            'peer_read_upto' => $peerReadUpTo,
            'peer_typing'    => Cache::has($this->typingKey($conversation->id, $peerId)),
            'pins'           => $this->pinsFor($conversation, $meId),
            'updates'        => $updates,
            // 1s overlap so a change made during this request is never missed
            'server_time'    => now()->subSecond()->toIso8601String(),
        ], 'Messages retrieved.');
    }

    public function sendMessage(Request $request)
    {
        $encrypted = $request->boolean('is_encrypted');

        $validator = Validator::make($request->all(), [
            'conversation_id' => 'required|integer|exists:conversations,id',
            'content'         => 'nullable|string|max:' . ($encrypted ? 8000 : 2000),
            'is_encrypted'    => 'nullable|boolean',
            'reply_to_id'     => 'nullable|integer',
            'file'            => 'nullable|file|max:' . self::MAX_VIDEO_KB,
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors()->first(), 422);
        }

        $user         = $request->user();
        $conversation = Conversation::find($request->conversation_id);

        if (!$conversation || !$this->isParticipant($conversation, $user)) {
            return $this->forbidden('Unauthorized to send messages.');
        }

        $content = trim((string) $request->input('content', ''));
        if ($content === '' && !$request->hasFile('file')) {
            return $this->errorResponse('Write a message or attach a file.', 422);
        }

        // Reply target must belong to the same conversation and must not be deleted.
        $replyToId = null;
        if ($request->filled('reply_to_id')) {
            $replyToId = Message::where('id', (int) $request->reply_to_id)
                ->where('conversation_id', $conversation->id)
                ->whereNull('deleted_for_everyone_at')
                ->value('id');
        }

        $isCustomer = (int) $user->id === (int) $conversation->customer_id;
        $receiverId = $isCustomer ? $conversation->fundi_id : $conversation->customer_id;

        $type     = Message::TYPE_TEXT;
        $fileData = [];

        try {
            if ($request->hasFile('file')) {
                $file = $request->file('file');
                if (!$file->isValid()) {
                    return $this->errorResponse('The upload failed. Please try again.', 422);
                }
                [$type, $fileData] = $this->storeUpload($file);
            }

            $message = DB::transaction(function () use ($conversation, $user, $receiverId, $isCustomer, $type, $content, $fileData, $replyToId, $encrypted) {
                $message = Message::create(array_merge([
                    'conversation_id'    => $conversation->id,
                    'reply_to_id'        => $replyToId,
                    'sender_id'          => $user->id,
                    'receiver_id'        => $receiverId,
                    'sender_type'        => $isCustomer ? 'customer' : 'fundi',
                    'message_type'       => $type,
                    'content'            => $content,
                    'has_link'           => !$encrypted && Message::containsLink($content),
                    'is_encrypted'       => $encrypted,
                    'encryption_version' => $encrypted ? 1 : null,
                    'is_read'            => false,
                    'is_delivered'       => false,
                ], $fileData));

                $conversation->update(['last_message_at' => now()]);

                return $message;
            });
        } catch (\InvalidArgumentException $e) {
            return $this->errorResponse($e->getMessage(), 422);
        } catch (\Throwable $e) {
            if (!empty($fileData['file_path'])) {
                $this->deleteStoredFile($fileData['file_path']);
            }
            // If a send fails, THIS line in storage/logs/laravel.log tells you the real SQL error
            Log::error('Send message error: ' . $e->getMessage());
            return $this->serverError('Failed to send message.');
        }

        $message->setRelation('sender', $user);

        // Sending a message ends "typing"
        Cache::forget($this->typingKey($conversation->id, (int) $user->id));

        // Push + in-app notification must never break sending
        $this->notifyReceiver($message, $conversation, $user, (int) $receiverId);

        return $this->successResponse([
            'message'         => $this->presentOne($message, (int) $user->id),
            'conversation_id' => $conversation->id,
        ], 'Message sent.');
    }

    /** Lightweight "typing…" signal; auto-expires after 6 seconds. */
    public function typing(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'conversation_id' => 'required|integer|exists:conversations,id',
        ]);
        if ($validator->fails()) {
            return $this->errorResponse($validator->errors()->first(), 422);
        }

        $user         = $request->user();
        $conversation = Conversation::find($request->conversation_id);

        if (!$conversation || !$this->isParticipant($conversation, $user)) {
            return $this->forbidden('Unauthorized.');
        }

        Cache::put($this->typingKey($conversation->id, (int) $user->id), 1, now()->addSeconds(6));

        return $this->successResponse(null, 'ok');
    }

    public function markConversationAsRead(Request $request, $conversationId)
    {
        $user         = $request->user();
        $conversation = Conversation::find($conversationId);

        if (!$conversation) {
            return $this->notFound('Conversation not found.');
        }
        if (!$this->isParticipant($conversation, $user)) {
            return $this->forbidden('Unauthorized.');
        }

        $count = Message::where('conversation_id', $conversation->id)
            ->where('receiver_id', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true, 'read_at' => now(), 'is_delivered' => true, 'delivered_at' => now()]);

        return $this->successResponse([
            'conversation_id'   => (int) $conversationId,
            'marked_read_count' => $count,
        ], 'Conversation marked as read.');
    }

    public function getUnreadCount(Request $request)
    {
        $user = $request->user();

        $perConversation = Message::where('receiver_id', $user->id)
            ->where('is_read', false)
            ->whereNull('deleted_for_everyone_at')
            ->visibleTo($user->id)
            ->selectRaw('conversation_id, COUNT(*) as c')
            ->groupBy('conversation_id')
            ->get()
            ->map(fn ($r) => ['conversation_id' => $r->conversation_id, 'unread_count' => (int) $r->c]);

        return $this->successResponse([
            'total_unread'     => (int) $perConversation->sum('unread_count'),
            'per_conversation' => $perConversation,
        ], 'Unread count retrieved.');
    }

    /**
     * Legacy route DELETE messages/{id}  ==  "delete for everyone" (tombstone).
     * New clients use POST messages/delete (ChatExtrasController) with scope me|everyone.
     */
    public function deleteMessage(Request $request, $messageId)
    {
        $request->merge(['message_ids' => [(int) $messageId], 'scope' => 'everyone']);

        return app(ChatExtrasController::class)->deleteMessages($request);
    }

    // ============================================================
    // REACTIONS  (reaction = emoji, empty = remove mine)
    // ============================================================

    public function react(Request $request, $messageId)
    {
        $validator = Validator::make($request->all(), ['reaction' => 'nullable|string|max:16']);
        if ($validator->fails()) {
            return $this->errorResponse($validator->errors()->first(), 422);
        }

        $user    = $request->user();
        $message = Message::with('conversation')->find($messageId);

        if (!$message) {
            return $this->notFound('Message not found.');
        }
        if (!$message->conversation || !$this->isParticipant($message->conversation, $user)) {
            return $this->forbidden('Unauthorized.');
        }
        if ($message->is_deleted) {
            return $this->errorResponse('This message was deleted.', 422);
        }

        $emoji = trim((string) $request->input('reaction', ''));

        if ($emoji === '') {
            MessageReaction::where('message_id', $message->id)->where('user_id', $user->id)->delete();
        } else {
            MessageReaction::updateOrCreate(
                ['message_id' => $message->id, 'user_id' => $user->id],
                ['reaction' => $emoji]
            );
        }

        $message->forceFill(['meta_updated_at' => now()])->saveQuietly();

        return $this->successResponse(
            $this->presentOne($message, (int) $user->id),
            'Reaction saved.'
        );
    }

    // ============================================================
    // STARS (private to each user)
    // ============================================================

    public function toggleStar(Request $request, $messageId)
    {
        $user    = $request->user();
        $message = Message::with('conversation')->find($messageId);

        if (!$message) {
            return $this->notFound('Message not found.');
        }
        if (!$message->conversation || !$this->isParticipant($message->conversation, $user)) {
            return $this->forbidden('Unauthorized.');
        }
        if ($message->is_deleted) {
            return $this->errorResponse('This message was deleted.', 422);
        }

        $star = MessageStar::where('user_id', $user->id)->where('message_id', $message->id)->first();
        if ($star) {
            $star->delete();
            $starred = false;
        } else {
            MessageStar::create(['user_id' => $user->id, 'message_id' => $message->id]);
            $starred = true;
        }

        return $this->successResponse(['message_id' => (int) $messageId, 'is_starred' => $starred], 'ok');
    }

    public function starred(Request $request, $conversationId)
    {
        $user         = $request->user();
        $conversation = Conversation::find($conversationId);

        if (!$conversation) {
            return $this->notFound('Conversation not found.');
        }
        if (!$this->isParticipant($conversation, $user)) {
            return $this->forbidden('Unauthorized.');
        }

        $ids = MessageStar::where('user_id', $user->id)->pluck('message_id');

        $messages = Message::with(['sender:id,name', 'replyTo.sender:id,name'])
            ->where('conversation_id', $conversation->id)
            ->visibleTo($user->id)
            ->whereNull('deleted_for_everyone_at')
            ->whereIn('id', $ids)
            ->orderByDesc('id')
            ->limit(200)
            ->get();

        return $this->successResponse(
            $this->presentMany($messages, (int) $user->id, $conversation->id),
            'Starred messages retrieved.'
        );
    }

    // ============================================================
    // PINS (shared by both people, max 3 per conversation)
    // ============================================================

    public function togglePin(Request $request, $messageId)
    {
        $user    = $request->user();
        $message = Message::with('conversation')->find($messageId);

        if (!$message) {
            return $this->notFound('Message not found.');
        }
        $conversation = $message->conversation;
        if (!$conversation || !$this->isParticipant($conversation, $user)) {
            return $this->forbidden('Unauthorized.');
        }
        if ($message->is_deleted) {
            return $this->errorResponse('This message was deleted.', 422);
        }

        $pin = MessagePin::where('message_id', $message->id)->first();

        if ($pin) {
            $pin->delete();
            $pinned = false;
        } else {
            if (MessagePin::where('conversation_id', $conversation->id)->count() >= self::MAX_PINS) {
                return $this->errorResponse('You can pin up to ' . self::MAX_PINS . ' messages. Unpin one first.', 422);
            }
            MessagePin::create([
                'conversation_id' => $conversation->id,
                'message_id'      => $message->id,
                'pinned_by'       => $user->id,
            ]);
            $pinned = true;
        }

        return $this->successResponse([
            'message_id' => (int) $messageId,
            'pinned'     => $pinned,
            'pins'       => $this->pinsFor($conversation, (int) $user->id),
        ], $pinned ? 'Message pinned.' : 'Message unpinned.');
    }

    public function pins(Request $request, $conversationId)
    {
        $user         = $request->user();
        $conversation = Conversation::find($conversationId);

        if (!$conversation) {
            return $this->notFound('Conversation not found.');
        }
        if (!$this->isParticipant($conversation, $user)) {
            return $this->forbidden('Unauthorized.');
        }

        return $this->successResponse($this->pinsFor($conversation, (int) $user->id), 'Pins retrieved.');
    }

    // ============================================================
    // FORWARD (copies the message into other conversations you are in)
    // ============================================================

    public function forward(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'message_ids'        => 'required|array|min:1|max:20',
            'message_ids.*'      => 'integer',
            'conversation_ids'   => 'required|array|min:1|max:5',
            'conversation_ids.*' => 'integer',
        ]);
        if ($validator->fails()) {
            return $this->errorResponse($validator->errors()->first(), 422);
        }

        $user = $request->user();

        $sources = Message::with('conversation')
            ->whereIn('id', $request->message_ids)
            ->orderBy('id')
            ->get();

        if ($sources->isEmpty()) {
            return $this->notFound('Message not found.');
        }
        foreach ($sources as $s) {
            if (!$s->conversation || !$this->isParticipant($s->conversation, $user)) {
                return $this->forbidden('Unauthorized.');
            }
            if ($s->is_deleted) {
                return $this->errorResponse('This message was deleted.', 422);
            }
            if ($s->is_encrypted) {
                // Ciphertext is wrapped for the original peer only; the new chat could not read it.
                return $this->errorResponse('Encrypted messages cannot be forwarded.', 422);
            }
        }

        $targetIds = array_values(array_unique(array_map('intval', $request->conversation_ids)));
        $targets   = Conversation::whereIn('id', $targetIds)->get();

        if ($targets->count() !== count($targetIds)) {
            return $this->notFound('Conversation not found.');
        }
        foreach ($targets as $t) {
            if (!$this->isParticipant($t, $user)) {
                return $this->forbidden('Unauthorized.');
            }
        }

        $created = [];
        $copied  = [];

        try {
            DB::transaction(function () use ($targets, $sources, $user, &$created, &$copied) {
                foreach ($targets as $t) {
                    $isCustomer = (int) $user->id === (int) $t->customer_id;
                    $receiverId = $isCustomer ? $t->fundi_id : $t->customer_id;

                    foreach ($sources as $s) {
                        $fileData = [];

                        if ($s->file_path) {
                            $newPath = $this->copyStoredFile($s->file_path, (string) $s->file_extension);
                            if (!$newPath) {
                                continue; // original file is gone
                            }
                            $copied[]  = $newPath;
                            $fileData  = [
                                'file_name'      => $s->file_name,
                                'file_path'      => $newPath,
                                'file_size'      => $s->file_size,
                                'file_mime_type' => $s->file_mime_type,
                                'file_extension' => $s->file_extension,
                            ];
                        }

                        $created[] = Message::create(array_merge([
                            'conversation_id' => $t->id,
                            'sender_id'       => $user->id,
                            'receiver_id'     => $receiverId,
                            'sender_type'     => $isCustomer ? 'customer' : 'fundi',
                            'message_type'    => $s->message_type,
                            'content'         => $s->content,
                            'has_link'        => (bool) $s->has_link,
                            'is_forwarded'    => true,
                            'is_read'         => false,
                            'is_delivered'    => false,
                        ], $fileData));
                    }

                    $t->update(['last_message_at' => now()]);
                }
            });
        } catch (\Throwable $e) {
            foreach ($copied as $p) {
                $this->deleteStoredFile($p);
            }
            Log::error('Forward error: ' . $e->getMessage());
            return $this->serverError('Failed to forward.');
        }

        foreach ($created as $m) {
            $m->setRelation('sender', $user);
            $conv = $targets->firstWhere('id', $m->conversation_id);
            if ($conv) {
                $this->notifyReceiver($m, $conv, $user, (int) $m->receiver_id);
            }
        }

        return $this->successResponse([
            'forwarded'        => count($created),
            'conversation_ids' => $targetIds,
        ], 'Message forwarded.');
    }

    // ============================================================
    // MESSAGE INFO
    // ============================================================

    public function info(Request $request, $messageId)
    {
        $user    = $request->user();
        $message = Message::with(['conversation', 'reactions.user:id,name'])->find($messageId);

        if (!$message) {
            return $this->notFound('Message not found.');
        }
        if (!$message->conversation || !$this->isParticipant($message->conversation, $user)) {
            return $this->forbidden('Unauthorized.');
        }
        if ($message->is_deleted) {
            return $this->errorResponse('This message was deleted.', 422);
        }

        return $this->successResponse([
            'message_id'   => $message->id,
            'is_mine'      => (int) $message->sender_id === (int) $user->id,
            'sent_at'      => $message->created_at?->toIso8601String(),
            'delivered_at' => $message->delivered_at?->toIso8601String(),
            'read_at'      => $message->read_at?->toIso8601String(),
            'reactions'    => $message->reactions->map(fn ($r) => [
                'user_id'   => $r->user_id,
                'user_name' => $r->user->name ?? 'Unknown',
                'emoji'     => $r->reaction,
            ])->values(),
        ], 'Info retrieved.');
    }

    // ============================================================
    // FILE VIEWING (inline, login required, supports HTTP Range)
    // ============================================================

    public function viewFile(Request $request, $messageId)
    {
        $user    = $request->user();
        $message = Message::with('conversation')->find($messageId);

        if (!$message || !$message->file_path || $message->is_deleted) {
            return $this->notFound('File not found.');
        }
        if (!$message->conversation || !$this->isParticipant($message->conversation, $user)) {
            return $this->forbidden('Unauthorized to view this file.');
        }

        $fullPath = $this->resolveStoredPath($message->file_path);
        if (!$fullPath) {
            return $this->notFound('File not found on server.');
        }

        $inline   = in_array($message->message_type, ['image', 'video'], true);
        $filename = preg_replace('/[^A-Za-z0-9._ -]/', '_', $message->file_name ?: basename($fullPath));

        return response()->file($fullPath, [
            'Content-Type'                 => $message->file_mime_type ?: 'application/octet-stream',
            'Content-Disposition'          => ($inline ? 'inline' : 'attachment') . '; filename="' . $filename . '"',
            'X-Content-Type-Options'       => 'nosniff',
            'Content-Security-Policy'      => "default-src 'none'; sandbox",
            'Cross-Origin-Resource-Policy' => 'same-origin',
            'Accept-Ranges'                => 'bytes',
            'Cache-Control'                => 'private, max-age=3600',
        ]);
    }

    // ============================================================
    // HELPERS
    // ============================================================

    private function typingKey(int $conversationId, int $userId): string
    {
        return "chat:typing:{$conversationId}:{$userId}";
    }

    /** Formatted message + the quoted (reply) message, if its relation is loaded. */
    private function present(Message $m): array
    {
        $data  = $m->getFormattedMessage();
        $reply = $m->relationLoaded('replyTo') ? $m->replyTo : null;

        $data['reply_to'] = $reply ? [
            'id'           => $reply->id,
            'sender_id'    => $reply->sender_id,
            'sender_name'  => $reply->sender?->name,
            'message_type' => $reply->message_type,
            'content'      => ($reply->message_type === 'text' && !$reply->is_deleted && !$reply->is_encrypted)
                ? Str::limit((string) $reply->content, 120)
                : null,
            'is_deleted'   => $reply->is_deleted,
            'file_name'    => $reply->is_deleted ? null : $reply->file_name,
        ] : null;

        return $data;
    }

    /** present() + reactions, my reaction, my star, pinned flag (3 queries for the whole list). */
    private function presentMany(EloquentCollection $messages, int $meId, int $conversationId): array
    {
        if ($messages->isEmpty()) {
            return [];
        }

        $messages->loadMissing(['sender:id,name', 'replyTo.sender:id,name']);
        $ids = $messages->pluck('id');

        $reactions = MessageReaction::whereIn('message_id', $ids)->get()->groupBy('message_id');
        $starred   = MessageStar::where('user_id', $meId)->whereIn('message_id', $ids)->pluck('message_id')->flip();
        $pinned    = MessagePin::where('conversation_id', $conversationId)->pluck('message_id')->flip();

        return $messages->map(function (Message $m) use ($reactions, $starred, $pinned, $meId) {
            $data = $this->present($m);
            $rs   = $reactions->get($m->id, collect());

            $data['reactions'] = $rs->groupBy('reaction')->map(fn ($g, $emoji) => [
                'emoji' => (string) $emoji,
                'count' => $g->count(),
                'mine'  => $g->contains('user_id', $meId),
            ])->values();
            $data['my_reaction'] = $rs->firstWhere('user_id', $meId)?->reaction;
            $data['is_starred']  = $starred->has($m->id);
            $data['is_pinned']   = $pinned->has($m->id);

            return $data;
        })->values()->all();
    }

    private function presentOne(Message $m, int $meId): array
    {
        return $this->presentMany(new EloquentCollection([$m]), $meId, (int) $m->conversation_id)[0];
    }

    /** Pinned messages of a conversation, newest pin first. */
    private function pinsFor(Conversation $c, int $meId): array
    {
        $ids = MessagePin::where('conversation_id', $c->id)->orderByDesc('id')->pluck('message_id');
        if ($ids->isEmpty()) {
            return [];
        }

        $msgs = Message::with(['sender:id,name', 'replyTo.sender:id,name'])
            ->whereIn('id', $ids)
            ->visibleTo($meId)
            ->whereNull('deleted_for_everyone_at')
            ->get()
            ->sortBy(fn ($m) => $ids->search($m->id))
            ->values();

        return $this->presentMany(new EloquentCollection($msgs->all()), $meId, $c->id);
    }

    private function isParticipant(Conversation $conversation, User $user): bool
    {
        return (int) $user->id === (int) $conversation->customer_id
            || (int) $user->id === (int) $conversation->fundi_id;
    }

    /** Validates and stores an upload. Returns [message_type, columns]. */
    private function storeUpload($file): array
    {
        $ext = strtolower(preg_replace('/[^a-z0-9]/i', '', (string) $file->getClientOriginalExtension()));
        if ($ext === '') {
            $ext = strtolower((string) ($file->guessExtension() ?: 'bin'));
        }
        if (in_array($ext, self::BLOCKED_EXTENSIONS, true)) {
            throw new \InvalidArgumentException('This file type is not allowed.');
        }

        $mime   = $file->getMimeType() ?: 'application/octet-stream';
        $sizeKb = ($file->getSize() ?: 0) / 1024;

        if (in_array($mime, self::IMAGE_MIMES, true)) {
            $type = Message::TYPE_IMAGE;
            if ($sizeKb > self::MAX_IMAGE_KB) {
                throw new \InvalidArgumentException('Photos can be up to 5 MB.');
            }
        } elseif (str_starts_with($mime, 'video/')) {
            $type = Message::TYPE_VIDEO;
            if ($sizeKb > self::MAX_VIDEO_KB) {
                throw new \InvalidArgumentException('Videos can be up to 20 MB. Please send a shorter clip.');
            }
        } else {
            $type = Message::TYPE_FILE;
            if ($sizeKb > self::MAX_FILE_KB) {
                throw new \InvalidArgumentException('Files can be up to 15 MB.');
            }
        }

        $path = $file->storeAs('chat/' . date('Y/m'), Str::random(40) . '.' . $ext, 'local');

        return [$type, [
            'file_name'      => Str::limit(basename((string) $file->getClientOriginalName()), 200, ''),
            'file_path'      => $path,
            'file_size'      => $file->getSize(),
            'file_mime_type' => $mime,
            'file_extension' => $ext,
        ]];
    }

    /** New files are private ('local'); older chat files live on the 'public' disk. */
    private function resolveStoredPath(string $relative): ?string
    {
        if (str_contains($relative, '..')) {
            return null;
        }
        foreach (['local', 'public'] as $disk) {
            if (Storage::disk($disk)->exists($relative)) {
                return Storage::disk($disk)->path($relative);
            }
        }
        return null;
    }

    /** Copies a stored chat file to a new private path (used by forward). */
    private function copyStoredFile(string $relative, string $ext): ?string
    {
        if (str_contains($relative, '..')) {
            return null;
        }
        $ext = strtolower(preg_replace('/[^a-z0-9]/i', '', $ext)) ?: 'bin';

        foreach (['local', 'public'] as $disk) {
            if (!Storage::disk($disk)->exists($relative)) {
                continue;
            }
            $stream = Storage::disk($disk)->readStream($relative);
            if (!$stream) {
                return null;
            }
            $new = 'chat/' . date('Y/m') . '/' . Str::random(40) . '.' . $ext;
            Storage::disk('local')->writeStream($new, $stream);
            if (is_resource($stream)) {
                fclose($stream);
            }
            return $new;
        }
        return null;
    }

    private function deleteStoredFile(?string $relative): void
    {
        if (!$relative || str_contains($relative, '..')) {
            return;
        }
        foreach (['local', 'public'] as $disk) {
            if (Storage::disk($disk)->exists($relative)) {
                Storage::disk($disk)->delete($relative);
            }
        }
    }

    private function notifyReceiver(Message $message, Conversation $conversation, User $sender, int $receiverId): void
    {
        try {
            $receiver = User::find($receiverId);
            if (!$receiver) {
                return;
            }

            $this->fcmService->sendChatNotification($receiver, $sender, $message, $conversation->id);
        } catch (\Throwable $e) {
            Log::warning('Chat FCM error: ' . $e->getMessage());
        }

        try {
            $body = match ($message->message_type) {
                'image' => '📷 Photo',
                'video' => '🎬 Video',
                'file'  => '📎 ' . ($message->file_name ?: 'File'),
                default => $message->is_encrypted ? '🔒 New message' : ($message->content ?: 'New message'),
            };

            Notification::create([
                'user_id' => $receiverId,
                'title'   => "New message from {$sender->name}",
                'body'    => $body,
                'type'    => 'chat_message',
                'data'    => [
                    'conversation_id' => (string) $conversation->id,
                    'message_id'      => (string) $message->id,
                    'sender_id'       => (string) $sender->id,
                    'sender_name'     => (string) $sender->name,
                    'message_type'    => (string) $message->message_type,
                ],
                'is_read' => false,
            ]);
        } catch (\Throwable $e) {
            Log::warning('Chat notification row error: ' . $e->getMessage());
        }
    }
}