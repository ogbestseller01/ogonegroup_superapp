// src/services/otp.service.js
import api from './api';

export const otpService = {
    getOtps: (params) => api.get('/v10/otps', { params }),
    cleanup: () => api.delete('/v10/otps/cleanup'),
};