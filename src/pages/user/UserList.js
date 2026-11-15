// src/pages/users/UsersList.jsx
import React, { useState, useEffect, useMemo } from 'react';
import {
    Box,
    Paper,
    Typography,
    Button,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    TablePagination,
    TableSortLabel,
    TextField,
    InputAdornment,
    IconButton,
    Chip,
    Menu,
    MenuItem,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    CircularProgress,
    Switch,
    FormControlLabel,
    useMediaQuery,
    useTheme,
    Card,
    CardContent,
    Divider,
    Alert,
    Avatar,
    Stack,
} from '@mui/material';
import {
    Add as AddIcon,
    Search as SearchIcon,
    Refresh as RefreshIcon,
    MoreVert as MoreVertIcon,
    Edit as EditIcon,
    Delete as DeleteIcon,
    Verified as VerifiedIcon,
    Block as BlockIcon,
    LockOpen as LockOpenIcon,
    VpnKey as VpnKeyIcon,
    Email as EmailIcon,
    Restore as RestoreIcon,
    DeleteSweep as DeleteSweepIcon,
    People as PeopleIcon,
    Handyman as HandymanIcon,
    SupportAgent as SupportIcon,
    AdminPanelSettings as AdminIcon,
    CheckCircle as CheckCircleIcon,
    Cancel as CancelIcon,
    Pending as PendingIcon,
    Phone as PhoneIcon,
    Work as WorkIcon,
    Clear as ClearIcon,
} from '@mui/icons-material';
import { useUserManagement } from 'hooks/useUser';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { userService } from 'services/user.service';
import { showSnackbar } from 'utils/snackbar';
import UserFormModal from './UserFormModal';
import { tUser } from './userlang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

// ── Status styles (visual only, labels resolved via t()) ─────────────────
const getStatusStyles = (t) => ({
    active: {
        color: '#047857',
        bg: '#d1fae5',
        border: '#10b981',
        label: t('user.status.active'),
        icon: <CheckCircleIcon sx={{ fontSize: 16 }} />,
    },
    inactive: {
        color: '#4b5563',
        bg: '#f3f4f6',
        border: '#9ca3af',
        label: t('user.status.inactive'),
        icon: <CancelIcon sx={{ fontSize: 16 }} />,
    },
    pending: {
        color: '#b45309',
        bg: '#fef3c7',
        border: '#f59e0b',
        label: t('user.status.pending'),
        icon: <PendingIcon sx={{ fontSize: 16 }} />,
    },
    suspended: {
        color: '#b91c1c',
        bg: '#fee2e2',
        border: '#ef4444',
        label: t('user.status.suspended'),
        icon: <BlockIcon sx={{ fontSize: 16 }} />,
    },
});

// ── Head cells (labels resolved via t()) ────────────────────────────────
const getHeadCells = (t) => [
    { id: 'count', label: '#', disableSort: true },
    { id: 'name', label: t('user.col.user') },
    { id: 'email', label: t('user.col.email') },
    { id: 'phone', label: t('user.col.phone') },
    { id: 'role', label: t('user.col.role') },
    { id: 'status', label: t('user.col.status') },
    { id: 'created_at', label: t('user.col.created') },
    { id: 'actions', label: t('user.col.actions'), disableSort: true },
];

