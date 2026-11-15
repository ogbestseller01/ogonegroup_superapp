// src/interfaces/request.interface.ts
import {Service, Technician, User} from "./user.interface";

export interface ServiceRequest {
    id: string;
    customer_id: string;
    technician_id: string;
    service_id: string;
    description: string;
    status: 'pending' | 'accepted' | 'rejected' | 'in_progress' | 'completed' | 'cancelled';
    created_at: string;
    updated_at: string;
    customer?: User;
    technician?: Technician;
    service?: Service;
}

export interface ServiceRequestFormData {
    technician_id: string;
    service_id: string;
    description: string;
}

export interface RequestLog {
    id: string;
    request_id: string;
    user_id: string;
    action: string;
    old_status: string | null;
    new_status: string;
    notes: string | null;
    ip_address: string;
    created_at: string;
    updated_at: string;
    user?: User;
}