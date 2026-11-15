// src/contexts/LikeContext.js (Enhanced)
import React, { createContext, useContext, useState, useCallback } from 'react';
import { likeService } from 'services/like.service';

const LikeContext = createContext();

export const LikeProvider = ({ children }) => {
    const [likes, setLikes] = useState([]);
    const [likeCount, setLikeCount] = useState(0);
    const [isLiked, setIsLiked] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    // Get likes for a specific post
    const getPostLikes = useCallback(async (postId, params) => {
        setLoading(true);
        setError(null);
        try {
            const res = await likeService.getPostLikes(postId, { params });
            if (res.data.success) {
                setLikes(res.data.data);
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

    // Get all likes (admin)
    const getAllLikes = useCallback(async (params) => {
        setLoading(true);
        setError(null);
        try {
            const res = await likeService.getLikes(params);
            if (res.data.success) {
                setLikes(res.data.data);
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

    // Toggle like on a post
    const toggleLike = useCallback(async (postId) => {
        setLoading(true);
        setError(null);
        try {
            const res = await likeService.toggleLike(postId);
            if (res.data.success) {
                const { liked, likes_count } = res.data.data;
                setIsLiked(liked);
                setLikeCount(likes_count);
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

    // Get like count for a post
    const getLikeCount = useCallback(async (postId) => {
        setLoading(true);
        setError(null);
        try {
            const res = await likeService.getLikeCount(postId);
            if (res.data.success) {
                setLikeCount(res.data.data.count);
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

    // Check if user has liked a post
    const checkLikeStatus = useCallback(async (postId) => {
        setLoading(true);
        setError(null);
        try {
            const res = await likeService.checkLikeStatus(postId);
            if (res.data.success) {
                setIsLiked(res.data.data.liked);
                return res.data.data.liked;
            }
            throw new Error(res.data.message);
        } catch (err) {
            setError(err.message);
            return null;
        } finally {
            setLoading(false);
        }
    }, []);

    // Remove a specific like (admin)
    const removeLike = useCallback(async (id) => {
        setLoading(true);
        setError(null);
        try {
            const res = await likeService.removeLike(id);
            if (res.data.success) {
                setLikes(prev => prev.filter(like => like.id !== id));
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

    const clearError = useCallback(() => setError(null), []);

    const value = {
        likes,
        likeCount,
        isLiked,
        loading,
        error,
        getPostLikes,
        getAllLikes,
        toggleLike,
        getLikeCount,
        checkLikeStatus,
        removeLike,
        clearError,
    };

    return <LikeContext.Provider value={value}>{children}</LikeContext.Provider>;
};

export const useLikes = () => {
    const ctx = useContext(LikeContext);
    if (!ctx) {
        throw new Error('useLikes must be used within a LikeProvider');
    }
    return ctx;
};