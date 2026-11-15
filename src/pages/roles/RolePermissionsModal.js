// src/pages/roles/RolePermissionsModal.js
import React, { useState, useEffect } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, Button, Box,
    CircularProgress, Checkbox, FormControlLabel, Typography, Divider,
    TextField, InputAdornment, Accordion, AccordionSummary, AccordionDetails,
    useMediaQuery, useTheme, IconButton, Stack,
} from '@mui/material';
import {
    Search as SearchIcon, ExpandMore as ExpandMoreIcon, Close as CloseIcon, Clear as ClearIcon,
} from '@mui/icons-material';
import { roleService } from 'services/role.service';
import { permissionService } from 'services/permission.service';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tRole } from './rolelang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const getGroupName = (permName) => {
    const parts = permName.split(/[._-]/);
    return parts[0] || 'other';
};

const groupPermissions = (permissions) => {
    const groups = {};
    permissions.forEach((perm) => {
        const group = getGroupName(perm.name);
        if (!groups[group]) groups[group] = [];
        groups[group].push(perm);
    });
    return Object.keys(groups)
        .sort()
        .reduce((acc, key) => {
            acc[key] = groups[key];
            return acc;
        }, {});
};

export default function RolePermissionsModal({ open, onClose, role }) {
    const theme = useTheme();
    const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
    const { language } = useLanguage();
    const t = (key) => tRole(language, key);

    const [loading, setLoading] = useState(false);
    const [allPermissions, setAllPermissions] = useState([]);
    const [selectedPermissionIds, setSelectedPermissionIds] = useState([]);
    const [search, setSearch] = useState('');

    useEffect(() => {
        if (open && role) {
            loadData();
        }
    }, [open, role]);

    const loadData = async () => {
        setLoading(true);
        try {
            const permRes = await permissionService.getPermissions({ per_page: 1000 });
            const all = permRes.data?.status === 'success' ? permRes.data.data.data : [];
            setAllPermissions(all);

            const rolePermRes = await roleService.getRolePermissions(role.id);
            const current = rolePermRes.data?.status === 'success' ? rolePermRes.data.data : [];
            const currentIds = current.map((p) => p.id);
            setSelectedPermissionIds(currentIds);
        } catch (err) {
            console.error(err);
            showSnackbar({ type: 'error', message: t('role.perm.loadFailed') });
        } finally {
            setLoading(false);
        }
    };

    const handleToggle = (permId) => {
        setSelectedPermissionIds((prev) =>
            prev.includes(permId) ? prev.filter((id) => id !== permId) : [...prev, permId]
        );
    };

    const handleSave = async () => {
        setLoading(true);
        try {
            await roleService.assignPermissionsToRole(role.id, selectedPermissionIds);
            showSnackbar({ type: 'success', message: t('role.perm.updated') });
            onClose();
        } catch (err) {
            showSnackbar({ type: 'error', message: t('role.perm.failed') });
        } finally {
            setLoading(false);
        }
    };

    const filteredPermissions = allPermissions.filter(
        (p) =>
            p.name.toLowerCase().includes(search.toLowerCase()) ||
            (p.display_name && p.display_name.toLowerCase().includes(search.toLowerCase()))
    );

    const groupedPermissions = groupPermissions(filteredPermissions);

    return (
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth="md"
            fullWidth
            fullScreen={fullScreen}
            PaperProps={{
                sx: {
                    borderRadius: { xs: 0, sm: 3 },
                    bgcolor: 'background.paper', // ✅ Theme aware
                },
            }}
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
                    <Typography variant="h6" fontWeight={800} color="text.primary">
                        {t('role.perm.title')}
                    </Typography>
                    <Typography variant="body2" color="text.secondary" fontWeight={500} sx={{ mt: 0.25 }}>
                        {t('role.perm.roleLabel')}: <strong>{role?.display_name || role?.name}</strong>
                    </Typography>
                </Box>
                <IconButton
                    onClick={onClose}
                    size="small"
                    disabled={loading}
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
                <TextField
                    placeholder={t('role.perm.search')}
                    size="small"
                    fullWidth
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
                        mb: 2.5,
                        '& .MuiOutlinedInput-root': {
                            borderRadius: 2,
                            bgcolor: 'action.hover',
                            '& fieldset': { borderColor: 'transparent' },
                            '&:hover fieldset': { borderColor: 'divider' },
                            '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                        },
                    }}
                />

                {loading ? (
                    <Box display="flex" justifyContent="center" py={6}>
                        <CircularProgress size={36} thickness={4} />
                    </Box>
                ) : (
                    <Box sx={{ maxHeight: { xs: '55vh', sm: 460 }, overflowY: 'auto', pr: 0.5 }}>
                        {Object.keys(groupedPermissions).length === 0 ? (
                            <Typography
                                sx={{ textAlign: 'center', py: 4, color: 'text.secondary', fontWeight: 500 }}
                            >
                                {t('role.perm.noFound')}
                            </Typography>
                        ) : (
                            <Stack spacing={1.25}>
                                {Object.entries(groupedPermissions).map(([groupName, perms]) => (
                                    <Accordion
                                        key={groupName}
                                        defaultExpanded
                                        disableGutters
                                        elevation={0}
                                        sx={{
                                            border: '1px solid',
                                            borderColor: 'divider',
                                            borderRadius: '12px !important',
                                            overflow: 'hidden',
                                            bgcolor: 'background.paper', // ✅ Theme aware
                                            '&:before': { display: 'none' },
                                        }}
                                    >
                                        <AccordionSummary
                                            expandIcon={<ExpandMoreIcon />}
                                            sx={{
                                                px: 2,
                                                bgcolor: 'action.hover',
                                                minHeight: 48,
                                                '& .MuiAccordionSummary-content': { my: 1 },
                                            }}
                                        >
                                            <Typography variant="subtitle2" fontWeight={700}>
                                                {groupName.charAt(0).toUpperCase() + groupName.slice(1)}
                                                <Typography
                                                    component="span"
                                                    variant="caption"
                                                    color="text.secondary"
                                                    sx={{ ml: 1, fontWeight: 600 }}
                                                >
                                                    ({perms.length})
                                                </Typography>
                                            </Typography>
                                        </AccordionSummary>
                                        <AccordionDetails sx={{ px: 2, pt: 1, pb: 1.5 }}>
                                            <Stack spacing={0.25}>
                                                {perms.map((perm) => (
                                                    <FormControlLabel
                                                        key={perm.id}
                                                        control={
                                                            <Checkbox
                                                                checked={selectedPermissionIds.includes(perm.id)}
                                                                onChange={() => handleToggle(perm.id)}
                                                                size="small"
                                                                sx={{
                                                                    color: 'text.secondary',
                                                                    '&.Mui-checked': {
                                                                        color: colors.sea || '#0f766e',
                                                                    },
                                                                }}
                                                            />
                                                        }
                                                        label={
                                                            <Box>
                                                                <Typography variant="body2" fontWeight={500}>
                                                                    {perm.display_name || perm.name}
                                                                </Typography>
                                                                <Typography
                                                                    variant="caption"
                                                                    color="text.secondary"
                                                                    sx={{ display: 'block' }}
                                                                >
                                                                    {perm.name}
                                                                </Typography>
                                                            </Box>
                                                        }
                                                        sx={{
                                                            alignItems: 'flex-start',
                                                            m: 0,
                                                            py: 0.5,
                                                            '& .MuiFormControlLabel-label': { width: '100%' },
                                                        }}
                                                    />
                                                ))}
                                            </Stack>
                                        </AccordionDetails>
                                    </Accordion>
                                ))}
                            </Stack>
                        )}
                    </Box>
                )}
            </DialogContent>

            <Divider />

            <DialogActions sx={{ px: { xs: 2.5, sm: 3 }, py: 2, gap: 1.5 }}>
                <Button
                    onClick={onClose}
                    disabled={loading}
                    sx={{
                        fontWeight: 600,
                        textTransform: 'none',
                        color: 'text.secondary',
                        '&:hover': { bgcolor: 'action.hover' },
                    }}
                >
                    {t('role.cancel')}
                </Button>
                <Button
                    onClick={handleSave}
                    variant="contained"
                    disabled={loading}
                    sx={{
                        minWidth: 130,
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
                    {loading ? (
                        <CircularProgress size={22} thickness={4} sx={{ color: '#fff' }} />
                    ) : (
                        t('role.perm.save')
                    )}
                </Button>
            </DialogActions>
        </Dialog>
    );
}