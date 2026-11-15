import api from './api';

// Consolidated reporting endpoints (v12) — combines what used to be four
// separate finance/* services (customers, requests, subscriptions, technicians)
// behind one controller. Most calls accept an optional `type` param:
//   type: 'customers' | 'requests' | 'subscriptions' | 'technicians'
// Omit `type` on summary/trends to get every domain combined.
// `detailed` always requires a `type` (the four tables don't share columns).
export const reportService = {
    getSummary: (params) => api.get('/v12/reports/summary', { params }),
    getTrends: (params) => api.get('/v12/reports/trends', { params }),
    getDetailed: (params) => api.get('/v12/reports/detailed', { params }),
    getOverview: (params) => api.get('/v12/reports/overview', { params }),
    exportReport: (params) => api.get('/v12/reports/export', { params, responseType: 'blob' }),
};