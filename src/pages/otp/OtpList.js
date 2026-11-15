// src/pages/otp/OtpList.js
import React, { useState, useEffect, useCallback } from 'react';
import {
    Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle,
    IconButton, InputAdornment, Paper, Table, TableBody, TableCell, TableContainer,
    TableHead, TablePagination, TableRow, TextField, Typography, FormControl,
    InputLabel, Select, MenuItem, Grid, Card, CardContent, CircularProgress,
    Tooltip, useTheme, useMediaQuery, Alert, Stack,
} from '@mui/material';
import {
    Refresh as RefreshIcon, Search as SearchIcon, DeleteSweep as CleanupIcon,
    CheckCircle as UsedIcon, Cancel as UnusedIcon, Email as EmailIcon,
    Schedule as ScheduleIcon, Computer as IpIcon, Label as TypeIcon, Clear as ClearIcon,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';

import { otpService } from 'services/otp.service';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tOtp } from './otplang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function OtpList() {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));
    const { language } = useLanguage();
    const t = (key) => tOtp(language, key);

    const { can } = usePermissions();
    const canView = can('otp.view');
    const canCleanup = can('otp.cleanup');

    const [otps, setOtps] = useState([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [stats, setStats] = useState(null);

    const [email, setEmail] = useState('');
    const [typeFilter, setTypeFilter] = useState('all');
    const [usedFilter, setUsedFilter] = useState('all');
    const [expiredFilter, setExpiredFilter] = useState(false);
    const [startDate, setStartDate] = useState(null);
    const [endDate, setEndDate] = useState(null);

    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);

    const [confirmDialog, setConfirmDialog] = useState({
        open: false,
        title: '',
        message: '',
        action: null,
    });

    const headCells = [
        { id: 'email', label: t('otp.col.email') },
        { id: 'type', label: t('otp.col.type') },
        { id: 'otp', label: t('otp.col.otp') },
        { id: 'is_used', label: t('otp.col.used') },
        { id: 'expires_at', label: t('otp.col.expiresAt') },
        { id: 'created_at', label: t('otp.col.createdAt') },
        { id: 'ip_address', label: t('otp.col.ip') },
    ];

    const typeOptions = [
        { value: 'all', label: t('otp.filter.allTypes') },
        { value: 'registration', label: t('otp.filter.registration') },
        { value: 'password_reset', label: t('otp.filter.passwordReset') },
        { value: 'email_verification', label: t('otp.filter.emailVerification') },
        { value: 'login', label: t('otp.filter.login') },
    ];

    const usedOptions = [
        { value: 'all', label: t('otp.filter.all') },
        { value: 'true', label: t('otp.filter.used') },
        { value: 'false', label: t('otp.filter.unused') },
    ];

    const fetchOtps = useCallback(async () => {
        if (!canView) return;
        setLoading(true);
        setError(null);
        try {
            const params = {
                page: page + 1,
                per_page: rowsPerPage,
                email: email || undefined,
                type: typeFilter !== 'all' ? typeFilter : undefined,
                is_used: usedFilter !== 'all' ? usedFilter === 'true' : undefined,
                expired: expiredFilter ? 'true' : undefined,
                start_date: startDate ? startDate.toISOString().split('T')[0] : undefined,
                end_date: endDate ? endDate.toISOString().split('T')[0] : undefined,
            };
            const response = await otpService.getOtps(params);

            if (response?.data?.status === 'success') {
                const data = response.data.data;
                if (data && data.data) {
                    setOtps(data.data);
                    setTotal(data.total || 0);
                    setStats(data.stats || null);
                } else if (Array.isArray(data)) {
                    setOtps(data);
                    setTotal(data.length || 0);
                } else {
                    setOtps([]);
                    setTotal(0);
                    setStats(null);
                }
            } else {
                setOtps([]);
                setTotal(0);
                setStats(null);
                if (response?.data?.message) setError(response.data.message);
            }
        } catch (err) {
            console.error('OTP error:', err);
            setError(err.message || t('otp.loadFailed'));
            showSnackbar({ type: 'error', message: t('otp.loadFailed') });
            setOtps([]);
            setTotal(0);
            setStats(null);
        } finally {
            setLoading(false);
        }
    }, [page, rowsPerPage, email, typeFilter, usedFilter, expiredFilter, startDate, endDate, canView, language]);

    useEffect(() => {
        if (canView) fetchOtps();
    }, [fetchOtps, canView]);

    const handleCleanupExpired = () => {
        setConfirmDialog({
            open: true,
            title: t('otp.cleanupTitle'),
            message: t('otp.cleanupMessage'),
            action: async () => {
                try {
                    const response = await otpService.cleanup();
                    if (response?.data?.status === 'success') {
                        showSnackbar({
                            type: 'success',
                            message: response.data.message || t('otp.cleanupSuccess'),
                        });
                        fetchOtps();
                    } else {
                        throw new Error(response?.data?.message || t('otp.cleanupFailed'));
                    }
                } catch (err) {
                    showSnackbar({ type: 'error', message: err.message });
                }
            },
        });
    };

    const handleConfirm = async () => {
        if (!confirmDialog.action) return;
        setConfirmDialog((prev) => ({ ...prev, open: false }));
        try {
            await confirmDialog.action();
        } catch (err) {
            showSnackbar({ type: 'error', message: t('otp.actionFailed') });
        }
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
                        {t('otp.accessDenied')}
                    </Typography>
                    <Typography color="text.secondary">
                        {t('otp.noPermission')}
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
                                fetchOtps();
                            }}
                        >
                            {t('otp.retry')}
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
                {stats && (
                    <Grid container spacing={2} sx={{ mb: 3 }}>
                        <Grid item xs={6} sm={4} md={2.4}>
                            <Card
                                elevation={0}
                                sx={{
                                    borderRadius: 3,
                                    border: '1px solid',
                                    borderColor: 'divider',
                                    bgcolor: 'background.paper', // ✅ Theme aware
                                    height: '100%',
                                }}
                            >
                                <CardContent sx={{ p: 2.25 }}>
                                    <Typography variant="overline" fontWeight={700} color="text.secondary" letterSpacing={1}>
                                        {t('otp.stats.total')}
                                    </Typography>
                                    <Typography variant="h4" fontWeight={800} color="info.main" sx={{ mt: 0.5, lineHeight: 1.1 }}>
                                        {stats.total ?? 0}
                                    </Typography>
                                </CardContent>
                            </Card>
                        </Grid>
                        <Grid item xs={6} sm={4} md={2.4}>
                            <Card
                                elevation={0}
                                sx={{
                                    borderRadius: 3,
                                    border: '1px solid',
                                    borderColor: 'divider',
                                    bgcolor: 'background.paper', // ✅ Theme aware
                                    height: '100%',
                                }}
                            >
                                <CardContent sx={{ p: 2.25 }}>
                                    <Typography variant="overline" fontWeight={700} color="text.secondary" letterSpacing={1}>
                                        {t('otp.stats.used')}
                                    </Typography>
                                    <Typography variant="h4" fontWeight={800} color="success.main" sx={{ mt: 0.5, lineHeight: 1.1 }}>
                                        {stats.used ?? 0}
                                    </Typography>
                                </CardContent>
                            </Card>
                        </Grid>
                        <Grid item xs={6} sm={4} md={2.4}>
                            <Card
                                elevation={0}
                                sx={{
                                    borderRadius: 3,
                                    border: '1px solid',
                                    borderColor: 'divider',
                                    bgcolor: 'background.paper', // ✅ Theme aware
                                    height: '100%',
                                }}
                            >
                                <CardContent sx={{ p: 2.25 }}>
                                    <Typography variant="overline" fontWeight={700} color="text.secondary" letterSpacing={1}>
                                        {t('otp.stats.unused')}
                                    </Typography>
                                    <Typography variant="h4" fontWeight={800} color="warning.main" sx={{ mt: 0.5, lineHeight: 1.1 }}>
                                        {stats.unused ?? 0}
                                    </Typography>
                                </CardContent>
                            </Card>
                        </Grid>
                        <Grid item xs={6} sm={4} md={2.4}>
                            <Card
                                elevation={0}
                                sx={{
                                    borderRadius: 3,
                                    border: '1px solid',
                                    borderColor: 'divider',
                                    bgcolor: 'background.paper', // ✅ Theme aware
                                    height: '100%',
                                }}
                            >
                                <CardContent sx={{ p: 2.25 }}>
                                    <Typography variant="overline" fontWeight={700} color="text.secondary" letterSpacing={1}>
                                        {t('otp.stats.expired')}
                                    </Typography>
                                    <Typography variant="h4" fontWeight={800} color="error.main" sx={{ mt: 0.5, lineHeight: 1.1 }}>
                                        {stats.expired ?? 0}
                                    </Typography>
                                </CardContent>
                            </Card>
                        </Grid>
                        <Grid item xs={12} sm={8} md={2.4}>
                            <Card
                                elevation={0}
                                sx={{
                                    borderRadius: 3,
                                    border: '1px solid',
                                    borderColor: 'divider',
                                    bgcolor: 'background.paper', // ✅ Theme aware
                                    height: '100%',
                                }}
                            >
                                <CardContent sx={{ p: 2.25 }}>
                                    <Typography variant="overline" fontWeight={700} color="text.secondary" letterSpacing={1}>
                                        {t('otp.stats.byType')}
                                    </Typography>
                                    <Typography variant="caption" component="div" fontWeight={600} color="text.primary" sx={{ mt: 0.75 }}>
                                        {stats.by_type?.map((item) => `${item.type}: ${item.count}`).join(', ') || 'N/A'}
                                    </Typography>
                                </CardContent>
                            </Card>
                        </Grid>
                    </Grid>
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
                        bgcolor: 'background.paper',
                    }}
                >
                    {/* Header + Filters */}
                    <Box
                        sx={{
                            px: { xs: 2, sm: 3 },
                            py: 2.5,
                            borderBottom: '1px solid',
                            borderColor: 'divider',
                        }}
                    >
                        <Stack
                            direction={{ xs: 'column', sm: 'row' }}
                            justifyContent="space-between"
                            alignItems={{ xs: 'stretch', sm: 'center' }}
                            spacing={2}
                            mb={2.5}
                        >
                            <Box>
                                <Typography variant="h5" fontWeight={800} color="text.primary">
                                    {t('otp.title')}
                                </Typography>
                                <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                    {t('otp.subtitle')}
                                </Typography>
                            </Box>

                            {canCleanup && (
                                <Tooltip title={t('otp.cleanupTooltip')}>
                                    <Button
                                        variant="contained"
                                        startIcon={<CleanupIcon />}
                                        onClick={handleCleanupExpired}
                                        size={isMobile ? 'small' : 'medium'}
                                        sx={{
                                            borderRadius: 2,
                                            fontWeight: 700,
                                            textTransform: 'none',
                                            boxShadow: 'none',
                                            bgcolor: 'warning.main',
                                            color: 'warning.contrastText',
                                            '&:hover': {
                                                bgcolor: 'warning.dark',
                                                boxShadow: '0 4px 12px rgba(245,158,11,0.35)',
                                            },
                                        }}
                                    >
                                        {t('otp.cleanup')}
                                    </Button>
                                </Tooltip>
                            )}
                        </Stack>

                        <Grid container spacing={1.5} alignItems="center">
                            <Grid item xs={12} sm={6} md={2.2}>
                                <TextField
                                    fullWidth
                                    size="small"
                                    placeholder={t('otp.filter.email')}
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    InputProps={{
                                        startAdornment: (
                                            <InputAdornment position="start">
                                                <SearchIcon fontSize="small" color="action" />
                                            </InputAdornment>
                                        ),
                                        endAdornment: email ? (
                                            <InputAdornment position="end">
                                                <IconButton size="small" onClick={() => setEmail('')}>
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

                            <Grid item xs={12} sm={6} md={1.8}>
                                <FormControl fullWidth size="small">
                                    <InputLabel>{t('otp.filter.type')}</InputLabel>
                                    <Select
                                        value={typeFilter}
                                        label={t('otp.filter.type')}
                                        onChange={(e) => setTypeFilter(e.target.value)}
                                        sx={{
                                            borderRadius: 2,
                                            bgcolor: 'action.hover',
                                            '& .MuiOutlinedInput-notchedOutline': { borderColor: 'transparent' },
                                            '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' },
                                        }}
                                    >
                                        {typeOptions.map((opt) => (
                                            <MenuItem key={opt.value} value={opt.value}>
                                                {opt.label}
                                            </MenuItem>
                                        ))}
                                    </Select>
                                </FormControl>
                            </Grid>

                            <Grid item xs={12} sm={6} md={1.8}>
                                <FormControl fullWidth size="small">
                                    <InputLabel>{t('otp.filter.usedStatus')}</InputLabel>
                                    <Select
                                        value={usedFilter}
                                        label={t('otp.filter.usedStatus')}
                                        onChange={(e) => setUsedFilter(e.target.value)}
                                        sx={{
                                            borderRadius: 2,
                                            bgcolor: 'action.hover',
                                            '& .MuiOutlinedInput-notchedOutline': { borderColor: 'transparent' },
                                            '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' },
                                        }}
                                    >
                                        {usedOptions.map((opt) => (
                                            <MenuItem key={opt.value} value={opt.value}>
                                                {opt.label}
                                            </MenuItem>
                                        ))}
                                    </Select>
                                </FormControl>
                            </Grid>

                            <Grid item xs={12} sm={6} md={1.6}>
                                <FormControl fullWidth size="small">
                                    <InputLabel>{t('otp.filter.expired')}</InputLabel>
                                    <Select
                                        value={expiredFilter ? 'true' : 'false'}
                                        label={t('otp.filter.expired')}
                                        onChange={(e) => setExpiredFilter(e.target.value === 'true')}
                                        sx={{
                                            borderRadius: 2,
                                            bgcolor: 'action.hover',
                                            '& .MuiOutlinedInput-notchedOutline': { borderColor: 'transparent' },
                                            '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' },
                                        }}
                                    >
                                        <MenuItem value="false">{t('otp.filter.all')}</MenuItem>
                                        <MenuItem value="true">{t('otp.filter.expiredOnly')}</MenuItem>
                                    </Select>
                                </FormControl>
                            </Grid>

                            <Grid item xs={12} sm={6} md={1.6}>
                                <DatePicker
                                    label={t('otp.filter.start')}
                                    value={startDate}
                                    onChange={setStartDate}
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

                            <Grid item xs={12} sm={6} md={1.6}>
                                <DatePicker
                                    label={t('otp.filter.end')}
                                    value={endDate}
                                    onChange={setEndDate}
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

                            <Grid item xs={12} sm={6} md={1.4}>
                                <Button
                                    variant="outlined"
                                    startIcon={<RefreshIcon />}
                                    onClick={fetchOtps}
                                    fullWidth
                                    sx={{
                                        height: 40,
                                        borderRadius: 2,
                                        fontWeight: 600,
                                        textTransform: 'none',
                                        borderColor: 'divider',
                                        color: 'text.primary',
                                        '&:hover': {
                                            borderColor: 'text.primary',
                                            bgcolor: 'action.hover',
                                        },
                                    }}
                                >
                                    {t('otp.refresh')}
                                </Button>
                            </Grid>
                        </Grid>
                    </Box>

                    {/* Table / Cards */}
                    {showTableView ? (
                        <TableContainer>
                            <Table sx={{ minWidth: 900 }}>
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
                                            <TableCell colSpan={headCells.length} align="center" sx={{ py: 8 }}>
                                                <CircularProgress size={36} thickness={4} />
                                            </TableCell>
                                        </TableRow>
                                    ) : otps.length === 0 ? (
                                        <TableRow>
                                            <TableCell colSpan={headCells.length} align="center" sx={{ py: 8 }}>
                                                <Typography color="text.secondary" fontWeight={500}>
                                                    {t('otp.noRecords')}
                                                </Typography>
                                            </TableCell>
                                        </TableRow>
                                    ) : (
                                        otps.map((otp) => {
                                            const isExpired = new Date(otp.expires_at) < new Date();
                                            return (
                                                <TableRow
                                                    key={otp.id}
                                                    hover
                                                    sx={{
                                                        '&:last-child td': { borderBottom: 0 },
                                                        transition: 'background-color 0.15s',
                                                    }}
                                                >
                                                    <TableCell sx={{ py: 2 }}>
                                                        <Typography variant="body2" fontWeight={600}>
                                                            {otp.email}
                                                        </Typography>
                                                    </TableCell>
                                                    <TableCell>
                                                        <Chip
                                                            label={otp.type}
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
                                                        <Typography
                                                            component="code"
                                                            variant="body2"
                                                            fontWeight={700}
                                                            sx={{
                                                                fontFamily: 'monospace',
                                                                color: colors.sea || '#0f766e',
                                                                letterSpacing: 1,
                                                            }}
                                                        >
                                                            {otp.otp}
                                                        </Typography>
                                                    </TableCell>
                                                    <TableCell>
                                                        {otp.is_used ? (
                                                            <Chip
                                                                icon={<UsedIcon sx={{ fontSize: 16 }} />}
                                                                label={t('otp.used')}
                                                                size="small"
                                                                sx={{
                                                                    fontWeight: 700,
                                                                    bgcolor: 'success.light',
                                                                    color: 'success.dark',
                                                                    border: '1.5px solid',
                                                                    borderColor: 'success.main',
                                                                    height: 26,
                                                                    '& .MuiChip-icon': { color: 'success.dark' },
                                                                }}
                                                            />
                                                        ) : (
                                                            <Chip
                                                                icon={<UnusedIcon sx={{ fontSize: 16 }} />}
                                                                label={t('otp.unused')}
                                                                size="small"
                                                                sx={{
                                                                    fontWeight: 700,
                                                                    bgcolor: 'action.hover',
                                                                    color: 'text.secondary',
                                                                    border: '1.5px solid',
                                                                    borderColor: 'divider',
                                                                    height: 26,
                                                                    '& .MuiChip-icon': { color: 'text.secondary' },
                                                                }}
                                                            />
                                                        )}
                                                    </TableCell>
                                                    <TableCell>
                                                        <Typography
                                                            variant="body2"
                                                            fontWeight={500}
                                                            color={isExpired ? 'error.main' : 'text.secondary'}
                                                        >
                                                            {formatDate(otp.expires_at)}
                                                            {isExpired && ` (${t('otp.expired')})`}
                                                        </Typography>
                                                    </TableCell>
                                                    <TableCell>
                                                        <Typography variant="body2" fontWeight={500} color="text.secondary">
                                                            {formatDate(otp.created_at)}
                                                        </Typography>
                                                    </TableCell>
                                                    <TableCell>
                                                        <Typography variant="body2" fontFamily="monospace" fontWeight={500}>
                                                            {otp.ip_address || '—'}
                                                        </Typography>
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
                            ) : otps.length === 0 ? (
                                <Paper
                                    variant="outlined"
                                    sx={{
                                        p: 5,
                                        textAlign: 'center',
                                        borderRadius: 3,
                                        borderStyle: 'dashed',
                                    }}
                                >
                                    <Typography color="text.secondary" fontWeight={500}>
                                        {t('otp.noRecords')}
                                    </Typography>
                                </Paper>
                            ) : (
                                <Stack spacing={2}>
                                    {otps.map((otp) => {
                                        const isExpired = new Date(otp.expires_at) < new Date();
                                        return (
                                            <Card
                                                key={otp.id}
                                                elevation={0}
                                                sx={{
                                                    borderRadius: 3,
                                                    border: '1px solid',
                                                    borderColor: 'divider',
                                                    bgcolor: 'background.paper',
                                                    overflow: 'hidden',
                                                }}
                                            >
                                                <CardContent sx={{ p: 2.25 }}>
                                                    <Stack
                                                        direction="row"
                                                        justifyContent="space-between"
                                                        alignItems="flex-start"
                                                        mb={1.5}
                                                    >
                                                        <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap">
                                                            <EmailIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                                            <Typography variant="body2" fontWeight={600} sx={{ wordBreak: 'break-all' }}>
                                                                {otp.email}
                                                            </Typography>
                                                        </Stack>
                                                        {otp.is_used ? (
                                                            <Chip
                                                                icon={<UsedIcon sx={{ fontSize: 14 }} />}
                                                                label={t('otp.used')}
                                                                size="small"
                                                                sx={{
                                                                    fontWeight: 700,
                                                                    bgcolor: 'success.light',
                                                                    color: 'success.dark',
                                                                    border: '1.5px solid',
                                                                    borderColor: 'success.main',
                                                                    height: 26,
                                                                }}
                                                            />
                                                        ) : (
                                                            <Chip
                                                                icon={<UnusedIcon sx={{ fontSize: 14 }} />}
                                                                label={t('otp.unused')}
                                                                size="small"
                                                                sx={{
                                                                    fontWeight: 700,
                                                                    bgcolor: 'action.hover',
                                                                    color: 'text.secondary',
                                                                    border: '1.5px solid',
                                                                    borderColor: 'divider',
                                                                    height: 26,
                                                                }}
                                                            />
                                                        )}
                                                    </Stack>

                                                    <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1.5}>
                                                        <Stack direction="row" spacing={1} alignItems="center">
                                                            <TypeIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                            <Typography variant="body2" fontWeight={500}>
                                                                {otp.type}
                                                            </Typography>
                                                        </Stack>
                                                        <Typography
                                                            component="code"
                                                            variant="body2"
                                                            fontWeight={700}
                                                            sx={{
                                                                fontFamily: 'monospace',
                                                                color: colors.sea || '#0f766e',
                                                                letterSpacing: 1,
                                                            }}
                                                        >
                                                            {otp.otp}
                                                        </Typography>
                                                    </Stack>

                                                    <Stack direction="row" spacing={1} alignItems="center" mb={1}>
                                                        <ScheduleIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                        <Typography
                                                            variant="caption"
                                                            fontWeight={500}
                                                            color={isExpired ? 'error.main' : 'text.secondary'}
                                                        >
                                                            {t('otp.expires')}: {formatDate(otp.expires_at)}
                                                            {isExpired && ` (${t('otp.expired')})`}
                                                        </Typography>
                                                    </Stack>

                                                    <Stack direction="row" justifyContent="space-between" alignItems="center">
                                                        <Typography variant="caption" color="text.secondary" fontWeight={500}>
                                                            {t('otp.created')}: {formatDate(otp.created_at)}
                                                        </Typography>
                                                        <Stack direction="row" spacing={0.5} alignItems="center">
                                                            <IpIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                                                            <Typography variant="caption" color="text.secondary" fontFamily="monospace">
                                                                {otp.ip_address || '—'}
                                                            </Typography>
                                                        </Stack>
                                                    </Stack>
                                                </CardContent>
                                            </Card>
                                        );
                                    })}
                                </Stack>
                            )}
                        </Box>
                    )}

                    {/* Pagination */}
                    <Box
                        sx={{
                            borderTop: '1px solid',
                            borderColor: 'divider',
                            bgcolor: 'action.hover',
                        }}
                    >
                        <TablePagination
                            rowsPerPageOptions={[5, 10, 25, 50, 100]}
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

                {/* Confirm Dialog */}
                <Dialog
                    open={confirmDialog.open}
                    onClose={() => setConfirmDialog((prev) => ({ ...prev, open: false }))}
                    fullWidth
                    maxWidth="xs"
                    PaperProps={{ sx: { borderRadius: 3 } }}
                >
                    <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>{confirmDialog.title}</DialogTitle>
                    <DialogContent>
                        <Typography color="text.secondary">{confirmDialog.message}</Typography>
                    </DialogContent>
                    <DialogActions sx={{ px: 3, pb: 2.5, pt: 1 }}>
                        <Button
                            onClick={() => setConfirmDialog((prev) => ({ ...prev, open: false }))}
                            sx={{ fontWeight: 600, textTransform: 'none' }}
                        >
                            {t('otp.cancel')}
                        </Button>
                        <Button
                            onClick={handleConfirm}
                            variant="contained"
                            color="error"
                            sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}
                        >
                            {t('otp.confirm')}
                        </Button>
                    </DialogActions>
                </Dialog>
            </Box>
        </LocalizationProvider>
    );
}