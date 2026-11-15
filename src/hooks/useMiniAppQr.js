import { useMiniAppQrs } from 'context/MiniAppQrContext';
import { useCallback } from 'react';

export const useMiniAppQrManagement = () => {
    const {
        items, item, loading, error,
        fetchAll, fetchOne, create, update, delete: remove, clearError,
    } = useMiniAppQrs();

    const getQrs = useCallback((params) => fetchAll(params), [fetchAll]);
    const getQr = useCallback((id) => fetchOne(id), [fetchOne]);
    const createQr = useCallback((data) => create(data), [create]);
    const updateQr = useCallback((id, data) => update(id, data), [update]);
    const deleteQr = useCallback((id) => remove(id), [remove]);

    return {
        qrs: items,
        qr: item,
        loading,
        error,
        getQrs,
        getQr,
        createQr,
        updateQr,
        deleteQr,
        clearError,
    };
};