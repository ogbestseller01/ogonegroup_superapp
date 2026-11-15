// src/pages/services/ServicesList.js
import React, { useState, useEffect, useMemo } from 'react';
import {
    Box, Paper, Typography, Button, TextField, InputAdornment, IconButton,
    Menu, MenuItem, Dialog, DialogTitle, DialogContent, DialogActions,
    CircularProgress, useMediaQuery, useTheme, Card, CardContent,
    Chip, Stack, alpha, Alert, TablePagination,
} from '@mui/material';
import {
    Add as AddIcon, Search as SearchIcon, Refresh as RefreshIcon,
    MoreVert as MoreVertIcon, Edit as EditIcon, Delete as DeleteIcon,
    Build as BuildIcon, People as PeopleIcon, Clear as ClearIcon,
    Category as CategoryIcon,
} from '@mui/icons-material';
import { serviceService } from 'services/service.service';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tService } from './serviceslang';
import ServiceFormModal from './ServiceFormModal';
import TechniciansModal from './TechniciansModal';
import appConfig from '../../config';

const colors = appConfig.app.colors;

/** CSS-grid helper (does not depend on the MUI Grid version). */
const gridSx = (columns, gap = 2) => ({
    display: 'grid',
    gap,
    gridTemplateColumns: columns,
});

