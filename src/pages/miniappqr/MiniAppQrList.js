// src/pages/miniappqr/MiniAppQrList.js
import React, { useState, useEffect, useMemo, useCallback } from 'react';
import {
    Box, Paper, Typography, Button, TextField, InputAdornment, IconButton, MenuItem,
    Dialog, DialogTitle, DialogContent, DialogActions, Table, TableBody,
    TableCell, TableContainer, TableHead, TableRow, TablePagination,
    CircularProgress, Alert, Chip, Stack, Card, CardContent, Grid,
    Menu, Tooltip, useMediaQuery, useTheme,
} from '@mui/material';
import {
    Add as AddIcon, Search as SearchIcon, Refresh as RefreshIcon,
    Edit as EditIcon, Delete as DeleteIcon, Clear as ClearIcon,
    QrCode2 as QrIcon, Autorenew as RenewIcon, Block as RevokeIcon,
    CheckCircle as ActivateIcon,
} from '@mui/icons-material';
import { miniAppQrService } from 'services/miniAppQr.service';
import { useMiniAppQrManagement } from 'hooks/useMiniAppQr';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tQr } from './qrlang';
import { VALIDITIES, STATUS_COLORS, displayStatus, fmtDate } from './qrHelpers';
import MiniAppQrFormModal from './MiniAppQrFormModal';
import QrPreviewDialog from './QrPreviewDialog';
import appConfig from '../../config';

const colors = appConfig.app.colors;
const STATUS_FILTERS = ['active', 'expiring', 'expired', 'revoked'];

