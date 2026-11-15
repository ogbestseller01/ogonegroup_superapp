import { useAbout } from 'context/AboutContext';
import { useCallback } from 'react';

export const useAboutManagement = () => {
    const {
        items,
        item,
        loading,
        error,
        fetchAll,
        create,
        update,
        delete: remove,
        clearError
    } = useAbout();

    const getAbout = useCallback(async () => fetchAll(), [fetchAll]);
    const createAbout = useCallback(async (data) => {
        const result = await create(data);
        await fetchAll();
        return result;
    }, [create, fetchAll]);
    const updateAbout = useCallback(async (data) => {
        const result = await update(null, data);
        await fetchAll();
        return result;
    }, [update, fetchAll]);
    const deleteAbout = useCallback(async () => {
        const result = await remove(null);
        await fetchAll();
        return result;
    }, [remove, fetchAll]);

    return {
        about: items,
        loading,
        error,
        getAbout,
        createAbout,
        updateAbout,
        deleteAbout,
        clearError,
    };
};