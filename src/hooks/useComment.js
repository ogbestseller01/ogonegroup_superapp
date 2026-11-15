// src/hooks/useComment.js
import { useComments } from '../context/CommentContext';
import { useCallback } from 'react';

export const useCommentManagement = () => {
    const {
        items,
        loading,
        error,
        fetchAll,
        create,
        delete: remove,
        clearError
    } = useComments();

    const getComments = useCallback(async (params) => {
        return await fetchAll(params);
    }, [fetchAll]);

    const createComment = useCallback(async (postId, data) => {
        return await create({ postId, ...data });
    }, [create]);

    const deleteComment = useCallback(async (id) => {
        return await remove(id);
    }, [remove]);

    return {
        comments: items,
        loading,
        error,
        getComments,
        createComment,
        deleteComment,
        clearError,
    };
};