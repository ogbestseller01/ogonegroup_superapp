// src/hooks/useOtp.js
import { useOtps } from 'context/OtpContext';
import { useCallback } from 'react';

export const useOtpManagement = () => {
    const {
        items,
        loading,
        error,
        fetchAll,
        clearError
    } = useOtps();

    const getOtps = useCallback(async (params) => {
        return fetchAll(params);
    }, [fetchAll]);

    return {
        otps: items,
        loading,
        error,
        getOtps,
        clearError,
    };
};