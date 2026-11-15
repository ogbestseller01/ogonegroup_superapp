// src/contexts/ServiceContext.js
import { createDataContext } from './createDataContext';
import { serviceService } from 'services/service.service';

const adapter = {
    getAll: async (params) => {
        try {
            const response = await serviceService.getServices(params);
            console.log('Services API response:', response);

            if (response?.data?.status === 'success') {
                const data = response.data.data;
                return { data: Array.isArray(data) ? data : [data] };
            }
            return { data: [] };
        } catch (error) {
            console.error('Services API error:', error);
            throw error;
        }
    },
    getOne: async (id) => {
        try {
            const response = await serviceService.getService(id);
            if (response?.data?.status === 'success') {
                return { data: response.data.data };
            }
            return { data: null };
        } catch (error) {
            console.error('Service API error:', error);
            throw error;
        }
    },
    create: async (data) => {
        try {
            const response = await serviceService.createService(data);
            if (response?.data?.status === 'success') {
                return { data: response.data.data };
            }
            return { data: null };
        } catch (error) {
            console.error('Create service error:', error);
            throw error;
        }
    },
    update: async (id, data) => {
        try {
            const response = await serviceService.updateService(id, data);
            if (response?.data?.status === 'success') {
                return { data: response.data.data };
            }
            return { data: null };
        } catch (error) {
            console.error('Update service error:', error);
            throw error;
        }
    },
    delete: async (id) => {
        try {
            const response = await serviceService.deleteService(id);
            // Check if deletion was successful
            if (response?.data?.status === 'success') {
                return { success: true, data: response.data };
            }
            // If the API returns a different success indicator
            if (response?.status === 200 || response?.status === 204) {
                return { success: true };
            }
            return { success: false };
        } catch (error) {
            console.error('Delete service error:', error);
            // Re-throw the error to be handled by the caller
            throw error;
        }
    },
};

export const { Provider: ServiceProvider, useResource: useServices } = createDataContext(adapter, 'Service');