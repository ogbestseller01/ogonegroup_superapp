// src/pages/faqs/FaqFormModal.js
import React, { useState, useEffect } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, TextField, Button,
    CircularProgress, useMediaQuery, useTheme, Typography, IconButton, Stack,
} from '@mui/material';
import { Close as CloseIcon } from '@mui/icons-material';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tFaq } from './faqlang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function FaqFormModal({ open, onClose, faq, createFaq, updateFaq }) {
    const theme = useTheme();
    const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
    const { language } = useLanguage();
    const t = (key) => tFaq(language, key);

    const [loading, setLoading] = useState(false);
    const [form, setForm] = useState({ question: '', answer: '', order: 0 });
    const [errors, setErrors] = useState({});

    useEffect(() => {
        if (faq) {
            setForm({
                question: faq.question || '',
                answer: faq.answer || '',
                order: faq.order || 0,
            });
        } else {
            setForm({ question: '', answer: '', order: 0 });
        }
        setErrors({});
    }, [faq, open]);

    const handleChange = (e) => {
        const value = e.target.name === 'order' ? parseInt(e.target.value) || 0 : e.target.value;
        setForm({ ...form, [e.target.name]: value });
        if (errors[e.target.name]) setErrors({ ...errors, [e.target.name]: '' });
    };

    const validate = () => {
        const newErrors = {};
        if (!form.question.trim()) newErrors.question = t('faq.modal.questionRequired');
        if (!form.answer.trim()) newErrors.answer = t('faq.modal.answerRequired');
        if (form.order < 0) newErrors.order = t('faq.modal.orderPositive');
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        setLoading(true);
        try {
            if (faq) {
                await updateFaq(faq.id, form);
                showSnackbar({ type: 'success', message: t('faq.modal.updated') });
            } else {
                await createFaq(form);
                showSnackbar({ type: 'success', message: t('faq.modal.created') });
            }
            onClose(true);
        } catch (err) {
            showSnackbar({
                type: 'error',
                message: err.response?.data?.message || t('faq.modal.failed'),
            });
        } finally {
            setLoading(false);
        }
    };

    const inputSx = {
        '& .MuiOutlinedInput-root': {
            borderRadius: 2,
            bgcolor: 'action.hover',
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
                    {faq ? t('faq.modal.editTitle') : t('faq.modal.createTitle')}
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
                            {faq ? t('faq.modal.editDesc') : t('faq.modal.createDesc')}
                        </Typography>

                        <TextField
                            label={t('faq.modal.question')}
                            name="question"
                            value={form.question}
                            onChange={handleChange}
                            required
                            fullWidth
                            multiline
                            rows={2}
                            error={!!errors.question}
                            helperText={errors.question}
                            placeholder={t('faq.modal.questionPlaceholder')}
                            disabled={loading}
                            sx={inputSx}
                        />

                        <TextField
                            label={t('faq.modal.answer')}
                            name="answer"
                            value={form.answer}
                            onChange={handleChange}
                            required
                            fullWidth
                            multiline
                            rows={4}
                            error={!!errors.answer}
                            helperText={errors.answer}
                            placeholder={t('faq.modal.answerPlaceholder')}
                            disabled={loading}
                            sx={inputSx}
                        />

                        <TextField
                            label={t('faq.modal.order')}
                            name="order"
                            type="number"
                            value={form.order}
                            onChange={handleChange}
                            fullWidth
                            error={!!errors.order}
                            helperText={errors.order || t('faq.modal.orderHelp')}
                            InputProps={{ inputProps: { min: 0 } }}
                            disabled={loading}
                            sx={inputSx}
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
                        {t('faq.modal.cancel')}
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
                        ) : faq ? (
                            t('faq.modal.update')
                        ) : (
                            t('faq.modal.create')
                        )}
                    </Button>
                </DialogActions>
            </form>
        </Dialog>
    );
}