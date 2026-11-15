<?php

namespace App\Http\Controllers\Api;

use App\Models\Post;
use App\Models\Comment;
use App\Traits\Auditable;
use Illuminate\Http\Request;

class CommentController extends BaseApiController
{
    use Auditable;

    public function store(Request $request, $postId)
    {
        $post = Post::findOrFail($postId);
        $user = $request->user();

        $data = $request->validate([
            'comment' => 'required|string|max:500',
        ]);

        $comment = Comment::create([
            'post_id' => $post->id,
            'user_id' => $user->id,
            'comment' => $data['comment'],
        ]);

        $this->logAudit('create_comment', 'comment', $comment->id, "User {$user->id} commented on post {$post->id}");

        return $this->created($comment->load('user'), 'Comment added.');
    }

    public function destroy(Request $request, $id)
    {
        $comment = Comment::findOrFail($id);
        $user = $request->user();

        if ($user->id != $comment->user_id && !$user->hasAnyRole(['ADMINISTRATOR', 'MANAGER'])) {
            return $this->forbidden('Unauthorized.');
        }

        $comment->delete();

        $this->logAudit('delete_comment', 'comment', $id, 'Deleted comment');

        return $this->successResponse(null, 'Comment deleted.');
    }
}