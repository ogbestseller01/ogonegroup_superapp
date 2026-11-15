// src/interfaces/dashboardService.interface.ts
export interface DashboardAnalyticsResponse {
    users: {
        total: number;
        active: number;
        inactive: number;
        by_role: Array<{
            id: string;
            name: string;
            display_name: string;
            users_count: number;
        }>;
    };
    roles: {
        total: number;
    };
    permissions: {
        total: number;
    };
    technicians: {
        total: number;
        verified: number;
        unverified: number;
        online: number;
        rating_stats: {
            average_rating: number;
            min_rating: number;
            max_rating: number;
        };
    };
    customers: {
        total: number;
        active: number;
    };
    likes: {
        total: number;
        top_posts: Array<{
            id: string;
            title: string;
            likes_count: number;
        }>;
    };
    comments: {
        total: number;
        top_posts: Array<{
            id: string;
            title: string;
            comments_count: number;
        }>;
    };
    services: {
        total: number;
        with_requests: number;
        without_requests: number;
        top_services: Array<{
            id: string;
            name: string;
            requests_count: number;
        }>;
    };
    service_requests: {
        total: number;
        by_status: Array<{
            status: string;
            total: number;
        }>;
        status_breakdown: {
            pending: number;
            accepted: number;
            in_progress: number;
            completed: number;
            cancelled: number;
            rejected: number;
        };
    };
    engagement_metrics: {
        total_posts: number;
        total_comments: number;
        total_likes: number;
        avg_comments_per_post: number;
        avg_likes_per_post: number;
    };
}

export interface DashboardSummary {
    total_users: number;
    total_roles: number;
    total_permissions: number;
    total_technicians: number;
    total_customers: number;
    total_likes: number;
    total_comments: number;
    total_services: number;
    total_requests: number;
    requests_by_status: Array<{
        status: string;
        total: number;
    }>;
}