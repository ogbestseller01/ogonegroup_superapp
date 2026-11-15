import React from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, Button, IconButton,
    Box, Stack, Typography, Chip,
} from '@mui/material';
import {
    Close as CloseIcon, ContentCopy as CopyIcon,
    Download as DownloadIcon, Print as PrintIcon,
} from '@mui/icons-material';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { tQr } from './qrlang';
import { displayStatus, STATUS_COLORS, fmtDateTime } from './qrHelpers';

const QrPreviewDialog = ({ open, onClose, qr }) => {
    const { language } = useLanguage();
    const t = (key, r) => tQr(language, key, r);

    if (!qr) return null;

    const status = displayStatus(qr);
    const colors = STATUS_COLORS[status] || STATUS_COLORS.active;
    const title = qr.label || qr.mini_app?.name || '';
    const fileName = `qr-${qr.mini_app?.slug || 'app'}-${qr.id}.svg`;

    const copyPayload = async () => {
        try {
            await navigator.clipboard.writeText(qr.qr_payload);
            showSnackbar({ type: 'success', message: t('qr.preview.copied') });
        } catch (e) { /* clipboard blocked */ }
    };

    const download = async () => {
        try {
            const res = await fetch(`${qr.qr_image_url}?format=svg&size=1024`);
            const blob = await res.blob();
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = fileName;
            a.click();
            URL.revokeObjectURL(url);
        } catch (e) {
            showSnackbar({ type: 'error', message: t('qr.form.failed') });
        }
    };

    const print = () => {
        const w = window.open('', '_blank', 'width=480,height=640');
        if (!w) return;
        w.document.write(`
            <html><head><title>${title}</title>
            <style>body{font-family:Arial,sans-serif;text-align:center;padding:24px;color:#1A2B4A}
            img{width:320px;height:320px}h2{margin:8px 0 2px}p{margin:2px 0;color:#5B6B82}</style></head>
            <body>
              <img src="${qr.qr_image_url}?format=svg&size=640" onload="window.print()" />
              <h2>${qr.mini_app?.name || ''}</h2>
              <p>${qr.label || ''}</p>
              <p>${t('qr.preview.expires')}: ${qr.expires_at ? fmtDateTime(qr.expires_at) : t('qr.expires.never')}</p>
            </body></html>`);
        w.document.close();
    };

    return (
        <Dialog
            open={open} onClose={onClose} maxWidth="xs" fullWidth
            PaperProps={{ sx: { borderRadius: 3, bgcolor: 'background.paper' } }}
        >
            <DialogTitle sx={{
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                fontWeight: 700, borderBottom: '1px solid', borderColor: 'divider',
            }}>
                {title}
                <IconButton size="small" onClick={onClose}><CloseIcon /></IconButton>
            </DialogTitle>

            <DialogContent sx={{ pt: 3 }}>
                <Stack spacing={2} alignItems="center">
                    {/* QR must stay on a white background to remain scannable */}
                    <Box sx={{ p: 2, bgcolor: '#fff', borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                        <img
                            src={`${qr.qr_image_url}?format=svg&size=512`}
                            alt={title}
                            style={{ width: 240, height: 240, display: 'block' }}
                        />
                    </Box>

                    <Chip
                        label={t(`qr.status.${status}`)}
                        size="small"
                        sx={{ fontWeight: 700, bgcolor: colors.bg, color: colors.fg }}
                    />

                    <Stack spacing={0.5} sx={{ width: '100%' }}>
                        <Typography variant="body2" color="text.secondary">
                            {t('qr.preview.expires')}:{' '}
                            <b>{qr.expires_at ? fmtDateTime(qr.expires_at) : t('qr.expires.never')}</b>
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            {t('qr.preview.scans')}: <b>{qr.scans_count}</b>
                            {' · '}
                            {t('qr.preview.lastScan')}: <b>{fmtDateTime(qr.last_scanned_at)}</b>
                        </Typography>
                        <Typography variant="caption" color="text.secondary" sx={{ wordBreak: 'break-all' }}>
                            {t('qr.preview.payload')}: {qr.qr_payload}
                        </Typography>
                    </Stack>
                </Stack>
            </DialogContent>

            <DialogActions sx={{ p: 2, borderTop: '1px solid', borderColor: 'divider', flexWrap: 'wrap', gap: 1 }}>
                <Button startIcon={<CopyIcon />} onClick={copyPayload} sx={{ textTransform: 'none', fontWeight: 600 }}>
                    {t('qr.preview.copy')}
                </Button>
                <Button startIcon={<DownloadIcon />} onClick={download} sx={{ textTransform: 'none', fontWeight: 600 }}>
                    {t('qr.preview.download')}
                </Button>
                <Button startIcon={<PrintIcon />} onClick={print} variant="contained"
                        sx={{ textTransform: 'none', fontWeight: 700, borderRadius: 2 }}>
                    {t('qr.preview.print')}
                </Button>
            </DialogActions>
        </Dialog>
    );
};

export default QrPreviewDialog;