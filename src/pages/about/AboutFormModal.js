// src/pages/about/AboutFormModal.js
import React, { useState, useEffect } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, TextField, Button,
    CircularProgress, useMediaQuery, useTheme, Typography, IconButton, Stack,
} from '@mui/material';
import { Close as CloseIcon } from '@mui/icons-material';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tAbout } from './aboutlang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function AboutFormModal({ open, onClose, aboutData, createAbout, updateAbout }) {
    const theme = useTheme();
    const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
    const { language } = useLanguage();
    const t = (key) => tAbout(language, key);

    const [loading, setLoading] = useState(false);
    const [form, setForm] = useState({ content: '' });
    const [errors, setErrors] = useState({});

    useEffect(() => {
        setForm({ content: aboutData?.content || '' });
        setErrors({});
    }, [aboutData, open]);

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
        if (errors[e.target.name]) setErrors({ ...errors, [e.target.name]: '' });
    };

    const validate = () => {
        const newErrors = {};
        if (!form.content.trim()) newErrors.content = t('about.modal.required');
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        setLoading(true);
        try {
            if (aboutData) {
                await updateAbout({ content: form.content });
                showSnackbar({ type: 'success', message: t('about.modal.updated') });
            } else {
                await createAbout({ content: form.content });
                showSnackbar({ type: 'success', message: t('about.modal.created') });
            }
            onClose(true);
        } catch (err) {
            showSnackbar({
                type: 'error',
                message: err.response?.data?.message || t('about.modal.failed'),
            });
        } finally {
            setLoading(false);
        }
    };

    return (
        <Dialog
            open={open}
            onClose={() => onClose(false)}
            maxWidth="md"
            fullWidth
            fullScreen={fullScreen}
            PaperProps={{
                sx: {
                    borderRadius: { xs: 0, sm: 3 },
                    border: '1px solid',
                    borderColor: 'divider',
                    bgcolor: 'background.paper', // ✅ Theme aware
                    margin: fullScreen ? 0 : 2,
                },
            }}
        >
            <form onSubmit={handleSubmit}>
                <DialogTitle
                    sx={{
                        pb: 1.5,
                        fontWeight: 700,
                        fontSize: { xs: '1.2rem', sm: '1.4rem' },
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        borderBottom: '1px solid',
                        borderColor: 'divider',
                        color: 'text.primary',
                    }}
                >
                    {aboutData ? t('about.modal.editTitle') : t('about.modal.createTitle')}
                    <IconButton
                        onClick={() => onClose(false)}
                        size="small"
                        sx={{ color: 'text.secondary', '&:hover': { bgcolor: 'action.hover' } }}
                    >
                        <CloseIcon />
                    </IconButton>
                </DialogTitle>

                <DialogContent sx={{ pt: 3, pb: 1 }}>
                    <Stack spacing={2.5}>
                        <Typography variant="body2" color="text.secondary">
                            {aboutData ? t('about.modal.editDesc') : t('about.modal.createDesc')}
                        </Typography>

                        <TextField
                            label={t('about.modal.content')}
                            name="content"
                            value={form.content}
                            onChange={handleChange}
                            required
                            fullWidth
                            multiline
                            rows={14}
                            error={!!errors.content}
                            helperText={errors.content}
                            placeholder={t('about.modal.placeholder')}
                            disabled={loading}
                            sx={{
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 2,
                                    fontFamily: 'inherit',
                                    fontSize: '1rem',
                                    lineHeight: 1.8,
                                    bgcolor: 'action.hover', // ✅ Theme aware
                                    '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: colors.sea },
                                    '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                        borderColor: colors.sea,
                                        borderWidth: 2,
                                    },
                                },
                                '& .MuiInputLabel-root': {
                                    color: 'text.secondary',
                                    '&.Mui-focused': { color: colors.sea },
                                },
                            }}
                        />
                    </Stack>
                </DialogContent>

                <DialogActions sx={{ p: { xs: 2, sm: 3 }, pt: 1, borderTop: '1px solid', borderColor: 'divider' }}>
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
                        {t('about.modal.cancel')}
                    </Button>
                    <Button
                        type="submit"
                        variant="contained"
                        disabled={loading}
                        sx={{
                            borderRadius: 2,
                            fontWeight: 700,
                            textTransform: 'none',
                            px: 3,
                            bgcolor: colors.sea || '#0f766e',
                            '&:hover': { bgcolor: colors.dark || '#0d5c56' },
                            '&:disabled': { opacity: 0.6 },
                        }}
                    >
                        {loading ? (
                            <CircularProgress size={24} color="inherit" />
                        ) : aboutData ? (
                            t('about.modal.update')
                        ) : (
                            t('about.modal.create')
                        )}
                    </Button>
                </DialogActions>
            </form>
        </Dialog>
    );
}