// src/services/technician.service.js
import api from './api';

export const technicianService = {
    // ===== PUBLIC =====
    getTechnicians:       (params) => api.get('/v1/technicians', { params }),
    getTechnician:        (id)     => api.get(`/v1/technicians/${id}`),
    getNearby:            (params) => api.get('/fundis/nearby', { params }),
    getNearbyByPlace:     (params) => api.get('/fundis/nearby-by-place', { params }),

    // ===== ADMIN — SPLIT LISTS =====
    getAdminTechnicians:   (params) => api.get('/v20/admin/technicians',          { params }),
    getPendingTechnicians: (params) => api.get('/v20/admin/technicians/pending',  { params }),
    getApprovedTechnicians:(params) => api.get('/v20/admin/technicians/approved', { params }),

    // ===== ADMIN — BIOMETRICS =====
    getTechnicianBiometrics: (id) => api.get(`/v20/admin/technicians/${id}/biometrics`),

    // ===== ADMIN — APPROVE =====
    approveTechnician: (id) => api.post(`/v19/admin/technicians/${id}/approve`),
};