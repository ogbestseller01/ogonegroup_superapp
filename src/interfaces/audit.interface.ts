// src/interfaces/audit.interface.ts
export interface AuditTrail {
    id: string;
    user_id: string;
    user_email: string;
    user_name: string;
    user_role: string;
    action: string;
    action_type: string;
    module: string;
    description: string;
    old_data: any;
    new_data: any;
    ip_address: string;
    user_agent: string;
    response_status: number | null;
    execution_time_ms: number | null;
    request_method: string;
    request_url: string;
    created_at: string;
    updated_at: string;
}

export interface AuditFilterParams {
    user_id?: string;
    action?: string;
    module?: string;
    from_date?: string;
    to_date?: string;
    page?: number;
    limit?: number;
}