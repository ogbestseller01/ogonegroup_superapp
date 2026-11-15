// src/services/audit.service.js
import api from './api';

export const auditService = {
    getAuditTrails: (params) => api.get('/v10/audit-logs', { params }),
    exportCsv: (params) => api.get('/v10/audit-logs/export', { params, responseType: 'blob' }),
};