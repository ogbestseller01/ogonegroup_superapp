// src/services/permission.service.js
import api from './api';

export const permissionService = {
    getPermissions: (params) => api.get('/v9/permissions', { params }),
    getPermission: (id) => api.get(`/v9/permissions/${id}`),
    createPermission: (data) => api.post('/v9/permissions', data),
    updatePermission: (id, data) => api.put(`/v9/permissions/${id}`, data),
    deletePermission: (id) => api.delete(`/v9/permissions/${id}`),
};