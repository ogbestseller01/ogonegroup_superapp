// src/services/service.service.js
import api from './api';

export const serviceService = {
    // ─── Services (existing) ──────────────────────────────────
    getPublicServices: () => api.get('/v1/services'),
    getServices: (params) => api.get('/v11/services', { params }),
    getService: (id) => api.get(`/v11/services/${id}`),
    createService: (data) => api.post('/v11/services', data),
    updateService: (id, data) => api.put(`/v11/services/${id}`, data),
    deleteService: (id) => api.delete(`/v11/services/${id}`),
    getGroupedServices: () => api.get('/v11/services/grouped-by-category'),
    getTechniciansByService: (serviceId, params = {}) =>
        api.get('/v1/technicians', { params: { service_id: serviceId, ...params } }),

    // ─── Categories (new) ─────────────────────────────────────
    // GET /v17/service-categories
    getCategories: (params) => api.get('/v17/service-categories', { params }),
    // GET /v17/service-categories/{id}
    getCategory: (id) => api.get(`/v17/service-categories/${id}`),
    // POST /v17/service-categories
    createCategory: (data) => api.post('/v17/service-categories', data),
    // PUT /v17/service-categories/{id}
    updateCategory: (id, data) => api.put(`/v17/service-categories/${id}`, data),
    // DELETE /v17/service-categories/{id}
    deleteCategory: (id) => api.delete(`/v17/service-categories/${id}`),
    // Bulk delete (optional)
    bulkDeleteCategories: (ids) => api.delete('/v17/service-categories/bulk-delete', { data: { ids } }),

    // ─── Category Assignment (new) ────────────────────────────
    // Attach one or more categories to a service
    // POST /v11/services/{id}/attach-categories
    attachCategories: (serviceId, categoryIds) =>
        api.post(`/v11/services/${serviceId}/attach-categories`, { category_ids: categoryIds }),

    // Detach one or more categories from a service
    // DELETE /v11/services/{id}/detach-categories
    detachCategories: (serviceId, categoryIds) =>
        api.delete(`/v11/services/${serviceId}/detach-categories`, { data: { category_ids: categoryIds } }),

    // Sync (replace) all categories for a service
    // PUT /v11/services/{id}/sync-categories
    syncCategories: (serviceId, categoryIds) =>
        api.put(`/v11/services/${serviceId}/sync-categories`, { category_ids: categoryIds }),
};