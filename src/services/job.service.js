// src/services/job.service.js
import api from './api';

export const jobService = {
    // ── list / show ─────────────────────────────────────
    getJobs:          (params) => api.get('/v4/admin/jobs', { params }),
    getJob:           (id)     => api.get(`/v4/jobs/${id}`),
    getJobStats:      (params) => api.get('/v4/admin/jobs/stats', { params }),
    getJobHistogram:  (params) => api.get('/v4/admin/jobs/histogram', { params }),
    getJobChartData:  (params) => api.get('/v4/admin/jobs/chart-data', { params }),

    // ── OTP ────────────────────────────────────────────
    requestCompletion: (id)      => api.post(`/v4/jobs/${id}/request-completion`),
    verifyCompletion:  (id, otp) => api.post(`/v4/jobs/${id}/verify-completion`, { otp }),

    // ── review ─────────────────────────────────────────
    reviewJob: (id, payload) => api.post(`/v4/jobs/${id}/review`, payload),
};