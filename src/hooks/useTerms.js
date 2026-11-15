import { useTerms } from 'context/TermsContext';
import { useCallback } from 'react';

export const useTermsManagement = () => {
    const {
        items,
        loading,
        error,
        fetchAll,
        create,
        update,
        delete: remove,
        clearError
    } = useTerms();

    const getTerms = useCallback(async () => fetchAll(), [fetchAll]);

    const createTerms = useCallback(async (data) => {
        const result = await create(data);
        await fetchAll();
        return result;
    }, [create, fetchAll]);

    const updateTerms = useCallback(async (data) => {
        const result = await update(null, data);
        await fetchAll();
        return result;
    }, [update, fetchAll]);

    const deleteTerms = useCallback(async () => {
        const result = await remove(null);
        await fetchAll();
        return result;
    }, [remove, fetchAll]);

    return {
        terms: items,
        loading,
        error,
        getTerms,
        createTerms,
        updateTerms,
        deleteTerms,
        clearError,
    };
};