// src/hooks/useLike.js
import { useLikes } from '../context/LikeContext';
import { useCallback } from 'react';

export const useLikeManagement = () => {
    const {
        items,
        loading,
        error,
        fetchAll,
        create,
        delete: remove,
        clearError
    } = useLikes();

    const getLikes = useCallback(async (params) => {
        return await fetchAll(params);
    }, [fetchAll]);

    const toggleLike = useCallback(async (postId) => {
        return await create({ postId });
    }, [create]);

    const removeLike = useCallback(async (id) => {
        return await remove(id);
    }, [remove]);

    return {
        likes: items,
        loading,
        error,
        getLikes,
        toggleLike,
        removeLike,
        clearError,
    };
};