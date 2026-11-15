// src/hooks/useRequest.js
import { useRequests } from 'context/RequestContext';
import { useCallback } from 'react';

export const useRequestManagement = () => {
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
    } = useRequests();

    const getRequests = useCallback(async (params) => {
        return await fetchAll(params);
    }, [fetchAll]);

    const getRequest = useCallback(async (id) => {
        return await fetchOne(id);
    }, [fetchOne]);

    const createRequest = useCallback(async (data) => {
        return await create(data);
    }, [create]);

    const updateRequestStatus = useCallback(async (id, status) => {
        return await update(id, { status });
    }, [update]);

    const deleteRequest = useCallback(async (id) => {
        return await remove(id);
    }, [remove]);

    const cancelRequest = useCallback(async (id) => {
        return await update(id, { status: 'cancelled' });
    }, [update]);

    return {
        requests: items,
        request: item,
        loading,
        error,
        getRequests,
        getRequest,
        createRequest,
        updateRequestStatus,
        deleteRequest,
        cancelRequest,
        clearError,
    };
};