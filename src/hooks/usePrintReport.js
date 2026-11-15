// src/hooks/usePrintReport.js
import { useCallback } from 'react';
import { usePrintReports } from 'context/PrintReportContext';
import { printReportService } from 'services/printReport.service';

export const usePrintReportManagement = () => {
    const {
        items, loading, error, fetchAll, clearError,
    } = usePrintReports();

    const getReportData = useCallback(async (params) => {
        clearError?.();
        try {
            const res = await printReportService.getReport(params);
            return res?.data?.data || null;
        } catch (e) {
            return null;
        }
    }, [clearError]);

    const exportReport = useCallback(async (params) => {
        const res = await printReportService.exportReport(params);
        return res;
    }, []);

    return {
        reportData: items,
        loading,
        error,
        getReportData,
        exportReport,
        clearError,
    };
};