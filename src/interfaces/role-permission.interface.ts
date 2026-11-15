// src/interfaces/role-permission.interface.ts
export interface Role {
    id: string;
    name: string;
    guard_name: string;
    display_name: string;
    description: string | null;
    permissions?: Permission[];
    users_count?: number;
    created_at: string;
    updated_at: string;
}

export interface Permission {
    id: string;
    name: string;
    guard_name: string;
    display_name: string;
    description: string | null;
    created_at: string;
    updated_at: string;
}

export interface RoleFormData {
    name: string;
    display_name: string;
    description?: string;
}

export interface PermissionFormData {
    name: string;
    display_name: string;
    description?: string;
}