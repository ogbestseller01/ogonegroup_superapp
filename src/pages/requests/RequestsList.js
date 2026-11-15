// src/pages/requests/RequestsList.js
import React, { useState, useEffect, useMemo } from 'react';
import {
    Box, Paper, Typography, Button, Grid, Card, CardContent, TextField, MenuItem,
    Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination,
    Chip, CircularProgress, Tooltip, Stack, Avatar, Dialog, DialogTitle,
    DialogContent, DialogActions, Divider, TableSortLabel, IconButton,
} from '@mui/material';
import {
    Refresh as RefreshIcon,
    Person as PersonIcon,
    LocationOn as LocationIcon,
    Build as BuildIcon,
    Visibility as ViewIcon,
    Delete as DeleteIcon,
    CheckCircle as CheckCircleIcon,
    Cancel as CancelIcon,
    Pending as PendingIcon,
    Phone as PhoneIcon,
    Email as EmailIcon,
    Close as CloseIcon,
    Receipt as ReceiptIcon,
    CalendarToday as CalendarIcon,
    Notes as NotesIcon,
} from '@mui/icons-material';
import { requestService } from 'services/request.service';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tReq } from './requestslang';
import { format } from 'date-fns';
import appConfig from '../../config';

const colors = appConfig.app.colors;

// Status color map (labels resolved via t())
const getStatusColors = (t) => ({
    pending: { color: '#f59e0b', bg: '#fef3c7', label: t('req.status.pending'), icon: <PendingIcon sx={{ fontSize: 14 }} /> },
    accepted: { color: '#10b981', bg: '#d1fae5', label: t('req.status.accepted'), icon: <CheckCircleIcon sx={{ fontSize: 14 }} /> },
    rejected: { color: '#ef4444', bg: '#fee2e2', label: t('req.status.rejected'), icon: <CancelIcon sx={{ fontSize: 14 }} /> },
    cancelled: { color: '#6b7280', bg: '#f3f4f6', label: t('req.status.cancelled'), icon: <CancelIcon sx={{ fontSize: 14 }} /> },
});

