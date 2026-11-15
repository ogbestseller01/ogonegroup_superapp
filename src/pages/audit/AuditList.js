// src/pages/audit/AuditList.js
import React, { useState, useEffect, useCallback } from 'react';
import {
    Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle,
    IconButton, InputAdornment, Menu, MenuItem, Paper, Table, TableBody,
    TableCell, TableContainer, TableHead, TablePagination, TableRow, TextField,
    Typography, FormControl, InputLabel, Select, Grid, Card, CardContent,
    CircularProgress, useTheme, useMediaQuery, Divider, Alert, Stack, Avatar,
} from '@mui/material';
import {
    Refresh as RefreshIcon, Search as SearchIcon, MoreVert as MoreVertIcon,
    Visibility as ViewIcon, AccessTime as TimeIcon, Public as IpIcon,
    Http as MethodIcon, Clear as ClearIcon, Close as CloseIcon,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';

import { auditService } from 'services/audit.service';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tAudit } from './auditlang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function AuditList() {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));
    const { language } = useLanguage();
    const t = (key) => tAudit(language, key);

    const { can } = usePermissions();
    const canView = can('audit.view');

    const [audits, setAudits] = useState([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [stats, setStats] = useState(null);
    const [statsLoading, setStatsLoading] = useState(false);

    const [modules, setModules] = useState([]);
    const [actions, setActions] = useState([]);

    const [search, setSearch] = useState('');
    const [moduleFilter, setModuleFilter] = useState('all');
    const [actionFilter, setActionFilter] = useState('all');
    const [fromDate, setFromDate] = useState(null);
    const [toDate, setToDate] = useState(null);

    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);

    const [viewModalOpen, setViewModalOpen] = useState(false);
    const [selectedAudit, setSelectedAudit] = useState(null);
    const [actionMenu, setActionMenu] = useState(null);

    const headCells = [
        { id: 'created_at', label: t('audit.col.dateTime') },
        { id: 'user', label: t('audit.col.user') },
        { id: 'action', label: t('audit.col.action') },
        { id: 'module', label: t('audit.col.module') },
        { id: 'description', label: t('audit.col.description') },
        { id: 'ip_address', label: t('audit.col.ip') },
        { id: 'request_method', label: t('audit.col.method') },
        { id: 'actions', label: t('audit.col.actions'), disableSort: true },
    ];

    useEffect(() => {
        if (canView) {
            setModules(['auth', 'user', 'technician', 'request', 'post', 'service', 'portfolio', 'report', 'profile']);
            setActions(['create', 'update', 'delete', 'view', 'login', 'logout', 'verify', 'reset', 'forgot_password', 'update_profile']);
        }
    }, [canView]);

    const fetchAudits = useCallback(async () => {
        if (!canView) return;
        setLoading(true);
        setError(null);
        try {
            const params = {
                page: page + 1,
                per_page: rowsPerPage,
                search: search || undefined,
                module: moduleFilter !== 'all' ? moduleFilter : undefined,
                action: actionFilter !== 'all' ? actionFilter : undefined,
                from_date: fromDate ? fromDate.toISOString().split('T')[0] : undefined,
                to_date: toDate ? toDate.toISOString().split('T')[0] : undefined,
            };
            const response = await auditService.getAuditTrails(params);

            if (response?.data?.status === 'success') {
                const data = response.data.data;
                if (data && data.data) {
                    setAudits(data.data);
                    setTotal(data.total || 0);
                } else if (Array.isArray(data)) {
                    setAudits(data);
                    setTotal(data.length || 0);
                } else {
                    setAudits([]);
                    setTotal(0);
                }
            } else {
                setAudits([]);
                setTotal(0);
                if (response?.data?.message) setError(response.data.message);
            }
        } catch (err) {
            console.error('Audit error:', err);
            setError(err.message || t('audit.loadFailed'));
            showSnackbar({ type: 'error', message: t('audit.loadFailed') });
        } finally {
            setLoading(false);
        }
    }, [page, rowsPerPage, search, moduleFilter, actionFilter, fromDate, toDate, canView, language]);

    useEffect(() => {
        if (canView) fetchAudits();
    }, [fetchAudits, canView]);

    const fetchStats = useCallback(async () => {
        if (!canView) return;
        setStatsLoading(true);
        try {
            const totalRecords = audits.length;
            const today = audits.filter(
                (a) => new Date(a.created_at).toDateString() === new Date().toDateString()
            ).length;
            const thisWeek = audits.filter((a) => {
                const date = new Date(a.created_at);
                const now = new Date();
                const weekStart = new Date(now.setDate(now.getDate() - now.getDay()));
                return date >= weekStart;
            }).length;

            const userMap = {};
            audits.forEach((a) => {
                const userName = a.user?.name || a.user_name || t('audit.unknown');
                const userEmail = a.user?.email || a.user_email || 'unknown@email.com';
                const key = `${userName}-${userEmail}`;
                if (!userMap[key]) {
                    userMap[key] = { user_name: userName, user_email: userEmail, count: 0 };
                }
                userMap[key].count++;
            });
            const byUser = Object.values(userMap).sort((a, b) => b.count - a.count);

            setStats({
                total: totalRecords,
                today,
                this_week: thisWeek,
                by_user: byUser,
            });
        } catch (err) {
            console.error(err);
        } finally {
            setStatsLoading(false);
        }
    }, [audits, canView, language]);

    useEffect(() => {
        if (canView) fetchStats();
    }, [fetchStats, canView]);

    const handleMenuOpen = (event, audit) => {
        setSelectedAudit(audit);
        setActionMenu(event.currentTarget);
    };

    const handleMenuClose = () => setActionMenu(null);

    const handleViewDetails = () => {
        setViewModalOpen(true);
        handleMenuClose();
    };

    const formatDate = (dateStr) => {
        if (!dateStr) return '—';
        try {
            return new Date(dateStr).toLocaleString(language === 'sw' ? 'sw-TZ' : 'en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
            });
        } catch {
            return '—';
        }
    };

    if (!canView) {
        return (
            <Box p={3}>
                <Paper
                    elevation={0}
                    sx={{
                        p: 4,
                        textAlign: 'center',
                        borderRadius: 3,
                        border: '1px solid',
                        borderColor: 'divider',
                        bgcolor: 'background.paper',
                    }}
                >
                    <Typography color="error" fontWeight={600} variant="h6" gutterBottom>
                        {t('audit.accessDenied')}
                    </Typography>
                    <Typography color="text.secondary">
                        {t('audit.noPermission')}
                    </Typography>
                </Paper>
            </Box>
        );
    }

    if (error) {
        return (
            <Box p={3}>
                <Alert
                    severity="error"
                    variant="filled"
                    action={
                        <Button
                            color="inherit"
                            size="small"
                            onClick={() => {
                                setError(null);
                                fetchAudits();
                            }}
                        >
                            {t('audit.retry')}
                        </Button>
                    }
                    sx={{ borderRadius: 2 }}
                >
                    {error}
                </Alert>
            </Box>
        );
    }

    return (
        <LocalizationProvider dateAdapter={AdapterDateFns}>
            <Box sx={{ width: '100%', p: { xs: 1.5, sm: 2.5 }, m: 0, bgcolor: 'background.default' }}>
                {/* Stats Cards */}
                {statsLoading ? (
                    <Box display="flex" justifyContent="center" py={3} mb={2}>
                        <CircularProgress size={28} thickness={4} />
                    </Box>
                ) : (
                    stats && (
                        <Grid container spacing={2} sx={{ mb: 3 }}>
                            <Grid item xs={6} sm={6} md={3}>
                                <Card
                                    elevation={0}
                                    sx={{
                                        borderRadius: 3,
                                        border: '1px solid',
                                        borderColor: 'divider',
                                        bgcolor: 'background.paper', // ✅ Theme aware
                                        height: '100%'
                                    }}
                                >
                                    <CardContent sx={{ p: 2.25 }}>
                                        <Typography variant="overline" fontWeight={700} color="text.secondary" letterSpacing={1}>
                                            {t('audit.stats.total')}
                                        </Typography>
                                        <Typography variant="h4" fontWeight={800} color="info.main" sx={{ mt: 0.5, lineHeight: 1.1 }}>
                                            {stats.total ?? 0}
                                        </Typography>
                                    </CardContent>
                                </Card>
                            </Grid>
                            <Grid item xs={6} sm={6} md={3}>
                                <Card
                                    elevation={0}
                                    sx={{
                                        borderRadius: 3,
                                        border: '1px solid',
                                        borderColor: 'divider',
                                        bgcolor: 'background.paper', // ✅ Theme aware
                                        height: '100%'
                                    }}
                                >
                                    <CardContent sx={{ p: 2.25 }}>
                                        <Typography variant="overline" fontWeight={700} color="text.secondary" letterSpacing={1}>
                                            {t('audit.stats.today')}
                                        </Typography>
                                        <Typography variant="h4" fontWeight={800} color="success.main" sx={{ mt: 0.5, lineHeight: 1.1 }}>
                                            {stats.today ?? 0}
                                        </Typography>
                                    </CardContent>
                                </Card>
                            </Grid>
                            <Grid item xs={6} sm={6} md={3}>
                                <Card
                                    elevation={0}
                                    sx={{
                                        borderRadius: 3,
                                        border: '1px solid',
                                        borderColor: 'divider',
                                        bgcolor: 'background.paper', // ✅ Theme aware
                                        height: '100%'
                                    }}
                                >
                                    <CardContent sx={{ p: 2.25 }}>
                                        <Typography variant="overline" fontWeight={700} color="text.secondary" letterSpacing={1}>
                                            {t('audit.stats.thisWeek')}
                                        </Typography>
                                        <Typography variant="h4" fontWeight={800} color="warning.main" sx={{ mt: 0.5, lineHeight: 1.1 }}>
                                            {stats.this_week ?? 0}
                                        </Typography>
                                    </CardContent>
                                </Card>
                            </Grid>
                            <Grid item xs={6} sm={6} md={3}>
                                <Card
                                    elevation={0}
                                    sx={{
                                        borderRadius: 3,
                                        border: '1px solid',
                                        borderColor: 'divider',
                                        bgcolor: 'background.paper', // ✅ Theme aware
                                        height: '100%'
                                    }}
                                >
                                    <CardContent sx={{ p: 2.25 }}>
                                        <Typography variant="overline" fontWeight={700} color="text.secondary" letterSpacing={1}>
                                            {t('audit.stats.topUsers')}
                                        </Typography>
                                        <Box sx={{ mt: 0.75 }}>
                                            {stats.by_user && stats.by_user.length > 0 ? (
                                                stats.by_user.slice(0, 3).map((u, idx) => (
                                                    <Typography key={idx} variant="caption" component="div" fontWeight={600} color="text.primary">
                                                        {u.user_name}: {u.count}
                                                    </Typography>
                                                ))
                                            ) : (
                                                <Typography variant="caption" color="text.secondary">
                                                    {t('audit.noData')}
                                                </Typography>
                                            )}
                                        </Box>
                                    </CardContent>
                                </Card>
                            </Grid>
                        </Grid>
                    )
                )}

                {/* Main Panel */}
                <Paper
                    elevation={0}
                    sx={{
                        width: '100%',
                        borderRadius: 3,
                        overflow: 'hidden',
                        border: '1px solid',
                        borderColor: 'divider',
                        bgcolor: 'background.paper'
                    }}
                >
                    {/* Header + Filters */}
                    <Box sx={{ px: { xs: 2, sm: 3 }, py: 2.5, borderBottom: '1px solid', borderColor: 'divider' }}>
                        <Box mb={2.5}>
                            <Typography variant="h5" fontWeight={800} color="text.primary">
                                {t('audit.title')}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('audit.subtitle')}
                            </Typography>
                        </Box>

                        <Grid container spacing={1.5} alignItems="center">
                            <Grid item xs={12} sm={6} md={3}>
                                <TextField
                                    fullWidth
                                    size="small"
                                    placeholder={t('audit.filter.search')}
                                    value={search}
                                    onChange={(e) => setSearch(e.target.value)}
                                    InputProps={{
                                        startAdornment: (
                                            <InputAdornment position="start">
                                                <SearchIcon fontSize="small" color="action" />
                                            </InputAdornment>
                                        ),
                                        endAdornment: search ? (
                                            <InputAdornment position="end">
                                                <IconButton size="small" onClick={() => setSearch('')}>
                                                    <ClearIcon fontSize="small" />
                                                </IconButton>
                                            </InputAdornment>
                                        ) : null,
                                    }}
                                    sx={{
                                        '& .MuiOutlinedInput-root': {
                                            borderRadius: 2,
                                            bgcolor: 'action.hover',
                                            '& fieldset': { borderColor: 'transparent' },
                                            '&:hover fieldset': { borderColor: 'divider' },
                                            '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                                        },
                                    }}
                                />
                            </Grid>

                            <Grid item xs={12} sm={6} md={2}>
                                <FormControl fullWidth size="small">
                                    <InputLabel>{t('audit.filter.module')}</InputLabel>
                                    <Select
                                        value={moduleFilter}
                                        label={t('audit.filter.module')}
                                        onChange={(e) => setModuleFilter(e.target.value)}
                                        sx={{
                                            borderRadius: 2,
                                            bgcolor: 'action.hover',
                                            '& .MuiOutlinedInput-notchedOutline': { borderColor: 'transparent' },
                                            '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' },
                                        }}
                                    >
                                        <MenuItem value="all">{t('audit.filter.allModules')}</MenuItem>
                                        {modules.map((m) => (
                                            <MenuItem key={m} value={m}>{m}</MenuItem>
                                        ))}
                                    </Select>
                                </FormControl>
                            </Grid>

                            <Grid item xs={12} sm={6} md={2}>
                                <FormControl fullWidth size="small">
                                    <InputLabel>{t('audit.filter.action')}</InputLabel>
                                    <Select
                                        value={actionFilter}
                                        label={t('audit.filter.action')}
                                        onChange={(e) => setActionFilter(e.target.value)}
                                        sx={{
                                            borderRadius: 2,
                                            bgcolor: 'action.hover',
                                            '& .MuiOutlinedInput-notchedOutline': { borderColor: 'transparent' },
                                            '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' },
                                        }}
                                    >
                                        <MenuItem value="all">{t('audit.filter.allActions')}</MenuItem>
                                        {actions.map((a) => (
                                            <MenuItem key={a} value={a}>{a}</MenuItem>
                                        ))}
                                    </Select>
                                </FormControl>
                            </Grid>

                            <Grid item xs={12} sm={6} md={1.5}>
                                <DatePicker
                                    label={t('audit.filter.from')}
                                    value={fromDate}
                                    onChange={setFromDate}
                                    slotProps={{
                                        textField: {
                                            size: 'small',
                                            fullWidth: true,
                                            sx: {
                                                '& .MuiOutlinedInput-root': {
                                                    borderRadius: 2,
                                                    bgcolor: 'action.hover',
                                                    '& fieldset': { borderColor: 'transparent' },
                                                    '&:hover fieldset': { borderColor: 'divider' },
                                                },
                                            },
                                        },
                                    }}
                                />
                            </Grid>

                            <Grid item xs={12} sm={6} md={1.5}>
                                <DatePicker
                                    label={t('audit.filter.to')}
                                    value={toDate}
                                    onChange={setToDate}
                                    slotProps={{
                                        textField: {
                                            size: 'small',
                                            fullWidth: true,
                                            sx: {
                                                '& .MuiOutlinedInput-root': {
                                                    borderRadius: 2,
                                                    bgcolor: 'action.hover',
                                                    '& fieldset': { borderColor: 'transparent' },
                                                    '&:hover fieldset': { borderColor: 'divider' },
                                                },
                                            },
                                        },
                                    }}
                                />
                            </Grid>

                            <Grid item xs={12} sm={6} md={2}>
                                <Button
                                    variant="outlined"
                                    startIcon={<RefreshIcon />}
                                    onClick={fetchAudits}
                                    fullWidth
                                    sx={{
                                        height: 40,
                                        borderRadius: 2,
                                        fontWeight: 600,
                                        textTransform: 'none',
                                        borderColor: 'divider',
                                        color: 'text.primary',
                                        '&:hover': { borderColor: 'text.primary', bgcolor: 'action.hover' },
                                    }}
                                >
                                    {t('audit.refresh')}
                                </Button>
                            </Grid>
                        </Grid>
                    </Box>

                    {/* Table / Cards */}
                    {showTableView ? (
                        <TableContainer>
                            <Table sx={{ minWidth: 1000 }}>
                                <TableHead>
                                    <TableRow
                                        sx={{
                                            bgcolor: 'action.hover',
                                            '& th': {
                                                fontWeight: 700,
                                                fontSize: '0.8125rem',
                                                color: 'text.secondary',
                                                textTransform: 'uppercase',
                                                letterSpacing: 0.6,
                                                borderBottom: '1px solid',
                                                borderColor: 'divider',
                                                py: 1.75,
                                            },
                                        }}
                                    >
                                        {headCells.map((cell) => (
                                            <TableCell key={cell.id}>{cell.label}</TableCell>
                                        ))}
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                    {loading ? (
                                        <TableRow>
                                            <TableCell colSpan={8} align="center" sx={{ py: 8 }}>
                                                <CircularProgress size={36} thickness={4} />
                                            </TableCell>
                                        </TableRow>
                                    ) : audits.length === 0 ? (
                                        <TableRow>
                                            <TableCell colSpan={8} align="center" sx={{ py: 8 }}>
                                                <Typography color="text.secondary" fontWeight={500}>
                                                    {t('audit.noRecords')}
                                                </Typography>
                                            </TableCell>
                                        </TableRow>
                                    ) : (
                                        audits.map((audit, idx) => {
                                            const userName = audit.user?.name || audit.user_name || t('audit.unknown');
                                            const userEmail = audit.user?.email || audit.user_email || t('audit.noEmail');
                                            return (
                                                <TableRow
                                                    key={`${audit.created_at}-${idx}`}
                                                    hover
                                                    sx={{
                                                        '&:last-child td': { borderBottom: 0 },
                                                        transition: 'background-color 0.15s',
                                                    }}
                                                >
                                                    <TableCell sx={{ py: 2 }}>
                                                        <Typography variant="body2" fontWeight={500} color="text.secondary">
                                                            {formatDate(audit.created_at)}
                                                        </Typography>
                                                    </TableCell>
                                                    <TableCell>
                                                        <Stack direction="row" spacing={1.25} alignItems="center">
                                                            <Avatar
                                                                sx={{
                                                                    width: 34,
                                                                    height: 34,
                                                                    bgcolor: colors.sea || '#0f766e',
                                                                    fontSize: 13,
                                                                    fontWeight: 700,
                                                                }}
                                                            >
                                                                {userName.charAt(0).toUpperCase()}
                                                            </Avatar>
                                                            <Box>
                                                                <Typography variant="body2" fontWeight={600}>{userName}</Typography>
                                                                <Typography variant="caption" color="text.secondary">{userEmail}</Typography>
                                                            </Box>
                                                        </Stack>
                                                    </TableCell>
                                                    <TableCell>
                                                        <Chip
                                                            label={audit.action}
                                                            size="small"
                                                            sx={{
                                                                fontWeight: 700,
                                                                bgcolor: 'action.hover',
                                                                color: 'text.primary',
                                                                border: '1px solid',
                                                                borderColor: 'divider',
                                                                height: 26,
                                                            }}
                                                        />
                                                    </TableCell>
                                                    <TableCell>
                                                        <Typography variant="body2" fontWeight={500}>{audit.module || '—'}</Typography>
                                                    </TableCell>
                                                    <TableCell sx={{ maxWidth: 260 }}>
                                                        <Typography variant="body2" color="text.secondary" sx={{ wordBreak: 'break-word' }}>
                                                            {audit.description?.substring(0, 55) || t('audit.noDescription')}
                                                            {audit.description?.length > 55 && '…'}
                                                        </Typography>
                                                    </TableCell>
                                                    <TableCell>
                                                        <Typography variant="body2" fontFamily="monospace" fontWeight={500}>
                                                            {audit.ip_address || '—'}
                                                        </Typography>
                                                    </TableCell>
                                                    <TableCell>
                                                        <Chip
                                                            label={audit.request_method || 'N/A'}
                                                            size="small"
                                                            variant="outlined"
                                                            sx={{ height: 24, fontWeight: 600, borderColor: 'divider' }}
                                                        />
                                                    </TableCell>
                                                    <TableCell align="center">
                                                        <IconButton
                                                            size="small"
                                                            onClick={(e) => handleMenuOpen(e, audit)}
                                                            sx={{
                                                                color: 'text.secondary',
                                                                '&:hover': { bgcolor: 'action.hover', color: 'text.primary' },
                                                            }}
                                                        >
                                                            <MoreVertIcon />
                                                        </IconButton>
                                                    </TableCell>
                                                </TableRow>
                                            );
                                        })
                                    )}
                                </TableBody>
                            </Table>
                        </TableContainer>
                    ) : (
                        <Box sx={{ p: { xs: 2, sm: 2.5 } }}>
                            {loading ? (
                                <Box display="flex" justifyContent="center" py={6}>
                                    <CircularProgress size={36} thickness={4} />
                                </Box>
                            ) : audits.length === 0 ? (
                                <Paper variant="outlined" sx={{ p: 5, textAlign: 'center', borderRadius: 3, borderStyle: 'dashed' }}>
                                    <Typography color="text.secondary" fontWeight={500}>
                                        {t('audit.noRecords')}
                                    </Typography>
                                </Paper>
                            ) : (
                                <Stack spacing={2}>
                                    {audits.map((audit, idx) => {
                                        const userName = audit.user?.name || audit.user_name || t('audit.unknown');
                                        const userEmail = audit.user?.email || audit.user_email || t('audit.noEmail');
                                        return (
                                            <Card
                                                key={`${audit.created_at}-${idx}`}
                                                elevation={0}
                                                sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', overflow: 'hidden' }}
                                            >
                                                <CardContent sx={{ p: 2.25 }}>
                                                    <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={1.5}>
                                                        <Stack direction="row" spacing={1} alignItems="center">
                                                            <TimeIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                                                {formatDate(audit.created_at)}
                                                            </Typography>
                                                        </Stack>
                                                        <Chip
                                                            label={audit.action}
                                                            size="small"
                                                            sx={{
                                                                fontWeight: 700,
                                                                bgcolor: 'action.hover',
                                                                border: '1px solid',
                                                                borderColor: 'divider',
                                                                height: 26,
                                                            }}
                                                        />
                                                    </Stack>

                                                    <Stack direction="row" spacing={1.25} alignItems="center" mb={1.5}>
                                                        <Avatar
                                                            sx={{
                                                                width: 36,
                                                                height: 36,
                                                                bgcolor: colors.sea || '#0f766e',
                                                                fontSize: 14,
                                                                fontWeight: 700,
                                                            }}
                                                        >
                                                            {userName.charAt(0).toUpperCase()}
                                                        </Avatar>
                                                        <Box>
                                                            <Typography variant="body2" fontWeight={600}>{userName}</Typography>
                                                            <Typography variant="caption" color="text.secondary">{userEmail}</Typography>
                                                        </Box>
                                                    </Stack>

                                                    <Stack direction="row" justifyContent="space-between" mb={1}>
                                                        <Typography variant="body2" color="text.secondary">
                                                            {t('audit.col.module')}: <strong>{audit.module || '—'}</strong>
                                                        </Typography>
                                                        <Stack direction="row" spacing={0.5} alignItems="center">
                                                            <IpIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                                                            <Typography variant="caption" fontFamily="monospace">
                                                                {audit.ip_address}
                                                            </Typography>
                                                        </Stack>
                                                    </Stack>

                                                    <Stack direction="row" spacing={1} alignItems="center" mb={1.5}>
                                                        <MethodIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                        <Chip
                                                            label={audit.request_method || 'N/A'}
                                                            size="small"
                                                            variant="outlined"
                                                            sx={{ height: 22, fontWeight: 600 }}
                                                        />
                                                    </Stack>

                                                    <Divider sx={{ my: 1.5 }} />

                                                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
                                                        {audit.description || t('audit.noDescription')}
                                                    </Typography>

                                                    <Box display="flex" justifyContent="flex-end">
                                                        <Button
                                                            size="small"
                                                            startIcon={<ViewIcon />}
                                                            onClick={(e) => handleMenuOpen(e, audit)}
                                                            sx={{
                                                                fontWeight: 600,
                                                                textTransform: 'none',
                                                                color: colors.sea || '#0f766e',
                                                            }}
                                                        >
                                                            {t('audit.viewDetails')}
                                                        </Button>
                                                    </Box>
                                                </CardContent>
                                            </Card>
                                        );
                                    })}
                                </Stack>
                            )}
                        </Box>
                    )}

                    {/* Pagination */}
                    <Box sx={{ borderTop: '1px solid', borderColor: 'divider', bgcolor: 'action.hover' }}>
                        <TablePagination
                            rowsPerPageOptions={[5, 10, 25, 50]}
                            component="div"
                            count={total}
                            rowsPerPage={rowsPerPage}
                            page={page}
                            onPageChange={(e, newPage) => setPage(newPage)}
                            onRowsPerPageChange={(e) => {
                                setRowsPerPage(parseInt(e.target.value, 10));
                                setPage(0);
                            }}
                            sx={{
                                '.MuiTablePagination-selectLabel, .MuiTablePagination-displayedRows': {
                                    fontWeight: 500,
                                },
                            }}
                        />
                    </Box>
                </Paper>

                {/* Action Menu */}
                <Menu
                    anchorEl={actionMenu}
                    open={Boolean(actionMenu)}
                    onClose={handleMenuClose}
                    anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                    transformOrigin={{ vertical: 'top', horizontal: 'right' }}
                    PaperProps={{ elevation: 8, sx: { borderRadius: 2, minWidth: 160, mt: 0.5 } }}
                >
                    <MenuItem onClick={handleViewDetails} sx={{ fontWeight: 500 }}>
                        <ViewIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('audit.viewDetails')}
                    </MenuItem>
                </Menu>

                {/* Details Modal */}
                <Dialog
                    open={viewModalOpen}
                    onClose={() => setViewModalOpen(false)}
                    maxWidth="md"
                    fullWidth
                    PaperProps={{ sx: { borderRadius: { xs: 0, sm: 3 }, bgcolor: 'background.paper' } }}
                >
                    <DialogTitle
                        sx={{
                            px: { xs: 2.5, sm: 3 },
                            pt: 2.5,
                            pb: 1.5,
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'flex-start',
                        }}
                    >
                        <Box>
                            <Typography variant="h6" fontWeight={800}>
                                {t('audit.modal.title')}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('audit.modal.subtitle')}
                            </Typography>
                        </Box>
                        <IconButton
                            onClick={() => setViewModalOpen(false)}
                            size="small"
                            sx={{
                                color: 'text.secondary',
                                mt: -0.5,
                                '&:hover': { bgcolor: 'action.hover', color: 'text.primary' },
                            }}
                        >
                            <CloseIcon />
                        </IconButton>
                    </DialogTitle>

                    <Divider />

                    <DialogContent sx={{ px: { xs: 2.5, sm: 3 }, py: 2.5 }}>
                        {selectedAudit && (
                            <Box
                                component="dl"
                                sx={{
                                    display: 'grid',
                                    gridTemplateColumns: { xs: '1fr', sm: '140px 1fr' },
                                    gap: 1.25,
                                    '& dt': {
                                        fontWeight: 700,
                                        color: 'text.secondary',
                                        fontSize: '0.8125rem',
                                        mt: 0.5,
                                    },
                                    '& dd': {
                                        m: 0,
                                        wordBreak: 'break-all',
                                        fontSize: '0.875rem',
                                        color: 'text.primary',
                                        mb: 0.75,
                                        fontWeight: 500,
                                    },
                                }}
                            >
                                <dt>{t('audit.modal.dateTime')}</dt>
                                <dd>{formatDate(selectedAudit.created_at)}</dd>

                                <dt>{t('audit.modal.user')}</dt>
                                <dd>
                                    {selectedAudit.user?.name || selectedAudit.user_name || t('audit.unknown')} (
                                    {selectedAudit.user?.email || selectedAudit.user_email || t('audit.noEmail')})
                                </dd>

                                <dt>{t('audit.modal.role')}</dt>
                                <dd>{selectedAudit.user?.role || selectedAudit.user_role || 'N/A'}</dd>

                                <dt>{t('audit.modal.action')}</dt>
                                <dd>{selectedAudit.action}</dd>

                                <dt>{t('audit.modal.module')}</dt>
                                <dd>{selectedAudit.module || '—'}</dd>

                                <dt>{t('audit.modal.description')}</dt>
                                <dd>{selectedAudit.description || t('audit.noDescription')}</dd>

                                <dt>{t('audit.modal.ip')}</dt>
                                <dd style={{ fontFamily: 'monospace' }}>{selectedAudit.ip_address}</dd>

                                <dt>{t('audit.modal.method')}</dt>
                                <dd>{selectedAudit.request_method || 'N/A'}</dd>

                                <dt>{t('audit.modal.url')}</dt>
                                <dd style={{ wordBreak: 'break-all' }}>{selectedAudit.request_url || 'N/A'}</dd>

                                <dt>{t('audit.modal.userAgent')}</dt>
                                <dd style={{ wordBreak: 'break-all' }}>{selectedAudit.user_agent || 'N/A'}</dd>

                                {selectedAudit.old_data && (
                                    <>
                                        <dt>{t('audit.modal.oldData')}</dt>
                                        <dd>
                                            <Box
                                                component="pre"
                                                sx={{
                                                    whiteSpace: 'pre-wrap',
                                                    m: 0,
                                                    fontSize: '0.75rem',
                                                    bgcolor: 'action.hover',
                                                    p: 1.5,
                                                    borderRadius: 2,
                                                    maxHeight: 200,
                                                    overflow: 'auto',
                                                    border: '1px solid',
                                                    borderColor: 'divider',
                                                }}
                                            >
                                                {JSON.stringify(selectedAudit.old_data, null, 2)}
                                            </Box>
                                        </dd>
                                    </>
                                )}

                                {selectedAudit.new_data && (
                                    <>
                                        <dt>{t('audit.modal.newData')}</dt>
                                        <dd>
                                            <Box
                                                component="pre"
                                                sx={{
                                                    whiteSpace: 'pre-wrap',
                                                    m: 0,
                                                    fontSize: '0.75rem',
                                                    bgcolor: 'action.hover',
                                                    p: 1.5,
                                                    borderRadius: 2,
                                                    maxHeight: 200,
                                                    overflow: 'auto',
                                                    border: '1px solid',
                                                    borderColor: 'divider',
                                                }}
                                            >
                                                {JSON.stringify(selectedAudit.new_data, null, 2)}
                                            </Box>
                                        </dd>
                                    </>
                                )}
                            </Box>
                        )}
                    </DialogContent>

                    <Divider />

                    <DialogActions sx={{ px: { xs: 2.5, sm: 3 }, py: 2 }}>
                        <Button
                            onClick={() => setViewModalOpen(false)}
                            variant="contained"
                            sx={{
                                borderRadius: 2,
                                fontWeight: 700,
                                textTransform: 'none',
                                boxShadow: 'none',
                                bgcolor: colors.sea || '#0f766e',
                                '&:hover': {
                                    bgcolor: colors.dark || '#0d5c56',
                                    boxShadow: '0 4px 12px rgba(15,118,110,0.35)',
                                },
                            }}
                        >
                            {t('audit.close')}
                        </Button>
                    </DialogActions>
                </Dialog>
            </Box>
        </LocalizationProvider>
    );
}