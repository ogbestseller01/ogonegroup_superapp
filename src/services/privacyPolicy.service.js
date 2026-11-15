// src/services/privacyPolicy.service.js
import api from './api';

export const privacyPolicyService = {
    // Singleton (get the first/latest)
    getPrivacyPolicy: () => api.get('/v18/privacy-policy'),

    // Collection
    getPrivacyPolicies: () => api.get('/v18/privacy-policies'),

    // Create a new policy (if none exists)
    createPrivacyPolicy: (data) => api.post('/v18/privacy-policies', data),

    // Update a specific policy by ID
    updatePrivacyPolicy: (id, data) => api.put(`/v18/privacy-policies/${id}`, data),

    // Delete a policy by ID
    deletePrivacyPolicy: (id) => api.delete(`/v18/privacy-policies/${id}`),

    // Convenience: update the singleton (upsert)
    updateSingletonPrivacyPolicy: (data) => api.put('/v18/privacy-policy', data),
};