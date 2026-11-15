import React, { createContext, useContext, useReducer, useCallback } from 'react';
import { reportService } from 'services/report.service';
import { showSnackbar } from 'utils/snackbar';

const ReportContext = createContext(null);

const initialState = {
    summary: {},
    trends: {},
    detailed: { data: [], pagination: { total: 0 } },
    overview: {},
    loadingSummary: false,
    loadingTrends: false,
    loadingDetailed: false,
    loadingOverview: false,
    exporting: false,
    error: null,
};

function reducer(state, action) {
    switch (action.type) {
        case 'SUMMARY_START': return { ...state, loadingSummary: true, error: null };
        case 'SUMMARY_SUCCESS': return { ...state, loadingSummary: false, summary: action.payload };
        case 'SUMMARY_ERROR': return { ...state, loadingSummary: false, error: action.payload };

        case 'TRENDS_START': return { ...state, loadingTrends: true, error: null };
        case 'TRENDS_SUCCESS': return { ...state, loadingTrends: false, trends: action.payload };
        case 'TRENDS_ERROR': return { ...state, loadingTrends: false, error: action.payload };

        case 'DETAILED_START': return { ...state, loadingDetailed: true, error: null };
        case 'DETAILED_SUCCESS': return { ...state, loadingDetailed: false, detailed: action.payload };
        case 'DETAILED_ERROR': return { ...state, loadingDetailed: false, error: action.payload };

        case 'OVERVIEW_START': return { ...state, loadingOverview: true, error: null };
        case 'OVERVIEW_SUCCESS': return { ...state, loadingOverview: false, overview: action.payload };
        case 'OVERVIEW_ERROR': return { ...state, loadingOverview: false, error: action.payload };

        case 'EXPORT_START': return { ...state, exporting: true, error: null };
        case 'EXPORT_DONE': return { ...state, exporting: false };
        case 'EXPORT_ERROR': return { ...state, exporting: false, error: action.payload };

        case 'CLEAR_ERROR': return { ...state, error: null };
        default: return state;
    }
}

export const ReportProvider = ({ children }) => {
    const [state, dispatch] = useReducer(reducer, initialState);

    const fetchSummary = useCallback(async (params) => {
        dispatch({ type: 'SUMMARY_START' });
        try {
            const { data } = await reportService.getSummary(params);
            dispatch({ type: 'SUMMARY_SUCCESS', payload: data.data ?? data });
        } catch (err) {
            const message = err?.response?.data?.message || 'Failed to load report summary';
            dispatch({ type: 'SUMMARY_ERROR', payload: message });
            showSnackbar({ type: 'error', message });
        }
    }, []);

    const fetchTrends = useCallback(async (params) => {
        dispatch({ type: 'TRENDS_START' });
        try {
            const { data } = await reportService.getTrends(params);
            dispatch({ type: 'TRENDS_SUCCESS', payload: data.data ?? data });
        } catch (err) {
            const message = err?.response?.data?.message || 'Failed to load report trends';
            dispatch({ type: 'TRENDS_ERROR', payload: message });
            showSnackbar({ type: 'error', message });
        }
    }, []);

    const fetchDetailed = useCallback(async (params) => {
        dispatch({ type: 'DETAILED_START' });
        try {
            const { data } = await reportService.getDetailed(params);
            const payload = data.data ?? data;
            dispatch({
                type: 'DETAILED_SUCCESS',
                payload: {
                    data: payload.data ?? [],
                    pagination: {
                        total: payload.total ?? 0,
                        currentPage: payload.current_page ?? 1,
                        perPage: payload.per_page ?? 10,
                    },
                },
            });
        } catch (err) {
            const message = err?.response?.data?.message || 'Failed to load detailed report';
            dispatch({ type: 'DETAILED_ERROR', payload: message });
            showSnackbar({ type: 'error', message });
        }
    }, []);

    const fetchOverview = useCallback(async (params) => {
        dispatch({ type: 'OVERVIEW_START' });
        try {
            const { data } = await reportService.getOverview(params);
            dispatch({ type: 'OVERVIEW_SUCCESS', payload: data.data ?? data });
        } catch (err) {
            const message = err?.response?.data?.message || 'Failed to load dashboard overview';
            dispatch({ type: 'OVERVIEW_ERROR', payload: message });
            showSnackbar({ type: 'error', message });
        }
    }, []);

    const exportReport = useCallback(async (params) => {
        dispatch({ type: 'EXPORT_START' });
        try {
            const response = await reportService.exportReport(params);
            dispatch({ type: 'EXPORT_DONE' });
            return response;
        } catch (err) {
            const message = err?.response?.data?.message || 'Export failed';
            dispatch({ type: 'EXPORT_ERROR', payload: message });
            showSnackbar({ type: 'error', message });
            throw err;
        }
    }, []);

    const clearError = useCallback(() => dispatch({ type: 'CLEAR_ERROR' }), []);

    return (
        <ReportContext.Provider
            value={{
                ...state,
                fetchSummary,
                fetchTrends,
                fetchDetailed,
                fetchOverview,
                exportReport,
                clearError,
            }}
        >
            {children}
        </ReportContext.Provider>
    );
};

export const useReport = () => {
    const ctx = useContext(ReportContext);
    if (!ctx) {
        throw new Error('useReport must be used within a ReportProvider');
    }
    return ctx;
};