// src/pages/privacy-policy/PrivacyPolicyPage.js
import React, { useState, useEffect } from 'react';
import {
    Box, Paper, Typography, Button, CircularProgress, Alert, Card, CardContent,
    IconButton, TextField, InputAdornment, useMediaQuery, useTheme, Stack, Grid, alpha,
} from '@mui/material';
import {
    Edit as EditIcon, Refresh as RefreshIcon, Add as AddIcon, Delete as DeleteIcon,
    Search as SearchIcon, Clear as ClearIcon, Description as DescriptionIcon,
    History as HistoryIcon, PrivacyTip as PrivacyTipIcon,
} from '@mui/icons-material';
import { usePrivacyPolicyManagement } from 'hooks/usePrivacyPolicy';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import PrivacyPolicyFormModal from './components/PrivacyPolicyFormModal';
import { tPrivacy } from './privacylang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const PrivacyPolicyPage = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const { language } = useLanguage();
    const t = (key) => tPrivacy(language, key);

    const {
        privacyPolicies,
        loading,
        error,
        getPrivacyPolicy,
        createPrivacyPolicy,
        updatePrivacyPolicy,
        deletePrivacyPolicy,
        clearError,
    } = usePrivacyPolicyManagement();

    const { can } = usePermissions();
    const [modalOpen, setModalOpen] = useState(false);
    const [editingPolicy, setEditingPolicy] = useState(null);
    const [search, setSearch] = useState('');

    const canEdit = can('privacy.edit');

    const loadPolicy = async () => {
        try {
            await getPrivacyPolicy();
        } catch {
            showSnackbar({ type: 'error', message: t('privacy.loadFailed') });
        }
    };

    useEffect(() => {
        loadPolicy();
    }, []);

    const handleOpenModal = (data = null) => {
        setEditingPolicy(data);
        setModalOpen(true);
    };

    const handleCloseModal = (refresh = false) => {
        setModalOpen(false);
        setEditingPolicy(null);
        if (refresh) loadPolicy();
    };

    const handleDelete = async (id) => {
        if (!window.confirm(t('privacy.deleteConfirm'))) return;
        try {
            await deletePrivacyPolicy(id);
            showSnackbar({ type: 'success', message: t('privacy.deleted') });
            loadPolicy();
        } catch (err) {
            showSnackbar({
                type: 'error',
                message: err.response?.data?.message || t('privacy.deleteFailed'),
            });
        }
    };

    const policyData =
        Array.isArray(privacyPolicies) && privacyPolicies.length > 0
            ? privacyPolicies[0]
            : null;

    const filteredContent = search.trim()
        ? policyData?.content?.toLowerCase().includes(search.toLowerCase())
            ? policyData
            : null
        : policyData;

    if (loading) {
        return (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
                <CircularProgress size={40} thickness={4} sx={{ color: colors.sea }} />
            </Box>
        );
    }

    if (error) {
        return (
            <Box p={3}>
                <Alert
                    severity="error"
                    action={
                        <Button color="inherit" size="small" onClick={() => { clearError(); loadPolicy(); }}>
                            {t('privacy.retry')}
                        </Button>
                    }
                    sx={{ borderRadius: 2 }}
                >
                    {error}
                </Alert>
            </Box>
        );
    }

    return (
        <Box sx={{ width: '100%', p: { xs: 1.5, sm: 2.5 }, m: 0, bgcolor: 'background.default' }}>
            <Paper
                elevation={0}
                sx={{
                    width: '100%',
                    borderRadius: 3,
                    overflow: 'hidden',
                    border: '1px solid',
                    borderColor: 'divider',
                    bgcolor: 'background.paper',
                }}
            >
                {/* HEADER */}
                <Box sx={{ px: { xs: 2, sm: 3 }, py: 2.5, borderBottom: '1px solid', borderColor: 'divider' }}>
                    <Stack
                        direction={{ xs: 'column', sm: 'row' }}
                        justifyContent="space-between"
                        alignItems={{ xs: 'stretch', sm: 'center' }}
                        spacing={2}
                        mb={2.5}
                    >
                        <Box>
                            <Typography variant="h5" fontWeight={800} color="text.primary">
                                {t('privacy.title')}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('privacy.subtitle')}
                            </Typography>
                        </Box>

                        <Stack direction="row" spacing={1.5} alignItems="center" justifyContent={{ xs: 'space-between', sm: 'flex-end' }}>
                            {!policyData ? (
                                <Button
                                    variant="contained"
                                    startIcon={<AddIcon />}
                                    onClick={() => handleOpenModal(null)}
                                    size={isMobile ? 'small' : 'medium'}
                                    sx={{
                                        borderRadius: 2,
                                        fontWeight: 700,
                                        textTransform: 'none',
                                        px: 2.5,
                                        boxShadow: 'none',
                                        bgcolor: colors.salat || '#10b981',
                                        '&:hover': {
                                            bgcolor: colors.dark || '#047857',
                                            boxShadow: '0 4px 12px rgba(16,185,129,0.35)',
                                        },
                                    }}
                                >
                                    {t('privacy.create')}
                                </Button>
                            ) : canEdit && (
                                <>
                                    <Button
                                        variant="contained"
                                        startIcon={<EditIcon />}
                                        onClick={() => handleOpenModal(policyData)}
                                        size={isMobile ? 'small' : 'medium'}
                                        sx={{
                                            borderRadius: 2,
                                            fontWeight: 700,
                                            textTransform: 'none',
                                            px: 2.5,
                                            boxShadow: 'none',
                                            bgcolor: colors.sea || '#0f766e',
                                            '&:hover': {
                                                bgcolor: colors.dark || '#0d5c56',
                                                boxShadow: '0 4px 12px rgba(15,118,110,0.35)',
                                            },
                                        }}
                                    >
                                        {t('privacy.edit')}
                                    </Button>
                                    <Button
                                        variant="contained"
                                        startIcon={<DeleteIcon />}
                                        onClick={() => handleDelete(policyData.id)}
                                        size={isMobile ? 'small' : 'medium'}
                                        sx={{
                                            borderRadius: 2,
                                            fontWeight: 700,
                                            textTransform: 'none',
                                            px: 2.5,
                                            boxShadow: 'none',
                                            bgcolor: 'error.main',
                                            '&:hover': {
                                                bgcolor: 'error.dark',
                                                boxShadow: '0 4px 12px rgba(239,68,68,0.35)',
                                            },
                                        }}
                                    >
                                        {t('privacy.delete')}
                                    </Button>
                                </>
                            )}

                            <Button
                                variant="outlined"
                                startIcon={<RefreshIcon />}
                                onClick={loadPolicy}
                                disabled={loading}
                                size={isMobile ? 'small' : 'medium'}
                                sx={{
                                    borderRadius: 2,
                                    fontWeight: 600,
                                    textTransform: 'none',
                                    borderColor: 'divider',
                                    color: 'text.primary',
                                    '&:hover': { borderColor: 'text.primary', bgcolor: 'action.hover' },
                                }}
                            >
                                {t('privacy.refresh')}
                            </Button>
                        </Stack>
                    </Stack>

                    {/* SEARCH */}
                    <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} alignItems={{ xs: 'stretch', sm: 'center' }}>
                        <TextField
                            placeholder={t('privacy.searchPlaceholder')}
                            size="small"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            InputProps={{
                                startAdornment: (
                                    <InputAdornment position="start">
                                        <SearchIcon fontSize="small" color="action" />
                                    </InputAdornment>
                                ),
                                endAdornment: search ? (
                                    <InputAdornment position="end">
                                        <IconButton size="small" onClick={() => setSearch('')}>
                                            <ClearIcon fontSize="small" />
                                        </IconButton>
                                    </InputAdornment>
                                ) : null,
                            }}
                            sx={{
                                minWidth: { xs: '100%', sm: 260 },
                                flexGrow: { xs: 1, sm: 0 },
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 2,
                                    bgcolor: 'action.hover',
                                    '& fieldset': { borderColor: 'transparent' },
                                    '&:hover fieldset': { borderColor: 'divider' },
                                    '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                                },
                            }}
                        />
                    </Stack>
                </Box>

                {/* SUMMARY CARDS */}
                <Box sx={{ px: { xs: 2, sm: 3 }, pt: 2.5, pb: 1 }}>
                    <Grid container spacing={2}>
                        {[
                            {
                                label: t('privacy.status'),
                                value: policyData ? t('privacy.published') : t('privacy.notCreated'),
                                color: policyData ? 'success.main' : 'warning.main',
                                icon: <PrivacyTipIcon sx={{ fontSize: 18 }} />,
                            },
                            {
                                label: t('privacy.wordCount'),
                                value: policyData?.content?.split(/\s+/).filter(Boolean).length || 0,
                                color: 'info.main',
                                icon: <DescriptionIcon sx={{ fontSize: 18 }} />,
                            },
                            {
                                label: t('privacy.lastUpdated'),
                                value: policyData?.updated_at
                                    ? new Date(policyData.updated_at).toLocaleDateString()
                                    : t('privacy.never'),
                                color: 'secondary.main',
                                icon: <HistoryIcon sx={{ fontSize: 18 }} />,
                            },
                        ].map((item, idx) => (
                            <Grid item xs={6} sm={4} key={idx}>
                                <Card
                                    elevation={0}
                                    sx={{
                                        borderRadius: 2,
                                        border: '1px solid',
                                        borderColor: 'divider',
                                        bgcolor: 'background.paper', // ✅ Theme aware
                                        height: '100%',
                                    }}
                                >
                                    <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
                                        <Box display="flex" alignItems="center" justifyContent="space-between">
                                            <Typography variant="caption" sx={{ color: item.color, fontWeight: 600 }}>
                                                {item.label}
                                            </Typography>
                                            {item.icon}
                                        </Box>
                                        <Typography variant="h4" sx={{ color: item.color, fontWeight: 700, fontSize: '1.3rem' }}>
                                            {item.value}
                                        </Typography>
                                    </CardContent>
                                </Card>
                            </Grid>
                        ))}
                    </Grid>
                </Box>

                {/* CONTENT */}
                <Box sx={{ p: { xs: 2, sm: 3 } }}>
                    <Card
                        variant="outlined"
                        sx={{
                            borderColor: 'divider',
                            borderRadius: 2.5,
                            overflow: 'hidden',
                            bgcolor: 'action.hover', // ✅ Theme aware (replaces alpha(colors.sea, 0.02))
                        }}
                    >
                        <CardContent sx={{ p: 3 }}>
                            {filteredContent ? (
                                <>
                                    <Typography
                                        variant="body1"
                                        component="div"
                                        sx={{
                                            whiteSpace: 'pre-wrap',
                                            wordBreak: 'break-word',
                                            lineHeight: 1.9,
                                            minHeight: '120px',
                                            color: 'text.primary',
                                        }}
                                    >
                                        {filteredContent.content}
                                    </Typography>

                                    <Box
                                        sx={{
                                            mt: 2.5,
                                            pt: 2,
                                            borderTop: '1px solid',
                                            borderColor: 'divider',
                                            display: 'flex',
                                            justifyContent: 'space-between',
                                            alignItems: 'center',
                                            flexWrap: 'wrap',
                                            gap: 1,
                                        }}
                                    >
                                        <Typography variant="caption" color="text.secondary">
                                            <HistoryIcon sx={{ fontSize: 14, mr: 0.5, verticalAlign: 'middle' }} />
                                            {t('privacy.lastUpdatedLabel')}:{' '}
                                            {filteredContent.updated_at
                                                ? new Date(filteredContent.updated_at).toLocaleString()
                                                : t('privacy.never')}
                                        </Typography>
                                        {filteredContent.created_at && (
                                            <Typography variant="caption" color="text.secondary">
                                                {t('privacy.created')}: {new Date(filteredContent.created_at).toLocaleString()}
                                            </Typography>
                                        )}
                                        <Typography variant="caption" color="text.secondary">
                                            {filteredContent.content.split(/\s+/).filter(Boolean).length} {t('privacy.words')}
                                        </Typography>
                                    </Box>
                                </>
                            ) : search ? (
                                <Box textAlign="center" py={3}>
                                    <Typography color="text.secondary">{t('privacy.noMatch')}</Typography>
                                </Box>
                            ) : (
                                <Box textAlign="center" py={4}>
                                    <PrivacyTipIcon sx={{ fontSize: 56, color: 'text.disabled', mb: 1.5 }} />
                                    <Typography color="text.secondary" fontWeight={500}>
                                        {t('privacy.noContent')}
                                    </Typography>
                                    {!policyData && canEdit && (
                                        <Button
                                            variant="contained"
                                            startIcon={<AddIcon />}
                                            onClick={() => handleOpenModal(null)}
                                            sx={{
                                                mt: 2,
                                                borderRadius: 2,
                                                textTransform: 'none',
                                                fontWeight: 600,
                                                bgcolor: colors.salat || '#10b981',
                                                '&:hover': { bgcolor: colors.dark || '#047857' },
                                            }}
                                        >
                                            {t('privacy.createPage')}
                                        </Button>
                                    )}
                                </Box>
                            )}
                        </CardContent>
                    </Card>
                </Box>
            </Paper>

            <PrivacyPolicyFormModal
                open={modalOpen}
                onClose={handleCloseModal}
                policyData={editingPolicy}
                createPrivacyPolicy={createPrivacyPolicy}
                updatePrivacyPolicy={updatePrivacyPolicy}
            />
        </Box>
    );
};

export default PrivacyPolicyPage;