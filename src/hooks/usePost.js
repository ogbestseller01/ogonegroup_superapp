// src/hooks/usePost.js
import { usePosts } from 'context/PostContext';
import { useCallback } from 'react';

export const usePostManagement = () => {
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
    } = usePosts();

    const getPosts = useCallback(async (params) => {
        return await fetchAll(params);
    }, [fetchAll]);

    const getPost = useCallback(async (id) => {
        return await fetchOne(id);
    }, [fetchOne]);

    const createPost = useCallback(async (data) => {
        return await create(data);
    }, [create]);

    const updatePost = useCallback(async (id, data) => {
        return await update(id, data);
    }, [update]);

    const deletePost = useCallback(async (id) => {
        return await remove(id);
    }, [remove]);

    return {
        posts: items,
        post: item,
        loading,
        error,
        getPosts,
        getPost,
        createPost,
        updatePost,
        deletePost,
        clearError,
    };
};