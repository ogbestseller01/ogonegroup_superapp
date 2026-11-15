import api from './api';

export const bannerService = {
    // Public (mobile app) – only image + link
    getPublicBanners: (params) => api.get('/v25/banners', { params }),

    // Admin
    getBanners: (params) => api.get('/v25/admin/banners', { params }),
    getBanner: (id) => api.get(`/v25/admin/banners/${id}`),
    createBanner: (formData) =>
        api.post('/v25/admin/banners', formData, {
            headers: { 'Content-Type': 'multipart/form-data' },
        }),
    updateBanner: (id, formData) =>
        api.post(`/v25/admin/banners/${id}`, formData, {   // POST for multipart
            headers: { 'Content-Type': 'multipart/form-data' },
        }),
    deleteBanner: (id) => api.delete(`/v25/admin/banners/${id}`),
    updateStatus: (id, status) =>
        api.patch(`/v25/admin/banners/${id}/status`, { status }),
};