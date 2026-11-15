import React, { useState, useEffect, useRef } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions,
    TextField, MenuItem, Button, CircularProgress, Stack,
    IconButton, Box, Typography,
} from '@mui/material';
import {
    Close as CloseIcon,
    CloudUpload as UploadIcon,
    Image as ImageIcon,
} from '@mui/icons-material';
import { useBannerManagement } from 'hooks/useBanner';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tBanner } from './bannerLang';
import { BANNER_TYPES } from './bannerHelpers';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const emptyForm = {
    title: '',
    type: 'hero',
    link: '',
    status: 'active',
    starts_at: '',
    expires_at: '',
    sort_order: 0,
    image: null,
};

const ACCEPTED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml', 'image/bmp'];
const MAX_SIZE_MB = 5;

const BannerFormModal = ({ open, onClose, banner }) => {
    const { language } = useLanguage();
    const t = (key, r) => tBanner(language, key, r);
    const { createBanner, updateBanner } = useBannerManagement();

    const isEdit = !!banner;
    const [form, setForm] = useState(emptyForm);
    const [preview, setPreview] = useState(null);
    const [loading, setLoading] = useState(false);
    const [errors, setErrors] = useState({});
    const [isDragging, setIsDragging] = useState(false);

    const fileInputRef = useRef(null);
    const dragCounter = useRef(0); // helps with nested drag events

    useEffect(() => {
        if (banner) {
            setForm({
                title: banner.title || '',
                type: banner.type || 'hero',
                link: banner.link || '',
                status: banner.status || 'active',
                starts_at: banner.starts_at ? banner.starts_at.slice(0, 16) : '',
                expires_at: banner.expires_at ? banner.expires_at.slice(0, 16) : '',
                sort_order: banner.sort_order ?? 0,
                image: null,
            });
            setPreview(banner.image || null);
        } else {
            setForm(emptyForm);
            setPreview(null);
        }
        setErrors({});
        setIsDragging(false);
        dragCounter.current = 0;
    }, [banner, open]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setForm((f) => ({ ...f, [name]: value }));
        if (errors[name]) setErrors((er) => ({ ...er, [name]: '' }));
    };

    // Validate + set file
    const processFile = (file) => {
        if (!file) return;

        if (!ACCEPTED_TYPES.includes(file.type)) {
            setErrors((er) => ({
                ...er,
                image: 'Only image files are allowed (jpg, png, gif, webp, svg, bmp)',
            }));
            return;
        }

        if (file.size > MAX_SIZE_MB * 1024 * 1024) {
            setErrors((er) => ({
                ...er,
                image: `Image must be smaller than ${MAX_SIZE_MB}MB`,
            }));
            return;
        }

        setForm((f) => ({ ...f, image: file }));
        setPreview(URL.createObjectURL(file));
        setErrors((er) => ({ ...er, image: '' }));
    };

    // Click to select
    const handleImageSelect = (e) => {
        const file = e.target.files?.[0];
        processFile(file);
        // reset input so same file can be selected again
        e.target.value = '';
    };

    // Drag & Drop handlers
    const handleDragEnter = (e) => {
        e.preventDefault();
        e.stopPropagation();
        dragCounter.current += 1;
        if (e.dataTransfer.items && e.dataTransfer.items.length > 0) {
            setIsDragging(true);
        }
    };

    const handleDragLeave = (e) => {
        e.preventDefault();
        e.stopPropagation();
        dragCounter.current -= 1;
        if (dragCounter.current === 0) {
            setIsDragging(false);
        }
    };

    const handleDragOver = (e) => {
        e.preventDefault();
        e.stopPropagation();
    };

    const handleDrop = (e) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(false);
        dragCounter.current = 0;

        const file = e.dataTransfer.files?.[0];
        processFile(file);
    };

    const validate = () => {
        const e = {};
        if (!isEdit && !form.image) e.image = t('banner.form.imageRequired');
        setErrors(e);
        return Object.keys(e).length === 0;
    };

    const handleSubmit = async (ev) => {
        ev.preventDefault();
        if (!validate()) return;
        setLoading(true);

        try {
            const fd = new FormData();
            if (form.title) fd.append('title', form.title.trim());
            fd.append('type', form.type);
            if (form.link) fd.append('link', form.link.trim());
            fd.append('status', form.status);
            if (form.starts_at) fd.append('starts_at', form.starts_at);
            if (form.expires_at) fd.append('expires_at', form.expires_at);
            fd.append('sort_order', form.sort_order ?? 0);
            if (form.image) fd.append('image', form.image);

            if (isEdit) {
                await updateBanner(banner.id, fd);
                showSnackbar({ type: 'success', message: t('banner.form.updated') });
            } else {
                await createBanner(fd);
                showSnackbar({ type: 'success', message: t('banner.form.created') });
            }
            onClose(true);
        } catch (err) {
            const msg = err.response?.data?.message || t('banner.form.failed');
            const errData = err.response?.data?.errors;
            if (errData) {
                const fe = {};
                Object.keys(errData).forEach((k) => { fe[k] = errData[k][0]; });
                setErrors(fe);
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
            maxWidth="sm"
            fullWidth
            PaperProps={{
                sx: { borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' },
            }}
        >
            <form onSubmit={handleSubmit}>
                <DialogTitle sx={{
                    pb: 1.5, fontWeight: 700, fontSize: '1.2rem',
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                    borderBottom: '1px solid', borderColor: 'divider',
                }}>
                    {isEdit ? t('banner.form.editTitle') : t('banner.form.createTitle')}
                    <IconButton onClick={() => onClose(false)} size="small">
                        <CloseIcon />
                    </IconButton>
                </DialogTitle>

                <DialogContent sx={{ pt: 3, pb: 1 }}>
                    <Stack spacing={2.5} sx={{ mt: 1 }}>

                        {/* ========== DRAG & DROP IMAGE AREA ========== */}
                        <Box>
                            <Typography variant="body2" fontWeight={600} mb={1}>
                                {t('banner.form.image')}
                            </Typography>

                            <Box
                                onDragEnter={handleDragEnter}
                                onDragLeave={handleDragLeave}
                                onDragOver={handleDragOver}
                                onDrop={handleDrop}
                                onClick={() => !loading && fileInputRef.current?.click()}
                                sx={{
                                    border: '2px dashed',
                                    borderColor: errors.image
                                        ? 'error.main'
                                        : isDragging
                                            ? colors.sea || '#0f766e'
                                            : 'divider',
                                    borderRadius: 2,
                                    p: 2.5,
                                    textAlign: 'center',
                                    cursor: loading ? 'not-allowed' : 'pointer',
                                    bgcolor: isDragging
                                        ? (colors.sea ? `${colors.sea}14` : 'rgba(15,118,110,0.08)')
                                        : 'action.hover',
                                    transition: 'all 0.2s ease',
                                    minHeight: 160,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    '&:hover': {
                                        borderColor: colors.sea || '#0f766e',
                                        bgcolor: colors.sea ? `${colors.sea}0A` : 'rgba(15,118,110,0.04)',
                                    },
                                }}
                            >
                                <input
                                    ref={fileInputRef}
                                    type="file"
                                    accept="image/jpeg,image/png,image/gif,image/webp,image/svg+xml,image/bmp"
                                    hidden
                                    onChange={handleImageSelect}
                                    disabled={loading}
                                />

                                {preview ? (
                                    <Box sx={{ width: '100%' }}>
                                        <Box
                                            component="img"
                                            src={preview}
                                            alt="preview"
                                            sx={{
                                                maxWidth: '100%',
                                                maxHeight: 180,
                                                borderRadius: 1.5,
                                                objectFit: 'contain',
                                                display: 'block',
                                                mx: 'auto',
                                            }}
                                        />
                                        <Typography variant="caption" display="block" mt={1.5} color="text.secondary">
                                            {isDragging
                                                ? 'Drop to replace image'
                                                : t('banner.form.changeImage') || 'Click or drag to change image'}
                                        </Typography>
                                    </Box>
                                ) : (
                                    <Stack alignItems="center" spacing={1.2}>
                                        <UploadIcon
                                            sx={{
                                                fontSize: 44,
                                                color: isDragging
                                                    ? (colors.sea || '#0f766e')
                                                    : 'text.secondary',
                                            }}
                                        />
                                        <Typography variant="body2" fontWeight={600} color="text.primary">
                                            {isDragging
                                                ? 'Drop image here'
                                                : 'Drag & drop image here'}
                                        </Typography>
                                        <Typography variant="caption" color="text.secondary">
                                            or click to browse • JPG, PNG, GIF, WebP, SVG (max {MAX_SIZE_MB}MB)
                                        </Typography>
                                    </Stack>
                                )}
                            </Box>

                            {errors.image && (
                                <Typography variant="caption" color="error" mt={0.75} display="block">
                                    {errors.image}
                                </Typography>
                            )}
                        </Box>

                        {/* Title */}
                        <TextField
                            label={t('banner.form.title')}
                            name="title"
                            value={form.title}
                            onChange={handleChange}
                            fullWidth
                            sx={inputSx}
                            disabled={loading}
                        />

                        {/* Type */}
                        <TextField
                            select
                            label={t('banner.form.type')}
                            name="type"
                            value={form.type}
                            onChange={handleChange}
                            fullWidth
                            required
                            sx={inputSx}
                            disabled={loading}
                        >
                            {BANNER_TYPES.map((tp) => (
                                <MenuItem key={tp} value={tp}>{t(`banner.type.${tp}`)}</MenuItem>
                            ))}
                        </TextField>

                        {/* Link */}
                        <TextField
                            label={t('banner.form.link')}
                            name="link"
                            value={form.link}
                            onChange={handleChange}
                            placeholder={t('banner.form.linkPlaceholder')}
                            fullWidth
                            sx={inputSx}
                            disabled={loading}
                            error={!!errors.link}
                            helperText={errors.link}
                        />

                        {/* Status */}
                        <TextField
                            select
                            label={t('banner.form.status')}
                            name="status"
                            value={form.status}
                            onChange={handleChange}
                            fullWidth
                            sx={inputSx}
                            disabled={loading}
                        >
                            <MenuItem value="active">{t('banner.status.active')}</MenuItem>
                            <MenuItem value="draft">{t('banner.status.draft')}</MenuItem>
                        </TextField>

                        {/* Dates */}
                        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                            <TextField
                                label={t('banner.form.startsAt')}
                                name="starts_at"
                                type="datetime-local"
                                value={form.starts_at}
                                onChange={handleChange}
                                fullWidth
                                InputLabelProps={{ shrink: true }}
                                sx={inputSx}
                                disabled={loading}
                            />
                            <TextField
                                label={t('banner.form.expiresAt')}
                                name="expires_at"
                                type="datetime-local"
                                value={form.expires_at}
                                onChange={handleChange}
                                fullWidth
                                InputLabelProps={{ shrink: true }}
                                sx={inputSx}
                                disabled={loading}
                                error={!!errors.expires_at}
                                helperText={errors.expires_at}
                            />
                        </Stack>

                        {/* Sort order */}
                        <TextField
                            label={t('banner.form.sortOrder')}
                            name="sort_order"
                            type="number"
                            value={form.sort_order}
                            onChange={handleChange}
                            fullWidth
                            sx={inputSx}
                            disabled={loading}
                            inputProps={{ min: 0 }}
                        />
                    </Stack>
                </DialogContent>

                <DialogActions sx={{ p: { xs: 2, sm: 3 }, pt: 1, borderTop: '1px solid', borderColor: 'divider' }}>
                    <Button
                        onClick={() => onClose(false)}
                        disabled={loading}
                        sx={{ fontWeight: 600, textTransform: 'none' }}
                    >
                        {t('banner.common.cancel')}
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
                        }}
                    >
                        {loading
                            ? <CircularProgress size={24} color="inherit" />
                            : (isEdit ? t('banner.common.update') : t('banner.common.create'))}
                    </Button>
                </DialogActions>
            </form>
        </Dialog>
    );
};

export default BannerFormModal;