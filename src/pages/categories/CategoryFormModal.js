// src/pages/categories/CategoryFormModal.js
import React, { useState, useEffect } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, TextField,
    Button, CircularProgress, Stack, IconButton,
} from '@mui/material';
import { Close as CloseIcon } from '@mui/icons-material';
import { serviceService } from 'services/service.service';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tCategory } from './categorieslang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const CategoryFormModal = ({ open, onClose, category }) => {
    const { language } = useLanguage();
    const t = (key, replacements) => tCategory(language, key, replacements);

    const [form, setForm] = useState({ category_name: '', swahili_name: '', slug: '', description: '' });
    const [loading, setLoading] = useState(false);
    const [errors, setErrors] = useState({});

    useEffect(() => {
        if (category) {
            setForm({
                category_name: category.category_name || '',
                swahili_name: category.swahili_name || '',
                slug: category.slug || '',
                description: category.description || '',
            });
        } else {
            setForm({ category_name: '', swahili_name: '', slug: '', description: '' });
        }
        setErrors({});
    }, [category, open]);

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
        if (errors[e.target.name]) setErrors({ ...errors, [e.target.name]: '' });
    };

    const validate = () => {
        const newErrors = {};
        if (!form.category_name.trim()) newErrors.category_name = t('category.form.nameRequired');
        if (form.category_name.trim().length < 2) newErrors.category_name = t('category.form.nameTooShort');
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;
        setLoading(true);
        try {
            const payload = {
                category_name: form.category_name.trim(),
                swahili_name: form.swahili_name?.trim() || null,
                slug: form.slug?.trim() || null,
                description: form.description?.trim() || null,
            };
            if (category) {
                await serviceService.updateCategory(category.service_categoryID, payload);
                showSnackbar({ type: 'success', message: t('category.form.updated') });
            } else {
                await serviceService.createCategory(payload);
                showSnackbar({ type: 'success', message: t('category.form.created') });
            }
            onClose(true);
        } catch (err) {
            const msg = err.response?.data?.message || t('category.form.operationFailed');
            const errData = err.response?.data?.errors;
            if (errData) {
                const fieldErrors = {};
                Object.keys(errData).forEach(key => fieldErrors[key] = errData[key][0]);
                setErrors(fieldErrors);
            } else if (msg.toLowerCase().includes('already been taken') || msg.toLowerCase().includes('duplicate')) {
                setErrors({ category_name: t('category.form.nameDuplicate') });
            }
            showSnackbar({ type: 'error', message: msg });
        } finally {
            setLoading(false);
        }
    };

    const inputSx = {
        '& .MuiOutlinedInput-root': {
            borderRadius: 2,
            '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: colors.sea },
            '&.Mui-focused .MuiOutlinedInput-notchedOutline': { borderColor: colors.sea, borderWidth: 2 },
        },
    };

    return (
        <Dialog
            open={open}
            onClose={() => onClose(false)}
            maxWidth="sm" fullWidth
            PaperProps={{
                sx: {
                    borderRadius: 3,
                    border: '1px solid', borderColor: 'divider',
                    bgcolor: 'background.paper', // ✅ Theme aware
                },
            }}
        >
            <form onSubmit={handleSubmit}>
                <DialogTitle sx={{
                    pb: 1.5, fontWeight: 700, fontSize: '1.2rem',
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                    borderBottom: '1px solid', borderColor: 'divider', color: 'text.primary',
                }}>
                    {category ? t('category.form.editTitle') : t('category.form.createTitle')}
                    <IconButton
                        onClick={() => onClose(false)}
                        size="small"
                        sx={{
                            color: 'text.secondary',
                            '&:hover': { bgcolor: 'action.hover' },
                        }}
                    >
                        <CloseIcon />
                    </IconButton>
                </DialogTitle>

                <DialogContent sx={{ pt: 3, pb: 1 }}>
                    <Stack spacing={2.5}>
                        <TextField
                            label={t('category.form.nameEnLabel')}
                            name="category_name"
                            value={form.category_name}
                            onChange={handleChange}
                            required
                            error={!!errors.category_name}
                            helperText={errors.category_name}
                            fullWidth
                            autoFocus
                            disabled={loading}
                            sx={inputSx}
                        />

                        <TextField
                            label={t('category.form.nameSwLabel')}
                            name="swahili_name"
                            value={form.swahili_name}
                            onChange={handleChange}
                            fullWidth
                            disabled={loading}
                            placeholder={t('category.form.nameSwPlaceholder')}
                            sx={inputSx}
                        />

                        <TextField
                            label={t('category.form.slugLabel')}
                            name="slug"
                            value={form.slug}
                            onChange={handleChange}
                            helperText={t('category.form.slugHelper')}
                            fullWidth
                            disabled={loading}
                            placeholder={t('category.form.slugPlaceholder')}
                            sx={inputSx}
                        />

                        <TextField
                            label={t('category.form.descriptionLabel')}
                            name="description"
                            value={form.description}
                            onChange={handleChange}
                            multiline
                            rows={3}
                            fullWidth
                            disabled={loading}
                            placeholder={t('category.form.descriptionPlaceholder')}
                            sx={inputSx}
                        />
                    </Stack>
                </DialogContent>

                <DialogActions sx={{ p: { xs: 2, sm: 3 }, pt: 1, borderTop: '1px solid', borderColor: 'divider' }}>
                    <Button
                        onClick={() => onClose(false)}
                        disabled={loading}
                        sx={{
                            fontWeight: 600, textTransform: 'none',
                            color: 'text.secondary',
                            '&:hover': { bgcolor: 'action.hover' },
                        }}
                    >
                        {t('category.common.cancel')}
                    </Button>
                    <Button
                        type="submit"
                        variant="contained"
                        disabled={loading}
                        sx={{
                            borderRadius: 2, fontWeight: 700, textTransform: 'none', px: 3,
                            bgcolor: colors.sea || '#0f766e',
                            '&:hover': { bgcolor: colors.dark || '#0d5c56' },
                            '&:disabled': { opacity: 0.6 },
                        }}
                    >
                        {loading ? <CircularProgress size={24} color="inherit" /> :
                            (category ? t('category.common.update') : t('category.common.create'))}
                    </Button>
                </DialogActions>
            </form>
        </Dialog>
    );
};

export default CategoryFormModal;