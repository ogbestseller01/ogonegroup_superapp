// src/pages/services/TechniciansModal.js
import React, { useState, useEffect } from 'react';
import {
    Dialog, DialogTitle, DialogContent, DialogActions, Button, List,
    ListItem, ListItemAvatar, Avatar, ListItemText, CircularProgress,
    Typography, Box, IconButton, Chip, Rating, Stack, Divider, Alert, alpha,
} from '@mui/material';
import {
    Close as CloseIcon, Phone as PhoneIcon, Work as WorkIcon,
    LocationOn as LocationIcon, Star as StarIcon, Person as PersonIcon,
} from '@mui/icons-material';
import { serviceService } from 'services/service.service';
import { useLanguage } from 'context/LanguageContext';
import { tService } from './serviceslang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const TechniciansModal = ({ open, onClose, serviceId, serviceName }) => {
    const { language } = useLanguage();
    const t = (key, replacements) => tService(language, key, replacements);

    const [technicians, setTechnicians] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        if (open && serviceId) loadTechnicians();
    }, [open, serviceId]);

    const loadTechnicians = async () => {
        setLoading(true);
        setError(null);
        try {
            const response = await serviceService.getTechniciansByService(serviceId);
            if (response?.data?.status === 'success') {
                const paginated = response.data.data;
                const techniciansList = paginated?.data || [];
                setTechnicians(Array.isArray(techniciansList) ? techniciansList : []);
            } else {
                setTechnicians([]);
            }
        } catch (err) {
            console.error('Error loading technicians:', err);
            setError(t('service.tech.loadingFailed'));
            setTechnicians([]);
        } finally {
            setLoading(false);
        }
    };

    const getImageUrl = (path) => {
        if (!path) return null;
        if (path.startsWith('http://') || path.startsWith('https://')) return path;
        const baseUrl = process.env.REACT_APP_API_URL || 'http://localhost:8000';
        const cleanPath = path.replace(/^\/+/, '');
        return `${baseUrl}/storage/${cleanPath}`;
    };

    const getInitials = (name) => name ? name.charAt(0).toUpperCase() : '?';

    return (
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth="sm" fullWidth
            PaperProps={{
                sx: {
                    borderRadius: 3,
                    border: '1px solid', borderColor: 'divider',
                    bgcolor: 'background.paper', // ✅ Theme aware
                },
            }}
        >
            <DialogTitle
                sx={{
                    pb: 1.5, borderBottom: '1px solid', borderColor: 'divider',
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                }}
            >
                <Box>
                    <Typography variant="h6" fontWeight={700} color="text.primary">
                        {t('service.tech.title')}
                    </Typography>
                    <Typography variant="h6" fontWeight={700} color={colors.sea || '#0f766e'}>
                        {serviceName || t('service.tech.fallbackService')}
                    </Typography>
                </Box>
                <IconButton
                    onClick={onClose}
                    size="small"
                    sx={{
                        color: 'text.secondary',
                        '&:hover': { bgcolor: 'action.hover' },
                    }}
                >
                    <CloseIcon />
                </IconButton>
            </DialogTitle>

            <DialogContent
                dividers
                sx={{
                    borderColor: 'divider', p: 0,
                    '& .MuiDialogContent-dividers': { borderTop: '1px solid', borderColor: 'divider' },
                }}
            >
                {loading ? (
                    <Box display="flex" justifyContent="center" py={6}>
                        <CircularProgress size={36} thickness={4} sx={{ color: colors.sea }} />
                    </Box>
                ) : error ? (
                    <Box p={2.5}>
                        <Alert severity="error" sx={{ borderRadius: 2 }}>{error}</Alert>
                    </Box>
                ) : technicians.length === 0 ? (
                    <Box textAlign="center" py={5}>
                        <PersonIcon sx={{ fontSize: 56, color: 'text.disabled', mb: 1.5 }} />
                        <Typography color="text.secondary" fontWeight={500}>
                            {t('service.tech.none')}
                        </Typography>
                    </Box>
                ) : (
                    <List sx={{ p: 0 }}>
                        {technicians.map((tech, index) => {
                            const user = tech.user || {};
                            const servicesCount = tech.services?.length || 0;
                            const rating = parseFloat(tech.rating) || 0;
                            const phone = user.phone || t('service.common.na');
                            const area = tech.area || t('service.common.unknownArea');
                            const completedJobs = tech.completed_jobs_count || 0;
                            const profilePhotoUrl = tech.profile_photo ? getImageUrl(tech.profile_photo) : null;

                            return (
                                <React.Fragment key={tech.id}>
                                    <ListItem
                                        alignItems="flex-start"
                                        sx={{
                                            py: 2.5, px: 2.5,
                                            transition: 'background-color 0.15s',
                                            '&:hover': { bgcolor: 'action.hover' }, // ✅ Theme aware
                                        }}
                                    >
                                        <ListItemAvatar>
                                            <Avatar
                                                src={profilePhotoUrl}
                                                sx={{
                                                    width: 52, height: 52,
                                                    bgcolor: colors.sea || '#0f766e',
                                                    color: '#fff', fontSize: '1.2rem', fontWeight: 700,
                                                    border: `2px solid ${alpha(colors.sea, 0.15)}`,
                                                }}
                                            >
                                                {!profilePhotoUrl && getInitials(user.name)}
                                            </Avatar>
                                        </ListItemAvatar>

                                        <ListItemText
                                            primary={
                                                <Stack direction="row" alignItems="center" flexWrap="wrap" gap={1}>
                                                    <Typography variant="subtitle1" fontWeight={700} color="text.primary">
                                                        {user.name || t('service.common.unknown')}
                                                    </Typography>
                                                    {tech.verified && (
                                                        <Chip
                                                            label={t('service.status.verified')}
                                                            size="small"
                                                            sx={{
                                                                fontWeight: 600,
                                                                bgcolor: 'success.light', // ✅ Theme aware
                                                                color: 'success.dark',
                                                                border: '1px solid',
                                                                borderColor: 'success.main',
                                                                height: 22, fontSize: '0.65rem',
                                                            }}
                                                        />
                                                    )}
                                                    <Chip
                                                        label={t('service.list.servicesCount', { n: servicesCount })}
                                                        size="small"
                                                        icon={<WorkIcon sx={{ fontSize: 14 }} />}
                                                        sx={{
                                                            fontWeight: 600,
                                                            bgcolor: alpha(colors.sea, 0.08),
                                                            color: colors.sea,
                                                            height: 22, fontSize: '0.65rem',
                                                        }}
                                                    />
                                                    <Chip
                                                        label={`${completedJobs} job${completedJobs !== 1 ? 's' : ''}`}
                                                        size="small"
                                                        sx={{
                                                            fontWeight: 600,
                                                            bgcolor: 'action.hover',
                                                            height: 22, fontSize: '0.65rem',
                                                        }}
                                                    />
                                                </Stack>
                                            }
                                            secondary={
                                                <Stack spacing={0.75} sx={{ mt: 1 }}>
                                                    <Box display="flex" alignItems="center" gap={1}>
                                                        <PhoneIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                        <Typography variant="body2" color="text.primary">
                                                            {phone}
                                                        </Typography>
                                                    </Box>

                                                    <Box display="flex" alignItems="center" gap={1}>
                                                        <LocationIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                        <Typography variant="body2" color="text.primary">
                                                            {area}
                                                        </Typography>
                                                    </Box>

                                                    <Box display="flex" alignItems="center" gap={1}>
                                                        <StarIcon sx={{ fontSize: 16, color: 'warning.main' }} />
                                                        <Rating
                                                            value={rating}
                                                            readOnly
                                                            precision={0.5}
                                                            size="small"
                                                            sx={{ color: 'warning.main' }}
                                                        />
                                                        <Typography variant="body2" fontWeight={600} color="text.primary">
                                                            ({rating.toFixed(1)})
                                                        </Typography>
                                                    </Box>

                                                    {tech.experience !== undefined && tech.experience !== null && (
                                                        <Typography variant="body2" color="text.secondary">
                                                            {t('service.tech.yearsExperience', { n: tech.experience })}
                                                        </Typography>
                                                    )}
                                                </Stack>
                                            }
                                        />
                                    </ListItem>
                                    {index < technicians.length - 1 && <Divider sx={{ mx: 2.5, borderColor: 'divider' }} />}
                                </React.Fragment>
                            );
                        })}
                    </List>
                )}
            </DialogContent>

            <DialogActions sx={{ p: 2.5, borderTop: '1px solid', borderColor: 'divider' }}>
                <Button
                    onClick={onClose}
                    variant="contained"
                    sx={{
                        borderRadius: 2, fontWeight: 700, textTransform: 'none', px: 3,
                        bgcolor: colors.sea || '#0f766e',
                        '&:hover': { bgcolor: colors.dark || '#0d5c56' },
                    }}
                >
                    {t('service.common.close')}
                </Button>
            </DialogActions>
        </Dialog>
    );
};

export default TechniciansModal;