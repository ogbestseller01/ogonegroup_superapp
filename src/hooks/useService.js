// src/hooks/useService.js
import { useServices } from 'context/ServiceContext';
import { useCallback } from 'react';

export const useServiceManagement = () => {
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
    } = useServices();

    const getServices = useCallback(async (params) => {
        return await fetchAll(params);
    }, [fetchAll]);

    const getService = useCallback(async (id) => {
        return await fetchOne(id);
    }, [fetchOne]);

    const createService = useCallback(async (data) => {
        return await create(data);
    }, [create]);

    const updateService = useCallback(async (id, data) => {
        return await update(id, data);
    }, [update]);

    const deleteService = useCallback(async (id) => {
        return await remove(id);
    }, [remove]);

    return {
        services: items,
        service: item,
        loading,
        error,
        getServices,
        getService,
        createService,
        updateService,
        deleteService,
        clearError,
    };
};