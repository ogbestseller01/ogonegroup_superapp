// src/services/post.service.js
import api from './api';

/**
 * Build a FormData payload for create/update, supporting multiple images
 * and a single video file.
 */
const buildPostFormData = (data = {}, isUpdate = false) => {
    const form = new FormData();
    if (isUpdate) form.append('_method', 'PUT');

    // Handle Video
    if (data.video) {
        if (data.video instanceof File || data.video instanceof Blob) {
            form.append('video', data.video);
        }
    }

    if (isUpdate && data.remove_video) {
        form.append('remove_video', '1');
    }

    // Handle Images
    if (isUpdate && Array.isArray(data.keep_images)) {
        data.keep_images.forEach((url) => {
            if (url) form.append('keep_images[]', String(url));
        });
        form.append('images_managed', '1');
    }

    const newFiles = Array.isArray(data.images) ? data.images : [];

    newFiles.forEach((file) => {
        if (file instanceof File || file instanceof Blob) {
            form.append('images[]', file);
        }
    });

    return form;
};

const isFormData = (v) =>
    typeof FormData !== 'undefined' && v instanceof FormData;

export const postService = {
    // ===== PUBLIC =====
    getAllPosts: (params) => api.get('/v1/posts', { params }),
    getPost: (id) => api.get(`/v1/posts/${id}`),

    // ===== LIKES & COMMENTS =====
    likePost: (postId) => api.post(`/v5/posts/${postId}/like`),
    commentOnPost: (postId, comment) =>
        api.post(`/v5/posts/${postId}/comments`, { content: comment }),
    deleteComment: (id) => api.delete(`/v5/comments/${id}`),

    // ===== TECHNICIAN (Authenticated) =====
    getMyPosts: (params) => api.get('/v5/my-posts', { params }),

    createPost: (data) =>
        api.post(
            '/v5/posts',
            isFormData(data) ? data : buildPostFormData(data, false),
            { headers: { 'Content-Type': undefined } }
        ),

    updatePost: (id, data) =>
        api.post(
            `/v5/posts/${id}`,
            isFormData(data) ? data : buildPostFormData(data, true),
            { headers: { 'Content-Type': undefined } }
        ),

    deletePost: (id) => api.delete(`/v5/posts/${id}`),

    // ===== ADMIN/MANAGER =====
    getAllPostsAdmin: (params) => api.get('/v5/admin/posts/all', { params }),
};