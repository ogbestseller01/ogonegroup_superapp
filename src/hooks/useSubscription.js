import { useCallback } from 'react';
import {
    useRateCards,
    usePaymentMethods,
    useSubscriptions,
} from 'context/SubscriptionContext';
import { subscriptionService } from 'services/subscription.service';

export const useRateCardManagement = () => {
    const {
        items,
        loading,
        error,
        fetchAll,
        createItem,
        updateItem,
        deleteItem,
        clearError,
    } = useRateCards();

    const getRateCards = useCallback((params) => fetchAll(params), [fetchAll]);

    return {
        rateCards: items,
        loading,
        error,
        getRateCards,
        createRateCard: createItem,
        updateRateCard: updateItem,
        deleteRateCard: deleteItem,
        clearError,
    };
};

// ✅ SIMPLIFIED - Direct API calls
export const usePaymentMethodManagement = () => {
    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const getPaymentMethods = useCallback(async (params) => {
        setLoading(true);
        try {
            const response = await subscriptionService.getPaymentMethods(params);
            let data = [];
            if (response?.data?.status === 'success') {
                const responseData = response.data.data;
                if (responseData?.data) {
                    data = responseData.data;
                } else if (Array.isArray(responseData)) {
                    data = responseData;
                }
            }
            setItems(data);
            return data;
        } catch (err) {
            setError(err.message);
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const createPaymentMethod = useCallback(
        (data) => subscriptionService.createPaymentMethod(data),
        []
    );

    const updatePaymentMethod = useCallback(
        (id, data) => subscriptionService.updatePaymentMethod(id, data),
        []
    );

    const deletePaymentMethod = useCallback(
        (id) => subscriptionService.deletePaymentMethod(id),
        []
    );

    const clearError = useCallback(() => setError(null), []);

    return {
        paymentMethods: items,
        loading,
        error,
        getPaymentMethods,
        createPaymentMethod,
        updatePaymentMethod,
        deletePaymentMethod,
        clearError,
    };
};

export const useSubscriptionManagement = () => {
    const {
        items,
        loading,
        error,
        fetchAll,
        clearError,
    } = useSubscriptions();

    const getSubscriptions = useCallback(async (params) => {
        const result = await fetchAll(params);
        return result;
    }, [fetchAll]);

    const approveSubscription = useCallback(
        (id) => subscriptionService.approveSubscription(id),
        []
    );

    const rejectSubscription = useCallback(
        (id, reason) => subscriptionService.rejectSubscription(id, reason),
        []
    );

    const getSubscriptionStats = useCallback(
        () => subscriptionService.getSubscriptionStats(),
        []
    );

    return {
        subscriptions: items,
        loading,
        error,
        getSubscriptions,
        approveSubscription,
        rejectSubscription,
        getSubscriptionStats,
        clearError,
    };
};