const UsersList = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));

    const { language } = useLanguage();

    // Enhanced translation function with fallback for missing keys
    const t = (key, replacements) => {
        let str = tUser(language, key);

        // Fallback if translation is missing (returns the key itself or undefined)
        if (!str || str === key) {
            // Convert 'user.col.user' to 'User'
            const parts = key.split('.');
            const lastPart = parts[parts.length - 1];
            str = lastPart.charAt(0).toUpperCase() + lastPart.slice(1).replace(/_/g, ' ');
        }

        if (replacements) {
            Object.entries(replacements).forEach(([k, v]) => {
                str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
            });
        }
        return str;
    };

    const statusStyles = useMemo(() => getStatusStyles(t), [language]);
    const headCells = useMemo(() => getHeadCells(t), [language]);

    const {
        users,
        loading,
        error,
        getUsers,
        deleteUser,
        updateUser,
        clearError,
        verifyUserOtp,
        markUserVerified,
    } = useUserManagement();

    const { can } = usePermissions();

    const [showDeleted, setShowDeleted] = useState(false);
    const [deletedUsers, setDeletedUsers] = useState([]);
    const [trashedTotal, setTrashedTotal] = useState(0);
    const [loadingDeleted, setLoadingDeleted] = useState(false);

    const [openModal, setOpenModal] = useState(false);
    const [editingUser, setEditingUser] = useState(null);
    const [actionMenu, setActionMenu] = useState(null);
    const [selectedUser, setSelectedUser] = useState(null);

    const [confirmDialog, setConfirmDialog] = useState({
        open: false,
        title: '',
        message: '',
        action: null,
    });

    const [passwordDialog, setPasswordDialog] = useState({
        open: false,
        userId: null,
        userName: '',
        password: '',
        confirmPassword: '',
        error: '',
    });

    const [verifyOtpDialog, setVerifyOtpDialog] = useState({
        open: false,
        userId: null,
        userName: '',
        otp: '',
        error: '',
    });

    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [roleFilter, setRoleFilter] = useState('');
    const [order, setOrder] = useState('desc');
    const [orderBy, setOrderBy] = useState('created_at');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);

    // Permissions
    const canView = can('users.view');
    const canCreate = can('users.create');
    const canEdit = can('users.edit');
    const canDelete = can('users.delete');
    const canActivate = can('users.activate');
    const canDeactivate = can('users.deactivate');
    const canSuspend = can('users.suspend');
    const canResetPassword = can('users.reset_password');
    const canRestore = can('users.restore');
    const canVerify = can('users.verify');

    // Fetch users when filters change
    useEffect(() => {
        if (!showDeleted && canView) {
            getUsers({
                page: page + 1,
                per_page: rowsPerPage,
                search: search || undefined,
                status: statusFilter || undefined,
            });
        }
    }, [page, rowsPerPage, showDeleted, search, statusFilter, getUsers, canView]);

    // Fetch deleted users when toggled
    useEffect(() => {
        if (showDeleted && canView) {
            fetchDeletedUsers();
        }
    }, [showDeleted, page, rowsPerPage, search, canView]);

    const fetchDeletedUsers = async () => {
        setLoadingDeleted(true);
        try {
            const response = await userService.getTrashedUsers({
                page: page + 1,
                per_page: rowsPerPage,
                search: search || undefined,
            });
            const data = response.data?.data;
            setDeletedUsers(data?.data || []);
            setTrashedTotal(data?.total || 0);
        } catch (error) {
            console.error('Failed to load deleted users', error);
            showSnackbar({ type: 'error', message: t('user.msg.loadDeletedFailed') });
            setDeletedUsers([]);
            setTrashedTotal(0);
        } finally {
            setLoadingDeleted(false);
        }
    };

    // Client-side filtering
    const filteredUsers = useMemo(() => {
        if (!Array.isArray(users)) return [];
        let filtered = [...users];

        if (search) {
            const searchLower = search.toLowerCase();
            filtered = filtered.filter(
                (user) =>
                    user.name?.toLowerCase().includes(searchLower) ||
                    user.email?.toLowerCase().includes(searchLower) ||
                    user.phone?.toLowerCase().includes(searchLower)
            );
        }

        if (statusFilter) {
            filtered = filtered.filter((user) => user.status === statusFilter);
        }

        if (roleFilter) {
            filtered = filtered.filter((user) => {
                if (!user.roles || user.roles.length === 0) return false;
                return user.roles.some((role) => role.name === roleFilter);
            });
        }

        return filtered;
    }, [users, search, statusFilter, roleFilter]);

    // Sort the filtered data
    const sortedData = useMemo(() => {
        const sorted = [...filteredUsers];
        sorted.sort((a, b) => {
            let aValue, bValue;

            switch (orderBy) {
                case 'name':
                    aValue = a.name || '';
                    bValue = b.name || '';
                    break;
                case 'email':
                    aValue = a.email || '';
                    bValue = b.email || '';
                    break;
                case 'phone':
                    aValue = a.phone || '';
                    bValue = b.phone || '';
                    break;
                case 'role':
                    aValue = getUserRoleName(a);
                    bValue = getUserRoleName(b);
                    break;
                case 'status':
                    aValue = a.status || '';
                    bValue = b.status || '';
                    break;
                case 'created_at':
                    aValue = a.created_at || '';
                    bValue = b.created_at || '';
                    break;
                default:
                    aValue = a[orderBy] || '';
                    bValue = b[orderBy] || '';
            }

            if (typeof aValue === 'string') {
                aValue = aValue.toLowerCase();
                bValue = bValue.toLowerCase();
            }

            if (aValue < bValue) return order === 'asc' ? -1 : 1;
            if (aValue > bValue) return order === 'asc' ? 1 : -1;
            return 0;
        });
        return sorted;
    }, [filteredUsers, orderBy, order]);

    const handleRestoreUser = async (userId) => {
        try {
            await userService.restoreUser(userId);
            showSnackbar({ type: 'success', message: t('user.msg.restored') });
            await fetchDeletedUsers();
            if (!showDeleted) await getUsers();
        } catch (error) {
            showSnackbar({ type: 'error', message: t('user.msg.restoreFailed') });
        }
    };

    const handleForceDelete = async (userId) => {
        try {
            await userService.forceDeleteUser(userId);
            showSnackbar({ type: 'success', message: t('user.msg.forceDeleted') });
            await fetchDeletedUsers();
        } catch (error) {
            showSnackbar({ type: 'error', message: t('user.msg.forceDeleteFailed') });
        }
    };

    const handleRequestSort = (property) => {
        const isAsc = orderBy === property && order === 'asc';
        setOrder(isAsc ? 'desc' : 'asc');
        setOrderBy(property);
    };

    const handleMenuOpen = (event, user) => {
        setSelectedUser(user);
        setActionMenu(event.currentTarget);
    };

    const handleMenuClose = () => setActionMenu(null);

    const openConfirmDialog = (title, message, actionFn) => {
        setConfirmDialog({ open: true, title, message, action: actionFn });
    };

    const handleAction = async (actionType) => {
        if (!selectedUser) return;
        handleMenuClose();

        if (showDeleted) {
            switch (actionType) {
                case 'restore':
                    openConfirmDialog(
                        t('user.confirm.restoreTitle'),
                        t('user.confirm.restoreMsg', { name: selectedUser.name }),
                        () => handleRestoreUser(selectedUser.id)
                    );
                    break;
                case 'force_delete':
                    openConfirmDialog(
                        t('user.confirm.forceDeleteTitle'),
                        t('user.confirm.forceDeleteMsg', { name: selectedUser.name }),
                        () => handleForceDelete(selectedUser.id)
                    );
                    break;
                default:
                    break;
            }
            return;
        }

        switch (actionType) {
            case 'edit':
                setEditingUser(selectedUser);
                setOpenModal(true);
                break;
            case 'activate':
                try {
                    await updateUser(selectedUser.id, { status: 'active' });
                    showSnackbar({ type: 'success', message: t('user.msg.activated') });
                    await getUsers();
                } catch (err) {
                    showSnackbar({ type: 'error', message: t('user.msg.activateFailed') });
                }
                break;
            case 'deactivate':
                openConfirmDialog(
                    t('user.confirm.deactivateTitle'),
                    t('user.confirm.deactivateMsg', { name: selectedUser.name }),
                    () => updateUser(selectedUser.id, { status: 'inactive' })
                );
                break;
            case 'suspend':
                openConfirmDialog(
                    t('user.confirm.suspendTitle'),
                    t('user.confirm.suspendMsg', { name: selectedUser.name }),
                    () => updateUser(selectedUser.id, { status: 'suspended' })
                );
                break;
            case 'delete':
                openConfirmDialog(
                    t('user.confirm.deleteTitle'),
                    t('user.confirm.deleteMsg', { name: selectedUser.name }),
                    () => deleteUser(selectedUser.id)
                );
                break;
            case 'reset_password':
                setPasswordDialog({
                    open: true,
                    userId: selectedUser.id,
                    userName: selectedUser.name,
                    password: '',
                    confirmPassword: '',
                    error: '',
                });
                break;
            case 'resend_otp':
                try {
                    await userService.resendOtp(selectedUser.id);
                    showSnackbar({ type: 'success', message: t('user.msg.otpSent') });
                } catch (err) {
                    showSnackbar({ type: 'error', message: t('user.msg.otpFailed') });
                }
                break;
            case 'verify_otp':
                setVerifyOtpDialog({
                    open: true,
                    userId: selectedUser.id,
                    userName: selectedUser.name,
                    otp: '',
                    error: '',
                });
                break;
            case 'mark_verified':
                openConfirmDialog(
                    t('user.confirm.markVerifiedTitle'),
                    t('user.confirm.markVerifiedMsg', { name: selectedUser.name }),
                    () => handleMarkVerified(selectedUser.id)
                );
                break;
            default:
                break;
        }
    };

    const handleMarkVerified = async (userId) => {
        try {
            await markUserVerified(userId);
            showSnackbar({ type: 'success', message: t('user.msg.verified') });
            await getUsers();
        } catch (err) {
            showSnackbar({
                type: 'error',
                message: err.response?.data?.message || t('user.msg.verifyFailed'),
            });
        }
    };

    const handleVerifyOtp = async () => {
        const { userId, otp } = verifyOtpDialog;

        if (!otp || otp.length !== 6) {
            setVerifyOtpDialog((prev) => ({ ...prev, error: t('user.msg.otpInvalid') }));
            return;
        }

        try {
            await verifyUserOtp(userId, otp);
            showSnackbar({ type: 'success', message: t('user.msg.verifySuccess') });
            setVerifyOtpDialog({ open: false, userId: null, userName: '', otp: '', error: '' });
            await getUsers();
        } catch (err) {
            const errorMessage = err.response?.data?.message || t('user.msg.verifyFailed');
            showSnackbar({ type: 'error', message: errorMessage });
            setVerifyOtpDialog((prev) => ({ ...prev, error: errorMessage }));
        }
    };

    const handleConfirm = async () => {
        if (!confirmDialog.action) return;
        const action = confirmDialog.action;
        setConfirmDialog((prev) => ({ ...prev, open: false }));

        try {
            await action();
            showSnackbar({ type: 'success', message: t('user.actionSuccess') });
            if (showDeleted) {
                await fetchDeletedUsers();
            } else {
                await getUsers();
            }
        } catch (err) {
            showSnackbar({ type: 'error', message: t('user.actionFailed') });
        }
    };

    const handlePasswordReset = async () => {
        const { userId, password, confirmPassword } = passwordDialog;

        if (!password || password.length < 8) {
            setPasswordDialog((prev) => ({ ...prev, error: t('user.msg.passwordShort') }));
            return;
        }
        if (password !== confirmPassword) {
            setPasswordDialog((prev) => ({ ...prev, error: t('user.msg.passwordMismatch') }));
            return;
        }

        try {
            await userService.resetUserPassword(userId, password);
            showSnackbar({ type: 'success', message: t('user.msg.passwordReset') });
            setPasswordDialog({
                open: false,
                userId: null,
                userName: '',
                password: '',
                confirmPassword: '',
                error: '',
            });
            await getUsers();
        } catch (err) {
            showSnackbar({ type: 'error', message: t('user.msg.passwordResetFailed') });
            setPasswordDialog((prev) => ({
                ...prev,
                error: err.message || t('user.msg.passwordResetFailed'),
            }));
        }
    };

    const formatDate = (dateStr) => {
        if (!dateStr) return '—';
        try {
            return new Date(dateStr).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
            });
        } catch {
            return '—';
        }
    };

    const getUserRoleName = (user) => {
        if (!user?.roles || !Array.isArray(user.roles) || user.roles.length === 0) {
            return t('user.role.user');
        }
        const role = user.roles[0];
        return role.display_name || role.name || t('user.role.user');
    };

    const getRoleIcon = (user) => {
        if (!user?.roles || !Array.isArray(user.roles) || user.roles.length === 0) {
            return <PeopleIcon fontSize="small" />;
        }
        const roleName = user.roles[0]?.name || '';
        switch (roleName) {
            case 'ADMINISTRATOR':
                return <AdminIcon fontSize="small" />;
            case 'MONITORING_OFFICER':
                return <SupportIcon fontSize="small" />;
            case 'FUNDI':
                return <HandymanIcon fontSize="small" />;
            default:
                return <PeopleIcon fontSize="small" />;
        }
    };

    const getStatusChip = (status) => {
        const s = statusStyles[status] || statusStyles.inactive;
        return (
            <Chip
                icon={s.icon}
                label={s.label}
                size="small"
                sx={{
                    backgroundColor: s.bg,
                    color: s.color,
                    fontWeight: 700,
                    border: `1.5px solid ${s.border}`,
                    height: 28,
                    '& .MuiChip-icon': { color: s.color },
                    '& .MuiChip-label': { px: 1 },
                }}
            />
        );
    };

    // ── Permission / Error states ───────────────────────────────────────────
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
                    }}
                >
                    <Typography color="error" fontWeight={600}>
                        {t('user.accessDenied')}
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
                        <Button color="inherit" size="small" onClick={() => { clearError(); getUsers(); }}>
                            {t('user.retry')}
                        </Button>
                    }
                    sx={{ borderRadius: 2 }}
                >
                    {error}
                </Alert>
            </Box>
        );
    }

    const currentData = showDeleted ? deletedUsers : sortedData;
    const isLoading = showDeleted ? loadingDeleted : loading;
    const totalCount = showDeleted ? trashedTotal : sortedData.length;

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
                {/* ── Header ──────────────────────────────────────────────── */}
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
                                {t('user.title')}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('user.subtitle')}
                            </Typography>
                        </Box>

                        <Stack direction="row" spacing={1.5} alignItems="center" justifyContent={{ xs: 'space-between', sm: 'flex-end' }}>
                            <FormControlLabel
                                control={
                                    <Switch
                                        checked={showDeleted}
                                        onChange={(e) => {
                                            setShowDeleted(e.target.checked);
                                            setPage(0);
                                        }}
                                        color="primary"
                                    />
                                }
                                label={
                                    <Typography variant="body2" fontWeight={600}>
                                        {t('user.showDeleted')}
                                    </Typography>
                                }
                            />

                            {canCreate && !showDeleted && (
                                <Button
                                    variant="contained"
                                    startIcon={<AddIcon />}
                                    onClick={() => {
                                        setEditingUser(null);
                                        setOpenModal(true);
                                    }}
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
                                    {t('user.add')}
                                </Button>
                            )}
                        </Stack>
                    </Stack>

                    {/* Filters */}
                    <Stack
                        direction={{ xs: 'column', sm: 'row' }}
                        spacing={1.5}
                        alignItems={{ xs: 'stretch', sm: 'center' }}
                        flexWrap="wrap"
                    >
                        <TextField
                            placeholder={t('user.searchPlaceholder')}
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

                        {!showDeleted && (
                            <>
                                <TextField
                                    select
                                    label={t('user.filter.status')}
                                    size="small"
                                    value={statusFilter}
                                    onChange={(e) => setStatusFilter(e.target.value)}
                                    sx={{
                                        minWidth: { xs: '100%', sm: 140 },
                                        '& .MuiOutlinedInput-root': {
                                            borderRadius: 2,
                                            bgcolor: 'action.hover',
                                            '& fieldset': { borderColor: 'transparent' },
                                            '&:hover fieldset': { borderColor: 'divider' },
                                        },
                                    }}
                                >
                                    <MenuItem value="">{t('user.filter.allStatuses')}</MenuItem>
                                    <MenuItem value="active">{t('user.status.active')}</MenuItem>
                                    <MenuItem value="inactive">{t('user.status.inactive')}</MenuItem>
                                    <MenuItem value="pending">{t('user.status.pending')}</MenuItem>
                                    <MenuItem value="suspended">{t('user.status.suspended')}</MenuItem>
                                </TextField>

                                <TextField
                                    select
                                    label={t('user.filter.role')}
                                    size="small"
                                    value={roleFilter}
                                    onChange={(e) => setRoleFilter(e.target.value)}
                                    sx={{
                                        minWidth: { xs: '100%', sm: 170 },
                                        '& .MuiOutlinedInput-root': {
                                            borderRadius: 2,
                                            bgcolor: 'action.hover',
                                            '& fieldset': { borderColor: 'transparent' },
                                            '&:hover fieldset': { borderColor: 'divider' },
                                        },
                                    }}
                                >
                                    <MenuItem value="">{t('user.filter.allRoles')}</MenuItem>
                                    <MenuItem value="ADMINISTRATOR">{t('user.role.admin')}</MenuItem>
                                    <MenuItem value="MANAGER">{t('user.role.manager')}</MenuItem>
                                    <MenuItem value="MONITORING_OFFICER">{t('user.role.monitoring')}</MenuItem>
                                    <MenuItem value="FUNDI">{t('user.role.fundi')}</MenuItem>
                                    <MenuItem value="CUSTOMER">{t('user.role.customer')}</MenuItem>
                                </TextField>
                            </>
                        )}

                        <Button
                            variant="outlined"
                            startIcon={<RefreshIcon />}
                            onClick={() => (showDeleted ? fetchDeletedUsers() : getUsers())}
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
                            {t('user.refresh')}
                        </Button>
                    </Stack>
                </Box>

                {/* ── Table (desktop) ─────────────────────────────────────── */}
                {showTableView ? (
                    <TableContainer>
                        <Table sx={{ minWidth: 960 }}>
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
                                        <TableCell key={cell.id} sx={{ whiteSpace: 'nowrap', width: cell.id === 'count' ? '50px' : 'auto' }}>
                                            {!cell.disableSort && !showDeleted ? (
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
                                {isLoading ? (
                                    <TableRow>
                                        <TableCell colSpan={headCells.length} align="center" sx={{ py: 8 }}>
                                            <CircularProgress size={36} thickness={4} />
                                        </TableCell>
                                    </TableRow>
                                ) : currentData.length === 0 ? (
                                    <TableRow>
                                        <TableCell colSpan={headCells.length} align="center" sx={{ py: 8 }}>
                                            <Typography color="text.secondary" fontWeight={500}>
                                                {showDeleted ? t('user.noDeletedFound') : t('user.noFound')}
                                            </Typography>
                                        </TableCell>
                                    </TableRow>
                                ) : (
                                    currentData.map((user, index) => {
                                        const isVerified = !!user.email_verified_at;
                                        const rowNumber = page * rowsPerPage + index + 1;

                                        return (
                                            <TableRow
                                                key={user.id}
                                                hover
                                                sx={{
                                                    '&:last-child td': { borderBottom: 0 },
                                                    transition: 'background-color 0.15s',
                                                }}
                                            >
                                                {/* Count/Row Number */}
                                                <TableCell sx={{ py: 2, color: 'text.secondary', fontWeight: 500, fontSize: '0.875rem' }}>
                                                    {rowNumber}
                                                </TableCell>

                                                {/* User */}
                                                <TableCell sx={{ py: 2 }}>
                                                    <Stack direction="row" spacing={1.5} alignItems="center">
                                                        <Avatar
                                                            sx={{
                                                                width: 40,
                                                                height: 40,
                                                                bgcolor: isVerified
                                                                    ? colors.salat || '#10b981'
                                                                    : '#64748b',
                                                                fontSize: 15,
                                                                fontWeight: 700,
                                                            }}
                                                        >
                                                            {user.name?.[0]?.toUpperCase() || 'U'}
                                                        </Avatar>
                                                        <Box>
                                                            <Typography variant="body2" fontWeight={600} color="text.primary">
                                                                {user.name}
                                                            </Typography>
                                                        </Box>
                                                    </Stack>
                                                </TableCell>

                                                {/* Email */}
                                                <TableCell>
                                                    <Typography variant="body2" fontWeight={500}>
                                                        {user.email}
                                                    </Typography>
                                                    {isVerified ? (
                                                        <Chip
                                                            label="Verified"
                                                            size="small"
                                                            icon={<VerifiedIcon sx={{ fontSize: 12 }} />}
                                                            sx={{
                                                                mt: 0.5,
                                                                height: 22,
                                                                fontWeight: 700,
                                                                bgcolor: '#d1fae5',
                                                                color: '#047857',
                                                                border: '1px solid #10b981',
                                                                '& .MuiChip-label': { fontSize: 11, px: 0.75 },
                                                                '& .MuiChip-icon': { color: '#047857' },
                                                            }}
                                                        />
                                                    ) : (
                                                        user.status !== 'deleted' && (
                                                            <Chip
                                                                label="Unverified"
                                                                size="small"
                                                                sx={{
                                                                    mt: 0.5,
                                                                    height: 22,
                                                                    fontWeight: 700,
                                                                    bgcolor: '#f3f4f6',
                                                                    color: '#4b5563',
                                                                    border: '1px solid #9ca3af',
                                                                    '& .MuiChip-label': { fontSize: 11, px: 0.75 },
                                                                }}
                                                            />
                                                        )
                                                    )}
                                                </TableCell>

                                                {/* Phone */}
                                                <TableCell>
                                                    <Typography variant="body2" fontWeight={500}>
                                                        {user.phone || '—'}
                                                    </Typography>
                                                </TableCell>

                                                {/* Role */}
                                                <TableCell>
                                                    <Chip
                                                        icon={getRoleIcon(user)}
                                                        label={getUserRoleName(user)}
                                                        size="small"
                                                        sx={{
                                                            fontWeight: 600,
                                                            bgcolor: 'action.hover',
                                                            color: 'text.primary',
                                                            border: '1px solid',
                                                            borderColor: 'divider',
                                                            height: 28,
                                                            '& .MuiChip-icon': { color: 'text.secondary' },
                                                        }}
                                                    />
                                                </TableCell>

                                                {/* Status */}
                                                <TableCell>
                                                    {showDeleted ? (
                                                        <Chip
                                                            label={t('user.status.deleted')}
                                                            size="small"
                                                            sx={{
                                                                fontWeight: 700,
                                                                bgcolor: '#fee2e2',
                                                                color: '#b91c1c',
                                                                border: '1.5px solid #ef4444',
                                                                height: 28,
                                                            }}
                                                        />
                                                    ) : (
                                                        getStatusChip(user.status)
                                                    )}
                                                </TableCell>

                                                {/* Created */}
                                                <TableCell>
                                                    <Typography variant="body2" fontWeight={500} color="text.secondary">
                                                        {formatDate(user.created_at)}
                                                    </Typography>
                                                </TableCell>

                                                {/* Actions */}
                                                <TableCell align="center">
                                                    <IconButton
                                                        size="small"
                                                        onClick={(e) => handleMenuOpen(e, user)}
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
                                        );
                                    })
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                ) : (
                    /* ── Mobile cards ────────────────────────────────────── */
                    <Box sx={{ p: { xs: 2, sm: 2.5 } }}>
                        {isLoading ? (
                            <Box display="flex" justifyContent="center" py={6}>
                                <CircularProgress size={36} thickness={4} />
                            </Box>
                        ) : currentData.length === 0 ? (
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
                                    {showDeleted ? t('user.noDeletedFound') : t('user.noFound')}
                                </Typography>
                            </Paper>
                        ) : (
                            <Stack spacing={2}>
                                {currentData.map((user, index) => {
                                    const isVerified = !!user.email_verified_at;
                                    const rowNumber = page * rowsPerPage + index + 1;

                                    return (
                                        <Card
                                            key={user.id}
                                            elevation={0}
                                            sx={{
                                                borderRadius: 3,
                                                border: '1px solid',
                                                borderColor: 'divider',
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
                                                    <Stack direction="row" spacing={1.5} alignItems="center">
                                                        <Box sx={{ position: 'relative' }}>
                                                            <Avatar
                                                                sx={{
                                                                    width: 44,
                                                                    height: 44,
                                                                    bgcolor: isVerified
                                                                        ? colors.salat || '#10b981'
                                                                        : '#64748b',
                                                                    fontSize: 16,
                                                                    fontWeight: 700,
                                                                }}
                                                            >
                                                                {user.name?.[0]?.toUpperCase() || 'U'}
                                                            </Avatar>
                                                            {/* Mobile Number Badge */}
                                                            <Box
                                                                sx={{
                                                                    position: 'absolute',
                                                                    top: -6,
                                                                    left: -6,
                                                                    bgcolor: 'background.paper',
                                                                    border: '1px solid',
                                                                    borderColor: 'divider',
                                                                    borderRadius: '50%',
                                                                    width: 22,
                                                                    height: 22,
                                                                    display: 'flex',
                                                                    alignItems: 'center',
                                                                    justifyContent: 'center',
                                                                    fontSize: '0.7rem',
                                                                    fontWeight: 700,
                                                                    color: 'text.secondary',
                                                                    zIndex: 1,
                                                                }}
                                                            >
                                                                {rowNumber}
                                                            </Box>
                                                        </Box>
                                                        <Box>
                                                            <Typography variant="body1" fontWeight={700}>
                                                                {user.name}
                                                            </Typography>
                                                        </Box>
                                                    </Stack>
                                                    <IconButton
                                                        size="small"
                                                        onClick={(e) => handleMenuOpen(e, user)}
                                                        sx={{ color: 'text.secondary' }}
                                                    >
                                                        <MoreVertIcon fontSize="small" />
                                                    </IconButton>
                                                </Stack>

                                                <Stack spacing={1} mb={1.5}>
                                                    <Stack direction="row" spacing={1} alignItems="center">
                                                        <EmailIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                                        <Typography variant="body2" fontWeight={500}>
                                                            {user.email}
                                                        </Typography>
                                                        {isVerified && (
                                                            <VerifiedIcon sx={{ fontSize: 16, color: '#10b981' }} />
                                                        )}
                                                    </Stack>

                                                    {user.phone && (
                                                        <Stack direction="row" spacing={1} alignItems="center">
                                                            <PhoneIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                                            <Typography variant="body2" fontWeight={500}>
                                                                {user.phone}
                                                            </Typography>
                                                        </Stack>
                                                    )}

                                                    <Stack direction="row" spacing={1} alignItems="center">
                                                        <WorkIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                                        <Chip
                                                            icon={getRoleIcon(user)}
                                                            label={getUserRoleName(user)}
                                                            size="small"
                                                            sx={{
                                                                fontWeight: 600,
                                                                bgcolor: 'action.hover',
                                                                border: '1px solid',
                                                                borderColor: 'divider',
                                                                height: 26,
                                                            }}
                                                        />
                                                    </Stack>
                                                </Stack>

                                                <Divider sx={{ my: 1.5 }} />

                                                <Stack
                                                    direction="row"
                                                    justifyContent="space-between"
                                                    alignItems="center"
                                                    flexWrap="wrap"
                                                    gap={1}
                                                >
                                                    <Stack direction="row" spacing={1} flexWrap="wrap">
                                                        {showDeleted ? (
                                                            <Chip
                                                                label={t('user.status.deleted')}
                                                                size="small"
                                                                sx={{
                                                                    fontWeight: 700,
                                                                    bgcolor: '#fee2e2',
                                                                    color: '#b91c1c',
                                                                    border: '1.5px solid #ef4444',
                                                                    height: 26,
                                                                }}
                                                            />
                                                        ) : (
                                                            getStatusChip(user.status)
                                                        )}
                                                    </Stack>
                                                    <Typography variant="caption" color="text.secondary" fontWeight={500}>
                                                        {t('user.joined')} {formatDate(user.created_at)}
                                                    </Typography>
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
                        rowsPerPageOptions={[5, 10, 25, 50]}
                        component="div"
                        count={totalCount}
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
                    sx: { borderRadius: 2, minWidth: 200, mt: 0.5 },
                }}
            >
                {(() => {
                    const menuItems = [];
                    if (showDeleted) {
                        if (canRestore) {
                            menuItems.push(
                                <MenuItem key="restore" onClick={() => handleAction('restore')} sx={{ fontWeight: 500 }}>
                                    <RestoreIcon sx={{ mr: 1.5, color: '#10b981', fontSize: 20 }} /> {t('user.action.restore')}
                                </MenuItem>
                            );
                        }
                        if (canDelete) {
                            menuItems.push(
                                <MenuItem
                                    key="force_delete"
                                    onClick={() => handleAction('force_delete')}
                                    sx={{ color: 'error.main', fontWeight: 500 }}
                                >
                                    <DeleteSweepIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('user.action.forceDelete')}
                                </MenuItem>
                            );
                        }
                    } else {
                        if (canEdit) {
                            menuItems.push(
                                <MenuItem key="edit" onClick={() => handleAction('edit')} sx={{ fontWeight: 500 }}>
                                    <EditIcon sx={{ mr: 1.5, fontSize: 20, color: colors.sea || '#0f766e' }} /> {t('user.action.edit')}
                                </MenuItem>
                            );
                        }
                        if (canActivate && selectedUser?.status !== 'active') {
                            menuItems.push(
                                <MenuItem key="activate" onClick={() => handleAction('activate')} sx={{ fontWeight: 500 }}>
                                    <VerifiedIcon sx={{ mr: 1.5, color: '#10b981', fontSize: 20 }} /> {t('user.action.activate')}
                                </MenuItem>
                            );
                        }
                        if (canDeactivate && selectedUser?.status === 'active') {
                            menuItems.push(
                                <MenuItem key="deactivate" onClick={() => handleAction('deactivate')} sx={{ fontWeight: 500 }}>
                                    <BlockIcon sx={{ mr: 1.5, color: '#f59e0b', fontSize: 20 }} /> {t('user.action.deactivate')}
                                </MenuItem>
                            );
                        }
                        if (canSuspend && selectedUser?.status !== 'suspended') {
                            menuItems.push(
                                <MenuItem key="suspend" onClick={() => handleAction('suspend')} sx={{ fontWeight: 500 }}>
                                    <LockOpenIcon sx={{ mr: 1.5, color: '#ef4444', fontSize: 20 }} /> {t('user.action.suspend')}
                                </MenuItem>
                            );
                        }
                        if (canResetPassword) {
                            menuItems.push(
                                <MenuItem key="reset_password" onClick={() => handleAction('reset_password')} sx={{ fontWeight: 500 }}>
                                    <VpnKeyIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('user.action.resetPassword')}
                                </MenuItem>
                            );
                        }
                        if (canVerify && !selectedUser?.email_verified_at && selectedUser?.status !== 'deleted') {
                            menuItems.push(
                                <MenuItem key="verify_otp" onClick={() => handleAction('verify_otp')} sx={{ fontWeight: 500 }}>
                                    <VerifiedIcon sx={{ mr: 1.5, color: '#10b981', fontSize: 20 }} /> {t('user.action.verifyOtp')}
                                </MenuItem>
                            );
                            menuItems.push(
                                <MenuItem key="mark_verified" onClick={() => handleAction('mark_verified')} sx={{ fontWeight: 500 }}>
                                    <VerifiedIcon sx={{ mr: 1.5, color: '#3b82f6', fontSize: 20 }} /> {t('user.action.markVerified')}
                                </MenuItem>
                            );
                        }
                        if (!selectedUser?.email_verified_at && selectedUser?.status !== 'deleted') {
                            menuItems.push(
                                <MenuItem key="resend_otp" onClick={() => handleAction('resend_otp')} sx={{ fontWeight: 500 }}>
                                    <EmailIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('user.action.resendOtp')}
                                </MenuItem>
                            );
                        }
                        if (canDelete) {
                            menuItems.push(
                                <MenuItem
                                    key="delete"
                                    onClick={() => handleAction('delete')}
                                    sx={{ color: 'error.main', fontWeight: 500 }}
                                >
                                    <DeleteIcon sx={{ mr: 1.5, fontSize: 20 }} /> {t('user.action.delete')}
                                </MenuItem>
                            );
                        }
                    }
                    return menuItems;
                })()}
            </Menu>

            {/* User Form Modal */}
            <UserFormModal
                open={openModal}
                onClose={() => {
                    setOpenModal(false);
                    setEditingUser(null);
                    getUsers();
                }}
                user={editingUser}
            />

            {/* Password Reset Dialog */}
            <Dialog
                open={passwordDialog.open}
                onClose={() =>
                    setPasswordDialog({
                        open: false,
                        userId: null,
                        userName: '',
                        password: '',
                        confirmPassword: '',
                        error: '',
                    })
                }
                maxWidth="xs"
                fullWidth
                PaperProps={{ sx: { borderRadius: 3 } }}
            >
                <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>
                    {t('user.pwd.title', { name: passwordDialog.userName })}
                </DialogTitle>
                <DialogContent>
                    <TextField
                        fullWidth
                        type="password"
                        label={t('user.pwd.new')}
                        value={passwordDialog.password}
                        onChange={(e) =>
                            setPasswordDialog((prev) => ({ ...prev, password: e.target.value, error: '' }))
                        }
                        margin="dense"
                        size="small"
                        error={!!passwordDialog.error}
                        helperText={passwordDialog.error}
                        sx={{
                            '& .MuiOutlinedInput-root': { borderRadius: 2 },
                        }}
                    />
                    <TextField
                        fullWidth
                        type="password"
                        label={t('user.pwd.confirm')}
                        value={passwordDialog.confirmPassword}
                        onChange={(e) =>
                            setPasswordDialog((prev) => ({
                                ...prev,
                                confirmPassword: e.target.value,
                                error: '',
                            }))
                        }
                        margin="dense"
                        size="small"
                        error={!!passwordDialog.error}
                        sx={{
                            '& .MuiOutlinedInput-root': { borderRadius: 2 },
                        }}
                    />
                </DialogContent>
                <DialogActions sx={{ px: 3, pb: 2.5, pt: 1 }}>
                    <Button
                        onClick={() =>
                            setPasswordDialog({
                                open: false,
                                userId: null,
                                userName: '',
                                password: '',
                                confirmPassword: '',
                                error: '',
                            })
                        }
                        sx={{ fontWeight: 600, textTransform: 'none' }}
                    >
                        {t('user.cancel')}
                    </Button>
                    <Button
                        onClick={handlePasswordReset}
                        variant="contained"
                        sx={{
                            fontWeight: 700,
                            textTransform: 'none',
                            borderRadius: 2,
                            bgcolor: colors.sea || '#0f766e',
                            '&:hover': { bgcolor: colors.dark || '#0d5c56' },
                        }}
                    >
                        {t('user.pwd.submit')}
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Verify OTP Dialog */}
            <Dialog
                open={verifyOtpDialog.open}
                onClose={() =>
                    setVerifyOtpDialog({ open: false, userId: null, userName: '', otp: '', error: '' })
                }
                maxWidth="xs"
                fullWidth
                PaperProps={{ sx: { borderRadius: 3 } }}
            >
                <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>
                    {t('user.otp.title', { name: verifyOtpDialog.userName })}
                </DialogTitle>
                <DialogContent>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                        {t('user.otp.hint')}
                    </Typography>
                    <TextField
                        fullWidth
                        type="text"
                        label={t('user.otp.label')}
                        value={verifyOtpDialog.otp}
                        onChange={(e) =>
                            setVerifyOtpDialog((prev) => ({
                                ...prev,
                                otp: e.target.value.replace(/\D/g, '').slice(0, 6),
                                error: '',
                            }))
                        }
                        margin="dense"
                        size="small"
                        placeholder={t('user.otp.placeholder')}
                        error={!!verifyOtpDialog.error}
                        helperText={verifyOtpDialog.error}
                        inputProps={{ maxLength: 6 }}
                        sx={{
                            '& .MuiOutlinedInput-root': { borderRadius: 2 },
                        }}
                    />
                </DialogContent>
                <DialogActions sx={{ px: 3, pb: 2.5, pt: 1 }}>
                    <Button
                        onClick={() =>
                            setVerifyOtpDialog({ open: false, userId: null, userName: '', otp: '', error: '' })
                        }
                        sx={{ fontWeight: 600, textTransform: 'none' }}
                    >
                        {t('user.cancel')}
                    </Button>
                    <Button
                        onClick={handleVerifyOtp}
                        variant="contained"
                        sx={{
                            fontWeight: 700,
                            textTransform: 'none',
                            borderRadius: 2,
                            bgcolor: colors.salat || '#10b981',
                            '&:hover': { bgcolor: colors.dark || '#047857' },
                        }}
                    >
                        {t('user.otp.submit')}
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Confirmation Dialog */}
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
                        {t('user.cancel')}
                    </Button>
                    <Button
                        onClick={handleConfirm}
                        variant="contained"
                        color="error"
                        sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}
                    >
                        {t('user.confirm')}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default UsersList;