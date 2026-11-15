// src/services/request.service.js
import api from './api';

export const requestService = {
    // ===== CUSTOMER =====
    createRequest: (data) => api.post('/v4/requests', data),
    updateRequestStatus: (id, status) => api.patch(`/v4/requests/${id}/status`, { status }),
    cancelRequest: (id) => api.delete(`/v4/requests/${id}/cancel`),
    getMyRequests: () => api.get('/v4/my-requests'),

    // ===== ADMIN/MANAGER =====
    // These are under /v4/admin/requests
    getRequests: (params) => api.get('/v4/admin/requests', { params }), // ✅ Fixed: added /admin/
    getRequest: (id) => api.get(`/v4/admin/requests/${id}`), // ✅ Fixed: added /admin/
    deleteRequest: (id) => api.delete(`/v4/admin/requests/${id}`), // ✅ Fixed: added /admin/
    getRequestLogs: (requestId) => api.get(`/v4/admin/request-logs/${requestId}`),
};