// src/hooks/useDashboard.js
import { useDashboard } from 'context/DashboardContext';
import { useCallback } from 'react';

export const useDashboardManagement = () => {
    const {
        loading,
        error,
        analytics,
        summary,
        fetchAnalytics,
        fetchSummary,
        clearError,
    } = useDashboard();

    const getDashboardAnalytics = useCallback(async (params) => {
        return await fetchAnalytics(params);
    }, [fetchAnalytics]);

    const getDashboardSummary = useCallback(async () => {
        return await fetchSummary();
    }, [fetchSummary]);

    return {
        analytics,
        summary,
        loading,
        error,
        getDashboardAnalytics,
        getDashboardSummary,
        clearError,
    };
};