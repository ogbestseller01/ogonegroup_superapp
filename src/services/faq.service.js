import api from './api';

export const faqService = {
    getFaqs: (params) => api.get('/v6/faqs', { params }),
    getFaq: (id) => api.get(`/v6/faqs/${id}`),
    createFaq: (data) => api.post('/v6/faqs', data),
    updateFaq: (id, data) => api.put(`/v6/faqs/${id}`, data),
    deleteFaq: (id) => api.delete(`/v6/faqs/${id}`),
};