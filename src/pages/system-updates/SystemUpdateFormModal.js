// src/pages/system-updates/SystemUpdateFormModal.jsx
import React, { useEffect, useState } from 'react';
import {
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    Button,
    Box,
    CircularProgress,
    useMediaQuery,
    useTheme,
    IconButton,
    Alert,
    Typography,
    Stack,
    Divider,
    FormControlLabel,
    Switch,
} from '@mui/material';
import { Close as CloseIcon } from '@mui/icons-material';
import { useSystemUpdateManagement } from 'hooks/useSystemUpdate';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tSystemUpdate } from './systemUpdateLang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function SystemUpdateFormModal({ open, onClose, systemUpdate }) {
    const theme = useTheme();
    const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
    const { language } = useLanguage();
    const t = (key, r) => tSystemUpdate(language, key, r);

    const {
        createSystemUpdate,
        updateSystemUpdate,
        saveSystemUpdateDraft,
        publishSystemUpdate,
    } = useSystemUpdateManagement();

    const [loading, setLoading] = useState(false);
    const [validationErrors, setValidationErrors] = useState({});
    const [errors, setErrors] = useState({});
    const [form, setForm] = useState({
        title: '',
        description: '',
        send_push: true,
    });

    useEffect(() => {
        if (!open) return;
        if (systemUpdate) {
            setForm({
                title: systemUpdate.title || '',
                description: systemUpdate.description || '',
                send_push: systemUpdate.send_push ?? true,
            });
        } else {
            setForm({ title: '', description: '', send_push: true });
        }
        setErrors({});
        setValidationErrors({});
    }, [open, systemUpdate]);

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;
        setForm((prev) => ({ ...prev, [name]: type === 'checkbox' ? checked : value }));
        if (errors[name]) setErrors((p) => ({ ...p, [name]: '' }));
        if (validationErrors[name]) setValidationErrors((p) => ({ ...p, [name]: '' }));
    };

    const validate = () => {
        const e = {};
        if (!form.title.trim()) e.title = t('su.form.titleRequired');
        else if (form.title.trim().length < 3) e.title = t('su.form.titleMin');
        if (!form.description.trim()) e.description = t('su.form.descriptionRequired');
        else if (form.description.trim().length < 3)
            e.description = t('su.form.descriptionMin');
        setErrors(e);
        return Object.keys(e).length === 0;
    };

    const handleError = (err) => {
        if (err?.response?.data?.errors) {
            setValidationErrors(err.response.data.errors);
            showSnackbar({ type: 'error', message: t('su.form.checkErrors') });
        } else {
            showSnackbar({ type: 'error', message: err?.message || t('su.form.failed') });
        }
    };

    const submit = async (mode) => {
        if (!validate()) return;
        setLoading(true);
        setValidationErrors({});
        try {
            const payload = {
                title: form.title.trim(),
                description: form.description.trim(),
                send_push: form.send_push,
            };

            if (mode === 'draft') {
                if (systemUpdate?.id) {
                    await updateSystemUpdate(systemUpdate.id, payload);
                    showSnackbar({ type: 'success', message: t('su.form.updated') });
                } else {
                    await saveSystemUpdateDraft(payload);
                    showSnackbar({ type: 'success', message: t('su.form.created') });
                }
            } else if (mode === 'save') {
                await updateSystemUpdate(systemUpdate.id, payload);
                showSnackbar({ type: 'success', message: t('su.form.updated') });
            } else if (mode === 'publish') {
                if (systemUpdate?.id) {
                    await updateSystemUpdate(systemUpdate.id, payload);
                    await publishSystemUpdate(systemUpdate.id);
                } else {
                    await createSystemUpdate({ ...payload, publish: true });
                }
                showSnackbar({ type: 'success', message: t('su.form.published') });
            }

            onClose(true);
        } catch (err) {
            handleError(err);
        } finally {
            setLoading(false);
        }
    };

    const isDraft = !systemUpdate || systemUpdate.status === 'draft';

    return (
        <Dialog
            open={open}
            onClose={() => onClose(false)}
            maxWidth="sm"
            fullWidth
            fullScreen={fullScreen}
            PaperProps={{
                sx: { borderRadius: { xs: 0, sm: 3 }, bgcolor: 'background.paper' },
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
                        {systemUpdate ? t('su.form.editTitle') : t('su.form.createTitle')}
                    </Typography>
                    <Typography variant="body2" color="text.secondary" fontWeight={500} sx={{ mt: 0.25 }}>
                        {systemUpdate ? t('su.form.editDesc') : t('su.form.createDesc')}
                    </Typography>
                </Box>
                <IconButton
                    onClick={() => onClose(false)}
                    size="small"
                    disabled={loading}
                    sx={{ color: 'text.secondary', mt: -0.5 }}
                >
                    <CloseIcon />
                </IconButton>
            </DialogTitle>

            <Divider />

            <DialogContent sx={{ px: { xs: 2.5, sm: 3 }, py: 2.5 }}>
                <Stack spacing={2.25}>
                    {Object.keys(validationErrors).length > 0 && (
                        <Alert severity="error" variant="filled" sx={{ borderRadius: 2 }}>
                            {Object.values(validationErrors)
                                .flat()
                                .map((m, i) => (
                                    <div key={i}>{m}</div>
                                ))}
                        </Alert>
                    )}

                    <TextField
                        label={t('su.form.title')}
                        name="title"
                        value={form.title}
                        onChange={handleChange}
                        required
                        fullWidth
                        size="small"
                        error={!!errors.title || !!validationErrors.title}
                        helperText={
                            errors.title ||
                            validationErrors.title?.[0] ||
                            t('su.form.titleHint')
                        }
                        disabled={loading}
                        inputProps={{ maxLength: 255 }}
                        sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2, bgcolor: 'action.hover' } }}
                    />

                    <TextField
                        label={t('su.form.description')}
                        name="description"
                        value={form.description}
                        onChange={handleChange}
                        required
                        fullWidth
                        multiline
                        minRows={5}
                        maxRows={10}
                        size="small"
                        error={!!errors.description || !!validationErrors.description}
                        helperText={
                            errors.description ||
                            validationErrors.description?.[0] ||
                            t('su.form.descriptionHint')
                        }
                        disabled={loading}
                        inputProps={{ maxLength: 5000 }}
                        sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2, bgcolor: 'action.hover' } }}
                    />

                    <Box sx={{ mt: 1 }}>
                        <Typography variant="body2" fontWeight={700} color="text.primary" sx={{ mb: 1 }}>
                            {t('su.form.channels')}
                        </Typography>
                        <Stack
                            spacing={1}
                            sx={{
                                pl: 1,
                                p: 1.5,
                                border: '1px solid',
                                borderColor: 'divider',
                                borderRadius: 2,
                            }}
                        >
                            <FormControlLabel
                                control={
                                    <Switch
                                        name="send_push"
                                        checked={form.send_push}
                                        onChange={handleChange}
                                        disabled={loading}
                                    />
                                }
                                label={
                                    <Box>
                                        <Typography variant="body2" fontWeight={600}>
                                            {t('su.form.sendPush')}
                                        </Typography>
                                        <Typography variant="caption" color="text.secondary">
                                            {t('su.form.sendPushHint')}
                                        </Typography>
                                    </Box>
                                }
                            />
                        </Stack>
                    </Box>
                </Stack>
            </DialogContent>

            <Divider />

            <DialogActions sx={{ px: { xs: 2.5, sm: 3 }, py: 2, gap: 1, flexWrap: 'wrap' }}>
                <Button
                    onClick={() => onClose(false)}
                    disabled={loading}
                    sx={{ fontWeight: 600, textTransform: 'none', color: 'text.secondary' }}
                >
                    {t('su.cancel')}
                </Button>
                <Box sx={{ flexGrow: 1 }} />
                {isDraft && (
                    <Button
                        onClick={() => submit('draft')}
                        disabled={loading}
                        variant="outlined"
                        sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}
                    >
                        {t('su.form.saveDraft')}
                    </Button>
                )}
                {systemUpdate && systemUpdate.status !== 'draft' && (
                    <Button
                        onClick={() => submit('save')}
                        disabled={loading}
                        variant="outlined"
                        sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}
                    >
                        {t('su.form.saveChanges')}
                    </Button>
                )}
                {isDraft && (
                    <Button
                        onClick={() => submit('publish')}
                        disabled={loading}
                        variant="contained"
                        sx={{
                            minWidth: 130,
                            borderRadius: 2,
                            fontWeight: 700,
                            textTransform: 'none',
                            boxShadow: 'none',
                            bgcolor: colors.salat || '#10b981',
                            '&:hover': { bgcolor: colors.dark || '#047857' },
                        }}
                    >
                        {loading ? (
                            <CircularProgress size={22} thickness={4} sx={{ color: '#fff' }} />
                        ) : (
                            t('su.form.publishNow')
                        )}
                    </Button>
                )}
            </DialogActions>
        </Dialog>
    );
}