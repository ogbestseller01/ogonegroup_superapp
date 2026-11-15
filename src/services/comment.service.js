// src/services/comment.service.js
import api from './api';

export const commentService = {
    // ===== USER =====
    createComment: (postId, data) => api.post(`/v5/posts/${postId}/comments`, data),
    deleteComment: (id) => api.delete(`/v5/comments/${id}`),

    // ===== ADMIN/MANAGER =====
    getAdminComments: (params) => api.get('/v5/admin/comments', { params }),
};