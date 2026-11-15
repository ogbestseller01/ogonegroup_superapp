// src/pages/technicians/TechnicianDetails.js
import React, { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
    Box, Paper, Typography, Avatar, Chip, CircularProgress, Alert,
    Card, CardContent, Grid, Divider, Button, Stack, Dialog, DialogTitle,
    DialogContent, DialogContentText, DialogActions, LinearProgress,
    IconButton, useMediaQuery, useTheme, alpha, Table as MuiTable,
    TableBody as MuiTableBody, TableCell as MuiTableCell,
    TableRow as MuiTableRow, Tooltip,
} from '@mui/material';
import {
    ArrowBack as ArrowBackIcon, Verified as VerifiedIcon,
    LocationOn as LocationIcon, Email as EmailIcon, Phone as PhoneIcon,
    Star as StarIcon, Image as ImageIcon, Close as CloseIcon,
    ZoomIn as ZoomInIcon, Person as PersonIcon, Work as WorkIcon,
    DocumentScanner as DocumentIcon, CalendarToday as CalendarIcon,
    Subscriptions as SubscriptionsIcon, CheckCircle as ApproveIcon,
    Refresh as RefreshIcon, Fingerprint as FingerprintIcon,
    Face as FaceIcon, Visibility as ViewIcon, VisibilityOff as HideIcon,
    ContentCopy as CopyIcon,
} from '@mui/icons-material';
import { technicianService } from 'services/technician.service';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { getImageUrl, isBase64Image, getBase64Mime } from 'utils/imageUtils';
import { tTech } from './technicianslang';
import appConfig from '../../config';

// ── Null-safe color palette ─────────────────────────────────
const colors = appConfig?.app?.colors || {};
const SEA = colors.sea || '#0f766e';
const SALAT = colors.salat || '#10b981';
const DARK = colors.dark || '#047857';

// ── Local Helpers ───────────────────────────────────────────
/** Turn `key=value|key=value` into [[k, v], ...] (skips empty parts). */
const parseFingerprintMetadata = (str) => {
    if (!str || typeof str !== 'string') return [];
    return str
        .split('|')
        .map((part) => {
            const idx = part.indexOf('=');
            return idx === -1 ? [part.trim(), ''] : [part.slice(0, idx).trim(), part.slice(idx + 1).trim()];
        })
        .filter(([k]) => k.length > 0);
};

/** Extract `verified_at=...` from fingerprint data and format it safely. */
const extractVerifiedAt = (fingerprintData) => {
    if (!fingerprintData || typeof fingerprintData !== 'string') return null;
    const match = fingerprintData.match(/verified_at=([^|]+)/);
    if (!match) return null;
    const ts = (match[1] || '').trim();
    if (!ts) return null;
    try {
        const d = new Date(ts);
        if (Number.isNaN(d.getTime())) return ts;
        return d.toLocaleString();
    } catch {
        return ts;
    }
};

/** Safe date formatter — never throws. */
const safeFormatDate = (input, fallback = '-') => {
    if (!input) return fallback;
    try {
        const d = new Date(input);
        if (Number.isNaN(d.getTime())) return String(input);
        return d.toLocaleString();
    } catch {
        return String(input);
    }
};

/** Copy helper (with silent fallback for old browsers). */
const copyToClipboard = async (text) => {
    try {
        if (navigator?.clipboard?.writeText) {
            await navigator.clipboard.writeText(text);
            return true;
        }
    } catch { /* ignore */ }
    return false;
};

