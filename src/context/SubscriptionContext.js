import { createDataContext } from './createDataContext';
import { subscriptionService } from 'services/subscription.service';

const adapter = {
    // ============================================================
    // RATE CARDS
    // ============================================================
    getAllRateCards: async (params) => {
        try {
            const response = await subscriptionService.getRateCards(params);

            if (response?.data?.status === 'success') {
                const data = response.data.data;

                // Check if paginated response
                if (data && data.data) {
                    return {
                        data: data.data,
                        pagination: {
                            total: data.total,
                            per_page: data.per_page,
                            current_page: data.current_page,
                            last_page: data.last_page,
                        }
                    };
                }

                // Direct array response
                return { data: Array.isArray(data) ? data : [data] };
            }

            return { data: [] };
        } catch (error) {
            console.error('Rate cards API error:', error);
            throw error;
        }
    },
    createRateCard: (data) => subscriptionService.createRateCard(data),
    updateRateCard: (id, data) => subscriptionService.updateRateCard(id, data),
    deleteRateCard: (id) => subscriptionService.deleteRateCard(id),

    // ============================================================
    // PAYMENT METHODS
    // ============================================================
    getAllPaymentMethods: async (params) => {
        try {
            const response = await subscriptionService.getPaymentMethods(params);

            console.log('Payment Methods API Response:', response?.data); // Debug

            if (response?.data?.status === 'success') {
                const data = response.data.data;

                // Check if paginated response
                if (data && data.data) {
                    return {
                        data: data.data,
                        pagination: {
                            total: data.total || data.data.length,
                            per_page: data.per_page || 20,
                            current_page: data.current_page || 1,
                            last_page: data.last_page || 1,
                        }
                    };
                }

                // Direct array response
                return { data: Array.isArray(data) ? data : [data] };
            }

            return { data: [] };
        } catch (error) {
            console.error('Payment methods API error:', error);
            throw error;
        }
    },
    createPaymentMethod: (data) => subscriptionService.createPaymentMethod(data),
    updatePaymentMethod: (id, data) => subscriptionService.updatePaymentMethod(id, data),
    deletePaymentMethod: (id) => subscriptionService.deletePaymentMethod(id),

    // ============================================================
    // SUBSCRIPTIONS
    // ============================================================
    getAllSubscriptions: async (params) => {
        try {
            const response = await subscriptionService.getSubscriptions(params);

            console.log('Subscriptions API Response:', response?.data); // Debug

            if (response?.data?.status === 'success') {
                const data = response.data.data;

                // Result object with data, pagination, and filters
                const result = {
                    data: [],
                    pagination: {},
                    filters: {},
                };

                // Extract data
                if (data && data.data) {
                    result.data = data.data;
                    result.pagination = {
                        total: data.total || 0,
                        per_page: data.per_page || 20,
                        current_page: data.current_page || 1,
                        last_page: data.last_page || 1,
                    };
                } else if (Array.isArray(data)) {
                    result.data = data;
                }

                // Extract filters (stats)
                if (data && data.filters) {
                    result.filters = data.filters;
                } else if (response.data.data && response.data.data.filters) {
                    result.filters = response.data.data.filters;
                } else if (response.data.filters) {
                    result.filters = response.data.filters;
                }

                console.log('Extracted filters:', result.filters);

                return result;
            }

            return { data: [], pagination: {}, filters: {} };
        } catch (error) {
            console.error('Subscriptions API error:', error);
            throw error;
        }
    },
    approveSubscription: (id) => subscriptionService.approveSubscription(id),
    rejectSubscription: (id, reason) => subscriptionService.rejectSubscription(id, reason),
    getSubscriptionStats: () => subscriptionService.getSubscriptionStats(),
};

// ============================================================
// RATE CARD CONTEXT
// ============================================================
const rateCardContext = createDataContext(
    {
        getAll: adapter.getAllRateCards,
        getOne: null,
        create: adapter.createRateCard,
        update: adapter.updateRateCard,
        delete: adapter.deleteRateCard,
    },
    'RateCard'
);

export const { Provider: RateCardProvider, useResource: useRateCards } = rateCardContext;

// ============================================================
// PAYMENT METHOD CONTEXT
// ============================================================
const paymentMethodContext = createDataContext(
    {
        getAll: adapter.getAllPaymentMethods,
        getOne: null,
        create: adapter.createPaymentMethod,
        update: adapter.updatePaymentMethod,
        delete: adapter.deletePaymentMethod,
    },
    'PaymentMethod'
);

export const { Provider: PaymentMethodProvider, useResource: usePaymentMethods } = paymentMethodContext;

// ============================================================
// SUBSCRIPTION CONTEXT
// ============================================================
const subscriptionContext = createDataContext(
    {
        getAll: adapter.getAllSubscriptions,
        getOne: null,
        create: null,      // Subscriptions are created by users, not admin
        update: null,      // Admin can only approve/reject, not generic update
        delete: null,
    },
    'Subscription'
);

export const { Provider: SubscriptionProvider, useResource: useSubscriptions } = subscriptionContext;