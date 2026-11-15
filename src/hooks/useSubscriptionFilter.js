import { useState, useEffect, useCallback } from 'react';
import { useSubscriptionManagement } from './useSubscription';
import { showSnackbar } from 'utils/snackbar';
import api from 'services/api';

export const useSubscriptionFilter = () => {
    const {
        subscriptions,
        loading,
        error,
        getSubscriptions,
        approveSubscription,
        rejectSubscription,
        getSubscriptionStats,
        clearError,
    } = useSubscriptionManagement();

    const [stats, setStats] = useState({
        pending_count: 0,
        active_count: 0,
        expired_count: 0,
        cancelled_count: 0,
    });
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [order, setOrder] = useState('desc');
    const [orderBy, setOrderBy] = useState('created_at');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [totalCount, setTotalCount] = useState(0);
    const [actionMenu, setActionMenu] = useState(null);
    const [selectedSub, setSelectedSub] = useState(null);
    const [rejectDialog, setRejectDialog] = useState({
        open: false,
        reason: '',
        subscriptionId: null,
    });

    const fetchSubscriptions = useCallback(async () => {
        try {
            const params = {
                page: page + 1,
                per_page: rowsPerPage,
                search: search || undefined,
                status: statusFilter || undefined,
            };
            const result = await getSubscriptions(params);

            console.log('Full result from getSubscriptions:', result);

            // ✅ Extract stats from the filters object
            if (result?.filters) {
                setStats({
                    pending_count: result.filters.pending_count || 0,
                    active_count: result.filters.active_count || 0,
                    expired_count: result.filters.expired_count || 0,
                    cancelled_count: result.filters.cancelled_count || 0,
                });
            }

            if (result?.pagination) {
                setTotalCount(result.pagination.total || 0);
            }
        } catch (err) {
            console.error('Failed to load subscriptions:', err);
            showSnackbar({ type: 'error', message: 'Failed to load subscriptions' });
        }
    }, [getSubscriptions, page, rowsPerPage, search, statusFilter]);

    const fetchStats = useCallback(async () => {
        try {
            const res = await getSubscriptionStats();
            console.log('Stats API Response:', res);
            if (res?.data) {
                setStats({
                    pending_count: res.data.pending || res.data.pending_count || 0,
                    active_count: res.data.active || res.data.active_count || 0,
                    expired_count: res.data.expired || res.data.expired_count || 0,
                    cancelled_count: res.data.cancelled || res.data.cancelled_count || 0,
                });
            }
        } catch (err) {
            console.error('Failed to load stats', err);
        }
    }, [getSubscriptionStats]);

    useEffect(() => {
        fetchSubscriptions();
    }, [fetchSubscriptions]);

    useEffect(() => {
        fetchStats();
    }, [fetchStats]);

    const handleApprove = useCallback(async (id) => {
        try {
            await approveSubscription(id);
            showSnackbar({ type: 'success', message: `Subscription #${id} approved` });
            fetchSubscriptions();
            fetchStats();
        } catch (err) {
            showSnackbar({ type: 'error', message: 'Approval failed' });
        }
        setActionMenu(null);
    }, [approveSubscription, fetchSubscriptions, fetchStats]);

    const handleReject = useCallback(async (id, reason) => {
        try {
            await rejectSubscription(id, reason);
            showSnackbar({ type: 'success', message: `Subscription #${id} rejected` });
            fetchSubscriptions();
            fetchStats();
        } catch (err) {
            showSnackbar({ type: 'error', message: 'Rejection failed' });
        }
        setActionMenu(null);
        setRejectDialog({ open: false, reason: '', subscriptionId: null });
    }, [rejectSubscription, fetchSubscriptions, fetchStats]);

    const handleViewInvoice = useCallback(async (sub) => {
        if (!sub.invoice?.id) {
            showSnackbar({ type: 'warning', message: 'No invoice available' });
            return;
        }

        try {
            const response = await api.get(`/v16/invoices/${sub.invoice.id}/download`, {
                responseType: 'blob',
            });

            const blob = new Blob([response.data], { type: 'application/pdf' });
            const url = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = `invoice_${sub.invoice.number || sub.invoice.id}.pdf`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            window.URL.revokeObjectURL(url);

            showSnackbar({ type: 'success', message: 'Invoice downloaded' });
        } catch (error) {
            console.error('Download error:', error);
            showSnackbar({ type: 'error', message: 'Failed to download invoice' });
        }
        setActionMenu(null);
    }, []);

    const handleMenuOpen = useCallback((event, sub) => {
        setSelectedSub(sub);
        setActionMenu(event.currentTarget);
    }, []);

    const handleMenuClose = useCallback(() => setActionMenu(null), []);

    const handleRequestSort = useCallback((property) => {
        const isAsc = orderBy === property && order === 'asc';
        setOrder(isAsc ? 'desc' : 'asc');
        setOrderBy(property);
    }, [order, orderBy]);

    return {
        subscriptions,
        loading,
        error,
        stats,
        totalCount,
        search,
        setSearch,
        statusFilter,
        setStatusFilter,
        order,
        orderBy,
        page,
        setPage,
        rowsPerPage,
        setRowsPerPage,
        handleRequestSort,
        handleApprove,
        handleReject,
        handleViewInvoice,
        handleMenuOpen,
        handleMenuClose,
        actionMenu,
        selectedSub,
        rejectDialog,
        setRejectDialog,
        refresh: fetchSubscriptions,
    };
};