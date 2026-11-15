// src/services/verification.service.js
import api from './api';

export const verificationService = {
    // Send OTP for registration/email verification
    sendOTP: (email) => api.post('/v1/auth/register', { email }),

    // Verify OTP code
    verifyWithOTP: (email, otp) => api.post('/v1/auth/verify-otp', { email, otp }),

    // Verify via token link (returns HTML view, not JSON)
    verifyByToken: (email, token) => api.get('/v1/verification/verify-token', {
        params: { email, token }
    }),

    // Resend OTP
    resendOTP: (email) => api.post('/v1/auth/forgot-password', { email }),

    // Check verification status
    checkStatus: (email) => api.get('/v1/auth/me', {
        params: { email }
    }),
};

// Alternative: Complete authentication service with all OTP/verification methods
export const authVerificationService = {
    // Register and send OTP
    register: (data) => api.post('/v1/auth/register', data),

    // Register Fundi and send OTP
    registerFundi: (data) => api.post('/v1/auth/register-fundi', data),

    // Verify OTP
    verifyOTP: (email, otp) => api.post('/v1/auth/verify-otp', { email, otp }),

    // Verify via token link
    verifyToken: (email, token) => api.get('/v1/verification/verify-token', {
        params: { email, token }
    }),

    // Resend OTP for registration
    resendRegistrationOTP: (email) => api.post('/v1/auth/resend-otp', { email }),

    // Forgot password - send reset OTP
    forgotPassword: (email) => api.post('/v1/auth/forgot-password', { email }),

    // Reset password with OTP
    resetPassword: (email, otp, password, password_confirmation) =>
        api.post('/v1/auth/reset-password', { email, otp, password, password_confirmation }),

    // Check if email is verified
    checkVerificationStatus: (email) => api.get('/v1/auth/me', {
        params: { email }
    }),
};