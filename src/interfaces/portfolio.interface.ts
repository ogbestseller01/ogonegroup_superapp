// src/interfaces/portfolio.interface.ts
import {Technician} from "./user.interface";

export interface Portfolio {
    id: string;
    technician_id: string;
    image: string;
    description: string | null;
    created_at: string;
    updated_at: string;
    technician?: Technician;
}

export interface PortfolioFormData {
    image: File;
    description?: string;
}