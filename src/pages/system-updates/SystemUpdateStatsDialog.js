// src/pages/system-updates/SystemUpdateStatsDialog.jsx
import React from 'react';
import {
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Button,
    Grid,
    Typography,
    Box,
    Divider,
    Chip,
    Stack,
} from '@mui/material';
import { useLanguage } from 'context/LanguageContext';
import { tSystemUpdate } from './systemUpdateLang';

function StatCard({ label, value, tone = 'default', icon = null }) {
    const toneColor =
        tone === 'success'
            ? '#047857'
            : tone === 'error'
                ? '#b91c1c'
                : tone === 'warning'
                    ? '#b45309'
                    : tone === 'info'
                        ? '#0369a1'
                        : 'text.primary';

    return (
        <Box
            sx={{
                p: 1.75,
                border: '1px solid',
                borderColor: 'divider',
                borderRadius: 2,
                bgcolor: 'action.hover',
                display: 'flex',
                flexDirection: 'column',
                gap: 0.25,
                height: '100%',
            }}
        >
            <Stack direction="row" spacing={0.75} alignItems="center">
                {icon}
                <Typography variant="caption" color="text.secondary" fontWeight={600}>
                    {label}
                </Typography>
            </Stack>
            <Typography variant="h6" fontWeight={800} sx={{ color: toneColor }}>
                {value ?? 0}
            </Typography>
        </Box>
    );
}

function pick(obj, keys, fallback = 0) {
    for (const k of keys) {
        if (obj?.[k] !== undefined && obj?.[k] !== null) return obj[k];
    }
    return fallback;
}

const STATUS_STYLES = {
    draft: { bg: '#f3f4f6', color: '#4b5563', border: '#9ca3af' },
    published: { bg: '#d1fae5', color: '#047857', border: '#10b981' },
    closed: { bg: '#fee2e2', color: '#b91c1c', border: '#ef4444' },
};

function StatusChip({ status, label }) {
    const s = STATUS_STYLES[status] || STATUS_STYLES.draft;
    return (
        <Chip
            label={label || status}
            size="small"
            sx={{
                bgcolor: s.bg,
                color: s.color,
                fontWeight: 700,
                border: `1.5px solid ${s.border}`,
                height: 26,
            }}
        />
    );
}

export default function SystemUpdateStatsDialog({ open, onClose, systemUpdate }) {
    const { language } = useLanguage();
    const t = (key, r) => tSystemUpdate(language, key, r);

    if (!systemUpdate) return null;

    const received  = pick(systemUpdate, ['received_count', 'received']);
    const viewed    = pick(systemUpdate, ['viewed_count', 'viewed']);
    const dismissed = pick(systemUpdate, ['dismissed_count', 'dismissed']);
    const pushSent  = pick(systemUpdate, ['push_sent']);
    const pushFailed= pick(systemUpdate, ['push_failed']);

    const statusLabel = t(
        systemUpdate.status === 'published'
            ? 'su.status.published'
            : systemUpdate.status === 'closed'
                ? 'su.status.closed'
                : 'su.status.draft'
    );

    return (
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth="sm"
            fullWidth
            PaperProps={{ sx: { borderRadius: 3 } }}
        >
            <DialogTitle sx={{ fontWeight: 800, pb: 1 }}>
                {t('su.stats.title', { title: systemUpdate.title })}
            </DialogTitle>

            <DialogContent>
                {/* Status + channel badges */}
                <Stack direction="row" spacing={1} sx={{ mb: 2 }} flexWrap="wrap">
                    <StatusChip status={systemUpdate.status} label={statusLabel} />
                    {systemUpdate.send_push && (
                        <Chip
                            label="Push"
                            size="small"
                            sx={{
                                bgcolor: '#e0f2fe',
                                color: '#075985',
                                fontWeight: 700,
                                height: 26,
                            }}
                        />
                    )}
                </Stack>

                <Divider sx={{ mb: 2 }} />

                {/* In-app engagement */}
                <Typography
                    variant="caption"
                    fontWeight={700}
                    color="text.secondary"
                    sx={{ textTransform: 'uppercase', letterSpacing: 0.6, mb: 1, display: 'block' }}
                >
                    In-app engagement
                </Typography>

                <Grid container spacing={1.5} sx={{ mb: 2 }}>
                    <Grid item xs={12} sm={4}>
                        <StatCard label={t('su.stats.received')} value={received} tone="info" />
                    </Grid>
                    <Grid item xs={12} sm={4}>
                        <StatCard label={t('su.stats.viewed')} value={viewed} tone="success" />
                    </Grid>
                    <Grid item xs={12} sm={4}>
                        <StatCard label={t('su.stats.dismissed')} value={dismissed} tone="warning" />
                    </Grid>
                </Grid>

                {/* Push delivery */}
                {systemUpdate.send_push && (
                    <>
                        <Typography
                            variant="caption"
                            fontWeight={700}
                            color="text.secondary"
                            sx={{
                                textTransform: 'uppercase',
                                letterSpacing: 0.6,
                                mb: 1,
                                display: 'block',
                            }}
                        >
                            Push notifications
                        </Typography>
                        <Grid container spacing={1.5} sx={{ mb: 2 }}>
                            <Grid item xs={12} sm={6}>
                                <StatCard
                                    label={t('su.stats.pushSent')}
                                    value={pushSent}
                                    tone="success"
                                />
                            </Grid>
                            <Grid item xs={12} sm={6}>
                                <StatCard
                                    label={t('su.stats.pushFailed')}
                                    value={pushFailed}
                                    tone="error"
                                />
                            </Grid>
                        </Grid>
                    </>
                )}
            </DialogContent>

            <DialogActions sx={{ px: 3, pb: 2.5 }}>
                <Button
                    onClick={onClose}
                    variant="contained"
                    sx={{ fontWeight: 700, textTransform: 'none', borderRadius: 2 }}
                >
                    {t('su.stats.close')}
                </Button>
            </DialogActions>
        </Dialog>
    );
}