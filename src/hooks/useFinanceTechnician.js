import { useFinanceTechnician as useCtx } from 'context/FinanceTechnicianContext';
import { useCallback } from 'react';

export const useFinanceTechnicianManagement = () => {
    const { summary, trends, table, loadingSummary, loadingTrends, loadingTable, exporting, error,
        fetchSummary, fetchTrends, fetchTable, exportReport, clearError } = useCtx();

    return {
        summary, trends, table, loadingSummary, loadingTrends, loadingTable, exporting, error,
        getSummary: useCallback((p) => fetchSummary(p), [fetchSummary]),
        getTrends: useCallback((p) => fetchTrends(p), [fetchTrends]),
        getTable: useCallback((p) => fetchTable(p), [fetchTable]),
        exportFinanceReport: useCallback((p) => exportReport(p), [exportReport]),
        clearError,
    };
};