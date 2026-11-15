// src/contexts/CommentContext.js (Enhanced)
import React, { createContext, useContext, useState, useCallback } from 'react';
import { commentService } from 'services/comment.service';

const CommentContext = createContext();

export const CommentProvider = ({ children }) => {
    const [comments, setComments] = useState([]);
    const [commentCount, setCommentCount] = useState(0);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [pagination, setPagination] = useState({
        current_page: 1,
        per_page: 15,
        total: 0,
        total_pages: 0,
    });

    // Get comments for a specific post
    const getPostComments = useCallback(async (postId, params = {}) => {
        setLoading(true);
        setError(null);
        try {
            const res = await commentService.getPostComments(postId, params);
            if (res.data.success) {
                const data = res.data.data;
                setComments(Array.isArray(data) ? data : data.data || []);
                if (data.meta) {
                    setPagination({
                        current_page: data.meta.current_page || 1,
                        per_page: data.meta.per_page || 15,
                        total: data.meta.total || 0,
                        total_pages: data.meta.last_page || 0,
                    });
                }
                return res.data.data;
            }
            throw new Error(res.data.message);
        } catch (err) {
            setError(err.message);
            return null;
        } finally {
            setLoading(false);
        }
    }, []);

    // Get all comments (admin)
    const getAllComments = useCallback(async (params = {}) => {
        setLoading(true);
        setError(null);
        try {
            const res = await commentService.getAdminComments(params);
            if (res.data.success) {
                const data = res.data.data;
                setComments(Array.isArray(data) ? data : data.data || []);
                if (data.meta) {
                    setPagination({
                        current_page: data.meta.current_page || 1,
                        per_page: data.meta.per_page || 15,
                        total: data.meta.total || 0,
                        total_pages: data.meta.last_page || 0,
                    });
                }
                return res.data.data;
            }
            throw new Error(res.data.message);
        } catch (err) {
            setError(err.message);
            return null;
        } finally {
            setLoading(false);
        }
    }, []);

    // Create a comment
    const createComment = useCallback(async (postId, data) => {
        setLoading(true);
        setError(null);
        try {
            const res = await commentService.createComment(postId, data);
            if (res.data.success) {
                const newComment = res.data.data;
                setComments(prev => [newComment, ...prev]);
                setCommentCount(prev => prev + 1);
                return newComment;
            }
            throw new Error(res.data.message);
        } catch (err) {
            setError(err.message);
            return null;
        } finally {
            setLoading(false);
        }
    }, []);

    // Update a comment
    const updateComment = useCallback(async (id, data) => {
        setLoading(true);
        setError(null);
        try {
            const res = await commentService.updateComment(id, data);
            if (res.data.success) {
                const updatedComment = res.data.data;
                setComments(prev => prev.map(comment =>
                    comment.id === id ? updatedComment : comment
                ));
                return updatedComment;
            }
            throw new Error(res.data.message);
        } catch (err) {
            setError(err.message);
            return null;
        } finally {
            setLoading(false);
        }
    }, []);

    // Delete a comment
    const deleteComment = useCallback(async (id) => {
        setLoading(true);
        setError(null);
        try {
            const res = await commentService.deleteComment(id);
            if (res.data.success) {
                setComments(prev => prev.filter(comment => comment.id !== id));
                setCommentCount(prev => Math.max(0, prev - 1));
                return true;
            }
            throw new Error(res.data.message);
        } catch (err) {
            setError(err.message);
            return false;
        } finally {
            setLoading(false);
        }
    }, []);

    // Get comment count for a post
    const getCommentCount = useCallback(async (postId) => {
        setLoading(true);
        setError(null);
        try {
            const res = await commentService.getCommentCount(postId);
            if (res.data.success) {
                setCommentCount(res.data.data.count);
                return res.data.data.count;
            }
            throw new Error(res.data.message);
        } catch (err) {
            setError(err.message);
            return null;
        } finally {
            setLoading(false);
        }
    }, []);

    // Get recent comments
    const getRecentComments = useCallback(async (limit = 10) => {
        setLoading(true);
        setError(null);
        try {
            const res = await commentService.getRecentComments(limit);
            if (res.data.success) {
                setComments(res.data.data);
                return res.data.data;
            }
            throw new Error(res.data.message);
        } catch (err) {
            setError(err.message);
            return null;
        } finally {
            setLoading(false);
        }
    }, []);

    const clearError = useCallback(() => setError(null), []);

    const value = {
        comments,
        commentCount,
        loading,
        error,
        pagination,
        getPostComments,
        getAllComments,
        createComment,
        updateComment,
        deleteComment,
        getCommentCount,
        getRecentComments,
        clearError,
    };

    return <CommentContext.Provider value={value}>{children}</CommentContext.Provider>;
};

export const useComments = () => {
    const ctx = useContext(CommentContext);
    if (!ctx) {
        throw new Error('useComments must be used within a CommentProvider');
    }
    return ctx;
};