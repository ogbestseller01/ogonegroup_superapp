// src/hooks/useSystemUpdate.js
import { useCallback } from 'react';
import { useSystemUpdates } from 'context/SystemUpdateContext';

export const useSystemUpdateManagement = () => {
    const {
        items,
        item,
        pagination,
        loading,
        submitting,
        error,
        fetchAll,
        fetchOne,
        create,
        saveDraft,
        update,
        publish,
        close,
        remove,
        clearError,
    } = useSystemUpdates();

    const getSystemUpdates = useCallback((params) => fetchAll(params), [fetchAll]);
    const getSystemUpdate = useCallback((id) => fetchOne(id), [fetchOne]);
    const createSystemUpdate = useCallback((payload) => create(payload), [create]);
    const saveSystemUpdateDraft = useCallback((payload) => saveDraft(payload), [saveDraft]);
    const updateSystemUpdate = useCallback((id, payload) => update(id, payload), [update]);
    const publishSystemUpdate = useCallback((id) => publish(id), [publish]);
    const closeSystemUpdate = useCallback((id) => close(id), [close]);
    const deleteSystemUpdate = useCallback((id) => remove(id), [remove]);

    return {
        systemUpdates: items,
        systemUpdate: item,
        pagination,
        loading,
        submitting,
        error,
        getSystemUpdates,
        getSystemUpdate,
        createSystemUpdate,
        saveSystemUpdateDraft,
        updateSystemUpdate,
        publishSystemUpdate,
        closeSystemUpdate,
        deleteSystemUpdate,
        clearError,
    };
};