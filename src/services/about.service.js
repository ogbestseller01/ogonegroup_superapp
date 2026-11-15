import api from './api';

export const aboutService = {
    getAbout: () => api.get('/v6/about'),
    createAbout: (data) => api.post('/v6/about', data),
    updateAbout: (data) => api.put('/v6/about', data),
    deleteAbout: () => api.delete('/v6/about'),
};