const MiniAppQrList = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));

    const { language } = useLanguage();
    const t = (key, r) => tQr(language, key, r);

    const { can } = usePermissions();
    const canView = can('miniapp-qrs.view');
    const canCreate = can('miniapp-qrs.create');
    const canEdit = can('miniapp-qrs.update');
    const canDelete = can('miniapp-qrs.delete');

    // Create / update / delete go through the hook (context).
    // The paged list is read with the service so we get total/page directly.
    const { updateQr, deleteQr } = useMiniAppQrManagement();

    const [rows, setRows] = useState([]);
    const [stats, setStats] = useState({ total: 0, active: 0, expiring: 0, expired: 0, revoked: 0 });
    const [apps, setApps] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const [search, setSearch] = useState('');
    const [appFilter, setAppFilter] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [total, setTotal] = useState(0);

    const [openForm, setOpenForm] = useState(false);
    const [editing, setEditing] = useState(null);
    const [preview, setPreview] = useState(null);
    const [renewMenu, setRenewMenu] = useState({ anchor: null, qr: null });
    const [confirm, setConfirm] = useState({ open: false, title: '', message: '', action: null });

    const load = useCallback(async () => {
        if (!canView) return;
        setLoading(true);
        setError(null);
        try {
            const [listRes, statsRes] = await Promise.all([
                miniAppQrService.getQrs({
                    page: page + 1,
                    per_page: rowsPerPage,
                    search: search || undefined,
                    mini_app_id: appFilter || undefined,
                    status: statusFilter || undefined,
                }),
                miniAppQrService.getStats().catch(() => null),
            ]);

            const body = listRes?.data;
            if (body?.status === 'success' || body?.success === true) {
                setRows(body.data?.data || []);
                setTotal(body.data?.total || 0);
            } else {
                setRows([]);
                setTotal(0);
            }
            if (statsRes?.data?.data) setStats(statsRes.data.data);
        } catch (err) {
            setError(err.response?.data?.message || err.message || t('qr.list.loadFailed'));
        } finally {
            setLoading(false);
        }
    }, [canView, page, rowsPerPage, search, appFilter, statusFilter, language]);

    // Debounce typing in the search box
    useEffect(() => {
        const id = setTimeout(load, 250);
        return () => clearTimeout(id);
    }, [load]);

    useEffect(() => {
        miniAppQrService.getMiniApps()
            .then((res) => setApps(Array.isArray(res?.data?.data) ? res.data.data : []))
            .catch(() => setApps([]));
    }, []);

    // ── Actions ─────────────────────────────────────────
    const run = async (fn, okKey) => {
        try {
            await fn();
            showSnackbar({ type: 'success', message: t(okKey) });
            load();
        } catch (err) {
            showSnackbar({ type: 'error', message: err.response?.data?.message || t('qr.form.failed') });
        }
    };

    const toggleActive = (qr) =>
        run(() => updateQr(qr.id, { is_active: !qr.is_active }),
            qr.is_active ? 'qr.revoke.success' : 'qr.activate.success');

    const renew = (qr, validity) => {
        setRenewMenu({ anchor: null, qr: null });
        run(() => updateQr(qr.id, { validity, is_active: true }), 'qr.renew.success');
    };

    const askDelete = (qr) => {
        setConfirm({
            open: true,
            title: t('qr.delete.title'),
            message: t('qr.delete.message', { name: qr.label || qr.mini_app?.name || '' }),
            action: async () => {
                setConfirm((c) => ({ ...c, open: false }));
                await run(() => deleteQr(qr.id), 'qr.delete.success');
            },
        });
    };

    const closeConfirm = () => setConfirm((c) => ({ ...c, open: false }));

    // ── Small render helpers ────────────────────────────
    const statCards = useMemo(() => [
        { key: 'total', color: '#8b5cf6' },
        { key: 'active', color: '#10b981' },
        { key: 'expiring', color: '#f59e0b' },
        { key: 'expired', color: '#ef4444' },
        { key: 'revoked', color: '#64748b' },
    ], []);

    const StatusChip = ({ qr }) => {
        const s = displayStatus(qr);
        const c = STATUS_COLORS[s] || STATUS_COLORS.active;
        return (
            <Chip label={t(`qr.status.${s}`)} size="small"
                  sx={{ fontWeight: 700, bgcolor: c.bg, color: c.fg, height: 24 }} />
        );
    };

    const ExpiryText = ({ qr }) => {
        if (!qr.expires_at) {
            return <Typography variant="body2" color="text.secondary">{t('qr.expires.never')}</Typography>;
        }
        return (
            <Box>
                <Typography variant="body2" fontWeight={600} color="text.primary">{fmtDate(qr.expires_at)}</Typography>
                <Typography variant="caption" color="text.secondary">
                    {qr.status === 'expired'
                        ? t('qr.expires.on', { date: fmtDate(qr.expires_at) })
                        : t('qr.expires.daysLeft', { n: qr.days_left })}
                </Typography>
            </Box>
        );
    };

    const RowActions = ({ qr }) => (
        <Stack direction="row" spacing={0.5} justifyContent="center">
            <Tooltip title={t('qr.action.preview')}>
                <IconButton size="small" onClick={() => setPreview(qr)}>
                    <QrIcon fontSize="small" />
                </IconButton>
            </Tooltip>
            {canEdit && (
                <>
                    <Tooltip title={t('qr.action.renew')}>
                        <IconButton size="small" onClick={(e) => setRenewMenu({ anchor: e.currentTarget, qr })}>
                            <RenewIcon fontSize="small" />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={qr.is_active ? t('qr.action.revoke') : t('qr.action.activate')}>
                        <IconButton size="small" onClick={() => toggleActive(qr)}>
                            {qr.is_active ? <RevokeIcon fontSize="small" /> : <ActivateIcon fontSize="small" />}
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t('qr.action.edit')}>
                        <IconButton size="small" onClick={() => { setEditing(qr); setOpenForm(true); }}>
                            <EditIcon fontSize="small" />
                        </IconButton>
                    </Tooltip>
                </>
            )}
            {canDelete && (
                <Tooltip title={t('qr.action.delete')}>
                    <IconButton size="small" onClick={() => askDelete(qr)}
                                sx={{ '&:hover': { color: 'error.main' } }}>
                        <DeleteIcon fontSize="small" />
                    </IconButton>
                </Tooltip>
            )}
        </Stack>
    );

    // ── Guards ──────────────────────────────────────────
    if (!canView) {
        return (
            <Box p={3}>
                <Paper elevation={0} sx={{ p: 4, textAlign: 'center', borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                    <Typography color="error" fontWeight={600}>{t('qr.accessDenied')}</Typography>
                </Paper>
            </Box>
        );
    }

    if (error) {
        return (
            <Box p={3}>
                <Alert
                    severity="error" sx={{ borderRadius: 2 }}
                    action={<Button color="inherit" size="small" onClick={() => { setError(null); load(); }}>
                        {t('qr.common.retry')}
                    </Button>}
                >
                    {error}
                </Alert>
            </Box>
        );
    }

    const empty = rows.length === 0;
    const hasFilter = !!(search || appFilter || statusFilter);

    return (
        <Box sx={{ width: '100%', p: { xs: 1.5, sm: 2.5 }, bgcolor: 'background.default' }}>
            <Paper elevation={0} sx={{
                width: '100%', borderRadius: 3, overflow: 'hidden',
                border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper',
            }}>
                {/* HEADER */}
                <Box sx={{ px: { xs: 2, sm: 3 }, py: 2.5, borderBottom: '1px solid', borderColor: 'divider' }}>
                    <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between"
                           alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} mb={2.5}>
                        <Box>
                            <Typography variant="h5" fontWeight={800} color="text.primary">{t('qr.list.title')}</Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>{t('qr.list.subtitle')}</Typography>
                        </Box>
                        {canCreate && (
                            <Button
                                variant="contained" startIcon={<AddIcon />}
                                onClick={() => { setEditing(null); setOpenForm(true); }}
                                size={isMobile ? 'small' : 'medium'}
                                sx={{
                                    borderRadius: 2, fontWeight: 700, textTransform: 'none', px: 2.5, boxShadow: 'none',
                                    bgcolor: colors.salat || '#10b981',
                                    '&:hover': { bgcolor: colors.dark || '#047857' },
                                }}
                            >
                                {t('qr.list.add')}
                            </Button>
                        )}
                    </Stack>

                    {/* FILTERS */}
                    <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} flexWrap="wrap"
                           alignItems={{ xs: 'stretch', sm: 'center' }}>
                        <TextField
                            placeholder={t('qr.list.search')} size="small" value={search}
                            onChange={(e) => { setSearch(e.target.value); setPage(0); }}
                            InputProps={{
                                startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" color="action" /></InputAdornment>,
                                endAdornment: search ? (
                                    <InputAdornment position="end">
                                        <IconButton size="small" onClick={() => setSearch('')}><ClearIcon fontSize="small" /></IconButton>
                                    </InputAdornment>
                                ) : null,
                            }}
                            sx={{
                                minWidth: { xs: '100%', sm: 260 },
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 2, bgcolor: 'action.hover',
                                    '& fieldset': { borderColor: 'transparent' },
                                },
                            }}
                        />
                        <TextField select size="small" value={appFilter}
                                   onChange={(e) => { setAppFilter(e.target.value); setPage(0); }}
                                   SelectProps={{ displayEmpty: true }}
                                   sx={{ minWidth: 170, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}>
                            <MenuItem value="">{t('qr.list.allApps')}</MenuItem>
                            {apps.map((a) => <MenuItem key={a.id} value={a.id}>{a.name}</MenuItem>)}
                        </TextField>
                        <TextField select size="small" value={statusFilter}
                                   onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
                                   SelectProps={{ displayEmpty: true }}
                                   sx={{ minWidth: 170, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}>
                            <MenuItem value="">{t('qr.list.allStatus')}</MenuItem>
                            {STATUS_FILTERS.map((s) => <MenuItem key={s} value={s}>{t(`qr.status.${s}`)}</MenuItem>)}
                        </TextField>
                        <Button variant="outlined" startIcon={<RefreshIcon />} onClick={load} disabled={loading}
                                size={isMobile ? 'small' : 'medium'}
                                sx={{ borderRadius: 2, fontWeight: 600, textTransform: 'none', borderColor: 'divider', color: 'text.primary' }}>
                            {t('qr.common.refresh')}
                        </Button>
                    </Stack>
                </Box>

                {/* SUMMARY CARDS */}
                <Box sx={{ px: { xs: 2, sm: 3 }, pt: 2.5, pb: 1 }}>
                    <Grid container spacing={2}>
                        {statCards.map((c) => (
                            <Grid item xs={6} sm={4} md key={c.key}>
                                <Card elevation={0} sx={{ borderRadius: 2, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', height: '100%' }}>
                                    <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
                                        <Typography variant="caption" sx={{ color: c.color, fontWeight: 600 }}>
                                            {t(`qr.stat.${c.key}`)}
                                        </Typography>
                                        <Typography variant="h4" sx={{ color: c.color, fontWeight: 700 }}>
                                            {stats[c.key] ?? 0}
                                        </Typography>
                                    </CardContent>
                                </Card>
                            </Grid>
                        ))}
                    </Grid>
                </Box>

                {/* TABLE */}
                {showTableView ? (
                    <TableContainer>
                        <Table sx={{ minWidth: 800 }}>
                            <TableHead>
                                <TableRow sx={{
                                    bgcolor: 'action.hover',
                                    '& th': {
                                        fontWeight: 700, fontSize: '0.8125rem', color: 'text.secondary',
                                        textTransform: 'uppercase', letterSpacing: 0.6,
                                        borderBottom: '1px solid', borderColor: 'divider', py: 1.75,
                                    },
                                }}>
                                    {['app', 'label', 'validity', 'expires', 'status', 'scans', 'actions'].map((k) => (
                                        <TableCell key={k} align={k === 'actions' ? 'center' : 'left'} sx={{ whiteSpace: 'nowrap' }}>
                                            {t(`qr.col.${k}`)}
                                        </TableCell>
                                    ))}
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {loading ? (
                                    <TableRow><TableCell colSpan={7} align="center" sx={{ py: 8 }}>
                                        <CircularProgress size={36} thickness={4} />
                                    </TableCell></TableRow>
                                ) : empty ? (
                                    <TableRow><TableCell colSpan={7} align="center" sx={{ py: 8 }}>
                                        <Typography color="text.secondary" fontWeight={500}>
                                            {hasFilter ? t('qr.list.noMatch') : t('qr.list.noFound')}
                                        </Typography>
                                    </TableCell></TableRow>
                                ) : rows.map((qr) => (
                                    <TableRow key={qr.id} hover sx={{ '&:last-child td': { borderBottom: 0 } }}>
                                        <TableCell>
                                            <Typography variant="body2" fontWeight={600} color="text.primary">{qr.mini_app?.name}</Typography>
                                            <Typography variant="caption" color="text.secondary">{qr.mini_app?.slug}</Typography>
                                        </TableCell>
                                        <TableCell>
                                            <Typography variant="body2" color="text.secondary">{qr.label || '-'}</Typography>
                                        </TableCell>
                                        <TableCell>
                                            <Chip label={t(`qr.validity.${qr.validity}`)} size="small"
                                                  sx={{ fontWeight: 600, bgcolor: 'action.hover', height: 24 }} />
                                        </TableCell>
                                        <TableCell><ExpiryText qr={qr} /></TableCell>
                                        <TableCell><StatusChip qr={qr} /></TableCell>
                                        <TableCell>
                                            <Typography variant="body2" fontWeight={600}>{qr.scans_count}</Typography>
                                        </TableCell>
                                        <TableCell align="center"><RowActions qr={qr} /></TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </TableContainer>
                ) : (
                    /* MOBILE CARDS */
                    <Box sx={{ p: { xs: 2, sm: 2.5 } }}>
                        {loading ? (
                            <Box display="flex" justifyContent="center" py={6}><CircularProgress size={36} thickness={4} /></Box>
                        ) : empty ? (
                            <Paper variant="outlined" sx={{ p: 5, textAlign: 'center', borderRadius: 3, borderStyle: 'dashed' }}>
                                <QrIcon sx={{ fontSize: 56, color: 'text.disabled', mb: 2 }} />
                                <Typography color="text.secondary" fontWeight={500}>
                                    {hasFilter ? t('qr.list.noMatch') : t('qr.list.noFound')}
                                </Typography>
                            </Paper>
                        ) : (
                            <Stack spacing={2}>
                                {rows.map((qr) => (
                                    <Card key={qr.id} elevation={0}
                                          sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}>
                                        <CardContent sx={{ p: 2.5 }}>
                                            <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={1.5}>
                                                <Box>
                                                    <Typography variant="h6" fontWeight={700} color="text.primary">{qr.mini_app?.name}</Typography>
                                                    {qr.label && <Typography variant="body2" color="text.secondary">{qr.label}</Typography>}
                                                </Box>
                                                <StatusChip qr={qr} />
                                            </Stack>
                                            <Stack direction="row" spacing={1} alignItems="center" mb={1.5} flexWrap="wrap">
                                                <Chip label={t(`qr.validity.${qr.validity}`)} size="small"
                                                      sx={{ fontWeight: 600, bgcolor: 'action.hover', height: 24 }} />
                                                <Chip label={`${t('qr.col.scans')}: ${qr.scans_count}`} size="small"
                                                      sx={{ fontWeight: 600, bgcolor: 'action.hover', height: 24 }} />
                                            </Stack>
                                            <ExpiryText qr={qr} />
                                            <Box mt={1.5}><RowActions qr={qr} /></Box>
                                        </CardContent>
                                    </Card>
                                ))}
                            </Stack>
                        )}
                    </Box>
                )}

                {/* PAGINATION */}
                <Box sx={{ borderTop: '1px solid', borderColor: 'divider', bgcolor: 'action.hover' }}>
                    <TablePagination
                        rowsPerPageOptions={[5, 10, 25, 50]} component="div"
                        count={total} rowsPerPage={rowsPerPage} page={page}
                        onPageChange={(e, p) => setPage(p)}
                        onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
                    />
                </Box>
            </Paper>

            {/* RENEW MENU */}
            <Menu anchorEl={renewMenu.anchor} open={!!renewMenu.anchor}
                  onClose={() => setRenewMenu({ anchor: null, qr: null })}>
                {VALIDITIES.map((v) => (
                    <MenuItem key={v} onClick={() => renew(renewMenu.qr, v)}>
                        {t('qr.action.renew')}: {t(`qr.validity.${v}`)}
                    </MenuItem>
                ))}
            </Menu>

            {/* FORM / PREVIEW */}
            <MiniAppQrFormModal
                open={openForm}
                qr={editing}
                onClose={() => { setOpenForm(false); setEditing(null); load(); }}
            />
            <QrPreviewDialog open={!!preview} qr={preview} onClose={() => setPreview(null)} />

            {/* CONFIRM */}
            <Dialog open={confirm.open} onClose={closeConfirm} fullWidth maxWidth="xs"
                    PaperProps={{ sx: { borderRadius: 3, bgcolor: 'background.paper' } }}>
                <DialogTitle sx={{ fontWeight: 700, pb: 1, color: 'text.primary' }}>{confirm.title}</DialogTitle>
                <DialogContent><Typography color="text.secondary">{confirm.message}</Typography></DialogContent>
                <DialogActions sx={{ px: 3, pb: 2.5, pt: 1 }}>
                    <Button onClick={closeConfirm} sx={{ fontWeight: 600, textTransform: 'none' }}>{t('qr.common.cancel')}</Button>
                    <Button onClick={() => confirm.action && confirm.action()} variant="contained" color="error"
                            sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}>
                        {t('qr.common.delete')}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default MiniAppQrList;