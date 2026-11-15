// src/pages/portfolios/PortfoliosList.js
import React, { useState, useEffect, useMemo } from 'react';
import {
    Box, Paper, Typography, Button, Table, TableBody, TableCell, TableContainer,
    TableHead, TableRow, TablePagination, TableSortLabel, TextField,
    InputAdornment, IconButton, Chip, Menu, MenuItem, Dialog, DialogTitle,
    DialogContent, DialogActions, CircularProgress, useMediaQuery, useTheme,
    Card, CardContent, Divider, Avatar, Stack, DialogContentText,
} from '@mui/material';
import {
    Search as SearchIcon, Refresh as RefreshIcon, MoreVert as MoreVertIcon,
    Delete as DeleteIcon, Visibility as ViewIcon, Person as PersonIcon,
    Verified as VerifiedIcon, LocationOn as LocationIcon, Star as StarIcon,
    Image as ImageIcon, CalendarToday as CalendarIcon, Clear as ClearIcon,
    PhotoCamera as PhotoCameraIcon, Collections as CollectionsIcon,
    Add as AddIcon, ChevronLeft as ChevronLeftIcon, ChevronRight as ChevronRightIcon,
} from '@mui/icons-material';
import { portfolioService } from 'services/portfolio.service';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tPortfolio } from './portfolioslang';
import { format } from 'date-fns';
import appConfig from '../../config';

const colors = appConfig.app.colors;
const SEA = colors.sea || '#0f766e';

/** CSS-grid helper (does not depend on the MUI Grid version). */
const gridSx = (columns, gap = 2) => ({
    display: 'grid',
    gap,
    gridTemplateColumns: columns,
});

/** Square thumbnail with error fallback and optional "+N" badge. */
const Thumb = ({ src, size = 52, onClick, extra = 0, fill = false, height }) => {
    const [failed, setFailed] = useState(false);
    useEffect(() => { setFailed(false); }, [src]);

    return (
        <Box
            onClick={onClick}
            sx={{
                width: fill ? '100%' : size,
                height: height || size,
                borderRadius: 1.5,
                overflow: 'hidden',
                flexShrink: 0,
                bgcolor: 'action.hover',
                border: '1px solid',
                borderColor: 'divider',
                position: 'relative',
                cursor: onClick ? 'pointer' : 'default',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
            }}
        >
            {failed || !src ? (
                <PhotoCameraIcon sx={{ color: 'text.disabled', fontSize: 26 }} />
            ) : (
                <img
                    src={src}
                    alt=""
                    onError={() => setFailed(true)}
                    style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
                />
            )}
            {extra > 0 && (
                <Box
                    sx={{
                        position: 'absolute',
                        right: 4,
                        bottom: 4,
                        display: 'flex',
                        alignItems: 'center',
                        bgcolor: 'rgba(0,0,0,0.72)',
                        color: '#fff',
                        borderRadius: 10,
                        px: 0.6,
                        py: 0.1,
                        fontSize: 11,
                        fontWeight: 700,
                        lineHeight: 1.4,
                    }}
                >
                    <AddIcon sx={{ fontSize: 12 }} />
                    {extra}
                </Box>
            )}
        </Box>
    );
};

