import api from './api';

export const financeCustomerService = {
    getSummary: (params) => api.get('/v21/finance/customers/summary', { params }),
    getTrends: (params) => api.get('/v21/finance/customers/trends', { params }),
    getTable: (params) => api.get('/v21/finance/customers/table', { params }),
    exportReport: (params) => api.get('/v21/finance/customers/export', { params, responseType: 'blob' }),
};