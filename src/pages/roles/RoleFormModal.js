// src/pages/roles/RoleFormModal.js
import React, { useState, useEffect } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, TextField, Button,
    Box, CircularProgress, useMediaQuery, useTheme, Typography, IconButton, Stack, Divider,
} from '@mui/material';
import { Close as CloseIcon } from '@mui/icons-material';
import { useRoleManagement } from 'hooks/useRole';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tRole } from './rolelang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function RoleFormModal({ open, onClose, role }) {
    const theme = useTheme();
    const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
    const { language } = useLanguage();
    const t = (key) => tRole(language, key);

    const { createRole, updateRole } = useRoleManagement();
    const [loading, setLoading] = useState(false);
    const [form, setForm] = useState({
        name: '',
        display_name: '',
        description: '',
        guard_name: 'web',
    });

    useEffect(() => {
        if (role) {
            setForm({
                name: role.name || '',
                display_name: role.display_name || '',
                description: role.description || '',
                guard_name: role.guard_name || 'web',
            });
        } else {
            setForm({
                name: '',
                display_name: '',
                description: '',
                guard_name: 'web',
            });
        }
    }, [role, open]);

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        try {
            if (role) {
                await updateRole(role.id, form);
                showSnackbar({ type: 'success', message: t('role.modal.updated') });
            } else {
                await createRole(form);
                showSnackbar({ type: 'success', message: t('role.modal.created') });
            }
            onClose(true);
        } catch (err) {
            showSnackbar({
                type: 'error',
                message: err.response?.data?.message || t('role.modal.failed'),
            });
        } finally {
            setLoading(false);
        }
    };

    return (
        <Dialog
            open={open}
            onClose={() => onClose(false)}
            maxWidth="sm"
            fullWidth
            fullScreen={fullScreen}
            PaperProps={{
                sx: {
                    borderRadius: { xs: 0, sm: 3 },
                    bgcolor: 'background.paper', // ✅ Theme aware
                },
            }}
        >
            <form onSubmit={handleSubmit}>
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
                            {role ? t('role.modal.editTitle') : t('role.modal.createTitle')}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" fontWeight={500} sx={{ mt: 0.25 }}>
                            {role ? t('role.modal.editDesc') : t('role.modal.createDesc')}
                        </Typography>
                    </Box>
                    <IconButton
                        onClick={() => onClose(false)}
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
                    <Stack spacing={2.25}>
                        <TextField
                            label={t('role.modal.name')}
                            name="name"
                            value={form.name}
                            onChange={handleChange}
                            required
                            fullWidth
                            size="small"
                            helperText={t('role.modal.nameHelp')}
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

                        <TextField
                            label={t('role.modal.displayName')}
                            name="display_name"
                            value={form.display_name}
                            onChange={handleChange}
                            required
                            fullWidth
                            size="small"
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

                        <TextField
                            label={t('role.modal.description')}
                            name="description"
                            value={form.description}
                            onChange={handleChange}
                            multiline
                            rows={2}
                            fullWidth
                            size="small"
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

                        <TextField
                            label={t('role.modal.guard')}
                            name="guard_name"
                            value={form.guard_name}
                            onChange={handleChange}
                            required
                            fullWidth
                            size="small"
                            helperText={t('role.modal.guardHelp')}
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
                    </Stack>
                </DialogContent>

                <Divider />

                <DialogActions sx={{ px: { xs: 2.5, sm: 3 }, py: 2, gap: 1.5 }}>
                    <Button
                        onClick={() => onClose(false)}
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
                        type="submit"
                        variant="contained"
                        disabled={loading}
                        sx={{
                            minWidth: 110,
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
                        ) : role ? (
                            t('role.modal.update')
                        ) : (
                            t('role.modal.create')
                        )}
                    </Button>
                </DialogActions>
            </form>
        </Dialog>
    );
}