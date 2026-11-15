// src/interfaces/like.interface.ts
import {User} from "./user.interface";
import {Post} from "./post.interface";

export interface Like {
    id: string;
    post_id: string;
    user_id: string;
    created_at: string;
    updated_at: string;
    user?: User;
    post?: Post;
}