// ── Component ───────────────────────────────────────────────
const TechnicianDetails = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

    const { language } = useLanguage();
    const t = (key, replacements) =>
        tTech(language, key, Object.fromEntries(
            Object.entries(replacements || {}).map(([k, v]) => [k, v ?? ''])
        ));

    const [technician, setTechnician] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const { can } = usePermissions();
    const canView = can('technicians.view');
    const canApprove = can('technicians.approve');

    // Image modal
    const [imageErrors, setImageErrors] = useState({});
    const [imageModalOpen, setImageModalOpen] = useState(false);
    const [imageModalSrc, setImageModalSrc] = useState('');
    const [imageModalAlt, setImageModalAlt] = useState('');

    // Approve dialog
    const [approveDialogOpen, setApproveDialogOpen] = useState(false);
    const [approveProcessing, setApproveProcessing] = useState(false);
    const [approveProgress, setApproveProgress] = useState(0);
    const [approveFeedback, setApproveFeedback] = useState(null);

    // Biometrics
    const [biometrics, setBiometrics] = useState(null);
    const [biometricsLoading, setBiometricsLoading] = useState(false);
    const [biometricsError, setBiometricsError] = useState(null);
    const [showBiometrics, setShowBiometrics] = useState(true);

    // ── Fetch technician ────────────────────────────────────
    const fetchTechnician = useCallback(async () => {
        if (!id) return;
        setLoading(true);
        try {
            const response = await technicianService.getTechnician(id);
            if (response?.data?.status === 'success') {
                setTechnician(response.data.data ?? null);
                setError(null);
            } else {
                setError(t('tech.notFound'));
            }
        } catch (err) {
            setError(err?.message || t('tech.loadFailed'));
        } finally {
            setLoading(false);
        }
    }, [id, language]); // eslint-disable-line react-hooks/exhaustive-deps

    // ── Fetch biometrics ────────────────────────────────────
    const fetchBiometrics = useCallback(async () => {
        if (!id) return;
        setBiometricsLoading(true);
        setBiometricsError(null);
        try {
            const res = await technicianService.getTechnicianBiometrics(id);
            if (res?.data?.status === 'success') {
                setBiometrics(res.data.data ?? null);
            } else {
                setBiometricsError(t('tech.bio.loadFailed'));
            }
        } catch (err) {
            setBiometricsError(err?.message || t('tech.bio.loadFailed'));
        } finally {
            setBiometricsLoading(false);
        }
    }, [id, language]); // eslint-disable-line react-hooks/exhaustive-deps

    // ── Mount: fetch technician + background pre-fetch biometrics ─
    useEffect(() => {
        if (!canView) {
            setError(t('tech.accessDenied'));
            setLoading(false);
            return;
        }
        fetchTechnician();
        fetchBiometrics();
    }, [id, canView, language, fetchTechnician, fetchBiometrics]); // eslint-disable-line react-hooks/exhaustive-deps

    const toggleBiometrics = () => setShowBiometrics((v) => !v);

    // ── Image modal ─────────────────────────────────────────
    const handleImageError = (key) => setImageErrors((p) => ({ ...p, [key]: true }));

    const openImageModal = (src, alt = '') => {
        if (!src) return;
        setImageModalSrc(src);
        setImageModalAlt(alt);
        setImageModalOpen(true);
    };

    const closeImageModal = () => {
        setImageModalOpen(false);
        setImageModalSrc('');
        setImageModalAlt('');
    };

    // ── Status chip ─────────────────────────────────────────
    const getStatusChip = () => {
        if (!technician) return null;
        const isVerified = technician.verified === true && technician.verification_status === 'approved';
        const status = technician.verification_status || 'pending';

        if (isVerified) {
            return (
                <Chip
                    label={t('tech.status.verified')}
                    icon={<VerifiedIcon sx={{ fontSize: 16 }} />}
                    sx={{
                        fontWeight: 700, bgcolor: 'success.light', color: 'success.dark',
                        border: '1.5px solid', borderColor: 'success.main', height: 32,
                        '& .MuiChip-icon': { color: 'success.dark' },
                    }}
                />
            );
        }

        const statusMap = {
            approved: { label: t('tech.status.approved'), color: 'success.dark', bg: 'success.light', border: 'success.main' },
            pending:  { label: t('tech.status.pending'),  color: 'warning.dark', bg: 'warning.light', border: 'warning.main' },
            rejected: { label: t('tech.status.rejected'), color: 'error.dark',   bg: 'error.light',   border: 'error.main'   },
        };
        const s = statusMap[status] || statusMap.pending;
        return (
            <Chip
                label={s.label}
                sx={{
                    fontWeight: 700, bgcolor: s.bg, color: s.color,
                    border: '1.5px solid', borderColor: s.border, height: 32,
                }}
            />
        );
    };

    // ── Approve ─────────────────────────────────────────────
    const openApproveDialog = () => {
        setApproveDialogOpen(true);
        setApproveProgress(0);
        setApproveFeedback(null);
    };

    const closeApproveDialog = () => {
        if (!approveProcessing) {
            setApproveDialogOpen(false);
            setApproveProgress(0);
        }
    };

    const confirmApprove = async () => {
        setApproveProcessing(true);
        setApproveProgress(0);

        const interval = setInterval(() => {
            setApproveProgress((prev) => (prev < 90 ? Math.min(prev + Math.random() * 10, 90) : prev));
        }, 300);

        try {
            const response = await technicianService.approveTechnician(id);
            clearInterval(interval);
            setApproveProgress(100);

            if (response?.data?.status === 'success') {
                setApproveFeedback({ type: 'success', message: t('tech.approve.successMsg') });
                setTechnician((prev) => (prev ? { ...prev, verified: true, verification_status: 'approved' } : prev));
                await fetchTechnician();
                showSnackbar({ type: 'success', message: t('tech.approve.snackbarSuccess') });
            } else {
                setApproveFeedback({
                    type: 'error',
                    message: response?.data?.message || t('tech.approve.failedMsg'),
                });
            }
        } catch (err) {
            clearInterval(interval);
            setApproveProgress(0);
            setApproveFeedback({ type: 'error', message: err?.message || t('tech.approve.errorMsg') });
        } finally {
            setApproveProcessing(false);
            setTimeout(() => {
                setApproveDialogOpen(false);
                setApproveProgress(0);
            }, 600);
        }
    };

    // ── Copy fingerprint raw data ───────────────────────────
    const handleCopyFingerprint = async () => {
        const ok = await copyToClipboard(biometrics?.fingerprint_data || '');
        showSnackbar({
            type: ok ? 'success' : 'warning',
            message: ok ? t('tech.bio.copied') : t('tech.bio.copyFailed'),
        });
    };

    // ── Early states ────────────────────────────────────────
    if (loading) {
        return (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
                <CircularProgress size={40} thickness={4} sx={{ color: SEA }} />
            </Box>
        );
    }

    if (error) {
        return (
            <Box p={3}>
                <Alert severity="error" sx={{ borderRadius: 2, mb: 2 }}>{error}</Alert>
                <Button
                    variant="contained" startIcon={<ArrowBackIcon />}
                    onClick={() => navigate('/app/technicians')}
                    sx={{ borderRadius: 2, textTransform: 'none' }}
                >
                    {t('tech.common.back')}
                </Button>
            </Box>
        );
    }

    if (!technician) return null;

    const user = technician.user || {};
    const profilePhotoUrl = technician.profile_photo ? getImageUrl(technician.profile_photo) : null;
    const idDocumentUrl = technician.id_document_image ? getImageUrl(technician.id_document_image) : null;
    const hasIdDocument = Boolean(technician.id_document_type || technician.id_document_image);
    const isVerified = technician.verified === true && technician.verification_status === 'approved';

    // Defensive arrays
    const services = Array.isArray(technician.services) ? technician.services.filter(Boolean) : [];
    const portfolios = Array.isArray(technician.portfolios) ? technician.portfolios.filter(Boolean) : [];
    const subscriptions = Array.isArray(user.subscriptions) ? user.subscriptions.filter(Boolean) : [];

    // Biometric derivations
    const bio = biometrics || {};
    const fingerprintIsImage = isBase64Image(bio.fingerprint_data);
    const fingerprintIsMetadata = !!bio.fingerprint_data && !fingerprintIsImage;
    const parsedFingerprint = fingerprintIsMetadata ? parseFingerprintMetadata(bio.fingerprint_data) : [];
    const verifiedAtFromData = extractVerifiedAt(bio.fingerprint_data);
    const fingerprintCapturedAt = bio.fingerprint_captured_at || verifiedAtFromData || null;

    const faceIsImage = isBase64Image(bio.face_data);
    const hasNextOfKin = Boolean(bio.next_of_kin_name || bio.next_of_kin_phone || bio.next_of_kin_relationship);
    const hasAnyBiometric = Boolean(
        bio.fingerprint_enrolled || bio.face_enrolled ||
        bio.fingerprint_data || bio.face_data
    );

    return (
        <Box sx={{ p: { xs: 1.5, sm: 2.5 }, m: 0, bgcolor: 'background.default', minHeight: '100vh' }}>
            <Paper elevation={0} sx={{
                width: '100%', borderRadius: 3, overflow: 'hidden',
                border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper',
            }}>
                {/* ═══ HEADER ═══ */}
                <Box sx={{
                    px: { xs: 2, sm: 3 }, py: 2.5,
                    borderBottom: '1px solid', borderColor: 'divider',
                    display: 'flex', justifyContent: 'space-between',
                    alignItems: 'center', flexWrap: 'wrap', gap: 2,
                }}>
                    <Button
                        startIcon={<ArrowBackIcon />}
                        onClick={() => navigate('/app/technicians')}
                        sx={{
                            color: SEA, fontWeight: 600, textTransform: 'none',
                            '&:hover': { bgcolor: alpha(SEA, 0.08) },
                        }}
                    >
                        {t('tech.common.back')}
                    </Button>

                    <Stack direction="row" spacing={1.5}>
                        <Button
                            variant="outlined" startIcon={<RefreshIcon />}
                            onClick={() => { fetchTechnician(); fetchBiometrics(); }}
                            disabled={loading || biometricsLoading}
                            size={isMobile ? 'small' : 'medium'}
                            sx={{
                                borderRadius: 2, textTransform: 'none', fontWeight: 600,
                                borderColor: 'divider',
                                '&:hover': { borderColor: SEA },
                            }}
                        >
                            {t('tech.common.refresh')}
                        </Button>
                        {canApprove && !isVerified && (
                            <Button
                                variant="contained" startIcon={<ApproveIcon />}
                                onClick={openApproveDialog}
                                sx={{
                                    borderRadius: 2, textTransform: 'none', fontWeight: 700,
                                    bgcolor: SALAT,
                                    '&:hover': { bgcolor: DARK },
                                }}
                            >
                                {t('tech.action.approveTechnician')}
                            </Button>
                        )}
                    </Stack>
                </Box>

                {approveFeedback && (
                    <Box sx={{ px: { xs: 2, sm: 3 }, pt: 2 }}>
                        <Alert
                            severity={approveFeedback.type}
                            onClose={() => setApproveFeedback(null)}
                            sx={{ borderRadius: 2 }}
                        >
                            {approveFeedback.message}
                        </Alert>
                    </Box>
                )}

                {/* ═══ PROFILE HEADER ═══ */}
                <Box sx={{
                    px: { xs: 2, sm: 3, md: 4 }, py: { xs: 2, sm: 3, md: 4 },
                    display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 3,
                    alignItems: { xs: 'center', md: 'flex-start' },
                    borderBottom: '1px solid', borderColor: 'divider',
                    bgcolor: 'action.hover',
                }}>
                    <Box
                        sx={{
                            position: 'relative',
                            cursor: profilePhotoUrl ? 'pointer' : 'default',
                            flexShrink: 0,
                        }}
                        onClick={() => profilePhotoUrl && openImageModal(profilePhotoUrl, `${user.name || 'Technician'} Profile`)}
                    >
                        <Avatar
                            src={profilePhotoUrl || undefined}
                            sx={{
                                width: { xs: 120, sm: 140, md: 160 },
                                height: { xs: 120, sm: 140, md: 160 },
                                bgcolor: SEA, fontSize: '4rem', fontWeight: 700,
                                border: `4px solid ${alpha(SEA, 0.15)}`,
                                boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
                                transition: 'all 0.2s',
                                '&:hover': profilePhotoUrl ? {
                                    transform: 'scale(1.03)',
                                    borderColor: SEA,
                                } : undefined,
                            }}
                            onError={() => handleImageError('profile')}
                        >
                            {!profilePhotoUrl || imageErrors['profile']
                                ? (user.name?.charAt(0) || 'T').toUpperCase()
                                : null}
                        </Avatar>
                        {profilePhotoUrl && !imageErrors['profile'] && (
                            <Box sx={{
                                position: 'absolute', bottom: 4, right: 4,
                                backgroundColor: 'rgba(0,0,0,0.6)', borderRadius: '50%',
                                p: 0.5, display: 'flex', alignItems: 'center', justifyContent: 'center',
                            }}>
                                <ZoomInIcon sx={{ fontSize: 18, color: '#fff' }} />
                            </Box>
                        )}
                    </Box>

                    <Box flex={1} textAlign={{ xs: 'center', md: 'left' }}>
                        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5}
                               alignItems={{ xs: 'center', sm: 'flex-start' }} mb={1}>
                            <Typography variant="h4" fontWeight={700} color="text.primary">
                                {user.name || t('tech.common.unknown')}
                            </Typography>
                            {getStatusChip()}
                        </Stack>

                        <Stack direction="row" spacing={1} flexWrap="wrap"
                               sx={{ mb: 1.5, justifyContent: { xs: 'center', md: 'flex-start' } }}>
                            <Chip
                                label={technician.registration_completed ? t('tech.reg.registered') : t('tech.reg.incomplete')}
                                size="small"
                                sx={{
                                    fontWeight: 600,
                                    bgcolor: technician.registration_completed ? 'success.light' : 'action.hover',
                                    color: technician.registration_completed ? 'success.dark' : 'text.secondary',
                                    border: '1px solid',
                                    borderColor: technician.registration_completed ? 'success.main' : 'divider',
                                }}
                            />
                            <Chip
                                label={t('tech.reg.step', { step: technician.registration_step || 0 })}
                                size="small"
                                sx={{ fontWeight: 600, bgcolor: 'action.hover' }}
                            />
                        </Stack>

                        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} flexWrap="wrap">
                            <Box display="flex" alignItems="center" gap={1}>
                                <EmailIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                <Typography variant="body2">{user.email || t('tech.common.na')}</Typography>
                            </Box>
                            <Box display="flex" alignItems="center" gap={1}>
                                <PhoneIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                <Typography variant="body2">{user.phone || t('tech.common.na')}</Typography>
                            </Box>
                            <Box display="flex" alignItems="center" gap={1}>
                                <LocationIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                <Typography variant="body2">{technician.area || t('tech.common.na')}</Typography>
                            </Box>
                        </Stack>

                        <Stack direction="row" spacing={2.5} flexWrap="wrap"
                               sx={{ mt: 1.5, justifyContent: { xs: 'center', md: 'flex-start' } }}>
                            <Box display="flex" alignItems="center" gap={0.5}>
                                <StarIcon sx={{ fontSize: 20, color: 'warning.main' }} />
                                <Typography variant="body2" fontWeight={700}>
                                    {technician.rating != null ? Number(technician.rating).toFixed(1) : t('tech.common.na')}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                    {t('tech.profile.jobsCount', { n: technician.completed_jobs_count ?? 0 })}
                                </Typography>
                            </Box>
                            {technician.experience != null && (
                                <Typography variant="body2">
                                    <strong>{t('tech.profile.experience')}</strong>{' '}
                                    {t('tech.profile.years', { n: technician.experience })}
                                </Typography>
                            )}
                            {technician.hourly_rate != null && (
                                <Typography variant="body2" fontWeight={700} color={SEA}>
                                    {t('tech.profile.perHour', { rate: technician.hourly_rate })}
                                </Typography>
                            )}
                        </Stack>
                    </Box>
                </Box>

                {/* ═══ DETAILS CONTENT ═══ */}
                <Box sx={{ p: { xs: 2, sm: 3, md: 4 } }}>
                    <Grid container spacing={3}>
                        {/* LEFT COLUMN */}
                        <Grid item xs={12} md={6}>
                            <Stack spacing={3}>
                                {/* Bio */}
                                <Card variant="outlined" sx={{ borderColor: 'divider', bgcolor: 'background.paper' }}>
                                    <CardContent>
                                        <Typography variant="subtitle1" fontWeight={700} color="text.primary" mb={1.5}>
                                            <PersonIcon sx={{ fontSize: 20, mr: 1, verticalAlign: 'middle', color: SEA }} />
                                            {t('tech.section.bio')}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary" sx={{ lineHeight: 1.8 }}>
                                            {technician.bio || t('tech.bio.empty')}
                                        </Typography>
                                    </CardContent>
                                </Card>

                                {/* Identification */}
                                <Card variant="outlined" sx={{ borderColor: 'divider', bgcolor: 'background.paper' }}>
                                    <CardContent>
                                        <Typography variant="subtitle1" fontWeight={700} color="text.primary" mb={1.5}>
                                            <DocumentIcon sx={{ fontSize: 20, mr: 1, verticalAlign: 'middle', color: SEA }} />
                                            {t('tech.section.identification')}
                                        </Typography>
                                        {hasIdDocument ? (
                                            <Stack spacing={1.5}>
                                                {technician.nida && (
                                                    <Typography variant="body2">
                                                        <strong>{t('tech.id.nida')}</strong> {technician.nida}
                                                    </Typography>
                                                )}
                                                <Typography variant="body2">
                                                    <strong>{t('tech.id.documentType')}</strong>{' '}
                                                    {technician.id_document_type || t('tech.common.na')}
                                                </Typography>
                                                <Typography variant="body2">
                                                    <strong>{t('tech.id.verificationStatus')}</strong>{' '}
                                                    {technician.verification_status || t('tech.common.na')}
                                                </Typography>
                                                {idDocumentUrl && !imageErrors['id'] && (
                                                    <Box mt={1}>
                                                        <Typography variant="body2" fontWeight={600} mb={1}>
                                                            {t('tech.id.documentLabel')}
                                                        </Typography>
                                                        <Box
                                                            component="img"
                                                            src={idDocumentUrl}
                                                            alt="ID Document"
                                                            onClick={() => openImageModal(idDocumentUrl, 'ID Document')}
                                                            sx={{
                                                                maxWidth: '100%', maxHeight: 250,
                                                                border: '1px solid', borderColor: 'divider',
                                                                borderRadius: 2, objectFit: 'contain',
                                                                bgcolor: 'action.hover', p: 1, cursor: 'pointer',
                                                                transition: 'all 0.2s',
                                                                '&:hover': {
                                                                    borderColor: SEA,
                                                                    transform: 'scale(1.02)',
                                                                },
                                                            }}
                                                            onError={() => handleImageError('id')}
                                                        />
                                                    </Box>
                                                )}
                                            </Stack>
                                        ) : (
                                            <Typography variant="body2" color="text.secondary">
                                                {t('tech.id.noDocuments')}
                                            </Typography>
                                        )}
                                    </CardContent>
                                </Card>

                                {/* ═══ Biometric Verification ═══ */}
                                <Card variant="outlined" sx={{ borderColor: 'divider', bgcolor: 'background.paper' }}>
                                    <CardContent>
                                        <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1.5}>
                                            <Typography variant="subtitle1" fontWeight={700}>
                                                <FingerprintIcon sx={{ fontSize: 20, mr: 1, verticalAlign: 'middle', color: SEA }} />
                                                {t('tech.section.biometrics')}
                                            </Typography>
                                            <Stack direction="row" spacing={1}>
                                                <IconButton
                                                    size="small"
                                                    onClick={fetchBiometrics}
                                                    disabled={biometricsLoading}
                                                    title={t('tech.common.refresh')}
                                                >
                                                    <RefreshIcon fontSize="small" />
                                                </IconButton>
                                                <Button
                                                    size="small"
                                                    variant="outlined"
                                                    startIcon={showBiometrics ? <HideIcon /> : <ViewIcon />}
                                                    onClick={toggleBiometrics}
                                                    sx={{ borderRadius: 2, textTransform: 'none', fontWeight: 600 }}
                                                >
                                                    {showBiometrics ? t('tech.bio.hide') : t('tech.bio.view')}
                                                </Button>
                                            </Stack>
                                        </Stack>

                                        {biometricsLoading && !biometrics && (
                                            <Box display="flex" justifyContent="center" py={3}>
                                                <CircularProgress size={28} />
                                            </Box>
                                        )}

                                        {biometricsError && !biometrics && (
                                            <Alert severity="error" sx={{ borderRadius: 2, mb: 2 }}>
                                                {biometricsError}
                                            </Alert>
                                        )}

                                        {biometrics && !hasAnyBiometric && (
                                            <Typography variant="body2" color="text.secondary">
                                                {t('tech.bio.noBiometrics')}
                                            </Typography>
                                        )}

                                        {showBiometrics && biometrics && hasAnyBiometric && (
                                            <Stack spacing={2}>
                                                {/* Enrollment summary */}
                                                <Grid container spacing={1.5}>
                                                    <Grid item xs={6}>
                                                        <Box sx={{ p: 1.5, borderRadius: 2, bgcolor: 'action.hover' }}>
                                                            <Stack direction="row" spacing={1} alignItems="center">
                                                                <FingerprintIcon fontSize="small" color="primary" />
                                                                <Typography variant="caption" fontWeight={700}>
                                                                    {t('tech.bio.fingerprint')}
                                                                </Typography>
                                                            </Stack>
                                                            <Typography variant="body2" fontWeight={600} mt={0.5}>
                                                                {bio.fingerprint_enrolled ? t('tech.bio.enrolled') : t('tech.bio.notEnrolled')}
                                                            </Typography>
                                                        </Box>
                                                    </Grid>
                                                    <Grid item xs={6}>
                                                        <Box sx={{ p: 1.5, borderRadius: 2, bgcolor: 'action.hover' }}>
                                                            <Stack direction="row" spacing={1} alignItems="center">
                                                                <FaceIcon fontSize="small" color="primary" />
                                                                <Typography variant="caption" fontWeight={700}>
                                                                    {t('tech.bio.face')}
                                                                </Typography>
                                                            </Stack>
                                                            <Typography variant="body2" fontWeight={600} mt={0.5}>
                                                                {bio.face_enrolled ? t('tech.bio.enrolled') : t('tech.bio.notEnrolled')}
                                                            </Typography>
                                                        </Box>
                                                    </Grid>
                                                </Grid>

                                                {/* ══ FINGERPRINT CAPTURE ══ */}
                                                {fingerprintIsMetadata && (
                                                    <Box>
                                                        <Stack direction="row" alignItems="center" justifyContent="space-between" mb={0.5}>
                                                            <Typography variant="caption" fontWeight={700} color="text.secondary">
                                                                {t('tech.bio.fingerprintCapture')}
                                                            </Typography>
                                                            <Tooltip title={t('tech.bio.copy')}>
                                                                <IconButton size="small" onClick={handleCopyFingerprint}>
                                                                    <CopyIcon fontSize="small" />
                                                                </IconButton>
                                                            </Tooltip>
                                                        </Stack>

                                                        {parsedFingerprint.length > 0 ? (
                                                            <MuiTable size="small" sx={{
                                                                border: '1px solid', borderColor: 'divider',
                                                                borderRadius: 2, overflow: 'hidden',
                                                            }}>
                                                                <MuiTableBody>
                                                                    {parsedFingerprint.map(([k, v]) => (
                                                                        <MuiTableRow key={`${k}-${v}`}>
                                                                            <MuiTableCell sx={{
                                                                                fontWeight: 700, py: 0.75, width: 140,
                                                                                borderColor: 'divider', textTransform: 'capitalize',
                                                                            }}>
                                                                                {k.replace(/_/g, ' ')}
                                                                            </MuiTableCell>
                                                                            <MuiTableCell sx={{
                                                                                py: 0.75, borderColor: 'divider',
                                                                                wordBreak: 'break-all', fontFamily: 'monospace', fontSize: '0.8rem',
                                                                            }}>
                                                                                {v || '-'}
                                                                            </MuiTableCell>
                                                                        </MuiTableRow>
                                                                    ))}
                                                                </MuiTableBody>
                                                            </MuiTable>
                                                        ) : (
                                                            <Box sx={{
                                                                p: 1.5, border: '1px solid', borderColor: 'divider',
                                                                borderRadius: 2, bgcolor: 'action.hover',
                                                                fontFamily: 'monospace', fontSize: '0.8rem',
                                                                wordBreak: 'break-all',
                                                            }}>
                                                                {bio.fingerprint_data}
                                                            </Box>
                                                        )}

                                                        {fingerprintCapturedAt && (
                                                            <Typography variant="caption" display="block" mt={1} color="text.secondary">
                                                                <strong>{t('tech.bio.capturedAt')}:</strong> {safeFormatDate(fingerprintCapturedAt)}
                                                            </Typography>
                                                        )}
                                                    </Box>
                                                )}

                                                {/* Fingerprint as image (rare) */}
                                                {fingerprintIsImage && (
                                                    <Box>
                                                        <Typography variant="caption" fontWeight={700} color="text.secondary">
                                                            {t('tech.bio.fingerprintCapture')}
                                                        </Typography>
                                                        <Box
                                                            component="img"
                                                            src={`data:${getBase64Mime(bio.fingerprint_data)};base64,${bio.fingerprint_data}`}
                                                            alt="Fingerprint capture"
                                                            onClick={() => openImageModal(
                                                                `data:${getBase64Mime(bio.fingerprint_data)};base64,${bio.fingerprint_data}`,
                                                                'Fingerprint Capture'
                                                            )}
                                                            sx={{
                                                                mt: 0.5, maxWidth: 220, maxHeight: 220,
                                                                borderRadius: 2, border: '1px solid', borderColor: 'divider',
                                                                objectFit: 'cover', cursor: 'pointer',
                                                                transition: 'transform 0.2s',
                                                                '&:hover': { transform: 'scale(1.03)', borderColor: SEA },
                                                            }}
                                                        />
                                                    </Box>
                                                )}

                                                {/* ══ FACE CAPTURE ══ */}
                                                {faceIsImage && (
                                                    <Box>
                                                        <Typography variant="caption" fontWeight={700} color="text.secondary">
                                                            {t('tech.bio.faceCapture')}
                                                        </Typography>
                                                        <Box
                                                            component="img"
                                                            src={`data:${getBase64Mime(bio.face_data)};base64,${bio.face_data}`}
                                                            alt="Face capture"
                                                            onClick={() => openImageModal(
                                                                `data:${getBase64Mime(bio.face_data)};base64,${bio.face_data}`,
                                                                'Face Capture'
                                                            )}
                                                            sx={{
                                                                mt: 0.5, maxWidth: 220, maxHeight: 220,
                                                                borderRadius: 2, border: '1px solid', borderColor: 'divider',
                                                                objectFit: 'cover', cursor: 'pointer',
                                                                transition: 'transform 0.2s',
                                                                '&:hover': { transform: 'scale(1.03)', borderColor: SEA },
                                                            }}
                                                        />
                                                    </Box>
                                                )}

                                                {bio.face_captured_at && (
                                                    <Typography variant="caption" color="text.secondary">
                                                        <strong>{t('tech.bio.face')} {t('tech.bio.capturedAt')}:</strong>{' '}
                                                        {safeFormatDate(bio.face_captured_at)}
                                                    </Typography>
                                                )}

                                                {/* Next of Kin */}
                                                {hasNextOfKin && (
                                                    <Box>
                                                        <Typography variant="caption" fontWeight={700} color="text.secondary">
                                                            {t('tech.bio.nextOfKin')}
                                                        </Typography>
                                                        <Box sx={{ mt: 0.5, p: 1.5, borderRadius: 2, bgcolor: 'action.hover' }}>
                                                            <Typography variant="body2">
                                                                <strong>{t('tech.bio.name')}</strong> {bio.next_of_kin_name || '-'}
                                                            </Typography>
                                                            <Typography variant="body2">
                                                                <strong>{t('tech.bio.phone')}</strong> {bio.next_of_kin_phone || '-'}
                                                            </Typography>
                                                            <Typography variant="body2">
                                                                <strong>{t('tech.bio.relationship')}</strong> {bio.next_of_kin_relationship || '-'}
                                                            </Typography>
                                                        </Box>
                                                    </Box>
                                                )}
                                            </Stack>
                                        )}
                                    </CardContent>
                                </Card>

                                {/* Services — no price ranges */}
                                <Card variant="outlined" sx={{ borderColor: 'divider', bgcolor: 'background.paper' }}>
                                    <CardContent>
                                        <Typography variant="subtitle1" fontWeight={700} color="text.primary" mb={1.5}>
                                            <WorkIcon sx={{ fontSize: 20, mr: 1, verticalAlign: 'middle', color: SEA }} />
                                            {t('tech.section.services')}
                                        </Typography>
                                        {services.length > 0 ? (
                                            <Grid container spacing={1.5}>
                                                {services.map((service, idx) => (
                                                    <Grid item xs={12} sm={6} key={service.id ?? `svc-${idx}`}>
                                                        <Box sx={{
                                                            p: 2, bgcolor: 'action.hover', borderRadius: 2,
                                                            border: '1px solid', borderColor: 'divider',
                                                            transition: 'all 0.2s',
                                                            '&:hover': {
                                                                borderColor: SEA,
                                                                bgcolor: alpha(SEA, 0.04),
                                                            },
                                                        }}>
                                                            <Typography variant="body2" fontWeight={600} color="text.primary">
                                                                {service.name || t('tech.common.unknown')}
                                                            </Typography>
                                                            {service.swahili_name && (
                                                                <Typography variant="caption" color="text.secondary">
                                                                    {service.swahili_name}
                                                                </Typography>
                                                            )}
                                                        </Box>
                                                    </Grid>
                                                ))}
                                            </Grid>
                                        ) : (
                                            <Typography variant="body2" color="text.secondary">
                                                {t('tech.service.none')}
                                            </Typography>
                                        )}
                                    </CardContent>
                                </Card>

                                {/* Location */}
                                <Card variant="outlined" sx={{ borderColor: 'divider', bgcolor: 'background.paper' }}>
                                    <CardContent>
                                        <Typography variant="subtitle1" fontWeight={700} color="text.primary" mb={1.5}>
                                            <LocationIcon sx={{ fontSize: 20, mr: 1, verticalAlign: 'middle', color: SEA }} />
                                            {t('tech.section.location')}
                                        </Typography>
                                        <Stack spacing={1.5}>
                                            <Typography variant="body2">
                                                <strong>{t('tech.location.area')}</strong>{' '}
                                                {technician.area || t('tech.common.na')}
                                            </Typography>
                                            {technician.latitude != null && technician.longitude != null && (
                                                <Typography variant="body2">
                                                    <strong>{t('tech.location.coordinates')}</strong>{' '}
                                                    {technician.latitude}, {technician.longitude}
                                                </Typography>
                                            )}
                                            {technician.location_updated_at && (
                                                <Typography variant="body2" display="flex" alignItems="center" gap={1}>
                                                    <CalendarIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                    <strong>{t('tech.location.lastUpdate')}</strong>{' '}
                                                    {safeFormatDate(technician.location_updated_at)}
                                                </Typography>
                                            )}
                                            {technician.last_activity_at && (
                                                <Typography variant="body2" display="flex" alignItems="center" gap={1}>
                                                    <CalendarIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                    <strong>{t('tech.location.lastActivity')}</strong>{' '}
                                                    {safeFormatDate(technician.last_activity_at)}
                                                </Typography>
                                            )}
                                        </Stack>
                                    </CardContent>
                                </Card>
                            </Stack>
                        </Grid>

                        {/* RIGHT COLUMN */}
                        <Grid item xs={12} md={6}>
                            <Stack spacing={3}>
                                {/* Portfolio */}
                                {portfolios.length > 0 && (
                                    <Card variant="outlined" sx={{ borderColor: 'divider', bgcolor: 'background.paper' }}>
                                        <CardContent>
                                            <Typography variant="subtitle1" fontWeight={700} color="text.primary" mb={1.5}>
                                                <ImageIcon sx={{ fontSize: 20, mr: 1, verticalAlign: 'middle', color: SEA }} />
                                                {t('tech.section.portfolio', { n: portfolios.length })}
                                            </Typography>
                                            <Grid container spacing={1.5}>
                                                {portfolios.map((item, idx) => {
                                                    const imgUrl = item?.image ? getImageUrl(item.image) : null;
                                                    const key = item?.id ?? `port-${idx}`;
                                                    return (
                                                        <Grid item xs={12} sm={6} key={key}>
                                                            <Box
                                                                sx={{
                                                                    border: '1px solid', borderColor: 'divider',
                                                                    borderRadius: 2, overflow: 'hidden',
                                                                    bgcolor: 'action.hover',
                                                                    cursor: imgUrl ? 'pointer' : 'default',
                                                                    transition: 'all 0.2s',
                                                                    '&:hover': imgUrl ? {
                                                                        borderColor: SEA,
                                                                        transform: 'scale(1.02)',
                                                                    } : undefined,
                                                                }}
                                                                onClick={() => imgUrl && openImageModal(imgUrl, item?.description || 'Portfolio')}
                                                            >
                                                                {imgUrl && !imageErrors[`portfolio-${key}`] ? (
                                                                    <img src={imgUrl} alt={item?.description || 'Portfolio'}
                                                                         style={{ width: '100%', height: 160, objectFit: 'cover', display: 'block' }}
                                                                         onError={() => handleImageError(`portfolio-${key}`)} />
                                                                ) : (
                                                                    <Box sx={{
                                                                        height: 160, display: 'flex',
                                                                        alignItems: 'center', justifyContent: 'center',
                                                                        bgcolor: 'action.hover', color: 'text.disabled',
                                                                    }}>
                                                                        <ImageIcon sx={{ fontSize: 48, opacity: 0.5 }} />
                                                                    </Box>
                                                                )}
                                                                {item?.description && (
                                                                    <Box sx={{ p: 1.5, bgcolor: 'background.paper' }}>
                                                                        <Typography variant="caption" color="text.secondary">
                                                                            {item.description}
                                                                        </Typography>
                                                                    </Box>
                                                                )}
                                                            </Box>
                                                        </Grid>
                                                    );
                                                })}
                                            </Grid>
                                        </CardContent>
                                    </Card>
                                )}

                                {/* Subscription */}
                                <Card variant="outlined" sx={{ borderColor: 'divider', bgcolor: 'background.paper' }}>
                                    <CardContent>
                                        <Typography variant="subtitle1" fontWeight={700} color="text.primary" mb={1.5}>
                                            <SubscriptionsIcon sx={{ fontSize: 20, mr: 1, verticalAlign: 'middle', color: SEA }} />
                                            {t('tech.section.subscriptionHistory')}
                                        </Typography>

                                        {subscriptions.length > 0 ? (
                                            <Stack spacing={1.5}>
                                                {subscriptions.map((sub, idx) => (
                                                    <Box key={sub?.id ?? `sub-${idx}`} sx={{
                                                        p: 2, bgcolor: 'action.hover', borderRadius: 2,
                                                        border: '1px solid', borderColor: 'divider',
                                                    }}>
                                                        <Grid container spacing={1}>
                                                            <Grid item xs={12} sm={6}>
                                                                <Typography variant="body2" fontWeight={600}>
                                                                    {t('tech.sub.plan', { name: sub?.rate_card?.name || t('tech.common.na') })}
                                                                </Typography>
                                                                <Box display="flex" alignItems="center" gap={0.5} mt={0.5}>
                                                                    <Typography variant="body2">{t('tech.sub.statusLabel')}</Typography>
                                                                    <Chip
                                                                        label={sub?.status || t('tech.common.na')}
                                                                        size="small"
                                                                        color={
                                                                            sub?.status === 'active' ? 'success' :
                                                                                sub?.status === 'expired' ? 'error' :
                                                                                    sub?.status === 'pending' ? 'warning' : 'default'
                                                                        }
                                                                    />
                                                                </Box>
                                                                <Typography variant="body2">
                                                                    {t('tech.sub.amount', {
                                                                        amount: sub?.amount_paid ?? 0,
                                                                        currency: sub?.currency || 'TZS',
                                                                    })}
                                                                </Typography>
                                                            </Grid>
                                                            <Grid item xs={12} sm={6}>
                                                                <Typography variant="body2">
                                                                    <strong>{t('tech.sub.start')}</strong> {safeFormatDate(sub?.start_date)}
                                                                </Typography>
                                                                <Typography variant="body2">
                                                                    <strong>{t('tech.sub.expiry')}</strong> {safeFormatDate(sub?.expiry_date)}
                                                                </Typography>
                                                                <Typography variant="body2">
                                                                    <strong>{t('tech.sub.payment')}</strong> {sub?.payment_method || t('tech.common.na')}
                                                                    {sub?.payment_reference ? ` (${sub.payment_reference})` : ''}
                                                                </Typography>
                                                            </Grid>
                                                        </Grid>
                                                    </Box>
                                                ))}
                                            </Stack>
                                        ) : (
                                            <Typography variant="body2" color="text.secondary">
                                                {t('tech.sub.none')}
                                            </Typography>
                                        )}

                                        <Divider sx={{ my: 1.5 }} />

                                        <Stack spacing={0.5}>
                                            <Box display="flex" alignItems="center" gap={0.5}>
                                                <Typography variant="body2">
                                                    <strong>{t('tech.sub.currentStatus')}</strong>
                                                </Typography>
                                                <Chip
                                                    label={user.subscription_status || t('tech.common.na')}
                                                    size="small"
                                                    color={
                                                        user.subscription_status === 'active' ? 'success' :
                                                            user.subscription_status === 'expired' ? 'error' :
                                                                user.subscription_status === 'pending' ? 'warning' : 'default'
                                                    }
                                                />
                                            </Box>
                                            {user.subscription_expires_at && (
                                                <Typography variant="body2">
                                                    <strong>{t('tech.sub.currentExpiry')}</strong>{' '}
                                                    {safeFormatDate(user.subscription_expires_at)}
                                                </Typography>
                                            )}
                                        </Stack>
                                    </CardContent>
                                </Card>
                            </Stack>
                        </Grid>
                    </Grid>
                </Box>
            </Paper>

            {/* ═══ APPROVAL DIALOG ═══ */}
            <Dialog
                open={approveDialogOpen}
                onClose={closeApproveDialog}
                maxWidth="sm" fullWidth
                PaperProps={{ sx: { borderRadius: 3, bgcolor: 'background.paper' } }}
            >
                <DialogTitle sx={{ fontWeight: 700, color: 'text.primary' }}>
                    {t('tech.approve.title')}
                </DialogTitle>
                <DialogContent>
                    <DialogContentText color="text.secondary" sx={{ mb: 2 }}>
                        {t('tech.approve.confirmMsg')}{' '}
                        <strong>{user.name || t('tech.approve.thisTechnician')}</strong>?{' '}
                        {t('tech.approve.freeTrialNote')}{' '}
                        <strong>{t('tech.approve.freeTrialDays')}</strong>{' '}
                        {t('tech.approve.freeTrialEnd')}
                    </DialogContentText>
                    {approveProcessing && (
                        <Box sx={{ width: '100%', mt: 2 }}>
                            <Box display="flex" justifyContent="space-between" alignItems="center">
                                <Typography variant="body2" color="text.secondary">
                                    {t('tech.approve.processing')}
                                </Typography>
                                <Typography variant="body2" fontWeight={600} color={SEA}>
                                    {Math.round(approveProgress)}%
                                </Typography>
                            </Box>
                            <LinearProgress
                                variant="determinate"
                                value={approveProgress}
                                sx={{
                                    height: 8, borderRadius: 4, mt: 0.5,
                                    bgcolor: 'action.hover',
                                    '& .MuiLinearProgress-bar': {
                                        bgcolor: SALAT,
                                        borderRadius: 4,
                                    },
                                }}
                            />
                        </Box>
                    )}
                </DialogContent>
                <DialogActions sx={{ px: 3, pb: 2.5, pt: 1 }}>
                    <Button onClick={closeApproveDialog} disabled={approveProcessing} sx={{ fontWeight: 600 }}>
                        {t('tech.common.cancel')}
                    </Button>
                    <Button
                        onClick={confirmApprove}
                        variant="contained"
                        disabled={approveProcessing}
                        sx={{
                            borderRadius: 2, fontWeight: 700, textTransform: 'none',
                            bgcolor: SALAT,
                            '&:hover': { bgcolor: DARK },
                        }}
                    >
                        {approveProcessing ? t('tech.approve.processingBtn') : t('tech.approve.confirmBtn')}
                    </Button>
                </DialogActions>
            </Dialog>

            {/* ═══ IMAGE MODAL ═══ */}
            <Dialog
                open={imageModalOpen}
                onClose={closeImageModal}
                maxWidth="lg" fullWidth
                PaperProps={{
                    sx: {
                        bgcolor: 'rgba(0,0,0,0.92)',
                        borderRadius: { xs: 0, sm: 3 },
                        overflow: 'hidden',
                    },
                }}
            >
                <IconButton
                    onClick={closeImageModal}
                    sx={{
                        position: 'absolute', top: 16, right: 16,
                        color: '#fff', zIndex: 10,
                        bgcolor: 'rgba(0,0,0,0.5)',
                        '&:hover': { bgcolor: 'rgba(0,0,0,0.7)' },
                    }}
                >
                    <CloseIcon />
                </IconButton>
                <DialogContent sx={{
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    minHeight: { xs: '60vh', sm: '80vh' }, p: 2,
                }}>
                    {imageModalSrc && (
                        <img
                            src={imageModalSrc}
                            alt={imageModalAlt || 'Image'}
                            style={{
                                maxWidth: '100%', maxHeight: '85vh',
                                objectFit: 'contain', borderRadius: 4,
                            }}
                        />
                    )}
                </DialogContent>
            </Dialog>
        </Box>
    );
};

export default TechnicianDetails;