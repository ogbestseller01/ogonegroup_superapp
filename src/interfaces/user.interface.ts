// src/interfaces/user.interface.ts (Final with all imports)
import { Role } from "./role-permission.interface";
import { Service } from "./service.interface";
import { Portfolio } from "./portfolio.interface";
import { Post } from "./post.interface";
import { Comment } from "./comment.interface";
import { Like } from "./like.interface";
import { ServiceRequest } from "./request.interface";

export interface User {
    id: string;
    name: string;
    email: string;
    phone: string | null;
    status: 'pending' | 'active' | 'suspended' | 'inactive';
    is_active: boolean;
    created_by: string | null;
    last_login_ip: string | null;
    email_verified_at: string | null;
    last_login_at: string | null;
    deleted_at: string | null;
    created_at: string;
    updated_at: string;
    locale: string;
    role?: Role;
    technician?: Technician;
    createdBy?: User;
    customerRequests?: ServiceRequest[];
    comments?: Comment[];
    likes?: Like[];
}

export interface Technician {
    id: string;
    user_id: string;
    profile_photo: string | null;
    bio: string | null;
    experience: number;
    rating: number;
    latitude: number | null;
    longitude: number | null;
    area: string | null;
    verified: boolean;
    last_activity_at: string | null;
    is_online: boolean;
    hourly_rate: number | null;
    created_at: string;
    updated_at: string;
    user?: User;
    services?: Service[];
    portfolios?: Portfolio[];
    posts?: Post[];
    requests?: ServiceRequest[];
}

export interface UserStats {
    total: number;
    customers: number;
    fundis: number;
    admins: number;
    active: number;
    inactive: number;
    verified: number;
}

export interface UserFormData {
    name: string;
    email: string;
    password?: string;
    phone?: string;
    role: string;
}

export interface TechnicianFormData {
    user_id?: string;
    bio?: string;
    experience?: number;
    hourly_rate?: number;
    area?: string;
    latitude?: number;
    longitude?: number;
    verified?: boolean;
    is_online?: boolean;
    profile_photo?: File | string;
    service_ids?: string[];
}