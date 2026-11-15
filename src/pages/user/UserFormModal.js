// src/pages/users/UserFormModal.jsx
import React, { useState, useEffect } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, TextField, Button,
    MenuItem, Box, CircularProgress, useMediaQuery, useTheme, IconButton,
    Alert, Typography, Stack, Divider,
} from '@mui/material';
import { Close as CloseIcon } from '@mui/icons-material';
import { useUserManagement } from 'hooks/useUser';
import { useRoleManagement } from 'hooks/useRole';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tUser } from './userlang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function UserFormModal({ open, onClose, user }) {
    const theme = useTheme();
    const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
    const { language } = useLanguage();
    const t = (key) => tUser(language, key);

    const { createUser, updateUser } = useUserManagement();
    const { dropdownRoles = [], dropdownLoading, fetchDropdownRoles } = useRoleManagement();

    const [loading, setLoading] = useState(false);
    const [validationErrors, setValidationErrors] = useState({});
    const [form, setForm] = useState({
        name: '',
        email: '',
        phone: '',
        role: '',
        password: '',
        password_confirmation: '',
        status: 'active',
    });
    const [errors, setErrors] = useState({});

    useEffect(() => {
        if (open) {
            fetchDropdownRoles();
        }
    }, [open, fetchDropdownRoles]);

    useEffect(() => {
        if (user) {
            const userRole = user.roles?.[0]?.name || '';
            setForm({
                name: user.name || '',
                email: user.email || '',
                phone: user.phone || '',
                role: userRole,
                status: user.status || 'active',
                password: '',
                password_confirmation: '',
            });
        } else {
            setForm({
                name: '',
                email: '',
                phone: '',
                role: '',
                password: '',
                password_confirmation: '',
                status: 'active',
            });
        }
        setErrors({});
        setValidationErrors({});
    }, [user]);

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
        if (errors[e.target.name]) {
            setErrors({ ...errors, [e.target.name]: '' });
        }
        if (validationErrors[e.target.name]) {
            setValidationErrors({ ...validationErrors, [e.target.name]: '' });
        }
    };

    const validate = () => {
        const newErrors = {};

        if (!form.name.trim()) newErrors.name = t('user.form.nameRequired');
        if (!form.email.trim()) newErrors.email = t('user.form.emailRequired');
        if (!form.role) newErrors.role = t('user.form.roleRequired');

        if (!user) {
            if (!form.password) newErrors.password = t('user.form.passwordRequired');
            else if (form.password.length < 8) newErrors.password = t('user.msg.passwordShort');
            if (form.password !== form.password_confirmation) {
                newErrors.password_confirmation = t('user.msg.passwordMismatch');
            }
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        setLoading(true);
        setValidationErrors({});

        try {
            if (user) {
                await updateUser(user.id, {
                    name: form.name,
                    email: form.email,
                    phone: form.phone || null,
                    status: form.status,
                    role: form.role,
                });
                showSnackbar({ type: 'success', message: t('user.form.updated') });
                onClose(true);
            } else {
                await createUser({
                    name: form.name,
                    email: form.email,
                    phone: form.phone || null,
                    role: form.role,
                    password: form.password,
                    password_confirmation: form.password_confirmation,
                });
                showSnackbar({ type: 'success', message: t('user.form.created') });
                onClose(true);
            }
        } catch (err) {
            if (err.response?.data?.errors) {
                setValidationErrors(err.response.data.errors);
                showSnackbar({ type: 'error', message: t('user.form.checkErrors') });
            } else {
                showSnackbar({ type: 'error', message: err.message || t('user.form.failed') });
            }
        } finally {
            setLoading(false);
        }
    };

    const isFormLoading = loading || dropdownLoading;

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
                    bgcolor: 'background.paper',
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
                            {user ? t('user.form.editTitle') : t('user.form.createTitle')}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" fontWeight={500} sx={{ mt: 0.25 }}>
                            {user ? t('user.form.editDesc') : t('user.form.createDesc')}
                        </Typography>
                    </Box>
                    <IconButton
                        onClick={() => onClose(false)}
                        size="small"
                        disabled={isFormLoading}
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
                        {Object.keys(validationErrors).length > 0 && (
                            <Alert severity="error" variant="filled" sx={{ borderRadius: 2, fontWeight: 500 }}>
                                {Object.values(validationErrors)
                                    .flat()
                                    .map((msg, idx) => (
                                        <div key={idx}>{msg}</div>
                                    ))}
                            </Alert>
                        )}

                        <TextField
                            label={t('user.form.name')}
                            name="name"
                            value={form.name}
                            onChange={handleChange}
                            required
                            fullWidth
                            size="small"
                            error={!!errors.name || !!validationErrors.name}
                            helperText={errors.name || validationErrors.name?.[0] || ''}
                            disabled={isFormLoading}
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
                            label={t('user.form.email')}
                            name="email"
                            type="email"
                            value={form.email}
                            onChange={handleChange}
                            required
                            fullWidth
                            disabled={!!user || isFormLoading}
                            size="small"
                            error={!!errors.email || !!validationErrors.email}
                            helperText={
                                errors.email ||
                                validationErrors.email?.[0] ||
                                (user ? t('user.form.emailLocked') : '')
                            }
                            sx={{
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 2,
                                    bgcolor: user ? 'action.disabledBackground' : 'action.hover',
                                    '& fieldset': { borderColor: 'transparent' },
                                    '&:hover fieldset': { borderColor: user ? 'transparent' : 'divider' },
                                    '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                                },
                            }}
                        />

                        <TextField
                            label={t('user.form.phone')}
                            name="phone"
                            value={form.phone}
                            onChange={handleChange}
                            fullWidth
                            size="small"
                            disabled={isFormLoading}
                            error={!!validationErrors.phone}
                            helperText={validationErrors.phone?.[0] || t('user.form.phoneOptional')}
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
                            select
                            label={t('user.form.role')}
                            name="role"
                            value={form.role}
                            onChange={handleChange}
                            required
                            fullWidth
                            disabled={isFormLoading}
                            size="small"
                            error={!!errors.role || !!validationErrors.role}
                            helperText={errors.role || validationErrors.role?.[0] || ''}
                            sx={{
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 2,
                                    bgcolor: 'action.hover',
                                    '& fieldset': { borderColor: 'transparent' },
                                    '&:hover fieldset': { borderColor: 'divider' },
                                    '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                                },
                            }}
                        >
                            <MenuItem value="" disabled>
                                {dropdownLoading ? t('user.form.loadingRoles') : t('user.form.selectRole')}
                            </MenuItem>
                            {Array.isArray(dropdownRoles) && dropdownRoles.length > 0 ? (
                                dropdownRoles.map((role) => (
                                    <MenuItem key={role.id} value={role.name}>
                                        {role.display_name || role.name}
                                    </MenuItem>
                                ))
                            ) : (
                                !dropdownLoading && <MenuItem disabled>{t('user.form.noRoles')}</MenuItem>
                            )}
                        </TextField>

                        {!user && (
                            <>
                                <TextField
                                    label={t('user.form.password')}
                                    name="password"
                                    type="password"
                                    value={form.password}
                                    onChange={handleChange}
                                    required
                                    fullWidth
                                    size="small"
                                    error={!!errors.password || !!validationErrors.password}
                                    helperText={
                                        errors.password ||
                                        validationErrors.password?.[0] ||
                                        t('user.form.passwordMin')
                                    }
                                    disabled={isFormLoading}
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
                                    label={t('user.form.confirmPassword')}
                                    name="password_confirmation"
                                    type="password"
                                    value={form.password_confirmation}
                                    onChange={handleChange}
                                    required
                                    fullWidth
                                    size="small"
                                    error={
                                        !!errors.password_confirmation ||
                                        !!validationErrors.password_confirmation
                                    }
                                    helperText={
                                        errors.password_confirmation ||
                                        validationErrors.password_confirmation?.[0] ||
                                        ''
                                    }
                                    disabled={isFormLoading}
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
                            </>
                        )}

                        {user && (
                            <TextField
                                select
                                label={t('user.form.status')}
                                name="status"
                                value={form.status}
                                onChange={handleChange}
                                fullWidth
                                size="small"
                                disabled={isFormLoading}
                                sx={{
                                    '& .MuiOutlinedInput-root': {
                                        borderRadius: 2,
                                        bgcolor: 'action.hover',
                                        '& fieldset': { borderColor: 'transparent' },
                                        '&:hover fieldset': { borderColor: 'divider' },
                                        '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                                    },
                                }}
                            >
                                <MenuItem value="active">{t('user.status.active')}</MenuItem>
                                <MenuItem value="inactive">{t('user.status.inactive')}</MenuItem>
                                <MenuItem value="pending">{t('user.status.pending')}</MenuItem>
                                <MenuItem value="suspended">{t('user.status.suspended')}</MenuItem>
                            </TextField>
                        )}
                    </Stack>
                </DialogContent>

                <Divider />

                <DialogActions sx={{ px: { xs: 2.5, sm: 3 }, py: 2, gap: 1.5 }}>
                    <Button
                        onClick={() => onClose(false)}
                        disabled={isFormLoading}
                        sx={{
                            fontWeight: 600,
                            textTransform: 'none',
                            color: 'text.secondary',
                            '&:hover': { bgcolor: 'action.hover' },
                        }}
                    >
                        {t('user.cancel')}
                    </Button>
                    <Button
                        type="submit"
                        variant="contained"
                        disabled={isFormLoading}
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
                            '&.Mui-disabled': {
                                bgcolor: 'action.disabledBackground',
                            },
                        }}
                    >
                        {loading ? (
                            <CircularProgress size={22} thickness={4} sx={{ color: '#fff' }} />
                        ) : user ? (
                            t('user.form.update')
                        ) : (
                            t('user.form.create')
                        )}
                    </Button>
                </DialogActions>
            </form>
        </Dialog>
    );
}