// src/hooks/useTechnician.js
import { useCallback } from 'react';
import { useTechnicians } from 'context/TechnicianContext';

/**
 * Legacy hook — unchanged public API.
 * Still exposes `technicians / technician / loading / error / clearError`.
 */
export const useTechnicianManagement = () => {
    const {
        items,
        item,
        loading,
        error,
        fetchAll,
        fetchOne,
        clearError,
    } = useTechnicians();

    const getTechnicians = useCallback((params) => fetchAll(params), [fetchAll]);
    const getTechnician  = useCallback((id) => fetchOne(id),         [fetchOne]);

    return {
        technicians: items,
        technician:  item,
        loading,
        error,
        getTechnicians,
        getTechnician,
        clearError,
    };
};

/**
 * Admin hook — split lists + biometrics.
 * Used by the tabbed TechniciansList and TechnicianDetails biometrics card.
 */
export const useAdminTechnicianManagement = () => {
    const {
        pendingItems,
        approvedItems,
        biometrics,
        loading,
        error,
        fetchPending,
        fetchApproved,
        fetchBiometrics,
        clearError,
    } = useTechnicians();

    const getPendingTechnicians = useCallback(
        (params) => fetchPending(params),
        [fetchPending],
    );

    const getApprovedTechnicians = useCallback(
        (params) => fetchApproved(params),
        [fetchApproved],
    );

    const getTechnicianBiometrics = useCallback(
        (id, options) => fetchBiometrics(id, options),
        [fetchBiometrics],
    );

    return {
        pendingTechnicians:  pendingItems,
        approvedTechnicians: approvedItems,
        biometrics,
        loading,
        error,
        getPendingTechnicians,
        getApprovedTechnicians,
        getTechnicianBiometrics,
        clearError,
    };
};