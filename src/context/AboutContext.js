import { createDataContext } from './createDataContext';
import { aboutService } from 'services/about.service';

const adapter = {
    isSingleRecord: true,
    getAll: async () => {
        try {
            const response = await aboutService.getAbout();
            if (response?.data?.status === 'success') {
                const data = response.data.data;
                return { data: data ? [data] : [] };
            }
            return { data: [] };
        } catch (error) {
            console.error('About API error:', error);
            throw error;
        }
    },
    getOne: null,
    create: (data) => aboutService.createAbout(data),
    update: (id, data) => aboutService.updateAbout(data),
    delete: () => aboutService.deleteAbout(),
};

export const { Provider: AboutProvider, useResource: useAbout } = createDataContext(adapter, 'About');