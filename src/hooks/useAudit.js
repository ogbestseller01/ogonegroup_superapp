// src/hooks/useAudit.js
import { useAudits } from 'context/AuditContext';
import { useCallback } from 'react';

export const useAuditManagement = () => {
    const {
        items,
        loading,
        error,
        fetchAll,
        clearError
    } = useAudits();

    const getAudits = useCallback(async (params) => {
        return fetchAll(params);
    }, [fetchAll]);

    return {
        audits: items,
        loading,
        error,
        getAudits,
        clearError,
    };
};