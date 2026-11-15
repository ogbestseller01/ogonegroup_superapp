<?php

namespace App\Http\Controllers\Api;

use App\Models\Post;
use App\Models\Like;
use App\Traits\Auditable;
use Illuminate\Http\Request;

class LikeController extends BaseApiController
{
    use Auditable;

    public function toggle(Request $request, $postId)
    {
        $post = Post::findOrFail($postId);
        $user = $request->user();

        $like = Like::where('post_id', $post->id)
                    ->where('user_id', $user->id)
                    ->first();

        if ($like) {
            $like->delete();
            $message = 'Like removed.';
            $liked = false;
        } else {
            Like::create([
                'post_id' => $post->id,
                'user_id' => $user->id,
            ]);
            $message = 'Post liked.';
            $liked = true;
        }

        $this->logAudit('toggle_like', 'like', $post->id, "User {$user->id} toggled like on post {$post->id}");

        return $this->successResponse(['liked' => $liked], $message);
    }
}