const PortfoliosList = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));

    const { language } = useLanguage();
    const t = (key, replacements) => tPortfolio(language, key, replacements);
    /** translate, but use `fallback` when the key has no translation (translator returns the key). */
    const tr = (key, fallback, replacements) => {
        const v = t(key, replacements);
        return !v || v === key ? fallback : v;
    };

    const headCells = useMemo(
        () => [
            { id: 'portfolio', label: tr('portfolio.table.col.portfolio', 'Portfolio'), disableSort: true },
            { id: 'technician', label: tr('portfolio.table.col.technician', 'Technician'), disableSort: true },
            { id: 'images', label: tr('portfolio.table.col.images', 'Images'), disableSort: true },
            { id: 'created_at', label: tr('portfolio.table.col.created', 'Created') },
            { id: 'actions', label: tr('portfolio.table.col.actions', 'Actions'), disableSort: true },
        ],
        // eslint-disable-next-line react-hooks/exhaustive-deps
        [language]
    );

    const { can } = usePermissions();
    const canView = can('portfolios.view');
    const canDelete = can('portfolios.delete');

    const [portfolios, setPortfolios] = useState([]);
    const [loading, setLoading] = useState(false);
    const [pagination, setPagination] = useState({ total: 0, per_page: 10, current_page: 1, last_page: 1 });

    const [search, setSearch] = useState('');
    const [debouncedSearch, setDebouncedSearch] = useState('');
    const [technicianFilter, setTechnicianFilter] = useState('all');
    const [technicians, setTechnicians] = useState([]);
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [order, setOrder] = useState('desc');
    const [orderBy, setOrderBy] = useState('created_at');

    const [selectedPortfolio, setSelectedPortfolio] = useState(null);
    const [openViewDialog, setOpenViewDialog] = useState(false);
    const [actionMenu, setActionMenu] = useState(null);
    const [selectedPortfolioForMenu, setSelectedPortfolioForMenu] = useState(null);
    const [lightboxIndex, setLightboxIndex] = useState(null);

    const [confirmDialog, setConfirmDialog] = useState({
        open: false, title: '', message: '', action: null,
    });

    // ---- helpers ----
    const getTechnicianName = (tech) =>
        tech?.name || tech?.user?.name || t('portfolio.common.unknown');

    const getInitials = (name) => {
        if (!name) return '?';
        return name.split(' ').map((word) => word[0]).join('').toUpperCase().substring(0, 2);
    };

    const formatDate = (dateStr) => {
        if (!dateStr) return '-';
        try { return format(new Date(dateStr), 'MMM d, yyyy'); } catch { return '-'; }
    };

    const formatDateFull = (dateStr) => {
        if (!dateStr) return '-';
        try { return format(new Date(dateStr), 'MMM d, yyyy h:mm a'); } catch { return '-'; }
    };

    const imagesOf = (p) => (Array.isArray(p?.images) ? p.images : []);

    // ---- data loading ----
    useEffect(() => {
        const timer = setTimeout(() => {
            setDebouncedSearch(search.trim());
            setPage(0);
        }, 400);
        return () => clearTimeout(timer);
    }, [search]);

    useEffect(() => {
        let active = true;
        const loadTechnicians = async () => {
            try {
                const response = await portfolioService.getTechnicians?.({ per_page: 100, status: 'active' });
                if (!active || response?.data?.status !== 'success') return;
                const data = response.data.data;
                if (data?.data) setTechnicians(data.data);
                else if (Array.isArray(data)) setTechnicians(data);
            } catch (err) {
                console.error('Error loading technicians:', err);
            }
        };
        loadTechnicians();
        return () => { active = false; };
    }, []);

    const loadPortfolios = async () => {
        if (!canView) return;
        setLoading(true);
        try {
            const params = { page: page + 1, per_page: rowsPerPage };
            if (technicianFilter !== 'all') params.technician_id = technicianFilter;
            if (debouncedSearch) params.search = debouncedSearch;

            const response = await portfolioService.getPortfolios(params);

            if (response?.data?.status === 'success') {
                const payload = response.data.data;
                let list = [];
                let pag = { total: 0, per_page: rowsPerPage, current_page: 1, last_page: 1 };

                if (payload && Array.isArray(payload.data)) {
                    list = payload.data;
                    const src = payload.pagination || payload;
                    pag = {
                        total: src.total ?? list.length,
                        per_page: src.per_page ?? rowsPerPage,
                        current_page: src.current_page ?? 1,
                        last_page: src.last_page ?? 1,
                    };
                } else if (Array.isArray(payload)) {
                    list = payload;
                    pag = { total: list.length, per_page: rowsPerPage, current_page: 1, last_page: 1 };
                }

                setPortfolios(list);
                setPagination(pag);
            } else {
                setPortfolios([]);
            }
        } catch (err) {
            console.error('Portfolios error:', err);
            showSnackbar({ type: 'error', message: err.message || t('portfolio.toast.loadFailed') });
            setPortfolios([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (canView) loadPortfolios();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [page, rowsPerPage, debouncedSearch, technicianFilter, canView]);

    const refreshAll = () => { loadPortfolios(); };

    // ---- sorting + running number (1, 2, 3 ... instead of database id) ----
    const handleRequestSort = (property) => {
        const isAsc = orderBy === property && order === 'asc';
        setOrder(isAsc ? 'desc' : 'asc');
        setOrderBy(property);
    };

    const numberedPortfolios = useMemo(() => {
        const sorted = [...portfolios];
        sorted.sort((a, b) => {
            let aValue = a[orderBy] || '';
            let bValue = b[orderBy] || '';
            if (typeof aValue === 'string') {
                aValue = aValue.toLowerCase();
                bValue = String(bValue).toLowerCase();
            }
            if (aValue < bValue) return order === 'asc' ? -1 : 1;
            if (aValue > bValue) return order === 'asc' ? 1 : -1;
            return 0;
        });
        const offset = page * rowsPerPage;
        return sorted.map((p, i) => ({ ...p, _no: offset + i + 1 }));
    }, [portfolios, orderBy, order, page, rowsPerPage]);

    // ---- actions ----
    const handleViewPortfolio = (portfolio) => {
        setSelectedPortfolio(portfolio);
        setOpenViewDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenViewDialog(false);
        setSelectedPortfolio(null);
        setLightboxIndex(null);
    };

    const handleDeletePortfolio = async (id) => {
        try {
            if (portfolioService.deletePortfolioAdmin) {
                await portfolioService.deletePortfolioAdmin(id);
            } else {
                await portfolioService.deletePortfolio(id);
            }
            showSnackbar({ type: 'success', message: t('portfolio.toast.deleteSuccess') });
            await loadPortfolios();
            return true;
        } catch (err) {
            console.error('Delete error:', err);
            const errorMessage = err.response?.data?.message || t('portfolio.toast.deleteFailed');
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
        setConfirmDialog((prev) => ({ ...prev, open: false }));
        try { await action(); } catch (err) { console.error('Confirm action failed:', err); }
    };

    const handleMenuOpen = (event, portfolio) => {
        setSelectedPortfolioForMenu(portfolio);
        setActionMenu(event.currentTarget);
    };

    const handleMenuClose = () => {
        setActionMenu(null);
        setSelectedPortfolioForMenu(null);
    };

    const handleAction = (actionType) => {
        const target = selectedPortfolioForMenu;
        if (!target) return;
        handleMenuClose();
        if (actionType === 'view') {
            handleViewPortfolio(target);
        } else if (actionType === 'delete') {
            openConfirmDialog(
                t('portfolio.delete.title'),
                t('portfolio.delete.message'),
                () => handleDeletePortfolio(target.id) // real id is still used for the API call
            );
        }
    };

    // ---- stats (current page) ----
    const totalPortfolios = pagination.total || 0;
    const uniqueTechnicians = new Set(portfolios.map((p) => p.technician?.id).filter(Boolean)).size;

    const fieldSx = {
        '& .MuiOutlinedInput-root': {
            borderRadius: 2,
            bgcolor: 'action.hover',
            '& fieldset': { borderColor: 'transparent' },
            '&:hover fieldset': { borderColor: 'divider' },
            '&.Mui-focused fieldset': { borderColor: 'primary.main' },
        },
    };

    const itemLabel = (no) => `${tr('portfolio.table.itemPrefix', 'Portfolio')} #${no}`;

    // lightbox helpers
    const dialogImages = imagesOf(selectedPortfolio);
    const lightboxImage = lightboxIndex !== null ? dialogImages[lightboxIndex] : null;
    const stepLightbox = (dir) => {
        if (!dialogImages.length) return;
        setLightboxIndex((i) => (i + dir + dialogImages.length) % dialogImages.length);
    };

    if (!canView) {
        return (
            <Box p={3}>
                <Paper
                    elevation={0}
                    sx={{ p: 4, textAlign: 'center', borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}
                >
                    <Typography color="error" fontWeight={600}>{t('portfolio.accessDenied')}</Typography>
                </Paper>
            </Box>
        );
    }

    return (
        <Box sx={{ width: '100%', p: { xs: 1.5, sm: 2.5 }, m: 0, bgcolor: 'background.default' }}>
            <Paper
                elevation={0}
                sx={{ width: '100%', borderRadius: 3, overflow: 'hidden', border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}
            >
                {/* HEADER */}
                <Box sx={{ px: { xs: 2, sm: 3 }, py: 2.5, borderBottom: '1px solid', borderColor: 'divider' }}>
                    <Stack
                        direction={{ xs: 'column', sm: 'row' }}
                        justifyContent="space-between"
                        alignItems={{ xs: 'stretch', sm: 'center' }}
                        spacing={2}
                        mb={2.5}
                    >
                        <Box>
                            <Typography variant="h5" fontWeight={800} color="text.primary">
                                {t('portfolio.header.title')}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('portfolio.header.subtitle')}
                            </Typography>
                        </Box>

                        <Button
                            variant="contained"
                            startIcon={<RefreshIcon />}
                            onClick={refreshAll}
                            disabled={loading}
                            size={isMobile ? 'small' : 'medium'}
                            sx={{
                                borderRadius: 2, fontWeight: 600, textTransform: 'none', px: 2.5,
                                boxShadow: 'none', bgcolor: 'primary.main',
                                '&:hover': { boxShadow: '0 4px 12px rgba(0,0,0,0.15)' },
                            }}
                        >
                            {t('portfolio.common.refresh')}
                        </Button>
                    </Stack>

                    {/* FILTERS */}
                    <Stack
                        direction={{ xs: 'column', sm: 'row' }}
                        spacing={1.5}
                        alignItems={{ xs: 'stretch', sm: 'center' }}
                        flexWrap="wrap"
                    >
                        <TextField
                            select
                            label={t('portfolio.filter.technician')}
                            size="small"
                            value={technicianFilter}
                            onChange={(e) => { setTechnicianFilter(e.target.value); setPage(0); }}
                            sx={{ minWidth: { xs: '100%', sm: 180 }, flexGrow: { xs: 1, sm: 0 }, ...fieldSx }}
                        >
                            <MenuItem value="all">{t('portfolio.common.all')}</MenuItem>
                            {technicians.map((tech) => (
                                <MenuItem key={tech.id} value={tech.id}>
                                    {tech.user?.name || tech.name || t('portfolio.common.unknown')}
                                </MenuItem>
                            ))}
                        </TextField>

                        <TextField
                            placeholder={t('portfolio.filter.searchPlaceholder')}
                            size="small"
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
                            sx={{ minWidth: { xs: '100%', sm: 260 }, flexGrow: { xs: 1, sm: 0 }, ...fieldSx }}
                        />
                    </Stack>
                </Box>

                {/* SUMMARY CARDS */}
                <Box sx={{ px: { xs: 2, sm: 3 }, pt: 2.5, pb: 1 }}>
                    <Box sx={gridSx({ xs: 'repeat(2, 1fr)', sm: 'repeat(2, 1fr)' })}>
                        {[
                            { label: t('portfolio.stats.totalPortfolios'), value: totalPortfolios, color: '#8b5cf6', icon: <ImageIcon sx={{ fontSize: 18 }} /> },
                            { label: t('portfolio.stats.technicians'), value: uniqueTechnicians, color: '#3b82f6', icon: <PersonIcon sx={{ fontSize: 18 }} /> },
                        ].map((item, idx) => (
                            <Card
                                key={idx}
                                elevation={0}
                                sx={{ borderRadius: 2, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', height: '100%' }}
                            >
                                <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
                                    <Box display="flex" alignItems="center" justifyContent="space-between" gap={1}>
                                        <Typography variant="caption" sx={{ color: item.color, fontWeight: 600 }}>
                                            {item.label}
                                        </Typography>
                                        {item.icon}
                                    </Box>
                                    <Typography variant="h4" sx={{ color: item.color, fontWeight: 700 }}>
                                        {item.value}
                                    </Typography>
                                </CardContent>
                            </Card>
                        ))}
                    </Box>
                </Box>

                {/* TABLE (desktop) */}
                {showTableView ? (
                    <TableContainer sx={{ mt: 2 }}>
                        <Table sx={{ minWidth: 900 }}>
                            <TableHead>
                                <TableRow
                                    sx={{
                                        bgcolor: 'action.hover',
                                        '& th': {
                                            fontWeight: 700, fontSize: '0.8125rem', color: 'text.secondary',
                                            textTransform: 'uppercase', letterSpacing: 0.6,
                                            borderBottom: '1px solid', borderColor: 'divider', py: 1.75,
                                        },
                                    }}
                                >
                                    {headCells.map((cell) => (
                                        <TableCell key={cell.id} sx={{ whiteSpace: 'nowrap' }}>
                                            {!cell.disableSort ? (
                                                <TableSortLabel
                                                    active={orderBy === cell.id}
                                                    direction={orderBy === cell.id ? order : 'asc'}
                                                    onClick={() => handleRequestSort(cell.id)}
                                                >
                                                    {cell.label}
                                                </TableSortLabel>
                                            ) : (
                                                cell.label
                                            )}
                                        </TableCell>
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
                                ) : numberedPortfolios.length === 0 ? (
                                    <TableRow>
                                        <TableCell colSpan={headCells.length} align="center" sx={{ py: 8 }}>
                                            <Typography color="text.secondary" fontWeight={500}>
                                                {t('portfolio.table.noFound')}
                                            </Typography>
                                        </TableCell>
                                    </TableRow>
                                ) : (
                                    numberedPortfolios.map((portfolio) => {
                                        const imgs = imagesOf(portfolio);
                                        const techName = getTechnicianName(portfolio.technician);

                                        return (
                                            <TableRow
                                                key={portfolio.id}
                                                hover
                                                sx={{ '&:last-child td': { borderBottom: 0 }, transition: 'background-color 0.15s' }}
                                            >
                                                <TableCell sx={{ py: 2 }}>
                                                    <Typography variant="body2" fontWeight={600} color="text.primary">
                                                        {itemLabel(portfolio._no)}
                                                    </Typography>
                                                    <Chip
                                                        size="small"
                                                        icon={<CollectionsIcon sx={{ fontSize: 14 }} />}
                                                        label={`${imgs.length} ${imgs.length === 1 ? 'photo' : 'photos'}`}
                                                        sx={{ mt: 0.5, fontWeight: 600, bgcolor: 'action.hover', border: '1px solid', borderColor: 'divider' }}
                                                    />
                                                </TableCell>

                                                <TableCell>
                                                    <Stack direction="row" spacing={1} alignItems="center">
                                                        <Avatar
                                                            src={portfolio.technician?.profile_photo || undefined}
                                                            sx={{ width: 32, height: 32, bgcolor: SEA, fontSize: 12, fontWeight: 600 }}
                                                        >
                                                            {getInitials(techName)}
                                                        </Avatar>
                                                        <Typography variant="body2" fontWeight={500}>
                                                            {techName || t('portfolio.common.emDash')}
                                                        </Typography>
                                                        {portfolio.technician?.verified && (
                                                            <VerifiedIcon sx={{ fontSize: 14, color: 'success.main' }} />
                                                        )}
                                                    </Stack>
                                                </TableCell>

                                                {/* Only the top image + "+N" badge */}
                                                <TableCell>
                                                    <Thumb
                                                        src={imgs[0]?.url}
                                                        size={52}
                                                        extra={Math.max(0, imgs.length - 1)}
                                                        onClick={() => handleViewPortfolio(portfolio)}
                                                    />
                                                </TableCell>

                                                <TableCell>
                                                    <Typography variant="body2" fontWeight={500} color="text.secondary">
                                                        {formatDate(portfolio.created_at)}
                                                    </Typography>
                                                </TableCell>

                                                <TableCell align="center">
                                                    <IconButton
                                                        size="small"
                                                        onClick={(e) => handleMenuOpen(e, portfolio)}
                                                        sx={{ color: 'text.secondary', '&:hover': { bgcolor: 'action.hover', color: 'text.primary' } }}
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
                    /* MOBILE CARDS */
                    <Box sx={{ p: { xs: 2, sm: 2.5 } }}>
                        {loading ? (
                            <Box display="flex" justifyContent="center" py={6}>
                                <CircularProgress size={36} thickness={4} />
                            </Box>
                        ) : numberedPortfolios.length === 0 ? (
                            <Paper
                                variant="outlined"
                                sx={{ p: 5, textAlign: 'center', borderRadius: 3, borderStyle: 'dashed', bgcolor: 'background.paper' }}
                            >
                                <Typography color="text.secondary" fontWeight={500}>
                                    {t('portfolio.table.noFound')}
                                </Typography>
                            </Paper>
                        ) : (
                            <Box sx={gridSx({ xs: '1fr', sm: 'repeat(2, 1fr)' })}>
                                {numberedPortfolios.map((portfolio) => {
                                    const imgs = imagesOf(portfolio);
                                    const techName = getTechnicianName(portfolio.technician);

                                    return (
                                        <Card
                                            key={portfolio.id}
                                            elevation={0}
                                            sx={{
                                                borderRadius: 3, border: '1px solid', borderColor: 'divider',
                                                bgcolor: 'background.paper', overflow: 'hidden', height: '100%',
                                                display: 'flex', flexDirection: 'column',
                                                transition: 'box-shadow 0.2s', '&:hover': { boxShadow: 2 },
                                            }}
                                        >
                                            <Box sx={{ p: 2, pb: 0 }}>
                                                <Thumb
                                                    src={imgs[0]?.url}
                                                    fill
                                                    height={170}
                                                    extra={Math.max(0, imgs.length - 1)}
                                                    onClick={() => handleViewPortfolio(portfolio)}
                                                />
                                            </Box>

                                            <CardContent sx={{ p: 2.5, flex: 1, display: 'flex', flexDirection: 'column' }}>
                                                <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={1.5}>
                                                    <Stack direction="row" spacing={1.5} alignItems="center">
                                                        <Avatar
                                                            src={portfolio.technician?.profile_photo || undefined}
                                                            sx={{ width: 36, height: 36, bgcolor: SEA, fontSize: 13, fontWeight: 600 }}
                                                        >
                                                            {getInitials(techName)}
                                                        </Avatar>
                                                        <Box>
                                                            <Stack direction="row" spacing={0.5} alignItems="center">
                                                                <Typography variant="body2" fontWeight={600}>
                                                                    {techName || t('portfolio.common.emDash')}
                                                                </Typography>
                                                                {portfolio.technician?.verified && (
                                                                    <VerifiedIcon sx={{ fontSize: 14, color: 'success.main' }} />
                                                                )}
                                                            </Stack>
                                                            {portfolio.technician?.area && (
                                                                <Typography
                                                                    variant="caption"
                                                                    color="text.secondary"
                                                                    sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}
                                                                >
                                                                    <LocationIcon sx={{ fontSize: 12 }} />
                                                                    {portfolio.technician.area}
                                                                </Typography>
                                                            )}
                                                        </Box>
                                                    </Stack>
                                                    <IconButton
                                                        size="small"
                                                        onClick={(e) => handleMenuOpen(e, portfolio)}
                                                        sx={{ color: 'text.secondary', mt: -0.5 }}
                                                    >
                                                        <MoreVertIcon fontSize="small" />
                                                    </IconButton>
                                                </Stack>

                                                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                                                    {itemLabel(portfolio._no)}
                                                    {imgs.length > 0 && ` · ${imgs.length} photo${imgs.length !== 1 ? 's' : ''}`}
                                                </Typography>

                                                <Divider sx={{ mb: 2 }} />

                                                <Stack direction="row" justifyContent="space-between" alignItems="center">
                                                    <Stack direction="row" spacing={1}>
                                                        {portfolio.technician?.rating > 0 && (
                                                            <Chip
                                                                icon={<StarIcon sx={{ fontSize: 14 }} />}
                                                                label={Number(portfolio.technician.rating).toFixed(1)}
                                                                size="small"
                                                                sx={{
                                                                    fontWeight: 700, bgcolor: 'warning.light', color: 'warning.dark',
                                                                    border: '1px solid', borderColor: 'warning.main', height: 26,
                                                                    '& .MuiChip-icon': { color: 'warning.main' },
                                                                }}
                                                            />
                                                        )}
                                                    </Stack>
                                                    <Typography variant="caption" color="text.secondary" fontWeight={500}>
                                                        {formatDate(portfolio.created_at)}
                                                    </Typography>
                                                </Stack>

                                                <Button
                                                    variant="outlined"
                                                    fullWidth
                                                    startIcon={<ViewIcon />}
                                                    onClick={() => handleViewPortfolio(portfolio)}
                                                    sx={{
                                                        mt: 2, borderRadius: 2, textTransform: 'none', fontWeight: 600,
                                                        borderColor: 'divider', color: SEA,
                                                        '&:hover': { borderColor: SEA, bgcolor: 'action.hover' },
                                                    }}
                                                >
                                                    {t('portfolio.common.view')}
                                                </Button>
                                            </CardContent>
                                        </Card>
                                    );
                                })}
                            </Box>
                        )}
                    </Box>
                )}

                {/* PAGINATION */}
                <Box sx={{ borderTop: '1px solid', borderColor: 'divider', bgcolor: 'action.hover' }}>
                    <TablePagination
                        rowsPerPageOptions={[5, 10, 25, 50]}
                        component="div"
                        count={pagination.total || 0}
                        rowsPerPage={rowsPerPage}
                        page={page}
                        onPageChange={(e, newPage) => setPage(newPage)}
                        onRowsPerPageChange={(e) => {
                            setRowsPerPage(parseInt(e.target.value, 10));
                            setPage(0);
                        }}
                        sx={{ '.MuiTablePagination-selectLabel, .MuiTablePagination-displayedRows': { fontWeight: 500 } }}
                    />
                </Box>
            </Paper>

            {/* ACTION MENU */}
            <Menu
                anchorEl={actionMenu}
                open={Boolean(actionMenu)}
                onClose={handleMenuClose}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                transformOrigin={{ vertical: 'top', horizontal: 'right' }}
                PaperProps={{ elevation: 8, sx: { borderRadius: 2, minWidth: 180, mt: 0.5, bgcolor: 'background.paper' } }}
            >
                <MenuItem onClick={() => handleAction('view')} sx={{ fontWeight: 500 }}>
                    <ViewIcon sx={{ mr: 1.5, fontSize: 20, color: SEA }} />
                    {t('portfolio.menu.viewPortfolio')}
                </MenuItem>
                {canDelete && (
                    <MenuItem onClick={() => handleAction('delete')} sx={{ color: 'error.main', fontWeight: 500 }}>
                        <DeleteIcon sx={{ mr: 1.5, fontSize: 20 }} />
                        {t('portfolio.menu.delete')}
                    </MenuItem>
                )}
            </Menu>

            {/* PORTFOLIO DETAIL DIALOG — shows ALL images */}
            <Dialog
                open={openViewDialog}
                onClose={handleCloseDialog}
                maxWidth="md"
                fullWidth
                PaperProps={{
                    sx: { borderRadius: 3, border: '1px solid', borderColor: 'divider', maxHeight: '90vh', bgcolor: 'background.paper' },
                }}
            >
                {selectedPortfolio && (
                    <>
                        <DialogTitle sx={{ pb: 1.5, borderBottom: '1px solid', borderColor: 'divider' }}>
                            <Box display="flex" justifyContent="space-between" alignItems="flex-start">
                                <Box flex={1} minWidth={0}>
                                    <Typography variant="h6" fontWeight={700} color="text.primary">
                                        {t('portfolio.dialog.title')} · {itemLabel(selectedPortfolio._no)}
                                    </Typography>
                                    <Stack direction="row" spacing={2} alignItems="center" mt={1} flexWrap="wrap" useFlexGap>
                                        <Stack direction="row" spacing={1} alignItems="center">
                                            <Avatar
                                                src={selectedPortfolio.technician?.profile_photo || undefined}
                                                sx={{ width: 28, height: 28, bgcolor: SEA, fontSize: 11, fontWeight: 600 }}
                                            >
                                                {getInitials(getTechnicianName(selectedPortfolio.technician))}
                                            </Avatar>
                                            <Typography variant="body2" fontWeight={500}>
                                                {getTechnicianName(selectedPortfolio.technician)}
                                            </Typography>
                                            {selectedPortfolio.technician?.verified && (
                                                <VerifiedIcon sx={{ fontSize: 14, color: 'success.main' }} />
                                            )}
                                        </Stack>
                                        {selectedPortfolio.technician?.area && (
                                            <Chip
                                                icon={<LocationIcon sx={{ fontSize: 14 }} />}
                                                label={selectedPortfolio.technician.area}
                                                size="small"
                                                variant="outlined"
                                                sx={{ borderColor: 'divider' }}
                                            />
                                        )}
                                        <Typography variant="caption" color="text.secondary">
                                            <CalendarIcon sx={{ fontSize: 14, mr: 0.5, verticalAlign: 'middle' }} />
                                            {formatDateFull(selectedPortfolio.created_at)}
                                        </Typography>
                                    </Stack>
                                </Box>
                                <IconButton onClick={handleCloseDialog} size="small" sx={{ color: 'text.secondary' }}>
                                    <ClearIcon />
                                </IconButton>
                            </Box>
                        </DialogTitle>

                        <DialogContent sx={{ p: 3 }}>
                            {dialogImages.length > 0 ? (
                                <Box mb={3} sx={{ mt: 1 }}>
                                    <Typography variant="subtitle2" fontWeight={600} gutterBottom color="text.primary">
                                        {tr('portfolio.dialog.images', 'Images')} ({dialogImages.length})
                                    </Typography>
                                    <Box
                                        sx={gridSx(
                                            { xs: 'repeat(2, 1fr)', sm: 'repeat(3, 1fr)' },
                                            1.5
                                        )}
                                    >
                                        {dialogImages.map((img, idx) => (
                                            <Box
                                                key={img.id ?? idx}
                                                onClick={() => setLightboxIndex(idx)}
                                                sx={{ cursor: 'zoom-in' }}
                                            >
                                                <Thumb src={img.url} fill height={150} />
                                            </Box>
                                        ))}
                                    </Box>
                                </Box>
                            ) : (
                                <Box
                                    mb={3}
                                    mt={1}
                                    sx={{
                                        height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center',
                                        flexDirection: 'column', bgcolor: 'action.hover', borderRadius: 2,
                                        border: '1px dashed', borderColor: 'divider',
                                    }}
                                >
                                    <PhotoCameraIcon sx={{ color: 'text.disabled', fontSize: 48 }} />
                                    <Typography variant="body2" color="text.disabled" sx={{ mt: 1 }}>
                                        {t('portfolio.common.noImage')}
                                    </Typography>
                                </Box>
                            )}

                            <Divider sx={{ mb: 3, borderColor: 'divider' }} />

                            <Box sx={gridSx({ xs: '1fr', sm: 'repeat(2, 1fr)' }, 3)}>
                                <Box>
                                    <Typography variant="subtitle2" fontWeight={600} gutterBottom color="text.primary">
                                        {t('portfolio.dialog.technicianInfo')}
                                    </Typography>
                                    <Stack spacing={1}>
                                        <Box display="flex" alignItems="center" gap={1}>
                                            <PersonIcon sx={{ color: 'text.secondary', fontSize: 20 }} />
                                            <Typography variant="body2">
                                                {getTechnicianName(selectedPortfolio.technician)}
                                            </Typography>
                                        </Box>
                                        {selectedPortfolio.technician?.area && (
                                            <Box display="flex" alignItems="center" gap={1}>
                                                <LocationIcon sx={{ color: 'text.secondary', fontSize: 20 }} />
                                                <Typography variant="body2">{selectedPortfolio.technician.area}</Typography>
                                            </Box>
                                        )}
                                        {selectedPortfolio.technician?.rating > 0 && (
                                            <Box display="flex" alignItems="center" gap={0.5}>
                                                <StarIcon sx={{ color: 'warning.main', fontSize: 16 }} />
                                                <Typography variant="body2" fontWeight={500}>
                                                    {Number(selectedPortfolio.technician.rating).toFixed(1)}
                                                </Typography>
                                            </Box>
                                        )}
                                    </Stack>
                                </Box>
                                <Box>
                                    <Typography variant="subtitle2" fontWeight={600} gutterBottom color="text.primary">
                                        {t('portfolio.dialog.details')}
                                    </Typography>
                                    <Stack spacing={1}>
                                        <Box display="flex" alignItems="center" gap={1}>
                                            <CalendarIcon sx={{ color: 'text.secondary', fontSize: 20 }} />
                                            <Typography variant="body2">
                                                {tr('portfolio.dialog.created', `Created: ${formatDateFull(selectedPortfolio.created_at)}`, {
                                                    date: formatDateFull(selectedPortfolio.created_at),
                                                })}
                                            </Typography>
                                        </Box>
                                        <Box display="flex" alignItems="center" gap={1}>
                                            <ImageIcon sx={{ color: 'text.secondary', fontSize: 20 }} />
                                            <Typography variant="body2">{itemLabel(selectedPortfolio._no)}</Typography>
                                        </Box>
                                        <Box display="flex" alignItems="center" gap={1}>
                                            <CollectionsIcon sx={{ color: 'text.secondary', fontSize: 20 }} />
                                            <Typography variant="body2">
                                                {dialogImages.length} {tr('portfolio.dialog.photos', 'photos')}
                                            </Typography>
                                        </Box>
                                    </Stack>
                                </Box>
                            </Box>
                        </DialogContent>

                        <DialogActions sx={{ p: 2.5, borderTop: '1px solid', borderColor: 'divider' }}>
                            <Button
                                onClick={handleCloseDialog}
                                variant="contained"
                                sx={{
                                    borderRadius: 2, fontWeight: 700, textTransform: 'none', px: 4,
                                    bgcolor: SEA, '&:hover': { bgcolor: colors.dark || '#0d5c56' },
                                }}
                            >
                                {t('portfolio.common.close')}
                            </Button>
                        </DialogActions>
                    </>
                )}
            </Dialog>

            {/* LIGHTBOX — full size image with prev / next */}
            <Dialog
                open={lightboxImage !== null && lightboxImage !== undefined}
                onClose={() => setLightboxIndex(null)}
                maxWidth="lg"
                PaperProps={{ sx: { bgcolor: 'rgba(0,0,0,0.92)', borderRadius: 2, boxShadow: 'none', position: 'relative' } }}
            >
                {lightboxImage && (
                    <Box sx={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center', minWidth: { xs: 280, sm: 480 } }}>
                        <img
                            src={lightboxImage.url}
                            alt=""
                            style={{ maxWidth: '90vw', maxHeight: '85vh', objectFit: 'contain', display: 'block' }}
                        />
                        <IconButton
                            onClick={() => setLightboxIndex(null)}
                            sx={{ position: 'absolute', top: 8, right: 8, color: '#fff', bgcolor: 'rgba(255,255,255,0.15)' }}
                        >
                            <ClearIcon />
                        </IconButton>
                        {dialogImages.length > 1 && (
                            <>
                                <IconButton
                                    onClick={() => stepLightbox(-1)}
                                    sx={{ position: 'absolute', left: 8, color: '#fff', bgcolor: 'rgba(255,255,255,0.15)' }}
                                >
                                    <ChevronLeftIcon />
                                </IconButton>
                                <IconButton
                                    onClick={() => stepLightbox(1)}
                                    sx={{ position: 'absolute', right: 8, color: '#fff', bgcolor: 'rgba(255,255,255,0.15)' }}
                                >
                                    <ChevronRightIcon />
                                </IconButton>
                                <Typography
                                    variant="caption"
                                    sx={{ position: 'absolute', bottom: 8, color: '#fff', bgcolor: 'rgba(0,0,0,0.55)', px: 1.2, py: 0.3, borderRadius: 10 }}
                                >
                                    {lightboxIndex + 1} / {dialogImages.length}
                                </Typography>
                            </>
                        )}
                    </Box>
                )}
            </Dialog>

            {/* CONFIRMATION DIALOG */}
            <Dialog
                open={confirmDialog.open}
                onClose={() => setConfirmDialog((prev) => ({ ...prev, open: false }))}
                fullWidth
                maxWidth="xs"
                PaperProps={{ sx: { borderRadius: 3, bgcolor: 'background.paper' } }}
            >
                <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>{confirmDialog.title}</DialogTitle>
                <DialogContent>
                    <DialogContentText color="text.secondary">{confirmDialog.message}</DialogContentText>
                </DialogContent>
                <DialogActions sx={{ px: 3, pb: 2.5, pt: 1 }}>
                    <Button
                        onClick={() => setConfirmDialog((prev) => ({ ...prev, open: false }))}
                        sx={{ fontWeight: 600, textTransform: 'none' }}
                    >
                        {t('portfolio.common.cancel')}
                    </Button>
                    <Button
                        onClick={handleConfirm}
                        variant="contained"
                        color="error"
                        sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}
                    >
                        {t('portfolio.common.confirm')}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default PortfoliosList;