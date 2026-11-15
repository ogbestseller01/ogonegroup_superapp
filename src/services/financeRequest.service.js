import api from './api';

export const financeRequestService = {
    getSummary: (params) => api.get('/v21/finance/requests/summary', { params }),
    getTrends: (params) => api.get('/v21/finance/requests/trends', { params }),
    getTable: (params) => api.get('/v21/finance/requests/table', { params }),
    exportReport: (params) =>
        api.get('/v21/finance/requests/export', { params, responseType: 'blob' }),
};