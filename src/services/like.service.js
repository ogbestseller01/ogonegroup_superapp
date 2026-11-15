// src/services/like.service.js
import api from './api';

export const likeService = {
    toggleLike: (postId) => api.post(`/v5/posts/${postId}/like`),
};