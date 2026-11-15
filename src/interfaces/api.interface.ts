// src/interfaces/api.interface.ts
export interface ApiResponse<T = any> {
    success: boolean;
    message: string;
    data: T;
    errors?: any;
}

export interface PaginatedResponse<T = any> {
    current_page: number;
    data: T[];
    first_page_url: string;
    from: number;
    last_page: number;
    last_page_url: string;
    links: any[];
    next_page_url: string | null;
    path: string;
    per_page: number;
    prev_page_url: string | null;
    to: number;
    total: number;
}

export interface QueryParams {
    page?: number;
    limit?: number;
    search?: string;
    sort_by?: string;
    sort_order?: 'asc' | 'desc';
    [key: string]: any;
}