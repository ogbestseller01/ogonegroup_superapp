import React, { createContext, useContext, useState, useCallback } from 'react';

export function createFinanceContext(service, name) {
    const Ctx = createContext();

    const Provider = ({ children }) => {
        const [summary, setSummary] = useState({ totals: {}, status_breakdown: [] });
        const [trends, setTrends] = useState({ buckets: [] });
        const [table, setTable] = useState({ data: [], pagination: {} });
        const [loadingSummary, setLoadingSummary] = useState(false);
        const [loadingTrends, setLoadingTrends] = useState(false);
        const [loadingTable, setLoadingTable] = useState(false);
        const [exporting, setExporting] = useState(false);
        const [error, setError] = useState(null);

        const fetchSummary = useCallback(async (params) => {
            setLoadingSummary(true); setError(null);
            try {
                const res = await service.getSummary(params);
                if (res?.data?.status === 'success') { setSummary(res.data.data); return res.data.data; }
                throw new Error(res?.data?.message || `Failed to fetch ${name} summary`);
            } catch (err) { setError(err.message); throw err; }
            finally { setLoadingSummary(false); }
        }, []);

        const fetchTrends = useCallback(async (params) => {
            setLoadingTrends(true); setError(null);
            try {
                const res = await service.getTrends(params);
                if (res?.data?.status === 'success') { setTrends(res.data.data); return res.data.data; }
                throw new Error(res?.data?.message || `Failed to fetch ${name} trends`);
            } catch (err) { setError(err.message); throw err; }
            finally { setLoadingTrends(false); }
        }, []);

        const fetchTable = useCallback(async (params) => {
            setLoadingTable(true); setError(null);
            try {
                const res = await service.getTable(params);
                if (res?.data?.status === 'success') {
                    const data = res.data.data;
                    const formatted = {
                        data: data?.data || [],
                        pagination: { total: data?.total || 0, current_page: data?.current_page, last_page: data?.last_page },
                    };
                    setTable(formatted);
                    return formatted;
                }
                throw new Error(res?.data?.message || `Failed to fetch ${name} table`);
            } catch (err) { setError(err.message); throw err; }
            finally { setLoadingTable(false); }
        }, []);

        const exportReport = useCallback(async (params) => {
            setExporting(true); setError(null);
            try { return await service.exportReport(params); }
            catch (err) { setError(err.message || 'Export failed'); throw err; }
            finally { setExporting(false); }
        }, []);

        const clearError = useCallback(() => setError(null), []);

        const value = {
            summary, trends, table,
            loadingSummary, loadingTrends, loadingTable, exporting, error,
            fetchSummary, fetchTrends, fetchTable, exportReport, clearError,
        };

        return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
    };

    const useThisFinance = () => {
        const ctx = useContext(Ctx);
        if (!ctx) throw new Error(`useFinance for ${name} must be used within its Provider`);
        return ctx;
    };

    return { Provider, useFinance: useThisFinance };
}