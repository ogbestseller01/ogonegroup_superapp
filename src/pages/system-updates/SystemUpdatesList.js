// src/pages/system-updates/SystemUpdatesList.jsx
import React, { useEffect, useState } from 'react';
import {
    Box, Paper, Typography, Button, Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
    TablePagination, TextField, InputAdornment, IconButton, Chip, Menu, MenuItem, Dialog,
    DialogTitle, DialogContent, DialogActions, CircularProgress, useMediaQuery, useTheme, Card,
    CardContent, Divider, Alert, Stack,
} from '@mui/material';
import {
    Add as AddIcon, Search as SearchIcon, Refresh as RefreshIcon, MoreVert as MoreVertIcon,
    Edit as EditIcon, Delete as DeleteIcon, Publish as PublishIcon, Lock as LockIcon,
    BarChart as StatsIcon, Clear as ClearIcon, Campaign as CampaignIcon,
} from '@mui/icons-material';
import { useSystemUpdateManagement } from 'hooks/useSystemUpdate';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import SystemUpdateFormModal from './SystemUpdateFormModal';
import SystemUpdateStatsDialog from './SystemUpdateStatsDialog';
import { tSystemUpdate } from './systemUpdateLang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const statusStyles = {
    draft: { bg: '#f3f4f6', color: '#4b5563', border: '#9ca3af' },
    published: { bg: '#d1fae5', color: '#047857', border: '#10b981' },
    closed: { bg: '#fee2e2', color: '#b91c1c', border: '#ef4444' },
};

