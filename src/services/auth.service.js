// src/services/auth.service.js
import api from './api';

export const authService = {
    // ─── Classic Login (supports email OR phone) ──────────────
    login: (identifier, password) => {
        // Remove + sign from phone numbers for normalization
        const cleanIdentifier = identifier.replace(/^\+/, '');
        return api.post('/v1/auth/login', { email: cleanIdentifier, password });
    },

    logout: () => api.post('/v1/auth/logout'),
    me: () => api.get('/v1/auth/me'),
    getMyPermissions: () => api.get('/v1/auth/permissions'),

    // ─── Registration ─────────────────────────────────────────
    register: (data) => api.post('/v1/auth/register', data),
    registerFundi: (data) => api.post('/v1/auth/register-fundi', data),

    // ─── Classic OTP (registration / email verification) ──────
    verifyOTP: (email, otp) => api.post('/v1/auth/verify-otp', { email, otp }),
    resendOtp: (email) => api.post('/v1/auth/resend-otp', { email }),
    verifyToken: (email, token) =>
        api.get('/v1/verification/verify-token', { params: { email, token } }),

    // ─── Password ─────────────────────────────────────────────
    forgotPassword: (email) => api.post('/v1/auth/forgot-password', { email }),
    resetPassword: (email, otp, password, password_confirmation) =>
        api.post('/v1/auth/reset-password', { email, otp, password, password_confirmation }),
    changePassword: (current_password, password, password_confirmation) =>
        api.post('/v1/auth/change-password', { current_password, password, password_confirmation }),

    // ─── Profile ──────────────────────────────────────────────
    updateProfile: (data) => api.put('/v1/auth/profile', data),
    updateLocale: (locale) => api.post('/v1/auth/locale', { locale }),
    updateDeviceToken: (token) => api.post('/v1/device-token', { token }),
    getDeviceToken: () => api.get('/v1/device-token'),
    deleteDeviceToken: () => api.delete('/v1/device-token'),
    deleteAccount: () => api.delete('/v1/auth/account'),

    // ─── Sessions ─────────────────────────────────────────────
    getSessions: () => api.get('/v1/sessions'),
    deleteAllSessions: () => api.delete('/v1/sessions/all'),
    deleteOtherSessions: () => api.delete('/v1/sessions/others'),
    deleteSession: (id) => api.delete(`/v1/sessions/${id}`),

    // ─── Web-only OTP Login (privileged roles) ────────────────
    // Supports both email and phone for identifier
    requestWebOtp: (identifier, password) => {
        const cleanIdentifier = identifier.replace(/^\+/, '');
        return api.post('/v1/auth/web-otp/request', { email: cleanIdentifier, password });
    },

    verifyWebOtp: (email, otp) =>
        api.post('/v1/auth/web-otp/verify', { email, otp }),

    resendWebOtp: (email) =>
        api.post('/v1/auth/web-otp/resend', { email }),
};