const RequestsList = () => {
    const { can } = usePermissions();
    const canView = can('requests.view');
    const canDelete = can('requests.delete');

    const { language } = useLanguage();
    const t = (key, replacements) => tReq(language, key, replacements);
    const STATUS_COLORS = useMemo(() => getStatusColors(t), [language]);

    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(false);
    const [pagination, setPagination] = useState({ total: 0, per_page: 10, current_page: 1, last_page: 1 });

    const [statusFilter, setStatusFilter] = useState('all');
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [order, setOrder] = useState('desc');
    const [orderBy, setOrderBy] = useState('created_at');
    const [selectedRequest, setSelectedRequest] = useState(null);
    const [openViewDialog, setOpenViewDialog] = useState(false);
    const [confirmDialog, setConfirmDialog] = useState({
        open: false,
        title: '',
        message: '',
        action: null,
    });

    const loadRequests = async () => {
        if (!canView) return;

        setLoading(true);
        try {
            const response = await requestService.getRequests({
                page: page + 1,
                per_page: rowsPerPage,
                search: search || undefined,
                status: statusFilter === 'all' ? undefined : statusFilter,
            });

            if (response?.data?.status === 'success') {
                const data = response.data.data;
                if (data && data.data) {
                    setRequests(data.data);
                    setPagination({
                        total: data.total || 0,
                        per_page: data.per_page || rowsPerPage,
                        current_page: data.current_page || 1,
                        last_page: data.last_page || 1,
                    });
                } else if (Array.isArray(data)) {
                    setRequests(data);
                } else {
                    setRequests([]);
                }
            } else {
                setRequests([]);
            }
        } catch (err) {
            console.error('Requests error:', err);
            showSnackbar({ type: 'error', message: err.message || t('req.toast.loadFailed') });
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (canView) loadRequests();
    }, [page, rowsPerPage, search, statusFilter, canView]);

    const refreshAll = () => {
        loadRequests();
    };

    const handleViewRequest = (request) => {
        setSelectedRequest(request);
        setOpenViewDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenViewDialog(false);
        setSelectedRequest(null);
    };

    const handleDeleteRequest = async (id) => {
        try {
            await requestService.deleteRequest(id);
            showSnackbar({ type: 'success', message: t('req.toast.deleteSuccess') });
            await loadRequests();
            return true;
        } catch (err) {
            console.error('Delete error:', err);
            const errorMessage = err.response?.data?.message || t('req.toast.deleteFailed');
            showSnackbar({ type: 'error', message: errorMessage });
            throw err;
        }
    };

    const openConfirmDialog = (title, message, actionFn) => {
        setConfirmDialog({ open: true, title, message, action: actionFn });
    };

    const handleConfirm = async () => {
        if (!confirmDialog.action) return;
        const action = confirmDialog.action;
        setConfirmDialog(prev => ({ ...prev, open: false }));

        try {
            await action();
        } catch (err) {
            console.error('Confirm action failed:', err);
        }
    };

    const handleRequestSort = (property) => {
        const isAsc = orderBy === property && order === 'asc';
        setOrder(isAsc ? 'desc' : 'asc');
        setOrderBy(property);
    };

    const getStatusChip = (status) => {
        const st = STATUS_COLORS[status] || STATUS_COLORS.pending;
        return (
            <Chip
                icon={st.icon}
                label={st.label}
                size="small"
                sx={{
                    backgroundColor: st.bg,
                    color: st.color,
                    fontWeight: 600,
                    '& .MuiChip-icon': { color: st.color },
                }}
            />
        );
    };

    const formatDate = (dateStr) => {
        if (!dateStr) return '-';
        try { return format(new Date(dateStr), 'MMM d, yyyy'); } catch { return '-'; }
    };

    const formatDateFull = (dateStr) => {
        if (!dateStr) return '-';
        try { return format(new Date(dateStr), 'MMM d, yyyy h:mm a'); } catch { return '-'; }
    };

    if (!canView) {
        return (
            <Paper sx={{
                p: 3, textAlign: 'center',
                bgcolor: 'background.paper',
                border: '1px solid', borderColor: 'divider',
                borderRadius: 2,
            }}>
                <Typography color="error">{t('req.accessDenied')}</Typography>
            </Paper>
        );
    }

    // Summary stats
    const totalRequests = pagination.total || 0;
    const pendingCount = requests.filter(r => r.status === 'pending').length;
    const acceptedCount = requests.filter(r => r.status === 'accepted').length;
    const rejectedCount = requests.filter(r => r.status === 'rejected').length;
    const cancelledCount = requests.filter(r => r.status === 'cancelled').length;

    return (
        <Box sx={{ width: '100%', maxWidth: '100%' }}>
            {/* Filter Bar */}
            <Paper
                elevation={0}
                sx={{
                    p: 2, mb: 3, borderRadius: 3,
                    border: '1px solid', borderColor: 'divider',
                    bgcolor: 'background.paper',
                }}
            >
                <Stack direction="row" spacing={2} flexWrap="wrap" useFlexGap alignItems="center">
                    <TextField
                        select
                        label={t('req.filter.status')}
                        size="small"
                        value={statusFilter}
                        onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
                        sx={{ minWidth: 140 }}
                    >
                        <MenuItem value="all">{t('req.common.all')}</MenuItem>
                        <MenuItem value="pending">{t('req.status.pending')}</MenuItem>
                        <MenuItem value="accepted">{t('req.status.accepted')}</MenuItem>
                        <MenuItem value="rejected">{t('req.status.rejected')}</MenuItem>
                        <MenuItem value="cancelled">{t('req.status.cancelled')}</MenuItem>
                    </TextField>

                    <TextField
                        size="small"
                        placeholder={t('req.filter.searchPlaceholder')}
                        value={search}
                        onChange={(e) => { setSearch(e.target.value); setPage(0); }}
                        sx={{ minWidth: 200 }}
                    />

                    <Box flexGrow={1} />

                    <Button
                        variant="contained"
                        startIcon={<RefreshIcon />}
                        onClick={refreshAll}
                    >
                        {t('req.common.refresh')}
                    </Button>
                </Stack>
            </Paper>

            {/* Summary Cards */}
            <Grid container spacing={2} sx={{ mb: 3 }}>
                {[
                    { label: t('req.stats.total'), value: totalRequests, color: '#3b82f6' },
                    { label: t('req.stats.pending'), value: pendingCount, color: '#f59e0b' },
                    { label: t('req.status.accepted'), value: acceptedCount, color: '#10b981' },
                    { label: t('req.status.rejected'), value: rejectedCount, color: '#ef4444' },
                    { label: t('req.status.cancelled'), value: cancelledCount, color: '#6b7280' },
                ].map((item, idx) => (
                    <Grid item xs={12} sm={6} md={2.4} key={idx}>
                        <Card
                            elevation={0}
                            sx={{
                                borderRadius: 3,
                                border: '1px solid', borderColor: 'divider',
                                bgcolor: 'background.paper',
                                height: '100%',
                            }}
                        >
                            <CardContent>
                                <Typography variant="body2" sx={{ color: item.color, fontWeight: 600, mb: 0.5 }}>
                                    {item.label}
                                </Typography>
                                <Typography variant="h4" sx={{ color: item.color, fontWeight: 700 }}>
                                    {item.value}
                                </Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                ))}
            </Grid>

            {/* Table */}
            <Paper
                elevation={0}
                sx={{
                    borderRadius: 3,
                    border: '1px solid', borderColor: 'divider',
                    bgcolor: 'background.paper',
                    overflow: 'hidden',
                }}
            >
                <Box
                    sx={{
                        p: 2.5,
                        borderBottom: '1px solid', borderColor: 'divider',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        flexWrap: 'wrap',
                        gap: 2,
                    }}
                >
                    <Typography variant="h6" fontWeight={600}>
                        {t('req.table.title')}
                    </Typography>
                </Box>

                {loading ? (
                    <Box sx={{ py: 6, textAlign: 'center' }}>
                        <CircularProgress />
                    </Box>
                ) : requests.length === 0 ? (
                    <Box sx={{ py: 6, textAlign: 'center' }}>
                        <Typography color="text.secondary">{t('req.table.noFound')}</Typography>
                    </Box>
                ) : (
                    <>
                        <TableContainer>
                            <Table>
                                <TableHead sx={{ backgroundColor: 'action.hover' }}>
                                    <TableRow>
                                        <TableCell sx={{ fontWeight: 700 }}>{t('req.table.col.customer')}</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>{t('req.table.col.technician')}</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>{t('req.table.col.service')}</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>{t('req.table.col.status')}</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>
                                            <TableSortLabel
                                                active={orderBy === 'created_at'}
                                                direction={orderBy === 'created_at' ? order : 'asc'}
                                                onClick={() => handleRequestSort('created_at')}
                                            >
                                                {t('req.table.col.created')}
                                            </TableSortLabel>
                                        </TableCell>
                                        <TableCell sx={{ fontWeight: 700 }} align="center">
                                            {t('req.table.col.actions')}
                                        </TableCell>
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                    {requests.map((request) => (
                                        <TableRow key={request.id} hover>
                                            <TableCell>
                                                <Box display="flex" alignItems="center" gap={1}>
                                                    <Avatar
                                                        sx={{
                                                            width: 32, height: 32,
                                                            bgcolor: colors.sea, fontSize: 14,
                                                        }}
                                                    >
                                                        {request.customer?.name?.charAt(0).toUpperCase() || <PersonIcon />}
                                                    </Avatar>
                                                    <Box>
                                                        <Typography variant="body2" fontWeight={500}>
                                                            {request.customer?.name || '-'}
                                                        </Typography>
                                                        <Typography variant="caption" color="text.secondary">
                                                            {request.customer?.phone || ''}
                                                        </Typography>
                                                    </Box>
                                                </Box>
                                            </TableCell>
                                            <TableCell>
                                                <Box display="flex" alignItems="center" gap={1}>
                                                    <Avatar
                                                        src={request.technician?.profile_photo || undefined}
                                                        sx={{
                                                            width: 32, height: 32,
                                                            bgcolor: colors.sea, fontSize: 14,
                                                        }}
                                                    >
                                                        {request.technician?.name?.charAt(0).toUpperCase() || <PersonIcon />}
                                                    </Avatar>
                                                    <Box>
                                                        <Typography variant="body2" fontWeight={500}>
                                                            {request.technician?.name || '-'}
                                                        </Typography>
                                                        <Typography variant="caption" color="text.secondary">
                                                            {request.technician?.area || ''}
                                                        </Typography>
                                                    </Box>
                                                </Box>
                                            </TableCell>
                                            <TableCell>
                                                <Chip
                                                    icon={<BuildIcon sx={{ fontSize: 14 }} />}
                                                    label={request.service?.name || '-'}
                                                    size="small"
                                                    variant="outlined"
                                                    sx={{ borderColor: 'divider' }}
                                                />
                                            </TableCell>
                                            <TableCell>{getStatusChip(request.status)}</TableCell>
                                            <TableCell>{formatDate(request.created_at)}</TableCell>
                                            <TableCell align="center">
                                                <Tooltip title={t('req.table.viewTooltip')}>
                                                    <Button
                                                        size="small"
                                                        variant="outlined"
                                                        startIcon={<ViewIcon />}
                                                        onClick={() => handleViewRequest(request)}
                                                        sx={{
                                                            mr: 1,
                                                            borderColor: 'divider',
                                                            color: colors.sea,
                                                            '&:hover': {
                                                                borderColor: colors.sea,
                                                                backgroundColor: 'primary.50',
                                                            },
                                                        }}
                                                    >
                                                        {t('req.common.view')}
                                                    </Button>
                                                </Tooltip>
                                                {canDelete && (
                                                    <Tooltip title={t('req.table.deleteTooltip')}>
                                                        <Button
                                                            size="small"
                                                            variant="outlined"
                                                            color="error"
                                                            startIcon={<DeleteIcon />}
                                                            onClick={() => openConfirmDialog(
                                                                t('req.delete.title'),
                                                                t('req.delete.message'),
                                                                () => handleDeleteRequest(request.id)
                                                            )}
                                                        >
                                                            {t('req.common.delete')}
                                                        </Button>
                                                    </Tooltip>
                                                )}
                                            </TableCell>
                                        </TableRow>
                                    ))}
                                </TableBody>
                            </Table>
                        </TableContainer>

                        <TablePagination
                            component="div"
                            count={pagination.total || 0}
                            rowsPerPage={rowsPerPage}
                            page={page}
                            onPageChange={(e, p) => setPage(p)}
                            onRowsPerPageChange={(e) => {
                                setRowsPerPage(parseInt(e.target.value, 10));
                                setPage(0);
                            }}
                            rowsPerPageOptions={[5, 10, 25, 50]}
                            sx={{ borderTop: '1px solid', borderColor: 'divider' }}
                        />
                    </>
                )}
            </Paper>

            {/* Request Detail Dialog */}
            <Dialog
                open={openViewDialog}
                onClose={handleCloseDialog}
                maxWidth="md"
                fullWidth
                PaperProps={{
                    sx: {
                        borderRadius: 3,
                        border: '1px solid', borderColor: 'divider',
                        bgcolor: 'background.paper',
                        maxHeight: '90vh',
                    },
                }}
            >
                {selectedRequest && (
                    <>
                        <DialogTitle sx={{ pb: 1, borderBottom: '1px solid', borderColor: 'divider' }}>
                            <Box display="flex" justifyContent="space-between" alignItems="flex-start">
                                <Box>
                                    <Typography variant="h6" fontWeight={600} color="text.primary">
                                        {t('req.dialog.title')}
                                    </Typography>
                                    <Box display="flex" alignItems="center" gap={2} mt={1}>
                                        {getStatusChip(selectedRequest.status)}
                                        <Typography variant="caption" color="text.secondary">
                                            <CalendarIcon sx={{ fontSize: 14, mr: 0.5, verticalAlign: 'middle' }} />
                                            {formatDateFull(selectedRequest.created_at)}
                                        </Typography>
                                        <Typography variant="caption" color="text.secondary">
                                            <ReceiptIcon sx={{ fontSize: 14, mr: 0.5, verticalAlign: 'middle' }} />
                                            #{selectedRequest.id}
                                        </Typography>
                                    </Box>
                                </Box>
                                <IconButton onClick={handleCloseDialog} size="small" sx={{ color: 'text.secondary' }}>
                                    <CloseIcon />
                                </IconButton>
                            </Box>
                        </DialogTitle>

                        <DialogContent sx={{ p: 3 }}>
                            {/* Description Section */}
                            <Box mb={3}>
                                <Typography variant="subtitle2" fontWeight={600} gutterBottom sx={{
                                    color: 'text.primary',
                                    display: 'flex', alignItems: 'center', gap: 1,
                                }}>
                                    <NotesIcon sx={{ fontSize: 18, color: colors.sea }} />
                                    {t('req.dialog.description')}
                                </Typography>
                                <Paper
                                    variant="outlined"
                                    sx={{
                                        p: 2.5,
                                        backgroundColor: 'action.hover',
                                        borderColor: 'divider',
                                        borderRadius: 2,
                                    }}
                                >
                                    <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>
                                        {selectedRequest.description || t('req.dialog.noDescription')}
                                    </Typography>
                                </Paper>
                            </Box>

                            <Divider sx={{ mb: 3, borderColor: 'divider' }} />

                            {/* Customer & Technician Details */}
                            <Grid container spacing={3}>
                                {/* Customer Details */}
                                <Grid item xs={12} md={6}>
                                    <Typography variant="subtitle2" fontWeight={600} gutterBottom sx={{ color: 'text.primary' }}>
                                        {t('req.dialog.customerInfo')}
                                    </Typography>
                                    <Paper
                                        variant="outlined"
                                        sx={{ p: 2.5, borderColor: 'divider', borderRadius: 2 }}
                                    >
                                        <Stack spacing={1.5}>
                                            <Box display="flex" alignItems="center" gap={1.5}>
                                                <Avatar sx={{ bgcolor: colors.sea, width: 40, height: 40 }}>
                                                    {selectedRequest.customer?.name?.charAt(0).toUpperCase() || <PersonIcon />}
                                                </Avatar>
                                                <Box>
                                                    <Typography variant="body1" fontWeight={500}>
                                                        {selectedRequest.customer?.name || t('req.common.unknown')}
                                                    </Typography>
                                                    <Typography variant="caption" color="text.secondary">
                                                        {t('req.dialog.customerId', { id: selectedRequest.customer?.id || t('req.common.none') })}
                                                    </Typography>
                                                </Box>
                                            </Box>
                                            <Divider sx={{ borderColor: 'divider' }} />
                                            <Box display="flex" alignItems="center" gap={1.5}>
                                                <EmailIcon fontSize="small" sx={{ color: 'text.secondary', width: 20 }} />
                                                <Typography variant="body2">
                                                    {selectedRequest.customer?.email || t('req.common.none')}
                                                </Typography>
                                            </Box>
                                            <Box display="flex" alignItems="center" gap={1.5}>
                                                <PhoneIcon fontSize="small" sx={{ color: 'text.secondary', width: 20 }} />
                                                <Typography variant="body2">
                                                    {selectedRequest.customer?.phone || t('req.common.none')}
                                                </Typography>
                                            </Box>
                                            {selectedRequest.customer?.address && (
                                                <Box display="flex" alignItems="center" gap={1.5}>
                                                    <LocationIcon fontSize="small" sx={{ color: 'text.secondary', width: 20 }} />
                                                    <Typography variant="body2">
                                                        {selectedRequest.customer?.address}
                                                    </Typography>
                                                </Box>
                                            )}
                                        </Stack>
                                    </Paper>
                                </Grid>

                                {/* Technician Details */}
                                <Grid item xs={12} md={6}>
                                    <Typography variant="subtitle2" fontWeight={600} gutterBottom sx={{ color: 'text.primary' }}>
                                        {t('req.dialog.technicianInfo')}
                                    </Typography>
                                    <Paper
                                        variant="outlined"
                                        sx={{ p: 2.5, borderColor: 'divider', borderRadius: 2 }}
                                    >
                                        <Stack spacing={1.5}>
                                            <Box display="flex" alignItems="center" gap={1.5}>
                                                <Avatar
                                                    src={selectedRequest.technician?.profile_photo || undefined}
                                                    sx={{ bgcolor: colors.sea, width: 40, height: 40 }}
                                                >
                                                    {selectedRequest.technician?.name?.charAt(0).toUpperCase() || <PersonIcon />}
                                                </Avatar>
                                                <Box>
                                                    <Typography variant="body1" fontWeight={500}>
                                                        {selectedRequest.technician?.name || t('req.common.notAssigned')}
                                                    </Typography>
                                                    <Typography variant="caption" color="text.secondary">
                                                        {t('req.dialog.technicianId', { id: selectedRequest.technician?.id || t('req.common.none') })}
                                                    </Typography>
                                                </Box>
                                            </Box>
                                            <Divider sx={{ borderColor: 'divider' }} />
                                            <Box display="flex" alignItems="center" gap={1.5}>
                                                <BuildIcon fontSize="small" sx={{ color: 'text.secondary', width: 20 }} />
                                                <Typography variant="body2">
                                                    {selectedRequest.service?.name || t('req.common.none')}
                                                </Typography>
                                            </Box>
                                            {selectedRequest.technician?.area && (
                                                <Box display="flex" alignItems="center" gap={1.5}>
                                                    <LocationIcon fontSize="small" sx={{ color: 'text.secondary', width: 20 }} />
                                                    <Typography variant="body2">
                                                        {selectedRequest.technician?.area}
                                                    </Typography>
                                                </Box>
                                            )}
                                            {selectedRequest.technician?.phone && (
                                                <Box display="flex" alignItems="center" gap={1.5}>
                                                    <PhoneIcon fontSize="small" sx={{ color: 'text.secondary', width: 20 }} />
                                                    <Typography variant="body2">
                                                        {selectedRequest.technician?.phone}
                                                    </Typography>
                                                </Box>
                                            )}
                                        </Stack>
                                    </Paper>
                                </Grid>
                            </Grid>

                            {/* Activity Logs */}
                            {selectedRequest.logs && selectedRequest.logs.length > 0 && (
                                <>
                                    <Divider sx={{ my: 3, borderColor: 'divider' }} />
                                    <Box>
                                        <Typography variant="subtitle2" fontWeight={600} gutterBottom sx={{ color: 'text.primary' }}>
                                            {t('req.dialog.activityLog')}
                                        </Typography>
                                        <Paper
                                            variant="outlined"
                                            sx={{
                                                p: 2,
                                                maxHeight: 200,
                                                overflow: 'auto',
                                                borderColor: 'divider',
                                                borderRadius: 2,
                                                backgroundColor: 'action.hover',
                                            }}
                                        >
                                            <Stack spacing={1.5}>
                                                {selectedRequest.logs.map((log) => (
                                                    <Box
                                                        key={log.id}
                                                        display="flex"
                                                        gap={2}
                                                        alignItems="flex-start"
                                                        flexWrap="wrap"
                                                        sx={{
                                                            p: 1,
                                                            borderRadius: 1,
                                                            backgroundColor: 'background.paper',
                                                            border: '1px solid', borderColor: 'divider',
                                                        }}
                                                    >
                                                        <Typography variant="caption" color="text.secondary" sx={{ minWidth: 140, fontWeight: 500 }}>
                                                            {formatDateFull(log.created_at)}
                                                        </Typography>
                                                        <Chip
                                                            label={log.action}
                                                            size="small"
                                                            sx={{
                                                                backgroundColor: 'primary.50',
                                                                color: colors.sea,
                                                                fontWeight: 500,
                                                            }}
                                                        />
                                                        <Typography variant="caption" color="text.secondary">
                                                            {t('req.dialog.byUser', { name: log.user?.name || t('req.common.system') })}
                                                        </Typography>
                                                        {log.notes && (
                                                            <Typography variant="caption" color="text.secondary" sx={{ flex: 1 }}>
                                                                - {log.notes}
                                                            </Typography>
                                                        )}
                                                    </Box>
                                                ))}
                                            </Stack>
                                        </Paper>
                                    </Box>
                                </>
                            )}
                        </DialogContent>

                        <DialogActions sx={{ p: 2.5, borderTop: '1px solid', borderColor: 'divider' }}>
                            <Button
                                onClick={handleCloseDialog}
                                variant="contained"
                                sx={{
                                    backgroundColor: colors.sea,
                                    '&:hover': { backgroundColor: colors.dark },
                                    px: 4,
                                }}
                            >
                                {t('req.dialog.close')}
                            </Button>
                        </DialogActions>
                    </>
                )}
            </Dialog>

            {/* Confirmation Dialog */}
            <Dialog
                open={confirmDialog.open}
                onClose={() => setConfirmDialog(prev => ({ ...prev, open: false }))}
                fullWidth
                maxWidth="xs"
                PaperProps={{
                    sx: { borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' },
                }}
            >
                <DialogTitle sx={{ pb: 1, fontWeight: 600, color: 'text.primary' }}>
                    {confirmDialog.title}
                </DialogTitle>
                <DialogContent>
                    <Typography sx={{ color: 'text.primary' }}>{confirmDialog.message}</Typography>
                </DialogContent>
                <DialogActions sx={{ p: 2, pt: 0 }}>
                    <Button
                        onClick={() => setConfirmDialog(prev => ({ ...prev, open: false }))}
                        variant="outlined"
                        sx={{ borderColor: 'divider', color: 'text.secondary' }}
                    >
                        {t('req.common.cancel')}
                    </Button>
                    <Button
                        onClick={handleConfirm}
                        variant="contained"
                        color="error"
                    >
                        {t('req.common.confirm')}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default RequestsList;