import api from './api';

export const subscriptionService = {
    // ============================================================
    // RATE CARDS
    // ============================================================
    getRateCards: (params) => api.get('/v16/admin/rate-cards', { params }),
    createRateCard: (data) => api.post('/v16/admin/rate-cards', data),
    updateRateCard: (id, data) => api.put(`/v16/admin/rate-cards/${id}`, data),
    deleteRateCard: (id) => api.delete(`/v16/admin/rate-cards/${id}`),

    // ============================================================
    // PAYMENT METHODS - ✅ All methods defined
    // ============================================================
    getPaymentMethods: (params) => api.get('/v16/admin/payment-methods', { params }),
    getPaymentMethod: (id) => api.get(`/v16/admin/payment-methods/${id}`),
    createPaymentMethod: (data) => api.post('/v16/admin/payment-methods', data),
    updatePaymentMethod: (id, data) => api.put(`/v16/admin/payment-methods/${id}`, data),
    deletePaymentMethod: (id) => api.delete(`/v16/admin/payment-methods/${id}`),
    togglePaymentMethod: (id) => api.patch(`/v16/admin/payment-methods/${id}/toggle`),
    getPaymentMethodsDropdown: () => api.get('/v16/admin/payment-methods/dropdown'),

    // ============================================================
    // SUBSCRIPTIONS
    // ============================================================
    getSubscriptions: (params) => api.get('/v16/admin/subscriptions', { params }),
    approveSubscription: (id) => api.post(`/v16/admin/subscriptions/${id}/approve`),
    rejectSubscription: (id, reason) => api.post(`/v16/admin/subscriptions/${id}/reject`, { reason }),
    getSubscriptionStats: () => api.get('/v16/admin/subscriptions/stats'),
};