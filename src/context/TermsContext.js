import { createDataContext } from './createDataContext';
import { termsService } from 'services/terms.service';

const adapter = {
    isSingleRecord: true,
    getAll: async () => {
        try {
            const response = await termsService.getTerms();
            if (response?.data?.status === 'success') {
                const data = response.data.data;
                return { data: data ? [data] : [] };
            }
            return { data: [ ] };
        } catch (error) {
            console.error('Terms API error:', error);
            throw error;
        }
    },
    getOne: null,
    create: (data) => termsService.createTerms(data),
    update: (id, data) => termsService.updateTerms(data),
    delete: () => termsService.deleteTerms(),
};

export const { Provider: TermsProvider, useResource: useTerms } = createDataContext(adapter, 'Terms');