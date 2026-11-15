// src/contexts/DashboardContext.js
import React, { createContext, useContext, useState, useCallback } from 'react';
import { dashboardService } from 'services/dashboard.service';

const DashboardContext = createContext();

export const DashboardProvider = ({ children }) => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [analytics, setAnalytics] = useState(null);
    const [summary, setSummary] = useState(null);

    const fetchAnalytics = useCallback(async (params) => {
        setLoading(true);
        setError(null);
        try {
            const res = await dashboardService.getDashboardAnalytics(params);
            if (res.data) {
                setAnalytics(res.data.data);
            } else {
                throw new Error(res.data.message || 'Failed to fetch analytics');
            }
        } catch (err) {
            setError(err.message || 'An error occurred');
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchSummary = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const res = await dashboardService.getDashboardSummary();
            if (res.data) {
                setSummary(res.data.data);
            } else {
                throw new Error(res.data.message || 'Failed to fetch summary');
            }
        } catch (err) {
            setError(err.message || 'An error occurred');
        } finally {
            setLoading(false);
        }
    }, []);

    const clearError = useCallback(() => setError(null), []);

    const value = {
        loading,
        error,
        analytics,
        summary,
        fetchAnalytics,
        fetchSummary,
        clearError,
    };

    return <DashboardContext.Provider value={value}>{children}</DashboardContext.Provider>;
};

export const useDashboard = () => {
    const ctx = useContext(DashboardContext);
    if (!ctx) {
        throw new Error('useDashboard must be used within a DashboardProvider');
    }
    return ctx;
};