// src/services/role.service.js
import api from './api';

export const roleService = {
    // ===== ROLES =====
    getRoles: (params) => api.get('/v9/roles', { params }),
    getRolesDropdown: () => api.get('/v9/roles/dropdown'),
    getRole: (id) => api.get(`/v9/roles/${id}`),
    createRole: (data) => api.post('/v9/roles', data),
    updateRole: (id, data) => api.put(`/v9/roles/${id}`, data),
    deleteRole: (id) => api.delete(`/v9/roles/${id}`),

    // ===== ROLE PERMISSIONS =====
    getRolePermissions: (roleId) => api.get(`/v9/roles/${roleId}/permissions`),
    assignPermissionsToRole: (roleId, permissionIds) =>
        api.post(`/v9/roles/${roleId}/permissions`, { permissions: permissionIds }),

    // ===== USER-ROLE ASSIGNMENT =====
    assignRoleToUser: (userId, role) =>
        api.post(`/v9/users/${userId}/assign-role`, { role }),
    getUserRoles: (userId) => api.get(`/v9/users/${userId}/roles`),
    removeRoleFromUser: (userId, role) =>
        api.delete(`/v9/users/${userId}/remove-role`, { data: { role } }),
};