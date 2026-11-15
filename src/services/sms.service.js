// src/services/sms.service.js
import api from './api';

export const smsService = {
    // ===== SMS LOGS =====
    getSmsLogs: (params) => api.get('/v22/sms-logs', { params }),
    getUserSmsLogs: (userId, params) => api.get(`/v22/users/${userId}/sms-logs`, { params }),
    deleteSmsLog: (logId) => api.delete(`/v22/sms-logs/${logId}`),
    resendSms: (logId) => api.post(`/v22/sms-logs/${logId}/resend`),

    // ===== SMS BALANCE =====
    getSmsBalance: () => api.get('/v22/sms-balance'),

    // ===== SMS STATISTICS =====
    getSmsStats: (params) => api.get('/v22/sms-stats', { params }),

    // ===== SEND SMS =====
    sendSms: (data) => api.post('/v22/send-sms', data),
    sendBulkSms: (data) => api.post('/v22/send-bulk-sms', data),
};