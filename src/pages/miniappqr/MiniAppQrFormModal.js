import React, { useState, useEffect, useMemo } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, TextField, MenuItem,
    Button, CircularProgress, Stack, IconButton, FormControlLabel, Switch, Typography,
} from '@mui/material';
import { Close as CloseIcon } from '@mui/icons-material';
import { miniAppQrService } from 'services/miniAppQr.service';
import { useMiniAppQrManagement } from 'hooks/useMiniAppQr';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tQr } from './qrlang';
import { VALIDITIES, previewExpiry, fmtDate } from './qrHelpers';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const emptyForm = { mini_app_id: '', label: '', validity: 'month', is_active: true };

const MiniAppQrFormModal = ({ open, onClose, qr }) => {
    const { language } = useLanguage();
    const t = (key, r) => tQr(language, key, r);
    const { createQr, updateQr } = useMiniAppQrManagement();

    const isEdit = !!qr;
    const [form, setForm] = useState(emptyForm);
    const [apps, setApps] = useState([]);
    const [loading, setLoading] = useState(false);
    const [errors, setErrors] = useState({});

    // Mini apps for the dropdown
    useEffect(() => {
        if (!open) return;
        miniAppQrService.getMiniApps()
            .then((res) => {
                const list = res?.data?.data;
                setApps(Array.isArray(list) ? list : []);
            })
            .catch(() => setApps([]));
    }, [open]);

    useEffect(() => {
        if (qr) {
            setForm({
                mini_app_id: qr.mini_app_id,
                label: qr.label || '',
                validity: '', // '' = keep the current expiry
                is_active: !!qr.is_active,
            });
        } else {
            setForm(emptyForm);
        }
        setErrors({});
    }, [qr, open]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setForm((f) => ({ ...f, [name]: value }));
        if (errors[name]) setErrors((er) => ({ ...er, [name]: '' }));
    };

    const expiryText = useMemo(() => {
        if (!form.validity) {
            return qr ? t('qr.form.currentExpiry', {
                date: qr.expires_at ? fmtDate(qr.expires_at) : t('qr.expires.never'),
            }) : '';
        }
        const d = previewExpiry(form.validity);
        return d ? t('qr.form.willExpire', { date: fmtDate(d) }) : t('qr.form.noExpiry');
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [form.validity, qr, language]);

    const validate = () => {
        const e = {};
        if (!isEdit && !form.mini_app_id) e.mini_app_id = t('qr.form.appRequired');
        setErrors(e);
        return Object.keys(e).length === 0;
    };

    const handleSubmit = async (ev) => {
        ev.preventDefault();
        if (!validate()) return;
        setLoading(true);
        try {
            if (isEdit) {
                const payload = { label: form.label.trim() || null, is_active: form.is_active };
                if (form.validity) payload.validity = form.validity;
                await updateQr(qr.id, payload);
                showSnackbar({ type: 'success', message: t('qr.form.updated') });
            } else {
                await createQr({
                    mini_app_id: form.mini_app_id,
                    label: form.label.trim() || null,
                    validity: form.validity,
                });
                showSnackbar({ type: 'success', message: t('qr.form.created') });
            }
            onClose(true);
        } catch (err) {
            const msg = err.response?.data?.message || t('qr.form.failed');
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
            open={open} onClose={() => onClose(false)} maxWidth="sm" fullWidth
            PaperProps={{
                sx: { borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' },
            }}
        >
            <form onSubmit={handleSubmit}>
                <DialogTitle sx={{
                    pb: 1.5, fontWeight: 700, fontSize: '1.2rem',
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                    borderBottom: '1px solid', borderColor: 'divider', color: 'text.primary',
                }}>
                    {isEdit ? t('qr.form.editTitle') : t('qr.form.createTitle')}
                    <IconButton onClick={() => onClose(false)} size="small"
                                sx={{ color: 'text.secondary', '&:hover': { bgcolor: 'action.hover' } }}>
                        <CloseIcon />
                    </IconButton>
                </DialogTitle>

                <DialogContent sx={{ pt: 3, pb: 1 }}>
                    <Stack spacing={2.5} sx={{ mt: 1 }}>
                        <TextField
                            select
                            label={t('qr.form.app')}
                            name="mini_app_id"
                            value={form.mini_app_id}
                            onChange={handleChange}
                            error={!!errors.mini_app_id}
                            helperText={errors.mini_app_id}
                            disabled={loading || isEdit}
                            required
                            fullWidth
                            sx={inputSx}
                        >
                            {apps.map((a) => (
                                <MenuItem key={a.id} value={a.id}>{a.name}</MenuItem>
                            ))}
                            {/* when editing, the app may not be in the public list (switched off) */}
                            {isEdit && !apps.some((a) => a.id === qr.mini_app_id) && (
                                <MenuItem value={qr.mini_app_id}>{qr.mini_app?.name}</MenuItem>
                            )}
                        </TextField>

                        <TextField
                            label={t('qr.form.label')}
                            name="label"
                            value={form.label}
                            onChange={handleChange}
                            placeholder={t('qr.form.labelPlaceholder')}
                            error={!!errors.label}
                            helperText={errors.label}
                            disabled={loading}
                            fullWidth
                            sx={inputSx}
                        />

                        <TextField
                            select
                            label={t('qr.form.validity')}
                            name="validity"
                            value={form.validity}
                            onChange={handleChange}
                            error={!!errors.validity}
                            helperText={errors.validity || expiryText}
                            disabled={loading}
                            fullWidth
                            sx={inputSx}
                        >
                            {isEdit && <MenuItem value="">{t('qr.form.keepCurrent')}</MenuItem>}
                            {VALIDITIES.map((v) => (
                                <MenuItem key={v} value={v}>{t(`qr.validity.${v}`)}</MenuItem>
                            ))}
                        </TextField>

                        {isEdit && (
                            <>
                                <FormControlLabel
                                    control={
                                        <Switch
                                            checked={form.is_active}
                                            onChange={(e) => setForm((f) => ({ ...f, is_active: e.target.checked }))}
                                            disabled={loading}
                                        />
                                    }
                                    label={t('qr.form.active')}
                                />
                                <Typography variant="caption" color="text.secondary" sx={{ wordBreak: 'break-all' }}>
                                    {qr.qr_payload}
                                </Typography>
                            </>
                        )}
                    </Stack>
                </DialogContent>

                <DialogActions sx={{ p: { xs: 2, sm: 3 }, pt: 1, borderTop: '1px solid', borderColor: 'divider' }}>
                    <Button onClick={() => onClose(false)} disabled={loading}
                            sx={{ fontWeight: 600, textTransform: 'none', color: 'text.secondary' }}>
                        {t('qr.common.cancel')}
                    </Button>
                    <Button
                        type="submit" variant="contained" disabled={loading}
                        sx={{
                            borderRadius: 2, fontWeight: 700, textTransform: 'none', px: 3,
                            bgcolor: colors.sea || '#0f766e',
                            '&:hover': { bgcolor: colors.dark || '#0d5c56' },
                            '&:disabled': { opacity: 0.6 },
                        }}
                    >
                        {loading
                            ? <CircularProgress size={24} color="inherit" />
                            : (isEdit ? t('qr.common.update') : t('qr.common.create'))}
                    </Button>
                </DialogActions>
            </form>
        </Dialog>
    );
};

export default MiniAppQrFormModal;