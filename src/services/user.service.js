// src/services/user.service.js
import api from './api';

export const userService = {
    // ===== USER CRUD =====
    getUsers: (params) => api.get('/v8/users', { params }),
    getUser: (id) => api.get(`/v8/users/${id}`),
    createUser: (data) => api.post('/v8/users', data),
    updateUser: (id, data) => api.put(`/v8/users/${id}`, data),
    deleteUser: (id) => api.delete(`/v8/users/${id}`),

    // ===== SOFT DELETE =====
    getTrashedUsers: (params) => api.get('/v8/users/trashed', { params }),
    restoreUser: (id) => api.post(`/v8/users/${id}/restore`),
    forceDeleteUser: (id) => api.delete(`/v8/users/${id}/force`),

    // ===== STATUS MANAGEMENT =====
    activateUser: (id) => api.patch(`/v8/users/${id}/activate`),
    deactivateUser: (id) => api.patch(`/v8/users/${id}/deactivate`),
    suspendUser: (id) => api.patch(`/v8/users/${id}/suspend`),

    // ===== PASSWORD & OTP =====
    resetUserPassword: (id, password) =>
        api.post(`/v8/users/${id}/reset-password`, { password, password_confirmation: password }),
    resetUserPasswordRandom: (id) =>
        api.post(`/v8/users/${id}/reset-password-random`),
    resendOtp: (id) => api.post(`/v8/users/${id}/resend-otp`),
    resendOtpPhone: (id) => api.post(`/v8/users/${id}/resend-otp-phone`),
    sendPasswordReset: (id) => api.post(`/v8/users/${id}/send-password-reset`),

    // ===== USER VERIFICATION (NEW) =====
    verifyUserOtp: (id, otp) => api.post(`/v8/users/${id}/verify-otp`, { otp }),
    verifyUserToken: (id) => api.post(`/v8/users/${id}/verify-token`),
    markUserVerified: (id) => api.post(`/v8/users/${id}/mark-verified`),

    // ===== USER LISTINGS =====
    getCustomers: (params) => api.get('/v8/customers', { params }),
    getFundis: (params) => api.get('/v8/fundis', { params }),
    getUserStats: () => api.get('/v8/stats'),

    // ===== DROPDOWNS =====
    getUsersDropdown: (params) => api.get('/v8/dropdown/users', { params }),
    getCustomersDropdown: (params) => api.get('/v8/dropdown/customers', { params }),
    getFundisDropdown: (params) => api.get('/v8/dropdown/fundis', { params }),
    getActiveUsersDropdown: (params) => api.get('/v8/dropdown/active-users', { params }),

    // ===== TECHNICIAN VERIFICATION =====
    verifyTechnician: (technicianId) => api.patch(`/v2/technicians/${technicianId}/verify`),
};