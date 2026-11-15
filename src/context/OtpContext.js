// src/contexts/OtpContext.js
import { createDataContext } from './createDataContext';
import { otpService } from 'services/otp.service';

const adapter = {
    getAll: async (params) => {
        try {
            const response = await otpService.getOtps(params);
            console.log('OTP response:', response);

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
                        stats: data.stats || null
                    };
                }
                return { data: Array.isArray(data) ? data : [data] };
            }
            return { data: [] };
        } catch (error) {
            console.error('OTP API error:', error);
            throw error;
        }
    },
    getOne: null,
    create: null,
    update: null,
    delete: null,
};

export const { Provider: OtpProvider, useResource: useOtps } = createDataContext(adapter, 'Otp');