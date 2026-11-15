// src/contexts/AuditContext.js
import { createDataContext } from './createDataContext';
import { auditService } from 'services/audit.service';

const adapter = {
    getAll: async (params) => {
        try {
            const response = await auditService.getAuditTrails(params);
            console.log('Audit response:', response);

            if (response?.data?.status === 'success') {
                const data = response.data.data;
                if (data && data.data) {
                    return {
                        data: data.data,
                        pagination: {
                            total: data.total,
                            per_page: data.per_page,
                            current_page: data.current_page,
                            last_page: data.last_page,
                        }
                    };
                }
                return { data: Array.isArray(data) ? data : [data] };
            }
            return { data: [] };
        } catch (error) {
            console.error('Audit API error:', error);
            throw error;
        }
    },
    getOne: null,
    create: null,
    update: null,
    delete: null,
};

export const { Provider: AuditProvider, useResource: useAudits } = createDataContext(adapter, 'Audit');