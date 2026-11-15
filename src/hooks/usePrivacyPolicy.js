// src/hooks/usePrivacyPolicy.js
import { usePrivacyPolicy } from 'context/PrivacyPolicyContext';
import { useCallback } from 'react';

export const usePrivacyPolicyManagement = () => {
    const {
        items,
        item,
        loading,
        error,
        fetchAll,
        create,
        update,
        delete: remove,
        clearError,
    } = usePrivacyPolicy();

    const getPrivacyPolicy = useCallback(async () => fetchAll(), [fetchAll]);

    const createPrivacyPolicy = useCallback(
        async (data) => {
            const result = await create(data);
            await fetchAll();
            return result;
        },
        [create, fetchAll]
    );

    const updatePrivacyPolicy = useCallback(
        async (id, data) => {
            const result = await update(id, data);
            await fetchAll();
            return result;
        },
        [update, fetchAll]
    );

    const deletePrivacyPolicy = useCallback(
        async (id) => {
            const result = await remove(id);
            await fetchAll();
            return result;
        },
        [remove, fetchAll]
    );

    return {
        privacyPolicies: items,
        loading,
        error,
        getPrivacyPolicy,
        createPrivacyPolicy,
        updatePrivacyPolicy,
        deletePrivacyPolicy,
        clearError,
    };
};