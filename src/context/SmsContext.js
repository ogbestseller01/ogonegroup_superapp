// src/context/SmsContext.js
import { createDataContext } from './createDataContext';
import { smsService } from 'services/sms.service';

const adapter = {
    getAll: async (params) => {
        try {
            const response = await smsService.getSmsLogs(params);

            if (response?.data?.status === 'success') {
                const data = response.data.data;

                // Handle paginated response
                if (data && data.data) {
                    return {
                        data: data.data,
                        pagination: data.pagination || {
                            total: data.total || data.data.length,
                            per_page: data.per_page || 20,
                            current_page: data.current_page || 1,
                            last_page: data.last_page || 1,
                        }
                    };
                }

                // Handle direct array response
                if (Array.isArray(data)) {
                    return {
                        data: data,
                        pagination: {
                            total: data.length,
                            per_page: 20,
                            current_page: 1,
                            last_page: 1,
                        }
                    };
                }
            }

            return { data: [], pagination: { total: 0, per_page: 20, current_page: 1, last_page: 1 } };
        } catch (error) {
            console.error('Error fetching SMS logs:', error);
            throw error;
        }
    },

    getOne: (id) => {
        return Promise.reject(new Error('Not implemented'));
    },

    create: (data) => smsService.sendSms(data),

    update: (id, data) => {
        return Promise.reject(new Error('Not implemented'));
    },

    delete: (id) => smsService.deleteSmsLog(id),

    getDropdown: () => {
        return Promise.reject(new Error('Not implemented'));
    },

    // ===== CUSTOM METHODS =====
    getUserLogs: async (userId, params) => {
        try {
            const response = await smsService.getUserSmsLogs(userId, params);
            if (response?.data?.status === 'success') {
                const data = response.data.data;
                if (data && data.data) {
                    return {
                        data: data.data,
                        pagination: data.pagination || {
                            total: data.total || data.data.length,
                            per_page: data.per_page || 20,
                            current_page: data.current_page || 1,
                            last_page: data.last_page || 1,
                        }
                    };
                }
                if (Array.isArray(data)) {
                    return {
                        data: data,
                        pagination: {
                            total: data.length,
                            per_page: 20,
                            current_page: 1,
                            last_page: 1,
                        }
                    };
                }
            }
            return { data: [], pagination: { total: 0, per_page: 20, current_page: 1, last_page: 1 } };
        } catch (error) {
            console.error('Error fetching user SMS logs:', error);
            throw error;
        }
    },

    getBalance: async () => {
        try {
            const response = await smsService.getSmsBalance();
            if (response?.data?.status === 'success') {
                return response.data.data;
            }
            return { balance: 0, currency: 'TZS' };
        } catch (error) {
            console.error('Error fetching SMS balance:', error);
            throw error;
        }
    },

    getStats: async (params) => {
        try {
            const response = await smsService.getSmsStats(params);
            if (response?.data?.status === 'success') {
                return response.data.data;
            }
            return null;
        } catch (error) {
            console.error('Error fetching SMS stats:', error);
            throw error;
        }
    },

    sendSms: async (data) => {
        try {
            const response = await smsService.sendSms(data);
            return response.data;
        } catch (error) {
            console.error('Error sending SMS:', error);
            throw error;
        }
    },

    resendSms: async (logId) => {
        try {
            const response = await smsService.resendSms(logId);
            return response.data;
        } catch (error) {
            console.error('Error resending SMS:', error);
            throw error;
        }
    },

    deleteSmsLog: async (logId) => {
        try {
            const response = await smsService.deleteSmsLog(logId);
            return response.data;
        } catch (error) {
            console.error('Error deleting SMS log:', error);
            throw error;
        }
    }
};

export const { Provider: SmsProvider, useResource: useSms } = createDataContext(adapter, 'Sms');