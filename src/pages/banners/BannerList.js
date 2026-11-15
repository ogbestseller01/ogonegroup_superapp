import React, { useState, useEffect, useCallback } from 'react';
import {
    Box, Paper, Typography, Button, TextField, InputAdornment, IconButton,
    MenuItem, Dialog, DialogTitle, DialogContent, DialogActions,
    Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination,
    CircularProgress, Alert, Chip, Stack, Card, CardContent, Tooltip,
    useMediaQuery, useTheme,
} from '@mui/material';
import {
    Add as AddIcon, Search as SearchIcon, Refresh as RefreshIcon,
    Edit as EditIcon, Delete as DeleteIcon, Clear as ClearIcon,
    Image as ImageIcon, Visibility as ActiveIcon, VisibilityOff as DraftIcon,
} from '@mui/icons-material';
import { bannerService } from 'services/banner.service';
import { useBannerManagement } from 'hooks/useBanner';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tBanner } from './bannerLang';
import { BANNER_TYPES, STATUS_COLORS, displayStatus, fmtDate } from './bannerHelpers';
import BannerFormModal from './BannerFormModal';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const BannerList = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));

    const { language } = useLanguage();
    const t = (key, r) => tBanner(language, key, r);

    const { can } = usePermissions();
    // Change these permission names if you already have different ones
    const canView   = can('banners.view')   || can('dashboard.view');
    const canCreate = can('banners.create') || can('dashboard.view');
    const canEdit   = can('banners.update') || can('dashboard.view');
    const canDelete = can('banners.delete') || can('dashboard.view');

    const { updateStatus, deleteBanner } = useBannerManagement();

    const [rows, setRows] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const [search, setSearch] = useState('');
    const [typeFilter, setTypeFilter] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [total, setTotal] = useState(0);

    const [openForm, setOpenForm] = useState(false);
    const [editing, setEditing] = useState(null);
    const [confirm, setConfirm] = useState({ open: false, title: '', message: '', action: null });

    const load = useCallback(async () => {
        if (!canView) return;
        setLoading(true);
        setError(null);
        try {
            const res = await bannerService.getBanners({
                page: page + 1,
                per_page: rowsPerPage,
                search: search || undefined,
                type: typeFilter || undefined,
                status: statusFilter || undefined,
            });

            const body = res?.data;
            if (body?.status === 'success' || body?.success === true) {
                setRows(body.data?.data || []);
                setTotal(body.data?.pagination?.total || body.data?.total || 0);
            } else {
                setRows([]);
                setTotal(0);
            }
        } catch (err) {
            setError(err.response?.data?.message || err.message || t('banner.list.loadFailed'));
        } finally {
            setLoading(false);
        }
    }, [canView, page, rowsPerPage, search, typeFilter, statusFilter, language]);

    useEffect(() => {
        const id = setTimeout(load, 250);
        return () => clearTimeout(id);
    }, [load]);

    const run = async (fn, okKey) => {
        try {
            await fn();
            showSnackbar({ type: 'success', message: t(okKey) });
            load();
        } catch (err) {
            showSnackbar({ type: 'error', message: err.response?.data?.message || t('banner.form.failed') });
        }
    };

    const toggleStatus = (banner) => {
        const next = banner.status === 'active' ? 'draft' : 'active';
        run(() => updateStatus(banner.id, next), 'banner.status.updated');
    };

    const askDelete = (banner) => {
        setConfirm({
            open: true,
            title: t('banner.delete.title'),
            message: t('banner.delete.message'),
            action: async () => {
                setConfirm((c) => ({ ...c, open: false }));
                await run(() => deleteBanner(banner.id), 'banner.delete.success');
            },
        });
    };

    const StatusChip = ({ banner }) => {
        const s = displayStatus(banner);
        const c = STATUS_COLORS[s] || STATUS_COLORS.active;
        return (
            <Chip
                label={t(`banner.status.${s}`)}
                size="small"
                sx={{ fontWeight: 700, bgcolor: c.bg, color: c.fg, height: 24 }}
            />
        );
    };

    const RowActions = ({ banner }) => (
        <Stack direction="row" spacing={0.5} justifyContent="center">
            {canEdit && (
                <>
                    <Tooltip title={banner.status === 'active' ? t('banner.action.setDraft') : t('banner.action.setActive')}>
                        <IconButton size="small" onClick={() => toggleStatus(banner)}>
                            {banner.status === 'active' ? <DraftIcon fontSize="small" /> : <ActiveIcon fontSize="small" />}
                        </IconButton>
                    </Tooltip>
                    <Tooltip title={t('banner.action.edit')}>
                        <IconButton size="small" onClick={() => { setEditing(banner); setOpenForm(true); }}>
                            <EditIcon fontSize="small" />
                        </IconButton>
                    </Tooltip>
                </>
            )}
            {canDelete && (
                <Tooltip title={t('banner.action.delete')}>
                    <IconButton size="small" onClick={() => askDelete(banner)} sx={{ '&:hover': { color: 'error.main' } }}>
                        <DeleteIcon fontSize="small" />
                    </IconButton>
                </Tooltip>
            )}
        </Stack>
    );

    if (!canView) {
        return (
            <Box p={3}>
                <Paper elevation={0} sx={{ p: 4, textAlign: 'center', borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                    <Typography color="error" fontWeight={600}>{t('banner.accessDenied')}</Typography>
                </Paper>
            </Box>
        );
    }

    if (error) {
        return (
            <Box p={3}>
                <Alert severity="error" sx={{ borderRadius: 2 }}
                       action={<Button color="inherit" size="small" onClick={() => { setError(null); load(); }}>{t('banner.common.retry')}</Button>}>
                    {error}
                </Alert>
            </Box>
        );
    }

    const empty = rows.length === 0;
    const hasFilter = !!(search || typeFilter || statusFilter);

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
                            <Typography variant="h5" fontWeight={800}>{t('banner.list.title')}</Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('banner.list.subtitle')}
                            </Typography>
                        </Box>
                        {canCreate && (
                            <Button
                                variant="contained"
                                startIcon={<AddIcon />}
                                onClick={() => { setEditing(null); setOpenForm(true); }}
                                size={isMobile ? 'small' : 'medium'}
                                sx={{
                                    borderRadius: 2, fontWeight: 700, textTransform: 'none', px: 2.5, boxShadow: 'none',
                                    bgcolor: colors.salat || '#10b981',
                                    '&:hover': { bgcolor: colors.dark || '#047857' },
                                }}
                            >
                                {t('banner.list.add')}
                            </Button>
                        )}
                    </Stack>

                    {/* FILTERS */}
                    <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} flexWrap="wrap"
                           alignItems={{ xs: 'stretch', sm: 'center' }}>
                        <TextField
                            placeholder={t('banner.list.search')}
                            size="small"
                            value={search}
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
                                minWidth: { xs: '100%', sm: 240 },
                                '& .MuiOutlinedInput-root': { borderRadius: 2, bgcolor: 'action.hover', '& fieldset': { borderColor: 'transparent' } },
                            }}
                        />
                        <TextField select size="small" value={typeFilter}
                                   onChange={(e) => { setTypeFilter(e.target.value); setPage(0); }}
                                   SelectProps={{ displayEmpty: true }}
                                   sx={{ minWidth: 150, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}>
                            <MenuItem value="">{t('banner.list.allTypes')}</MenuItem>
                            {BANNER_TYPES.map((tp) => <MenuItem key={tp} value={tp}>{t(`banner.type.${tp}`)}</MenuItem>)}
                        </TextField>
                        <TextField select size="small" value={statusFilter}
                                   onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
                                   SelectProps={{ displayEmpty: true }}
                                   sx={{ minWidth: 150, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}>
                            <MenuItem value="">{t('banner.list.allStatus')}</MenuItem>
                            <MenuItem value="active">{t('banner.status.active')}</MenuItem>
                            <MenuItem value="draft">{t('banner.status.draft')}</MenuItem>
                        </TextField>
                        <Button variant="outlined" startIcon={<RefreshIcon />} onClick={load} disabled={loading}
                                size={isMobile ? 'small' : 'medium'}
                                sx={{ borderRadius: 2, fontWeight: 600, textTransform: 'none', borderColor: 'divider' }}>
                            {t('banner.common.refresh')}
                        </Button>
                    </Stack>
                </Box>

                {/* TABLE / CARDS */}
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
                                    {['image', 'title', 'type', 'status', 'expires', 'order', 'actions'].map((k) => (
                                        <TableCell key={k} align={k === 'actions' ? 'center' : 'left'}>
                                            {t(`banner.col.${k}`)}
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
                                            {hasFilter ? t('banner.list.noMatch') : t('banner.list.noFound')}
                                        </Typography>
                                    </TableCell></TableRow>
                                ) : rows.map((b) => (
                                    <TableRow key={b.id} hover>
                                        <TableCell>
                                            {b.image ? (
                                                <Box component="img" src={b.image} alt=""
                                                     sx={{ width: 72, height: 40, objectFit: 'cover', borderRadius: 1, border: '1px solid', borderColor: 'divider' }} />
                                            ) : (
                                                <ImageIcon color="disabled" />
                                            )}
                                        </TableCell>
                                        <TableCell>
                                            <Typography variant="body2" fontWeight={600}>{b.title || '-'}</Typography>
                                            {b.link && (
                                                <Typography variant="caption" color="text.secondary" sx={{ wordBreak: 'break-all' }}>
                                                    {b.link}
                                                </Typography>
                                            )}
                                        </TableCell>
                                        <TableCell>
                                            <Chip label={t(`banner.type.${b.type}`)} size="small"
                                                  sx={{ fontWeight: 600, bgcolor: 'action.hover', height: 24 }} />
                                        </TableCell>
                                        <TableCell><StatusChip banner={b} /></TableCell>
                                        <TableCell>
                                            <Typography variant="body2">{fmtDate(b.expires_at)}</Typography>
                                        </TableCell>
                                        <TableCell>{b.sort_order}</TableCell>
                                        <TableCell align="center"><RowActions banner={b} /></TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </TableContainer>
                ) : (
                    /* Mobile cards */
                    <Box sx={{ p: 2 }}>
                        {loading ? (
                            <Box display="flex" justifyContent="center" py={6}><CircularProgress size={36} /></Box>
                        ) : empty ? (
                            <Paper variant="outlined" sx={{ p: 5, textAlign: 'center', borderRadius: 3, borderStyle: 'dashed' }}>
                                <ImageIcon sx={{ fontSize: 56, color: 'text.disabled', mb: 2 }} />
                                <Typography color="text.secondary">
                                    {hasFilter ? t('banner.list.noMatch') : t('banner.list.noFound')}
                                </Typography>
                            </Paper>
                        ) : (
                            <Stack spacing={2}>
                                {rows.map((b) => (
                                    <Card key={b.id} elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                                        <CardContent sx={{ p: 2 }}>
                                            <Stack direction="row" spacing={2} alignItems="flex-start">
                                                {b.image && (
                                                    <Box component="img" src={b.image} alt=""
                                                         sx={{ width: 80, height: 48, objectFit: 'cover', borderRadius: 1 }} />
                                                )}
                                                <Box flex={1}>
                                                    <Stack direction="row" justifyContent="space-between" mb={0.5}>
                                                        <Typography fontWeight={700}>{b.title || '-'}</Typography>
                                                        <StatusChip banner={b} />
                                                    </Stack>
                                                    <Chip label={t(`banner.type.${b.type}`)} size="small" sx={{ mb: 0.5, height: 22 }} />
                                                    <Typography variant="caption" color="text.secondary" display="block">
                                                        {t('banner.col.expires')}: {fmtDate(b.expires_at)}
                                                    </Typography>
                                                    <Box mt={1}><RowActions banner={b} /></Box>
                                                </Box>
                                            </Stack>
                                        </CardContent>
                                    </Card>
                                ))}
                            </Stack>
                        )}
                    </Box>
                )}

                <Box sx={{ borderTop: '1px solid', borderColor: 'divider', bgcolor: 'action.hover' }}>
                    <TablePagination
                        rowsPerPageOptions={[5, 10, 25, 50]}
                        component="div"
                        count={total}
                        rowsPerPage={rowsPerPage}
                        page={page}
                        onPageChange={(e, p) => setPage(p)}
                        onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
                    />
                </Box>
            </Paper>

            <BannerFormModal
                open={openForm}
                banner={editing}
                onClose={(refresh) => {
                    setOpenForm(false);
                    setEditing(null);
                    if (refresh) load();
                }}
            />

            <Dialog open={confirm.open} onClose={() => setConfirm((c) => ({ ...c, open: false }))} maxWidth="xs" fullWidth
                    PaperProps={{ sx: { borderRadius: 3 } }}>
                <DialogTitle sx={{ fontWeight: 700 }}>{confirm.title}</DialogTitle>
                <DialogContent><Typography color="text.secondary">{confirm.message}</Typography></DialogContent>
                <DialogActions sx={{ px: 3, pb: 2.5 }}>
                    <Button onClick={() => setConfirm((c) => ({ ...c, open: false }))} sx={{ fontWeight: 600, textTransform: 'none' }}>
                        {t('banner.common.cancel')}
                    </Button>
                    <Button onClick={() => confirm.action && confirm.action()} variant="contained" color="error"
                            sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}>
                        {t('banner.common.delete')}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default BannerList;