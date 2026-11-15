// src/hooks/useAdminTechnicians.js
import { useAdminTechnicians } from 'context/AdminTechnicianContext';
import { useCallback } from 'react';

export const useAdminTechnicianManagement = () => {
    const {
        items,
        item,
        loading,
        error,
        fetchAll,
        fetchOne,
        clearError,
    } = useAdminTechnicians();

    const getTechnicians = useCallback(async (params) => {
        return await fetchAll(params);
    }, [fetchAll]);

    const getTechnician = useCallback(async (id) => {
        return await fetchOne(id);
    }, [fetchOne]);

    return {
        technicians: items,
        technician: item,
        loading,
        error,
        getTechnicians,
        getTechnician,
        clearError,
    };
};