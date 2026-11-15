import api from './api';

export const miniAppQrService = {
    getQrs: (params) => api.get('/v24/admin/mini-app-qrs', { params }),
    getQr: (id) => api.get(`/v24/admin/mini-app-qrs/${id}`),
    getStats: () => api.get('/v24/admin/mini-app-qrs/stats'),
    createQr: (data) => api.post('/v24/admin/mini-app-qrs', data),
    updateQr: (id, data) => api.put(`/v24/admin/mini-app-qrs/${id}`, data),
    deleteQr: (id) => api.delete(`/v24/admin/mini-app-qrs/${id}`),

    // Public list, used for the "mini app" dropdown
    getMiniApps: () => api.get('/v24/mini-apps'),
};