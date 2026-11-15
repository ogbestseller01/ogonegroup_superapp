// src/utils/imageUtils.js
import api from '../services/api';

/**
 * Builds the full public URL for a stored file path using the api instance.
 * Returns null if path is invalid or missing.
 */
export const getImageUrl = (path) => {
    if (!path || typeof path !== 'string') return null;

    // If it's already an absolute URL, return as is
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    // Grab the base URL from the axios instance (e.g. http://192.168.100.144:8000/api)
    const apiUrl = api?.defaults?.baseURL || '';

    // Strip the trailing '/api' to get the root domain (e.g. http://192.168.100.144:8000)
    const rootUrl = apiUrl.replace(/\/api\/?$/, '');

    // Ensure the path doesn't start with a slash to avoid double slashes
    const cleanPath = path.replace(/^\/+/, '');

    return `${rootUrl}/storage/${cleanPath}`;
};

/** Detect base64-encoded image strings by magic bytes. */
export const isBase64Image = (str) => {
    if (!str || typeof str !== 'string') return false;
    return /^(\/9j\/|iVBOR|R0lGO|UklGR)/.test(str);
};

/** Resolve MIME type from base64 magic bytes. */
export const getBase64Mime = (str) => {
    if (!str || typeof str !== 'string') return 'image/jpeg';
    if (str.startsWith('/9j/'))  return 'image/jpeg';
    if (str.startsWith('iVBOR')) return 'image/png';
    if (str.startsWith('R0lGO')) return 'image/gif';
    if (str.startsWith('UklGR')) return 'image/webp';
    return 'image/jpeg';
};