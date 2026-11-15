// src/context/FinanceContext.js
import React, { createContext, useContext, useState, useCallback } from 'react';
import { financeService } from 'services/finance.service';

const FinanceContext = createContext();

export const FinanceProvider = ({ children }) => {
    const [loadingSummary, setLoadingSummary] = useState(false);
    const [loadingTrends, setLoadingTrends] = useState(false);
    const [loadingTable, setLoadingTable] = useState(false);
    const [exporting, setExporting] = useState(false);
    const [error, setError] = useState(null);

    const [summary, setSummary] = useState({ totals: {}, status_breakdown: [] });
    const [trends, setTrends] = useState({ buckets: [] });
    const [table, setTable] = useState({ data: [], pagination: {} });

    // ============================================================
    // SUMMARY (pie chart + top cards)
    // ============================================================
    const fetchSummary = useCallback(async (params) => {
        setLoadingSummary(true);
        setError(null);
        try {
            const res = await financeService.getSummary(params);
            if (res?.data?.status === 'success') {
                setSummary(res.data.data);
                return res.data.data;
            }
            throw new Error(res?.data?.message || 'Failed to fetch finance summary');
        } catch (err) {
            setError(err.message || 'An error occurred');
            throw err;
        } finally {
            setLoadingSummary(false);
        }
    }, []);

    // ============================================================
    // TRENDS (bar chart / histogram)
    // ============================================================
    const fetchTrends = useCallback(async (params) => {
        setLoadingTrends(true);
        setError(null);
        try {
            const res = await financeService.getTrends(params);
            if (res?.data?.status === 'success') {
                setTrends(res.data.data);
                return res.data.data;
            }
            throw new Error(res?.data?.message || 'Failed to fetch finance trends');
        } catch (err) {
            setError(err.message || 'An error occurred');
            throw err;
        } finally {
            setLoadingTrends(false);
        }
    }, []);

    // ============================================================
    // TABLE (bottom listing)
    // ============================================================
    const fetchTable = useCallback(async (params) => {
        setLoadingTable(true);
        setError(null);
        try {
            const res = await financeService.getTable(params);
            if (res?.data?.status === 'success') {
                const data = res.data.data;
                const formatted = {
                    data: data?.data || [],
                    pagination: {
                        total: data?.total || 0,
                        per_page: data?.per_page,
                        current_page: data?.current_page,
                        last_page: data?.last_page,
                    },
                };
                setTable(formatted);
                return formatted;
            }
            throw new Error(res?.data?.message || 'Failed to fetch finance table');
        } catch (err) {
            setError(err.message || 'An error occurred');
            throw err;
        } finally {
            setLoadingTable(false);
        }
    }, []);

    // ============================================================
    // EXPORT (csv / xlsx)
    // ============================================================
    const exportReport = useCallback(async (params) => {
        setExporting(true);
        setError(null);
        try {
            const response = await financeService.exportReport(params);
            return response;
        } catch (err) {
            setError(err.message || 'Export failed');
            throw err;
        } finally {
            setExporting(false);
        }
    }, []);

    const clearError = useCallback(() => setError(null), []);

    const value = {
        // state
        summary,
        trends,
        table,
        loadingSummary,
        loadingTrends,
        loadingTable,
        exporting,
        error,
        // actions
        fetchSummary,
        fetchTrends,
        fetchTable,
        exportReport,
        clearError,
    };

    return <FinanceContext.Provider value={value}>{children}</FinanceContext.Provider>;
};

export const useFinance = () => {
    const ctx = useContext(FinanceContext);
    if (!ctx) {
        throw new Error('useFinance must be used within a FinanceProvider');
    }
    return ctx;
};