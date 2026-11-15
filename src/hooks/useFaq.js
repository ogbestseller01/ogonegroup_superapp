import { useFaqs } from 'context/FaqContext';
import { useCallback } from 'react';

export const useFaqManagement = () => {
    const {
        items,
        item,
        loading,
        error,
        fetchAll,
        fetchOne,
        create,
        update,
        delete: remove,
        clearError
    } = useFaqs();

    const getFaqs = useCallback(async (params) => fetchAll(params), [fetchAll]);
    const getFaq = useCallback(async (id) => fetchOne(id), [fetchOne]);
    const createFaq = useCallback(async (data) => {
        const result = await create(data);
        await fetchAll();
        return result;
    }, [create, fetchAll]);
    const updateFaq = useCallback(async (id, data) => {
        const result = await update(id, data);
        await fetchAll();
        return result;
    }, [update, fetchAll]);
    const deleteFaq = useCallback(async (id) => {
        const result = await remove(id);
        await fetchAll();
        return result;
    }, [remove, fetchAll]);

    return {
        faqs: items,
        faq: item,
        loading,
        error,
        getFaqs,
        getFaq,
        createFaq,
        updateFaq,
        deleteFaq,
        clearError,
    };
};