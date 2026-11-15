// src/services/systemUpdate.service.js
import api from './api';

const BASE = '/v26/admin/system-updates';

export const systemUpdateService = {
    // ─── List & Single ───────────────────────────────────────
    // GET /v26/admin/system-updates?status=&search=&per_page=&page=
    getSystemUpdates: (params) => api.get(BASE, { params }),

    // GET /v26/admin/system-updates/{id}
    getSystemUpdate: (id) => api.get(`${BASE}/${id}`),

    // ─── Create ──────────────────────────────────────────────
    // POST /v26/admin/system-updates  ({ title, description, send_push, send_sms, publish? })
    createSystemUpdate: (data) => api.post(BASE, data),

    // POST /v26/admin/system-updates/draft  ({ id?, title, description, send_push, send_sms })
    saveSystemUpdateDraft: (data) => api.post(`${BASE}/draft`, data),

    // ─── Update / Publish / Close / Delete ───────────────────
    // PUT /v26/admin/system-updates/{id}
    updateSystemUpdate: (id, data) => api.put(`${BASE}/${id}`, data),

    // POST /v26/admin/system-updates/{id}/publish
    publishSystemUpdate: (id) => api.post(`${BASE}/${id}/publish`),

    // POST /v26/admin/system-updates/{id}/close
    closeSystemUpdate: (id) => api.post(`${BASE}/${id}/close`),

    // DELETE /v26/admin/system-updates/{id}
    deleteSystemUpdate: (id) => api.delete(`${BASE}/${id}`),
};