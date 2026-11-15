import api from './api';

export const financeTechnicianService = {
    getSummary: (params) => api.get('/v21/finance/technicians/summary', { params }),
    getTrends: (params) => api.get('/v21/finance/technicians/trends', { params }),
    getTable: (params) => api.get('/v21/finance/technicians/table', { params }),
    exportReport: (params) => api.get('/v21/finance/technicians/export', { params, responseType: 'blob' }),
};