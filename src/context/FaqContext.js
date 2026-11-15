import { createDataContext } from './createDataContext';
import { faqService } from 'services/faq.service';

const adapter = {
    isSingleRecord: false,
    getAll: async (params) => {
        try {
            const response = await faqService.getFaqs(params);
            if (response?.data?.status === 'success') {
                const data = response.data.data;
                return { data: Array.isArray(data) ? data : [data] };
            }
            return { data: [] };
        } catch (error) {
            console.error('FAQs API error:', error);
            throw error;
        }
    },
    getOne: async (id) => {
        try {
            const response = await faqService.getFaq(id);
            if (response?.data?.status === 'success') {
                return { data: response.data.data };
            }
            return { data: null };
        } catch (error) {
            console.error('FAQ API error:', error);
            throw error;
        }
    },
    create: (data) => faqService.createFaq(data),
    update: (id, data) => faqService.updateFaq(id, data),
    delete: (id) => faqService.deleteFaq(id),
};

export const { Provider: FaqProvider, useResource: useFaqs } = createDataContext(adapter, 'Faq');