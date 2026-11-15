// src/interfaces/comment.interface.ts
import {User} from "./user.interface";
import {Post} from "./post.interface";

export interface Comment {
    id: string;
    post_id: string;
    user_id: string;
    comment: string;
    created_at: string;
    updated_at: string;
    user?: User;
    post?: Post;
}

export interface CommentFormData {
    comment: string;
}