// src/utils/postMedia.js
import { getImageUrl as formatImageUrl } from 'utils/imageUtils';

/**
 * Build a full URL for a storage path or return the URL as-is.
 * Delegates to the central imageUtils to keep environment variables in one place.
 */
export const getImageUrl = (path) => {
    if (!path) return null;
    const str = String(path).trim();
    if (!str) return null;
    if (/^https?:\/\//i.test(str)) return str;
    if (str.startsWith('data:') || str.startsWith('blob:')) return str;

    // Delegate to the shared image utility
    return formatImageUrl(str);
};

/**
 * Normalize the list of images for a post.
 * Supports the new `image_urls` array from the backend.
 */
export const getPostImages = (post) => {
    if (!post) return [];
    const raw = post.image_urls ?? post.images ?? [];
    if (!Array.isArray(raw)) return [];
    return raw.filter((x) => x != null && String(x).trim() !== '');
};

/**
 * Normalize a post object so `images` and `technician` fields are predictable
 * throughout the web app.
 */
export const normalizePost = (post) => {
    if (!post) return post;
    const images = getPostImages(post);
    const tech = post.technician
        ? {
            ...post.technician,
            name:
                post.technician.user?.name ||
                post.technician.name ||
                'Fundi',
            avatar:
                post.technician.profile_photo ||
                post.technician.user?.profile_photo ||
                null,
        }
        : null;

    return {
        ...post,
        images,
        video_url: post.video_url || null,
        technician: tech,
    };
};

export const normalizePosts = (list) =>
    Array.isArray(list) ? list.map(normalizePost) : [];