const SystemUpdatesList = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));

    const { language } = useLanguage();
    const t = (key, r) => tSystemUpdate(language, key, r);
    const { can } = usePermissions();

    const {
        systemUpdates, pagination, loading, submitting, error,
        getSystemUpdates, deleteSystemUpdate, publishSystemUpdate, closeSystemUpdate, clearError,
    } = useSystemUpdateManagement();

    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(15);

    const [openForm, setOpenForm] = useState(false);
    const [editing, setEditing] = useState(null);
    const [statsFor, setStatsFor] = useState(null);
    const [actionMenu, setActionMenu] = useState(null);
    const [selected, setSelected] = useState(null);

    const [confirmDialog, setConfirmDialog] = useState({
        open: false, title: '', message: '', action: null,
    });

    const canView = can('system-updates.manage');

    // ── Fetch ────────────────────────────────────────────────
    const fetchData = () => {
        if (!canView) return;
        getSystemUpdates({
            page: page + 1,
            per_page: rowsPerPage,
            search: search || undefined,
            status: statusFilter || undefined,
        }).catch(() => {});
    };

    useEffect(() => {
        fetchData();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [page, rowsPerPage, search, statusFilter, canView]);

    const handleRefresh = () => {
        clearError();
        fetchData();
    };

    // ── Menu & Actions ───────────────────────────────────────
    const handleMenuOpen = (event, row) => {
        setSelected(row);
        setActionMenu(event.currentTarget);
    };
    const handleMenuClose = () => setActionMenu(null);

    const openConfirm = (title, message, actionFn) => {
        setConfirmDialog({ open: true, title, message, action: actionFn });
    };

    const handleConfirm = async () => {
        if (!confirmDialog.action) return;
        const action = confirmDialog.action;
        setConfirmDialog((p) => ({ ...p, open: false }));
        try {
            await action();
            showSnackbar({ type: 'success', message: t('su.actionSuccess') });
            handleRefresh();
        } catch {
            showSnackbar({ type: 'error', message: t('su.actionFailed') });
        }
    };

    const handleAction = async (type) => {
        if (!selected) return;
        handleMenuClose();

        if (type === 'edit') {
            setEditing(selected);
            setOpenForm(true);
            return;
        }
        if (type === 'stats') {
            setStatsFor(selected);
            return;
        }
        if (type === 'publish') {
            openConfirm(t('su.confirm.publishTitle'), t('su.confirm.publishMsg'), async () => {
                await publishSystemUpdate(selected.id);
                showSnackbar({ type: 'success', message: t('su.msg.published') });
            });
            return;
        }
        if (type === 'close') {
            openConfirm(t('su.confirm.closeTitle'), t('su.confirm.closeMsg'), async () => {
                await closeSystemUpdate(selected.id);
                showSnackbar({ type: 'success', message: t('su.msg.closed') });
            });
            return;
        }
        if (type === 'delete') {
            openConfirm(t('su.confirm.deleteTitle'), t('su.confirm.deleteMsg'), async () => {
                await deleteSystemUpdate(selected.id);
                showSnackbar({ type: 'success', message: t('su.msg.deleted') });
            });
        }
    };

    // ── Helpers ──────────────────────────────────────────────
    const formatDate = (d) => {
        if (!d) return '—';
        try {
            return new Date(d).toLocaleDateString('en-US', {
                year: 'numeric', month: 'short', day: 'numeric',
            });
        } catch { return '—'; }
    };

    const statusChip = (status) => {
        const s = statusStyles[status] || statusStyles.draft;
        const labelKey = status === 'published' ? 'su.status.published' : status === 'closed' ? 'su.status.closed' : 'su.status.draft';
        return <Chip label={t(labelKey)} size="small" sx={{ bgcolor: s.bg, color: s.color, fontWeight: 700, border: `1.5px solid ${s.border}`, height: 26 }} />;
    };

    const channelChip = (enabled, label, color) =>
        enabled ? <Chip label={label} size="small" sx={{ bgcolor: color.bg, color: color.fg, fontWeight: 700, height: 24, fontSize: 11 }} /> : null;

    // 👇 REACH CELL LOGIC - Now safely maps the Laravel aliases
    const reachCell = (row) => {
        // Laravel returns `received_count`, `viewed_count`, `dismissed_count`
        const received = row.received_count ?? row.received ?? 0;
        const viewed = row.viewed_count ?? row.viewed ?? 0;
        const dismissed = row.dismissed_count ?? row.dismissed ?? 0;

        // If all are 0 (e.g. draft), show a dash
        if (received === 0 && viewed === 0 && dismissed === 0) return '—';

        const parts = [];
        if (received > 0) parts.push(`${received} ${t('su.reach.received')}`);
        if (viewed > 0) parts.push(`${viewed} ${t('su.reach.viewed')}`);
        if (dismissed > 0) parts.push(`${dismissed} ${t('su.reach.dismissed')}`);

        return parts.length ? parts.join(' · ') : '—';
    };

    // ── Guards ───────────────────────────────────────────────
    if (!canView) {
        return (
            <Box p={3}>
                <Paper elevation={0} sx={{ p: 4, textAlign: 'center', borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                    <Typography color="error" fontWeight={600}>{t('su.accessDenied')}</Typography>
                </Paper>
            </Box>
        );
    }

    const data = Array.isArray(systemUpdates) ? systemUpdates : [];
    const totalCount = pagination?.total ?? data.length;

    return (
        <Box sx={{ width: '100%', p: { xs: 1.5, sm: 2.5 }, m: 0, bgcolor: 'background.default' }}>
            <Paper elevation={0} sx={{ width: '100%', borderRadius: 3, overflow: 'hidden', border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}>

                {/* Header */}
                <Box sx={{ px: { xs: 2, sm: 3 }, py: 2.5, borderBottom: '1px solid', borderColor: 'divider' }}>
                    <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} mb={2.5}>
                        <Box>
                            <Stack direction="row" spacing={1.25} alignItems="center">
                                <CampaignIcon sx={{ color: colors.sea || '#0f766e' }} />
                                <Typography variant="h5" fontWeight={800} color="text.primary">{t('su.title')}</Typography>
                            </Stack>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>{t('su.subtitle')}</Typography>
                        </Box>
                        {can('system-updates.manage') && (
                            <Button variant="contained" startIcon={<AddIcon />} onClick={() => { setEditing(null); setOpenForm(true); }}
                                    size={isMobile ? 'small' : 'medium'}
                                    sx={{ borderRadius: 2, fontWeight: 700, textTransform: 'none', px: 2.5, boxShadow: 'none', bgcolor: colors.salat || '#10b981', '&:hover': { bgcolor: colors.dark || '#047857' } }}>
                                {t('su.add')}
                            </Button>
                        )}
                    </Stack>

                    {/* Filters */}
                    <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap">
                        <TextField placeholder={t('su.searchPlaceholder')} size="small" value={search}
                                   onChange={(e) => { setSearch(e.target.value); setPage(0); }}
                                   InputProps={{
                                       startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" color="action" /></InputAdornment>,
                                       endAdornment: search ? <InputAdornment position="end"><IconButton size="small" onClick={() => setSearch('')}><ClearIcon fontSize="small" /></IconButton></InputAdornment> : null,
                                   }}
                                   sx={{ minWidth: { xs: '100%', sm: 280 }, flexGrow: { xs: 1, sm: 0 }, '& .MuiOutlinedInput-root': { borderRadius: 2, bgcolor: 'action.hover', '& fieldset': { borderColor: 'transparent' }, '&:hover fieldset': { borderColor: 'divider' }, '&.Mui-focused fieldset': { borderColor: 'primary.main' } } }}
                        />
                        <TextField select label={t('su.filter.status')} size="small" value={statusFilter}
                                   onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
                                   sx={{ minWidth: { xs: '100%', sm: 160 }, '& .MuiOutlinedInput-root': { borderRadius: 2, bgcolor: 'action.hover', '& fieldset': { borderColor: 'transparent' }, '&:hover fieldset': { borderColor: 'divider' } } }}>
                            <MenuItem value="">{t('su.filter.allStatuses')}</MenuItem>
                            <MenuItem value="draft">{t('su.status.draft')}</MenuItem>
                            <MenuItem value="published">{t('su.status.published')}</MenuItem>
                            <MenuItem value="closed">{t('su.status.closed')}</MenuItem>
                        </TextField>
                        <Button variant="outlined" startIcon={<RefreshIcon />} onClick={handleRefresh} size={isMobile ? 'small' : 'medium'}
                                sx={{ borderRadius: 2, fontWeight: 600, textTransform: 'none', borderColor: 'divider', color: 'text.primary', '&:hover': { borderColor: 'text.primary', bgcolor: 'action.hover' } }}>
                            {t('su.refresh')}
                        </Button>
                    </Stack>
                </Box>

                {/* Error Alert */}
                {error && (
                    <Box px={3} pt={2}>
                        <Alert severity="error" variant="filled" sx={{ borderRadius: 2 }}
                               action={<Button color="inherit" size="small" onClick={handleRefresh}>{t('su.retry')}</Button>}>
                            {error}
                        </Alert>
                    </Box>
                )}

                {/* Table */}
                {showTableView ? (
                    <TableContainer>
                        <Table sx={{ minWidth: 900 }}>
                            <TableHead>
                                <TableRow sx={{ bgcolor: 'action.hover', '& th': { fontWeight: 700, fontSize: '0.8125rem', color: 'text.secondary', textTransform: 'uppercase', letterSpacing: 0.6, borderBottom: '1px solid', borderColor: 'divider', py: 1.75 } }}>
                                    <TableCell>{t('su.col.title')}</TableCell>
                                    <TableCell>{t('su.col.status')}</TableCell>
                                    <TableCell>{t('su.col.channels')}</TableCell>
                                    <TableCell>{t('su.col.reach')}</TableCell>
                                    <TableCell>{t('su.col.published')}</TableCell>
                                    <TableCell>{t('su.col.created')}</TableCell>
                                    <TableCell align="center">{t('su.col.actions')}</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {loading ? (
                                    <TableRow><TableCell colSpan={7} align="center" sx={{ py: 8 }}><CircularProgress size={36} thickness={4} /></TableCell></TableRow>
                                ) : data.length === 0 && !error ? (
                                    <TableRow><TableCell colSpan={7} align="center" sx={{ py: 8 }}><Typography color="text.secondary" fontWeight={500}>{t('su.noFound')}</Typography></TableCell></TableRow>
                                ) : (
                                    data.map((row) => (
                                        <TableRow key={row.id} hover>
                                            <TableCell sx={{ maxWidth: 280 }}>
                                                <Typography variant="body2" fontWeight={700} color="text.primary" noWrap>{row.title}</Typography>
                                                <Typography variant="caption" color="text.secondary" sx={{ display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{row.description}</Typography>
                                            </TableCell>
                                            <TableCell>{statusChip(row.status)}</TableCell>
                                            <TableCell>
                                                <Stack direction="row" spacing={0.75}>
                                                    {channelChip(row.send_push, 'Push', { bg: '#e0f2fe', fg: '#075985' })}
                                                </Stack>
                                            </TableCell>
                                            <TableCell><Typography variant="body2" color="text.secondary" fontWeight={500}>{reachCell(row)}</Typography></TableCell>
                                            <TableCell><Typography variant="body2" color="text.secondary" fontWeight={500}>{formatDate(row.published_at)}</Typography></TableCell>
                                            <TableCell><Typography variant="body2" color="text.secondary" fontWeight={500}>{formatDate(row.created_at)}</Typography></TableCell>
                                            <TableCell align="center"><IconButton size="small" onClick={(e) => handleMenuOpen(e, row)}><MoreVertIcon /></IconButton></TableCell>
                                        </TableRow>
                                    ))
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                ) : (
                    /* Mobile view */
                    <Box sx={{ p: { xs: 2, sm: 2.5 } }}>
                        {loading ? (
                            <Box display="flex" justifyContent="center" py={6}><CircularProgress size={36} thickness={4} /></Box>
                        ) : data.length === 0 && !error ? (
                            <Paper variant="outlined" sx={{ p: 5, textAlign: 'center', borderRadius: 3, borderStyle: 'dashed' }}><Typography color="text.secondary" fontWeight={500}>{t('su.noFound')}</Typography></Paper>
                        ) : (
                            <Stack spacing={2}>
                                {data.map((row) => (
                                    <Card key={row.id} elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                                        <CardContent sx={{ p: 2.25 }}>
                                            <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={1.25}>
                                                <Typography variant="body1" fontWeight={700} sx={{ flex: 1, pr: 1 }}>{row.title}</Typography>
                                                <IconButton size="small" onClick={(e) => handleMenuOpen(e, row)}><MoreVertIcon fontSize="small" /></IconButton>
                                            </Stack>
                                            <Typography variant="caption" color="text.secondary" sx={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{row.description}</Typography>
                                            <Divider sx={{ my: 1.25 }} />
                                            <Stack direction="row" spacing={1} flexWrap="wrap" gap={0.75}>
                                                {statusChip(row.status)}
                                                {channelChip(row.send_push, 'Push', { bg: '#e0f2fe', fg: '#075985' })}
                                            </Stack>
                                            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1.25 }}>
                                                {t('su.col.reach')}: {reachCell(row)}
                                            </Typography>
                                        </CardContent>
                                    </Card>
                                ))}
                            </Stack>
                        )}
                    </Box>
                )}

                <Box sx={{ borderTop: '1px solid', borderColor: 'divider', bgcolor: 'action.hover' }}>
                    <TablePagination rowsPerPageOptions={[10, 15, 25, 50]} component="div" count={totalCount} rowsPerPage={rowsPerPage} page={page}
                                     onPageChange={(e, p) => setPage(p)} onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }} />
                </Box>
            </Paper>

            {/* Action Menu */}
            <Menu anchorEl={actionMenu} open={Boolean(actionMenu)} onClose={handleMenuClose} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} transformOrigin={{ vertical: 'top', horizontal: 'right' }} PaperProps={{ elevation: 8, sx: { borderRadius: 2, minWidth: 200 } }}>
                {selected?.status === 'draft' && <MenuItem onClick={() => handleAction('edit')}><EditIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('su.action.edit')}</MenuItem>}
                {selected?.status !== 'draft' && selected?.status !== 'closed' && <MenuItem onClick={() => handleAction('edit')}><EditIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('su.action.edit')}</MenuItem>}
                {selected?.status === 'draft' && <MenuItem onClick={() => handleAction('publish')}><PublishIcon sx={{ mr: 1.5, color: '#10b981', fontSize: 20 }} /> {t('su.action.publish')}</MenuItem>}
                {selected?.status === 'published' && <MenuItem onClick={() => handleAction('close')}><LockIcon sx={{ mr: 1.5, color: '#f59e0b', fontSize: 20 }} /> {t('su.action.close')}</MenuItem>}
                {selected?.status === 'published' && <MenuItem onClick={() => handleAction('stats')}><StatsIcon sx={{ mr: 1.5, color: '#0ea5e9', fontSize: 20 }} /> {t('su.action.viewStats')}</MenuItem>}
                <MenuItem onClick={() => handleAction('delete')} sx={{ color: 'error.main' }}><DeleteIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('su.action.delete')}</MenuItem>
            </Menu>

            {/* Modals */}
            <SystemUpdateFormModal open={openForm} onClose={(changed) => { setOpenForm(false); setEditing(null); if (changed) handleRefresh(); }} systemUpdate={editing} />
            <SystemUpdateStatsDialog open={!!statsFor} onClose={() => setStatsFor(null)} systemUpdate={statsFor} />

            {/* Confirm Dialog */}
            <Dialog open={confirmDialog.open} onClose={() => setConfirmDialog((p) => ({ ...p, open: false }))} fullWidth maxWidth="xs" PaperProps={{ sx: { borderRadius: 3 } }}>
                <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>{confirmDialog.title}</DialogTitle>
                <DialogContent><Typography color="text.secondary">{confirmDialog.message}</Typography></DialogContent>
                <DialogActions sx={{ px: 3, pb: 2.5, pt: 1 }}>
                    <Button onClick={() => setConfirmDialog((p) => ({ ...p, open: false }))} sx={{ fontWeight: 600, textTransform: 'none' }}>{t('su.cancel')}</Button>
                    <Button onClick={handleConfirm} variant="contained" color="error" disabled={submitting} sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}>{t('su.confirm')}</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default SystemUpdatesList;