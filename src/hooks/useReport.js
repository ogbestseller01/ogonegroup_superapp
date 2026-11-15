import { useReport as useCtx } from 'context/ReportContext';
import { useCallback } from 'react';

export const useReportManagement = () => {
    const {
        summary, trends, detailed, overview,
        loadingSummary, loadingTrends, loadingDetailed, loadingOverview, exporting, error,
        fetchSummary, fetchTrends, fetchDetailed, fetchOverview, exportReport, clearError,
    } = useCtx();

    return {
        summary, trends, detailed, overview,
        loadingSummary, loadingTrends, loadingDetailed, loadingOverview, exporting, error,
        getSummary: useCallback((p) => fetchSummary(p), [fetchSummary]),
        getTrends: useCallback((p) => fetchTrends(p), [fetchTrends]),
        getDetailed: useCallback((p) => fetchDetailed(p), [fetchDetailed]),
        getOverview: useCallback((p) => fetchOverview(p), [fetchOverview]),
        exportFinanceReport: useCallback((p) => exportReport(p), [exportReport]),
        clearError,
    };
};