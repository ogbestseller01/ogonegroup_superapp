// src/context/PrivacyPolicyContext.js
import { createDataContext } from './createDataContext';
import { privacyPolicyService } from 'services/privacyPolicy.service';

const adapter = {
    isSingleRecord: true,
    getAll: async () => {
        try {
            const response = await privacyPolicyService.getPrivacyPolicy();
            if (response?.data?.status === 'success') {
                const data = response.data.data;
                return { data: data ? [data] : [] };
            }
            return { data: [] };
        } catch (error) {
            console.error('Privacy policy API error:', error);
            throw error;
        }
    },
    getOne: null,
    create: (data) => privacyPolicyService.createPrivacyPolicy(data),
    update: (id, data) => privacyPolicyService.updatePrivacyPolicy(id, data),
    delete: (id) => privacyPolicyService.deletePrivacyPolicy(id),
};

export const { Provider: PrivacyPolicyProvider, useResource: usePrivacyPolicy } =
    createDataContext(adapter, 'PrivacyPolicy');