// src/services/printReport.service.js
import api from './api';

export const printReportService = {
    getReport: (params) => api.get('/v27/reports', { params }),
    exportReport: (params) => api.get('/v27/reports/export', { params, responseType: 'blob' }),
};