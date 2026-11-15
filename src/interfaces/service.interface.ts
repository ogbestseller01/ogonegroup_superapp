// src/interfaces/service.interface.ts
import {ServiceRequest, Technician} from "./user.interface";

export interface Service {
    id: string;
    name: string;
    description?: string;
    created_at: string;
    updated_at: string;
    technicians?: Technician[];
    requests?: ServiceRequest[];
}

export interface ServiceFormData {
    name: string;
    description?: string;
}