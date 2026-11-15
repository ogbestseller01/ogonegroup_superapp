// src/pages/services/ServiceFormModal.js
import React, { useState, useEffect } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, TextField, Button,
    Box, CircularProgress, useMediaQuery, useTheme, IconButton, FormControl,
    InputLabel, Select, MenuItem, Chip, OutlinedInput, Stack, alpha,
} from '@mui/material';
import { Close as CloseIcon } from '@mui/icons-material';
import { useServiceManagement } from 'hooks/useService';
import { serviceService } from 'services/service.service';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tService } from './serviceslang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function ServiceFormModal({ open, onClose, service }) {
    const theme = useTheme();
    const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));

    const { language } = useLanguage();
    const t = (key, replacements) => tService(language, key, replacements);

    const { createService, updateService } = useServiceManagement();
    const [loading, setLoading] = useState(false);
    const [categories, setCategories] = useState([]);
    const [loadingCategories, setLoadingCategories] = useState(false);

    const [form, setForm] = useState({ name: '', swahili_name: '' });
    const [selectedCategoryIds, setSelectedCategoryIds] = useState([]);
    const [errors, setErrors] = useState({});

    useEffect(() => {
        if (open) loadCategories();
    }, [open]);

    const loadCategories = async () => {
        setLoadingCategories(true);
        try {
            const response = await serviceService.getCategories({ per_page: 100 });
            if (response?.data?.status === 'success') {
                const data = response.data.data;
                setCategories(data.data || []);
            }
        } catch (err) {
            console.error('Failed to load categories:', err);
        } finally {
            setLoadingCategories(false);
        }
    };

    useEffect(() => {
        if (service) {
            const swahili = service.swahili_name || service.name_sw || '';
            setForm({
                name: service.name || '',
                swahili_name: swahili,
            });
            setSelectedCategoryIds(service.category_ids || []);
        } else {
            setForm({ name: '', swahili_name: '' });
            setSelectedCategoryIds([]);
        }
        setErrors({});
    }, [service]);

    const handleChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
        if (errors[e.target.name]) setErrors({ ...errors, [e.target.name]: '' });
    };

    const handleCategoryChange = (event) => {
        setSelectedCategoryIds(event.target.value);
    };

    const validate = () => {
        const newErrors = {};
        if (!form.name.trim()) {
            newErrors.name = t('service.form.nameRequired');
        } else if (form.name.trim().length < 3) {
            newErrors.name = t('service.form.nameTooShort');
        }
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        setLoading(true);
        try {
            const payload = {
                name: form.name.trim(),
                swahili_name: form.swahili_name?.trim() || null,
                category_ids: selectedCategoryIds,
            };

            if (service) {
                await updateService(service.id, payload);
                showSnackbar({ type: 'success', message: t('service.form.updated') });
            } else {
                await createService(payload);
                showSnackbar({ type: 'success', message: t('service.form.created') });
            }
            onClose(true);
        } catch (err) {
            console.error('Submit error:', err);
            const errorMessage = err.response?.data?.message || t('service.form.operationFailed');
            const errorData = err.response?.data?.errors;

            if (errorData) {
                const fieldErrors = {};
                Object.keys(errorData).forEach(key => {
                    fieldErrors[key] = errorData[key][0];
                });
                setErrors(fieldErrors);
            } else if (errorMessage.toLowerCase().includes('already been taken') ||
                errorMessage.toLowerCase().includes('duplicate') ||
                errorMessage.toLowerCase().includes('unique')) {
                setErrors({ name: t('service.form.nameDuplicate') });
            }

            showSnackbar({ type: 'error', message: errorMessage });
        } finally {
            setLoading(false);
        }
    };

    return (
        <Dialog
            open={open}
            onClose={() => onClose(false)}
            maxWidth="sm" fullWidth fullScreen={fullScreen}
            PaperProps={{
                sx: {
                    borderRadius: { xs: 0, sm: 3 },
                    border: '1px solid', borderColor: 'divider',
                    bgcolor: 'background.paper', // ✅ Theme aware
                },
            }}
        >
            <form onSubmit={handleSubmit}>
                <DialogTitle sx={{
                    pb: 1.5, fontWeight: 700,
                    fontSize: { xs: '1.2rem', sm: '1.4rem' },
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                    borderBottom: '1px solid', borderColor: 'divider',
                    color: 'text.primary',
                }}>
                    {service ? t('service.form.editTitle') : t('service.form.createTitle')}
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
                            label={t('service.form.nameEnLabel')}
                            name="name"
                            value={form.name}
                            onChange={handleChange}
                            required fullWidth
                            error={!!errors.name}
                            helperText={errors.name || t('service.form.nameEnHelper')}
                            disabled={loading}
                            placeholder={t('service.form.nameEnPlaceholder')}
                            autoFocus
                            sx={{
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 2,
                                    '&:hover .MuiOutlinedInput-notchedOutline': {
                                        borderColor: colors.sea,
                                    },
                                    '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                        borderColor: colors.sea,
                                        borderWidth: 2,
                                    },
                                },
                            }}
                        />

                        <TextField
                            label={t('service.form.nameSwLabel')}
                            name="swahili_name"
                            value={form.swahili_name}
                            onChange={handleChange}
                            fullWidth
                            disabled={loading}
                            placeholder={t('service.form.nameSwPlaceholder')}
                            sx={{
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 2,
                                    '&:hover .MuiOutlinedInput-notchedOutline': {
                                        borderColor: colors.sea,
                                    },
                                    '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                        borderColor: colors.sea,
                                        borderWidth: 2,
                                    },
                                },
                            }}
                        />

                        <FormControl fullWidth disabled={loadingCategories}>
                            <InputLabel sx={{ '&.Mui-focused': { color: colors.sea } }}>
                                {t('service.form.categoriesLabel')}
                            </InputLabel>
                            <Select
                                multiple
                                value={selectedCategoryIds}
                                onChange={handleCategoryChange}
                                input={<OutlinedInput label={t('service.form.categoriesLabel')} />}
                                renderValue={(selected) => (
                                    <Box display="flex" flexWrap="wrap" gap={0.5}>
                                        {selected.map((id) => {
                                            const cat = categories.find(c => c.service_categoryID === id);
                                            return (
                                                <Chip
                                                    key={id}
                                                    label={cat?.category_name || id}
                                                    size="small"
                                                    sx={{
                                                        fontWeight: 600,
                                                        bgcolor: alpha(colors.sea, 0.08),
                                                        color: colors.sea,
                                                    }}
                                                />
                                            );
                                        })}
                                    </Box>
                                )}
                                sx={{
                                    borderRadius: 2,
                                    '&:hover .MuiOutlinedInput-notchedOutline': {
                                        borderColor: colors.sea,
                                    },
                                    '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                        borderColor: colors.sea,
                                        borderWidth: 2,
                                    },
                                }}
                            >
                                {categories.map((cat) => (
                                    <MenuItem
                                        key={cat.service_categoryID}
                                        value={cat.service_categoryID}
                                        sx={{
                                            '&.Mui-selected': { bgcolor: alpha(colors.sea, 0.08) },
                                            '&.Mui-selected:hover': { bgcolor: alpha(colors.sea, 0.12) },
                                        }}
                                    >
                                        {cat.category_name}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>
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
                        {t('service.common.cancel')}
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
                            (service ? t('service.common.update') : t('service.common.create'))}
                    </Button>
                </DialogActions>
            </form>
        </Dialog>
    );
}