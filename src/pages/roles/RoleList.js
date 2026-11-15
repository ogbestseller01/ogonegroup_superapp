// src/pages/roles/RoleList.js
import React, { useState, useEffect } from 'react';
import {
    Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle,
    IconButton, InputAdornment, Menu, MenuItem, Paper, Table, TableBody,
    TableCell, TableContainer, TableHead, TablePagination, TableRow, TextField,
    Typography, useTheme, useMediaQuery, Card, CardContent, Divider,
    CircularProgress, Alert, Stack,
} from '@mui/material';
import {
    Add as AddIcon, Edit as EditIcon, Refresh as RefreshIcon, Search as SearchIcon,
    MoreVert as MoreVertIcon, VpnKey as PermissionsIcon, Shield as ShieldIcon,
    Description as DescriptionIcon, Delete as DeleteIcon, Clear as ClearIcon,
} from '@mui/icons-material';
import { roleService } from 'services/role.service';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import RoleFormModal from './RoleFormModal';
import RolePermissionsModal from './RolePermissionsModal';
import { tRole } from './rolelang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function RoleList() {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));
    const { language } = useLanguage();
    const t = (key) => tRole(language, key);

    const { can } = usePermissions();
    const canView = can('roles.view');
    const canCreate = can('roles.create');
    const canEdit = can('roles.edit');
    const canAssignPermissions = can('roles.assign_permissions');

    const [roles, setRoles] = useState([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [openFormModal, setOpenFormModal] = useState(false);
    const [editingRole, setEditingRole] = useState(null);
    const [openPermissionsModal, setOpenPermissionsModal] = useState(false);
    const [selectedRoleForPermissions, setSelectedRoleForPermissions] = useState(null);
    const [actionMenu, setActionMenu] = useState(null);
    const [selectedRole, setSelectedRole] = useState(null);
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [confirmDialog, setConfirmDialog] = useState({
        open: false,
        title: '',
        message: '',
        action: null,
    });

    const headCells = [
        { id: 'name', label: t('role.col.name') },
        { id: 'display_name', label: t('role.col.displayName') },
        { id: 'description', label: t('role.col.description') },
        { id: 'guard_name', label: t('role.col.guard') },
        { id: 'actions', label: t('role.col.actions'), disableSort: true },
    ];

    const fetchRoles = async () => {
        if (!canView) return;
        setLoading(true);
        setError(null);
        try {
            const response = await roleService.getRoles({
                page: page + 1,
                per_page: rowsPerPage,
                search: search || undefined,
            });

            if (response?.data?.status === 'success') {
                const data = response.data.data;
                if (data && data.data) {
                    setRoles(data.data);
                    setTotal(data.total || 0);
                } else if (Array.isArray(data)) {
                    setRoles(data);
                    setTotal(data.length || 0);
                } else {
                    setRoles([]);
                    setTotal(0);
                }
            } else {
                setRoles([]);
                setTotal(0);
                setError(response?.data?.message || t('role.loadFailed'));
            }
        } catch (err) {
            console.error('Roles error:', err);
            setError(err.message || t('role.loadFailed'));
            showSnackbar({ type: 'error', message: t('role.loadFailed') });
            setRoles([]);
            setTotal(0);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (canView) fetchRoles();
    }, [page, rowsPerPage, search, canView]);

    const handleMenuOpen = (event, role) => {
        setSelectedRole(role);
        setActionMenu(event.currentTarget);
    };

    const handleMenuClose = () => setActionMenu(null);

    const handleEdit = () => {
        setEditingRole(selectedRole);
        setOpenFormModal(true);
        handleMenuClose();
    };

    const handlePermissions = () => {
        setSelectedRoleForPermissions(selectedRole);
        setOpenPermissionsModal(true);
        handleMenuClose();
    };

    const handleCreate = () => {
        setEditingRole(null);
        setOpenFormModal(true);
    };

    const handleFormModalClose = () => {
        setOpenFormModal(false);
        setEditingRole(null);
        fetchRoles();
    };

    const handlePermissionsModalClose = () => {
        setOpenPermissionsModal(false);
        setSelectedRoleForPermissions(null);
    };

    const handleDelete = () => {
        if (!selectedRole) return;
        setConfirmDialog({
            open: true,
            title: t('role.deleteTitle'),
            message: t('role.deleteMessage').replace('{name}', selectedRole.name),
            action: async () => {
                await roleService.deleteRole(selectedRole.id);
                showSnackbar({ type: 'success', message: t('role.deleted') });
            },
        });
        handleMenuClose();
    };

    const handleConfirm = async () => {
        if (!confirmDialog.action) return;
        setConfirmDialog((prev) => ({ ...prev, open: false }));
        try {
            await confirmDialog.action();
            fetchRoles();
        } catch (err) {
            showSnackbar({
                type: 'error',
                message: err.response?.data?.message || t('role.actionFailed'),
            });
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
                        bgcolor: 'background.paper', // ✅ Theme aware
                    }}
                >
                    <Typography color="error" fontWeight={600} variant="h6" gutterBottom>
                        {t('role.accessDenied')}
                    </Typography>
                    <Typography color="text.secondary">
                        {t('role.noPermission')}
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
                                fetchRoles();
                            }}
                        >
                            {t('role.retry')}
                        </Button>
                    }
                    sx={{ borderRadius: 2 }}
                >
                    {error}
                </Alert>
            </Box>
        );
    }

    const roleList = Array.isArray(roles) ? roles : [];

    return (
        <Box sx={{ width: '100%', p: { xs: 1.5, sm: 2.5 }, m: 0, bgcolor: 'background.default' }}>
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
                {/* Header */}
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
                                {t('role.title')}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('role.subtitle')}
                            </Typography>
                        </Box>

                        {canCreate && (
                            <Button
                                variant="contained"
                                startIcon={<AddIcon />}
                                onClick={handleCreate}
                                size={isMobile ? 'small' : 'medium'}
                                sx={{
                                    borderRadius: 2,
                                    fontWeight: 700,
                                    textTransform: 'none',
                                    px: 2.5,
                                    boxShadow: 'none',
                                    bgcolor: colors.salat || '#10b981',
                                    '&:hover': {
                                        bgcolor: colors.dark || '#047857',
                                        boxShadow: '0 4px 12px rgba(16,185,129,0.35)',
                                    },
                                }}
                            >
                                {t('role.add')}
                            </Button>
                        )}
                    </Stack>

                    <Stack
                        direction={{ xs: 'column', sm: 'row' }}
                        spacing={1.5}
                        alignItems={{ xs: 'stretch', sm: 'center' }}
                    >
                        <TextField
                            placeholder={t('role.searchPlaceholder')}
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
                            sx={{
                                minWidth: { xs: '100%', sm: 260 },
                                flexGrow: { xs: 1, sm: 0 },
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 2,
                                    bgcolor: 'action.hover',
                                    '& fieldset': { borderColor: 'transparent' },
                                    '&:hover fieldset': { borderColor: 'divider' },
                                    '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                                },
                            }}
                        />

                        <Button
                            variant="outlined"
                            startIcon={<RefreshIcon />}
                            onClick={fetchRoles}
                            size={isMobile ? 'small' : 'medium'}
                            sx={{
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
                            {t('role.refresh')}
                        </Button>
                    </Stack>
                </Box>

                {/* Table / Cards */}
                {showTableView ? (
                    <TableContainer>
                        <Table sx={{ minWidth: 800 }}>
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
                                        <TableCell colSpan={5} align="center" sx={{ py: 8 }}>
                                            <CircularProgress size={36} thickness={4} />
                                        </TableCell>
                                    </TableRow>
                                ) : roleList.length === 0 ? (
                                    <TableRow>
                                        <TableCell colSpan={5} align="center" sx={{ py: 8 }}>
                                            <Typography color="text.secondary" fontWeight={500}>
                                                {t('role.noFound')}
                                            </Typography>
                                        </TableCell>
                                    </TableRow>
                                ) : (
                                    roleList.map((role) => (
                                        <TableRow
                                            key={role.id}
                                            hover
                                            sx={{
                                                '&:last-child td': { borderBottom: 0 },
                                                transition: 'background-color 0.15s',
                                            }}
                                        >
                                            <TableCell sx={{ py: 2 }}>
                                                <Chip
                                                    icon={<ShieldIcon sx={{ fontSize: 16 }} />}
                                                    label={role.name}
                                                    size="small"
                                                    sx={{
                                                        fontWeight: 700,
                                                        bgcolor: 'action.hover',
                                                        color: 'text.primary',
                                                        border: '1px solid',
                                                        borderColor: 'divider',
                                                        height: 28,
                                                        '& .MuiChip-icon': { color: colors.sea || '#0f766e' },
                                                    }}
                                                />
                                            </TableCell>
                                            <TableCell>
                                                <Typography variant="body2" fontWeight={600}>
                                                    {role.display_name || role.name}
                                                </Typography>
                                            </TableCell>
                                            <TableCell sx={{ maxWidth: 320 }}>
                                                <Typography
                                                    variant="body2"
                                                    color="text.secondary"
                                                    sx={{ wordBreak: 'break-word' }}
                                                >
                                                    {role.description || '—'}
                                                </Typography>
                                            </TableCell>
                                            <TableCell>
                                                <Typography variant="body2" fontWeight={500}>
                                                    {role.guard_name}
                                                </Typography>
                                            </TableCell>
                                            <TableCell align="center">
                                                <IconButton
                                                    size="small"
                                                    onClick={(e) => handleMenuOpen(e, role)}
                                                    sx={{
                                                        color: 'text.secondary',
                                                        '&:hover': {
                                                            bgcolor: 'action.hover',
                                                            color: 'text.primary',
                                                        },
                                                    }}
                                                >
                                                    <MoreVertIcon />
                                                </IconButton>
                                            </TableCell>
                                        </TableRow>
                                    ))
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
                        ) : roleList.length === 0 ? (
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
                                    {t('role.noFound')}
                                </Typography>
                            </Paper>
                        ) : (
                            <Stack spacing={2}>
                                {roleList.map((role) => (
                                    <Card
                                        key={role.id}
                                        elevation={0}
                                        sx={{
                                            borderRadius: 3,
                                            border: '1px solid',
                                            borderColor: 'divider',
                                            bgcolor: 'background.paper', // ✅ Theme aware
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
                                                <Chip
                                                    icon={<ShieldIcon sx={{ fontSize: 16 }} />}
                                                    label={role.name}
                                                    size="small"
                                                    sx={{
                                                        fontWeight: 700,
                                                        bgcolor: 'action.hover',
                                                        border: '1px solid',
                                                        borderColor: 'divider',
                                                        height: 28,
                                                        '& .MuiChip-icon': {
                                                            color: colors.sea || '#0f766e',
                                                        },
                                                    }}
                                                />
                                                <IconButton
                                                    size="small"
                                                    onClick={(e) => handleMenuOpen(e, role)}
                                                    sx={{ color: 'text.secondary' }}
                                                >
                                                    <MoreVertIcon fontSize="small" />
                                                </IconButton>
                                            </Stack>

                                            <Typography variant="body1" fontWeight={700} mb={0.75}>
                                                {role.display_name || role.name}
                                            </Typography>

                                            {role.description && (
                                                <Stack direction="row" spacing={1} alignItems="flex-start" mb={1.5}>
                                                    <DescriptionIcon
                                                        sx={{ fontSize: 18, color: 'text.secondary', mt: 0.2 }}
                                                    />
                                                    <Typography variant="body2" color="text.secondary">
                                                        {role.description}
                                                    </Typography>
                                                </Stack>
                                            )}

                                            <Divider sx={{ my: 1.5 }} />

                                            <Stack direction="row" spacing={1} alignItems="center">
                                                <ShieldIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                <Typography variant="caption" color="text.secondary" fontWeight={500}>
                                                    {t('role.guard')}: {role.guard_name}
                                                </Typography>
                                            </Stack>
                                        </CardContent>
                                    </Card>
                                ))}
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
                PaperProps={{
                    elevation: 8,
                    sx: { borderRadius: 2, minWidth: 200, mt: 0.5, bgcolor: 'background.paper' },
                }}
            >
                {canEdit && (
                    <MenuItem onClick={handleEdit} sx={{ fontWeight: 500 }}>
                        <EditIcon sx={{ mr: 1.5, fontSize: 20, color: colors.sea || '#0f766e' }} /> {t('role.edit')}
                    </MenuItem>
                )}
                {canAssignPermissions && (
                    <MenuItem onClick={handlePermissions} sx={{ fontWeight: 500 }}>
                        <PermissionsIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('role.assignPermissions')}
                    </MenuItem>
                )}
                <MenuItem onClick={handleDelete} sx={{ color: 'error.main', fontWeight: 500 }}>
                    <DeleteIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('role.delete')}
                </MenuItem>
            </Menu>

            {/* Modals */}
            <RoleFormModal open={openFormModal} onClose={handleFormModalClose} role={editingRole} />
            {selectedRoleForPermissions && (
                <RolePermissionsModal
                    open={openPermissionsModal}
                    onClose={handlePermissionsModalClose}
                    role={selectedRoleForPermissions}
                />
            )}

            {/* Confirm Dialog */}
            <Dialog
                open={confirmDialog.open}
                onClose={() => setConfirmDialog((prev) => ({ ...prev, open: false }))}
                fullWidth
                maxWidth="xs"
                PaperProps={{ sx: { borderRadius: 3, bgcolor: 'background.paper' } }}
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
                        {t('role.cancel')}
                    </Button>
                    <Button
                        onClick={handleConfirm}
                        variant="contained"
                        color="error"
                        sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}
                    >
                        {t('role.confirm')}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}