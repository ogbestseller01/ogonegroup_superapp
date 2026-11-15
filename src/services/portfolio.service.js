// src/services/portfolio.service.js
import api from './api';

/**
 * Laravel/PHP does NOT parse multipart bodies sent with a real PUT request,
 * so `images` arrive empty on update. We send POST + `_method=PUT` instead
 * (the existing PUT route still matches thanks to method spoofing).
 *
 * We deliberately do NOT set a Content-Type header: with FormData the browser/axios
 * must add it themselves so the multipart boundary is included.
 */
const toFormData = (data) => {
    if (data instanceof FormData) return data;
    const fd = new FormData();
    Object.entries(data || {}).forEach(([key, value]) => {
        if (value === undefined || value === null) return;
        if (Array.isArray(value)) {
            value.forEach((v) => fd.append(`${key}[]`, v));
        } else {
            fd.append(key, value);
        }
    });
    return fd;
};

export const portfolioService = {
    // ---------- PUBLIC (no auth — customer website) ----------
    getPublicPortfolios: (params) => api.get('/v1/portfolios', { params }),
    getPublicByTechnician: (technicianId) => api.get(`/v1/portfolios/${technicianId}`),

    // ---------- AUTHENTICATED (admin + technician) ----------
    getPortfolios: (params) => api.get('/v3/portfolios', { params }),
    getPortfoliosByTechnician: (technicianId) =>
        api.get(`/v3/portfolios/technician/${technicianId}`),
    getMyPortfolios: () => api.get('/v3/portfolios/my'),

    createPortfolio: (data) => api.post('/v3/portfolios', toFormData(data)),

    updatePortfolio: (id, data) => {
        const fd = toFormData(data);
        fd.append('_method', 'PUT');
        return api.post(`/v3/portfolios/${id}`, fd);
    },

    deletePortfolio: (id) => api.delete(`/v3/portfolios/${id}`),
    updateSocialLinks: (id, data) => api.put(`/v3/portfolios/${id}/social-links`, data),

    deletePortfolioAdmin: (id) => api.delete(`/v3/admin/portfolios/${id}`),
};