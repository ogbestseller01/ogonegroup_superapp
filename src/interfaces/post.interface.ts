// src/interfaces/post.interface.ts
import {Like, Technician} from "./user.interface";

export interface Post {
    id: string;
    technician_id: string;
    title: string;
    content: string;
    image: string | null;
    created_at: string;
    updated_at: string;
    technician?: Technician;
    comments?: Comment[];
    likes?: Like[];
    comments_count?: number;
    likes_count?: number;
}

export interface PostFormData {
    title: string;
    content: string;
    image?: File;
}