const ServicesList = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

    const { language } = useLanguage();
    const t = (key, replacements) => tService(language, key, replacements);
    /** translate, but use `fallback` when the key has no translation (translator returns the key). */
    const tr = (key, fallback, replacements) => {
        const v = t(key, replacements);
        return !v || v === key ? fallback : v;
    };

    const [groupedData, setGroupedData] = useState([]);
    const [filteredData, setFilteredData] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const { can } = usePermissions();

    const [openModal, setOpenModal] = useState(false);
    const [editingService, setEditingService] = useState(null);
    const [actionMenu, setActionMenu] = useState(null);
    const [selectedService, setSelectedService] = useState(null);

    const [techniciansModal, setTechniciansModal] = useState({
        open: false, serviceId: null, serviceName: '',
    });

    const [confirmDialog, setConfirmDialog] = useState({
        open: false, title: '', message: '', action: null,
    });

    const [search, setSearch] = useState('');
    const [debouncedSearch, setDebouncedSearch] = useState('');

    // pagination (by category — each page shows N category sections)
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(5);

    const canView = can('services.view');
    const canCreate = can('services.create');
    const canEdit = can('services.edit');
    const canDelete = can('services.delete');

    const loadGroupedServices = async () => {
        if (!canView) return;
        setLoading(true);
        setError(null);
        try {
            const response = await serviceService.getGroupedServices();
            if (response?.data?.status === 'success') {
                const data = response.data.data || [];
                setGroupedData(data);
            } else {
                setGroupedData([]);
            }
        } catch (err) {
            console.error('Grouped services error:', err);
            setError(err.message || t('service.list.loadFailed'));
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (canView) loadGroupedServices();

    }, [canView]);

    // debounce the search box so we don't re-filter on every keystroke
    useEffect(() => {
        const timer = setTimeout(() => {
            setDebouncedSearch(search.trim());
            setPage(0);
        }, 300);
        return () => clearTimeout(timer);
    }, [search]);

    useEffect(() => {
        if (!debouncedSearch) {
            setFilteredData(groupedData);
            return;
        }
        const lowerSearch = debouncedSearch.toLowerCase();
        const filtered = groupedData
            .map(category => ({
                ...category,
                services: category.services.filter(service =>
                    service.name.toLowerCase().includes(lowerSearch) ||
                    service.name_en?.toLowerCase().includes(lowerSearch) ||
                    service.name_sw?.toLowerCase().includes(lowerSearch)
                ),
            }))
            .filter(category => category.services.length > 0);
        setFilteredData(filtered);
    }, [debouncedSearch, groupedData]);

    // keep the page valid when data shrinks (after delete / refresh / search)
    useEffect(() => {
        const lastPage = Math.max(0, Math.ceil(filteredData.length / rowsPerPage) - 1);
        if (page > lastPage) setPage(lastPage);
    }, [filteredData, rowsPerPage, page]);

    // only the categories on the current page are rendered
    const pagedData = useMemo(
        () => filteredData.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage),
        [filteredData, page, rowsPerPage]
    );

    const handleMenuOpen = (event, service) => {
        setSelectedService(service);
        setActionMenu(event.currentTarget);
    };

    const handleMenuClose = () => setActionMenu(null);

    const openConfirmDialog = (title, message, actionFn) => {
        setConfirmDialog({ open: true, title, message, action: actionFn });
    };

    const handleDelete = async (id) => {
        try {
            await serviceService.deleteService(id);
            showSnackbar({ type: 'success', message: t('service.list.deleteSuccess') });
            await loadGroupedServices();
            return true;
        } catch (err) {
            console.error('Delete error:', err);
            const errorMessage = err.response?.data?.message || t('service.list.deleteFailed');
            showSnackbar({ type: 'error', message: errorMessage });
            throw err;
        }
    };

    const handleConfirm = async () => {
        if (!confirmDialog.action) return;
        const action = confirmDialog.action;
        setConfirmDialog(prev => ({ ...prev, open: false }));
        try { await action(); } catch (err) { console.error('Confirm action failed:', err); }
    };

    const handleViewTechnicians = (serviceId, serviceName) => {
        setTechniciansModal({ open: true, serviceId, serviceName });
    };

    const handleEdit = async (service) => {
        try {
            const response = await serviceService.getService(service.id);
            if (response?.data?.status === 'success') {
                setEditingService(response.data.data);
                setOpenModal(true);
            } else {
                showSnackbar({ type: 'error', message: t('service.list.loadDetailsFailed') });
            }
        } catch (err) {
            console.error('Error fetching service details:', err);
            showSnackbar({ type: 'error', message: t('service.list.loadDetailsFailed') });
        }
        handleMenuClose();
    };

    const handlePageChange = (_, newPage) => {
        setPage(newPage);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    };

    if (!canView) {
        return (
            <Box p={3}>
                <Paper elevation={0} sx={{
                    p: 4, textAlign: 'center', borderRadius: 3,
                    border: '1px solid', borderColor: 'divider',
                    bgcolor: 'background.paper',
                }}>
                    <Typography color="error" fontWeight={600}>
                        {t('service.accessDenied')}
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
                    action={
                        <Button color="inherit" size="small" onClick={() => { setError(null); loadGroupedServices(); }}>
                            {t('service.common.retry')}
                        </Button>
                    }
                    sx={{ borderRadius: 2 }}
                >
                    {error}
                </Alert>
            </Box>
        );
    }

    const totalServices = groupedData.reduce((acc, cat) => acc + cat.services.length, 0);
    const totalCategories = groupedData.length;

    return (
        <Box sx={{ width: '100%', p: { xs: 1.5, sm: 2.5 }, m: 0, bgcolor: 'background.default' }}>
            <Paper elevation={0} sx={{
                width: '100%', borderRadius: 3, overflow: 'hidden',
                border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper',
            }}>
                {/* HEADER */}
                <Box sx={{ px: { xs: 2, sm: 3 }, py: 2.5, borderBottom: '1px solid', borderColor: 'divider' }}>
                    <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between"
                           alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} mb={2.5}>
                        <Box>
                            <Typography variant="h5" fontWeight={800} color="text.primary">
                                {t('service.list.title')}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('service.list.subtitle')}
                            </Typography>
                        </Box>

                        <Stack direction="row" spacing={1.5} alignItems="center" justifyContent={{ xs: 'space-between', sm: 'flex-end' }}>
                            {canCreate && (
                                <Button
                                    variant="contained" startIcon={<AddIcon />}
                                    onClick={() => { setEditingService(null); setOpenModal(true); }}
                                    size={isMobile ? 'small' : 'medium'}
                                    sx={{
                                        borderRadius: 2, fontWeight: 700, textTransform: 'none', px: 2.5, boxShadow: 'none',
                                        bgcolor: colors.salat || '#10b981',
                                        '&:hover': { bgcolor: colors.dark || '#047857', boxShadow: '0 4px 12px rgba(16,185,129,0.35)' },
                                    }}
                                >
                                    {t('service.list.addService')}
                                </Button>
                            )}
                        </Stack>
                    </Stack>

                    {/* FILTERS */}
                    <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5}
                           alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap">
                        <TextField
                            placeholder={t('service.list.searchPlaceholder')}
                            size="small" value={search}
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
                                minWidth: { xs: '100%', sm: 260 }, flexGrow: { xs: 1, sm: 0 },
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 2, bgcolor: 'action.hover',
                                    '& fieldset': { borderColor: 'transparent' },
                                    '&:hover fieldset': { borderColor: 'divider' },
                                    '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                                },
                            }}
                        />

                        <Button
                            variant="outlined" startIcon={<RefreshIcon />}
                            onClick={loadGroupedServices} disabled={loading}
                            size={isMobile ? 'small' : 'medium'}
                            sx={{
                                borderRadius: 2, fontWeight: 600, textTransform: 'none',
                                borderColor: 'divider', color: 'text.primary',
                                '&:hover': { borderColor: 'text.primary', bgcolor: 'action.hover' },
                            }}
                        >
                            {t('service.common.refresh')}
                        </Button>
                    </Stack>
                </Box>

                {/* SUMMARY CARDS */}
                <Box sx={{ px: { xs: 2, sm: 3 }, pt: 2.5, pb: 1 }}>
                    <Box sx={gridSx({ xs: 'repeat(2, 1fr)', sm: 'repeat(2, 1fr)' })}>
                        {[
                            { label: t('service.list.stat.totalServices'), value: totalServices, color: '#3b82f6', icon: <BuildIcon sx={{ fontSize: 18 }} /> },
                            { label: t('service.list.stat.categories'), value: totalCategories, color: '#8b5cf6', icon: <CategoryIcon sx={{ fontSize: 18 }} /> },
                        ].map((item, idx) => (
                            <Card
                                key={idx}
                                elevation={0}
                                sx={{
                                    borderRadius: 2, border: '1px solid', borderColor: 'divider',
                                    bgcolor: 'background.paper',
                                    height: '100%',
                                }}
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

                {/* SERVICES GRID */}
                <Box sx={{ p: { xs: 2, sm: 3 } }}>
                    {loading ? (
                        <Box display="flex" justifyContent="center" py={6}>
                            <CircularProgress size={36} thickness={4} />
                        </Box>
                    ) : filteredData.length === 0 ? (
                        <Paper variant="outlined" sx={{ p: 5, textAlign: 'center', borderRadius: 3, borderStyle: 'dashed', bgcolor: 'background.paper' }}>
                            <BuildIcon sx={{ fontSize: 56, color: 'text.disabled', mb: 2 }} />
                            <Typography color="text.secondary" fontWeight={500}>
                                {search ? t('service.list.noMatch') : t('service.list.noFound')}
                            </Typography>
                            {search && (
                                <Button
                                    variant="outlined" onClick={() => setSearch('')}
                                    sx={{ mt: 2, borderRadius: 2, textTransform: 'none' }}
                                >
                                    {t('service.list.clearSearch')}
                                </Button>
                            )}
                        </Paper>
                    ) : (
                        pagedData.map((category) => (
                            <Paper
                                key={category.category_id}
                                elevation={0}
                                sx={{
                                    mb: 3, p: { xs: 2, sm: 3 }, borderRadius: 2.5,
                                    border: '1px solid', borderColor: 'divider',
                                    bgcolor: 'action.hover',
                                }}
                            >
                                <Stack direction="row" justifyContent="space-between" alignItems="center"
                                       mb={2.5} flexWrap="wrap" gap={1}>
                                    <Typography variant="h6" fontWeight={700} color="text.primary">
                                        <CategoryIcon sx={{ fontSize: 22, mr: 1, verticalAlign: 'middle', color: colors.sea }} />
                                        {category.category_name}
                                        <Chip
                                            label={t('service.list.servicesCount', { n: category.services.length })}
                                            size="small"
                                            sx={{
                                                ml: 1.5, fontWeight: 600,
                                                bgcolor: alpha(colors.sea, 0.08),
                                                color: colors.sea,
                                            }}
                                        />
                                    </Typography>
                                </Stack>

                                <Box sx={gridSx({ xs: '1fr', sm: 'repeat(2, 1fr)', md: 'repeat(3, 1fr)' }, 2.5)}>
                                    {category.services.map((service) => (
                                        <Card
                                            key={service.id}
                                            elevation={0}
                                            sx={{
                                                height: '100%', borderRadius: 2.5,
                                                border: '1px solid', borderColor: 'divider',
                                                bgcolor: 'background.paper',
                                                transition: 'all 0.25s ease',
                                                '&:hover': {
                                                    borderColor: colors.sea,
                                                    boxShadow: '0 8px 24px rgba(0,0,0,0.06)',
                                                    transform: 'translateY(-2px)',
                                                },
                                                display: 'flex', flexDirection: 'column',
                                            }}
                                        >
                                            <CardContent sx={{ p: 2.5, flex: 1, display: 'flex', flexDirection: 'column' }}>
                                                <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={1.5}>
                                                    <Typography variant="subtitle1" fontWeight={700} color="text.primary">
                                                        {service.name}
                                                    </Typography>
                                                    <IconButton
                                                        size="small"
                                                        onClick={(e) => handleMenuOpen(e, service)}
                                                        sx={{
                                                            color: 'text.secondary',
                                                            '&:hover': { bgcolor: 'action.hover', color: 'text.primary' },
                                                        }}
                                                    >
                                                        <MoreVertIcon fontSize="small" />
                                                    </IconButton>
                                                </Stack>

                                                {service.swahili_name && (
                                                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
                                                        {service.swahili_name}
                                                    </Typography>
                                                )}

                                                <Box display="flex" alignItems="center" gap={0.5} sx={{ mb: 1.5, mt: 'auto' }}>
                                                    <PeopleIcon fontSize="small" sx={{ color: 'text.secondary' }} />
                                                    <Typography variant="body2" fontWeight={500} color="text.primary">
                                                        {t('service.list.techniciansCount', {
                                                            n: service.technicians_count || 0,
                                                            s: service.technicians_count !== 1 ? 's' : '',
                                                        })}
                                                    </Typography>
                                                </Box>

                                                <Button
                                                    variant="outlined" size="small" fullWidth
                                                    onClick={() => handleViewTechnicians(service.id, service.name)}
                                                    sx={{
                                                        borderRadius: 2, textTransform: 'none', fontWeight: 600,
                                                        borderColor: 'divider', color: colors.sea || '#0f766e',
                                                        '&:hover': {
                                                            borderColor: colors.sea || '#0f766e',
                                                            bgcolor: alpha(colors.sea, 0.06),
                                                        },
                                                    }}
                                                >
                                                    {t('service.list.viewTechnicians')}
                                                </Button>
                                            </CardContent>
                                        </Card>
                                    ))}
                                </Box>
                            </Paper>
                        ))
                    )}
                </Box>

                {/* PAGINATION */}
                {!loading && filteredData.length > 0 && (
                    <Box sx={{ borderTop: '1px solid', borderColor: 'divider', bgcolor: 'action.hover' }}>
                        <TablePagination
                            component="div"
                            rowsPerPageOptions={[3, 5, 10, 20]}
                            count={filteredData.length}
                            rowsPerPage={rowsPerPage}
                            page={page}
                            onPageChange={handlePageChange}
                            onRowsPerPageChange={(e) => {
                                setRowsPerPage(parseInt(e.target.value, 10));
                                setPage(0);
                            }}
                            labelRowsPerPage={tr('service.list.categoriesPerPage', 'Categories per page:')}
                            sx={{ '.MuiTablePagination-selectLabel, .MuiTablePagination-displayedRows': { fontWeight: 500 } }}
                        />
                    </Box>
                )}
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
                {canEdit && (
                    <MenuItem onClick={() => handleEdit(selectedService)} sx={{ fontWeight: 500 }}>
                        <EditIcon sx={{ mr: 1.5, fontSize: 20, color: colors.sea || '#0f766e' }} />
                        {t('service.common.edit')}
                    </MenuItem>
                )}
                {canDelete && (
                    <MenuItem
                        onClick={() => {
                            openConfirmDialog(
                                t('service.delete.title'),
                                t('service.delete.message', { name: selectedService?.name }),
                                () => handleDelete(selectedService?.id)
                            );
                            handleMenuClose();
                        }}
                        sx={{ color: 'error.main', fontWeight: 500 }}
                    >
                        <DeleteIcon sx={{ mr: 1.5, fontSize: 20 }} />
                        {t('service.common.delete')}
                    </MenuItem>
                )}
            </Menu>

            {/* SERVICE FORM MODAL */}
            <ServiceFormModal
                open={openModal}
                onClose={() => {
                    setOpenModal(false);
                    setEditingService(null);
                    loadGroupedServices();
                }}
                service={editingService}
            />

            {/* TECHNICIANS MODAL */}
            <TechniciansModal
                open={techniciansModal.open}
                onClose={() => setTechniciansModal({ open: false, serviceId: null, serviceName: '' })}
                serviceId={techniciansModal.serviceId}
                serviceName={techniciansModal.serviceName}
            />

            {/* CONFIRMATION DIALOG */}
            <Dialog
                open={confirmDialog.open}
                onClose={() => setConfirmDialog(prev => ({ ...prev, open: false }))}
                fullWidth maxWidth="xs"
                PaperProps={{ sx: { borderRadius: 3, bgcolor: 'background.paper' } }}
            >
                <DialogTitle sx={{ fontWeight: 700, pb: 1, color: 'text.primary' }}>
                    {confirmDialog.title}
                </DialogTitle>
                <DialogContent>
                    <Typography color="text.secondary">{confirmDialog.message}</Typography>
                </DialogContent>
                <DialogActions sx={{ px: 3, pb: 2.5, pt: 1 }}>
                    <Button
                        onClick={() => setConfirmDialog(prev => ({ ...prev, open: false }))}
                        sx={{ fontWeight: 600, textTransform: 'none' }}
                    >
                        {t('service.common.cancel')}
                    </Button>
                    <Button
                        onClick={handleConfirm}
                        variant="contained" color="error"
                        sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}
                    >
                        {t('service.common.confirm')}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default ServicesList;