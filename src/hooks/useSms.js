// src/hooks/useSms.js
import { useSms } from 'context/SmsContext';
import { useCallback, useState } from 'react';
import { smsService } from 'services/sms.service';

export const useSmsManagement = () => {
    const {
        items,
        item,
        loading,
        error,
        fetchAll,
        create,
        delete: remove,
        clearError
    } = useSms();

    // Add pagination state
    const [pagination, setPagination] = useState({
        current_page: 1,
        per_page: 10,
        total: 0,
        last_page: 1
    });

    // Get all SMS logs with filters
    const getSmsLogs = useCallback(async (params = {}) => {
        try {
            const result = await fetchAll(params);
            if (result?.pagination) {
                setPagination(result.pagination);
            }
            return result;
        } catch (err) {
            console.error('Error fetching SMS logs:', err);
            throw err;
        }
    }, [fetchAll]);

    // Get SMS logs for a specific user
    const getUserSmsLogs = useCallback(async (userId, params = {}) => {
        try {
            const result = await fetchAll({ ...params, userId });
            if (result?.pagination) {
                setPagination(result.pagination);
            }
            return result;
        } catch (err) {
            console.error('Error fetching user SMS logs:', err);
            throw err;
        }
    }, [fetchAll]);

    // Get SMS balance
    const getSmsBalance = useCallback(async () => {
        try {
            const result = await smsService.getSmsBalance();
            console.log('📊 Balance API Response:', result);

            // Handle different response structures
            if (result?.data?.status === 'success') {
                return result.data.data;
            }
            if (result?.data) {
                return result.data;
            }
            return result;
        } catch (err) {
            console.error('Error fetching SMS balance:', err);
            throw err;
        }
    }, []);

    // Get SMS statistics - FIXED
    const getSmsStats = useCallback(async (params = {}) => {
        try {
            const result = await smsService.getSmsStats(params);
            console.log('📊 Stats API Response:', result);

            // Handle different response structures
            // Case 1: { status: 'success', data: { total: 3, sent: 2, ... } }
            if (result?.data?.status === 'success' && result.data.data) {
                return result.data.data;
            }
            // Case 2: { data: { total: 3, sent: 2, ... } }
            if (result?.data && !result.data.status) {
                return result.data;
            }
            // Case 3: { total: 3, sent: 2, ... } (direct)
            if (result?.total !== undefined) {
                return result;
            }
            // Case 4: The response is wrapped in another layer
            if (result?.data?.data) {
                return result.data.data;
            }
            // Default: return what we got
            return result;
        } catch (err) {
            console.error('Error fetching SMS stats:', err);
            throw err;
        }
    }, []);

    // Send a single SMS
    const sendSms = useCallback(async (data) => {
        try {
            const result = await smsService.sendSms(data);
            await fetchAll();
            return result;
        } catch (err) {
            console.error('Error sending SMS:', err);
            throw err;
        }
    }, [fetchAll]);

    // Resend failed SMS
    const resendSms = useCallback(async (logId) => {
        try {
            const result = await smsService.resendSms(logId);
            await fetchAll();
            return result;
        } catch (err) {
            console.error('Error resending SMS:', err);
            throw err;
        }
    }, [fetchAll]);

    // Delete SMS log
    const deleteSmsLog = useCallback(async (logId) => {
        try {
            const result = await remove(logId);
            await fetchAll();
            return result;
        } catch (err) {
            console.error('Error deleting SMS log:', err);
            throw err;
        }
    }, [remove, fetchAll]);

    return {
        logs: items,
        log: item,
        loading,
        error,
        pagination,
        getSmsLogs,
        getUserSmsLogs,
        getSmsBalance,
        getSmsStats,
        sendSms,
        resendSms,
        deleteSmsLog,
        clearError,
    };
};