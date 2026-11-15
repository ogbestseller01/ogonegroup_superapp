// src/context/AdminTechnicianContext.js
import { createDataContext } from './createDataContext';
import { technicianService } from 'services/technician.service';

const adapter = {
    getAll: async (params) => {
        try {
            const response = await technicianService.getAdminTechnicians(params);
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
                        },
                    };
                }
                if (Array.isArray(data)) {
                    return { data };
                }
                if (data) {
                    return { data: [data] };
                }
            }
            return { data: [] };
        } catch (error) {
            console.error('Admin technicians API error:', error);
            throw error;
        }
    },
    getOne: async (id) => {
        try {
            const response = await technicianService.getTechnician(id);
            if (response?.data?.status === 'success') {
                return { data: response.data.data };
            }
            return { data: null };
        } catch (error) {
            console.error('Technician API error:', error);
            throw error;
        }
    },
};

export const { Provider: AdminTechnicianProvider, useResource: useAdminTechnicians } =
    createDataContext(adapter, 'AdminTechnician');