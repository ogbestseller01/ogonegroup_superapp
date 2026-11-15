// src/services/dashboard.service.js
import api from './api';

export const dashboardService = {
    getDashboardStats: () => api.get('/v7/dashboard/stats'),
    getDashboardAnalytics: (params) => api.get('/v13/analytics/dashboard', { params }),
    getDashboardSummary: () => api.get('/v13/analytics/summary'),
    getTopCommentedPosts: (params) => api.get('/v13/analytics/top-commented-posts', { params }),
    getTopLikedPosts: (params) => api.get('/v13/analytics/top-liked-posts', { params }),
    getTopUsedServices: (params) => api.get('/v13/analytics/top-used-services', { params }),
};