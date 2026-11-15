// src/services/monitoring.service.js
import api from './api';

export const monitoringService = {
    // ===== MAP & DASHBOARD =====
    getMap: (status, pendingDaysBack = 3) =>
        api.get('/v4/monitoring/map', {
            params: {
                status: status || undefined,
                pending_days_back: pendingDaysBack
            }
        }),
    getNotifications: (days = 1) =>
        api.get('/v4/monitoring/notifications', { params: { days } }),
    getStatuses: () => api.get('/v4/monitoring/statuses'),
    getPendingHistory: (days = 3) =>
        api.get('/v4/monitoring/pending-history', { params: { days } }),

    // ===== TECHNICIANS =====
    getTechnicians: (params = {}) => api.get('/v4/monitoring/technicians', { params }),
    getTechnician: (id) => api.get(`/v4/monitoring/technicians/${id}`),
    getTechniciansByArea: (area) => api.get(`/v4/monitoring/technicians/area/${area}`),
    getTechnicianCompletedRequests: (id) => api.get(`/v4/monitoring/technicians/${id}/completed-requests`),
    callTechnician: (technicianId, requestId) =>
        api.post(`/v4/monitoring/technicians/${technicianId}/call`, { request_id: requestId }),

    // ===== REQUESTS =====
    updateRequestStatus: (id, status, data = {}) =>
        api.patch(`/v4/monitoring/requests/${id}/status`, { status, ...data }),
    completeRequest: (id, data = {}) =>
        api.post(`/v4/monitoring/requests/${id}/complete`, data),
    getRequestLogs: (id) => api.get(`/v4/monitoring/requests/${id}/logs`),

    // ✅ NEW: live technician tracking (haversine distance / ETA / current GPS position)
    getRequestTracking: (id) => api.get(`/v4/monitoring/requests/${id}/tracking`),
};

// ===== UTILITY FUNCTIONS =====
export const getWhatsAppUrl = (phone) => {
    if (!phone) return '#';
    const cleaned = phone.replace(/\D/g, '');
    const formatted = cleaned.length === 9 ? '255' + cleaned : cleaned;
    return `https://wa.me/${formatted}`;
};

export const getCallUrl = (phone) => {
    if (!phone) return '#';
    const cleaned = phone.replace(/\D/g, '');
    const formatted = cleaned.length === 9 ? '255' + cleaned : cleaned;
    return `tel:+${formatted}`;
};

export default monitoringService;