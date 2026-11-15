import api from './api';

export const financeSubscriptionService = {
    getSummary: (params) => api.get('/v21/finance/subscriptions/summary', { params }),
    getTrends: (params) => api.get('/v21/finance/subscriptions/trends', { params }),
    getTable: (params) => api.get('/v21/finance/subscriptions/table', { params }),
    exportReport: (params) => api.get('/v21/finance/subscriptions/export', { params, responseType: 'blob' }),
};