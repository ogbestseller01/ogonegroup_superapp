// src/pages/terms/TermsPage.js
import React, { useState, useEffect } from 'react';
import {
    Box, Paper, Typography, Button, CircularProgress, Alert, Card, CardContent,
    IconButton, TextField, InputAdornment, useMediaQuery, useTheme, Stack, Grid, alpha,
} from '@mui/material';
import {
    Edit as EditIcon, Refresh as RefreshIcon, Add as AddIcon,
    Search as SearchIcon, Clear as ClearIcon, Description as DescriptionIcon,
    History as HistoryIcon, Gavel as GavelIcon,
} from '@mui/icons-material';
import { useTermsManagement } from 'hooks/useTerms';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import TermsFormModal from './TermsFormModal';
import { tTerms } from './termslang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const TermsPage = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const { language } = useLanguage();
    const t = (key) => tTerms(language, key);

    const { terms, loading, error, getTerms, createTerms, updateTerms, clearError } = useTermsManagement();
    const { can } = usePermissions();
    const [modalOpen, setModalOpen] = useState(false);
    const [editingTerms, setEditingTerms] = useState(null);
    const [search, setSearch] = useState('');

    const canEdit = can('terms.edit');

    const loadTerms = async () => {
        try {
            await getTerms();
        } catch {
            showSnackbar({ type: 'error', message: t('terms.loadFailed') });
        }
    };

    useEffect(() => {
        loadTerms();
    }, []);

    const handleOpenModal = (data = null) => {
        setEditingTerms(data);
        setModalOpen(true);
    };

    const handleCloseModal = (refresh = false) => {
        setModalOpen(false);
        setEditingTerms(null);
        if (refresh) loadTerms();
    };

    const termsData = Array.isArray(terms) && terms.length > 0 ? terms[0] : null;

    const filteredContent = search.trim()
        ? termsData?.content?.toLowerCase().includes(search.toLowerCase())
            ? termsData
            : null
        : termsData;

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
                        <Button color="inherit" size="small" onClick={() => { clearError(); loadTerms(); }}>
                            {t('terms.retry')}
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
                                {t('terms.title')}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('terms.subtitle')}
                            </Typography>
                        </Box>

                        <Stack direction="row" spacing={1.5} alignItems="center" justifyContent={{ xs: 'space-between', sm: 'flex-end' }}>
                            {!termsData ? (
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
                                    {t('terms.create')}
                                </Button>
                            ) : canEdit && (
                                <Button
                                    variant="contained"
                                    startIcon={<EditIcon />}
                                    onClick={() => handleOpenModal(termsData)}
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
                                    {t('terms.edit')}
                                </Button>
                            )}

                            <Button
                                variant="outlined"
                                startIcon={<RefreshIcon />}
                                onClick={loadTerms}
                                disabled={loading}
                                size={isMobile ? 'small' : 'medium'}
                                sx={{
                                    borderRadius: 2,
                                    fontWeight: 600,
                                    textTransform: 'none',
                                    borderColor: 'divider',
                                    color: 'text.primary',
                                    '&:hover': {
                                        borderColor: 'text.primary',
                                        bgcolor: 'action.hover',
                                    },
                                }}
                            >
                                {t('terms.refresh')}
                            </Button>
                        </Stack>
                    </Stack>

                    {/* SEARCH */}
                    <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} alignItems={{ xs: 'stretch', sm: 'center' }}>
                        <TextField
                            placeholder={t('terms.searchPlaceholder')}
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
                                label: t('terms.status'),
                                value: termsData ? t('terms.published') : t('terms.notCreated'),
                                color: termsData ? '#10b981' : '#f59e0b',
                                icon: <GavelIcon sx={{ fontSize: 18 }} />,
                            },
                            {
                                label: t('terms.wordCount'),
                                value: termsData?.content?.split(/\s+/).filter(Boolean).length || 0,
                                color: '#3b82f6',
                                icon: <DescriptionIcon sx={{ fontSize: 18 }} />,
                            },
                            {
                                label: t('terms.lastUpdated'),
                                value: termsData?.updated_at
                                    ? new Date(termsData.updated_at).toLocaleDateString()
                                    : t('terms.never'),
                                color: '#8b5cf6',
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
                                            {t('terms.lastUpdatedLabel')}:{' '}
                                            {filteredContent.updated_at
                                                ? new Date(filteredContent.updated_at).toLocaleString()
                                                : t('terms.never')}
                                        </Typography>
                                        {filteredContent.created_at && (
                                            <Typography variant="caption" color="text.secondary">
                                                {t('terms.created')}: {new Date(filteredContent.created_at).toLocaleString()}
                                            </Typography>
                                        )}
                                        <Typography variant="caption" color="text.secondary">
                                            {filteredContent.content.split(/\s+/).filter(Boolean).length} {t('terms.words')}
                                        </Typography>
                                    </Box>
                                </>
                            ) : search ? (
                                <Box textAlign="center" py={3}>
                                    <Typography color="text.secondary">{t('terms.noMatch')}</Typography>
                                </Box>
                            ) : (
                                <Box textAlign="center" py={4}>
                                    <GavelIcon sx={{ fontSize: 56, color: 'text.disabled', mb: 1.5 }} />
                                    <Typography color="text.secondary" fontWeight={500}>
                                        {t('terms.noContent')}
                                    </Typography>
                                    {!termsData && canEdit && (
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
                                            {t('terms.createPage')}
                                        </Button>
                                    )}
                                </Box>
                            )}
                        </CardContent>
                    </Card>
                </Box>
            </Paper>

            <TermsFormModal
                open={modalOpen}
                onClose={handleCloseModal}
                termsData={editingTerms}
                createTerms={createTerms}
                updateTerms={updateTerms}
            />
        </Box>
    );
};

export default TermsPage;