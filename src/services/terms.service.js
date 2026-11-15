import api from './api';

export const termsService = {
    getTerms: () => api.get('/v6/terms'),
    createTerms: (data) => api.post('/v6/terms', data),
    updateTerms: (data) => api.put('/v6/terms', data),
    deleteTerms: () => api.delete('/v6/terms'),
};