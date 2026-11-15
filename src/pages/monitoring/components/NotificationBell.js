// src/components/monitoring/NotificationBell.jsx
import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
    Badge, IconButton, Menu, Typography, Box, Chip, List, ListItem,
    ListItemAvatar, Avatar, CircularProgress, Alert, Button,
    useTheme, useMediaQuery,
} from '@mui/material';
import {
    Notifications as NotificationsIcon,
    NotificationsActive as NotificationsActiveIcon,
    Warning as WarningIcon,
    CheckCircle as CheckCircleIcon,
    Refresh as RefreshIcon,
    Build as BuildIcon,
    Timer as TimerIcon,
    LocationOn as LocationOnIcon,
    Engineering as EngineeringIcon,
} from '@mui/icons-material';
import { monitoringService } from 'services/monitoring.service';
import { useLanguage } from 'context/LanguageContext';
import { tMon } from 'pages/monitoring/monitoringlang';
import { formatDistanceToNow } from 'date-fns';

const POLL_INTERVAL = 15000;

export const NotificationBell = ({ onNotificationClick }) => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

    const { language } = useLanguage();
    const t = (key, replacements) => tMon(language, key, replacements);

    const [anchorEl, setAnchorEl] = useState(null);
    const [notifications, setNotifications] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [unreadCount, setUnreadCount] = useState(0);
    const [autoRefresh, setAutoRefresh] = useState(true);
    const intervalRef = useRef(null);

    const open = Boolean(anchorEl);

    const loadNotifications = useCallback(async () => {
        try {
            setError(null);
            const response = await monitoringService.getNotifications();
            const data = response.data?.data || response.data || {};
            const notes = data.notifications || [];
            const sorted = [...notes].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
            setNotifications(sorted);
            const urgent = sorted.filter(n => n.is_timeout).length;
            setUnreadCount(urgent > 0 ? urgent : sorted.length);
            return sorted;
        } catch (err) {
            console.error('Error loading notifications:', err);
            setError(err.response?.data?.message || t('mon.bell.loadFailed'));
            return [];
        }
    }, [language]);

    useEffect(() => {
        loadNotifications();
        if (autoRefresh) {
            intervalRef.current = setInterval(loadNotifications, POLL_INTERVAL);
        }
        return () => {
            if (intervalRef.current) clearInterval(intervalRef.current);
        };
    }, [autoRefresh, loadNotifications]);

    const toggleAutoRefresh = () => {
        setAutoRefresh(prev => !prev);
        if (!autoRefresh) loadNotifications();
    };

    const handleClick = (event) => { setAnchorEl(event.currentTarget); setUnreadCount(0); };
    const handleClose = () => setAnchorEl(null);

    const handleNotificationClick = (notification) => {
        handleClose();
        if (onNotificationClick) onNotificationClick(notification);
    };

    const handleRefresh = () => loadNotifications();

    const formatTime = (dateStr) => {
        try { return formatDistanceToNow(new Date(dateStr), { addSuffix: true }); } catch { return ''; }
    };

    const getStatusLabel = (notification) => {
        if (notification.is_timeout) {
            return t('mon.bell.waitingMin', { m: notification.minutes_elapsed });
        }
        return t('mon.bell.minAgo', { m: notification.minutes_elapsed });
    };

    return (
        <>
            <IconButton
                onClick={handleClick}
                color="inherit"
                aria-label={t('mon.bell.ariaLabel')}
                sx={{
                    position: 'relative',
                    '&:hover': { backgroundColor: 'rgba(255,255,255,0.15)' },
                }}
            >
                <Badge
                    badgeContent={unreadCount > 0 ? unreadCount : null}
                    color="error" max={99}
                    anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
                    sx={{
                        '& .MuiBadge-badge': {
                            animation: unreadCount > 0 ? 'pulse 2s infinite' : 'none',
                            fontWeight: 'bold',
                        },
                    }}
                >
                    {unreadCount > 0 ? <NotificationsActiveIcon sx={{ color: '#fff' }} /> : <NotificationsIcon sx={{ color: '#fff' }} />}
                </Badge>
            </IconButton>

            <Menu
                anchorEl={anchorEl} open={open} onClose={handleClose}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                transformOrigin={{ vertical: 'top', horizontal: 'right' }}
                PaperProps={{
                    sx: {
                        width: { xs: '100vw', sm: 420 },
                        maxHeight: { xs: '100vh', sm: '80vh' },
                        borderRadius: { xs: 0, sm: 3 },
                        marginTop: { xs: 0, sm: 1 },
                        overflow: 'hidden',
                        boxShadow: '0 10px 40px rgba(0,0,0,0.15)',
                    },
                }}
            >
                {/* Header */}
                <Box sx={{
                    p: 2.5, borderBottom: '1px solid #e5e7eb',
                    display: 'flex', justifyContent: 'space-between',
                    alignItems: 'center', bgcolor: '#fafafa',
                }}>
                    <Box display="flex" alignItems="center" gap={1.5}>
                        <NotificationsIcon sx={{ color: theme.palette.primary.main }} />
                        <Typography variant="h6" fontWeight="bold">{t('mon.bell.title')}</Typography>
                        {notifications.length > 0 && (
                            <Chip label={notifications.length} size="small"
                                  sx={{
                                      bgcolor: theme.palette.primary.main, color: 'white',
                                      fontWeight: 'bold', height: 20, fontSize: '0.7rem',
                                  }} />
                        )}
                    </Box>
                    <Box display="flex" gap={0.5}>
                        <IconButton size="small" onClick={handleRefresh} disabled={loading}
                                    sx={{ '&:hover': { bgcolor: 'rgba(0,0,0,0.05)' } }}>
                            <RefreshIcon fontSize="small" />
                        </IconButton>
                    </Box>
                </Box>

                {/* Status Bar */}
                <Box sx={{
                    px: 2.5, py: 1, borderBottom: '1px solid #e5e7eb',
                    display: 'flex', justifyContent: 'space-between',
                    alignItems: 'center', bgcolor: '#ffffff',
                }}>
                    <Typography variant="caption" color="text.secondary" fontWeight="500">
                        {loading
                            ? t('mon.bell.loading')
                            : t('mon.bell.pendingRequests', {
                                n: notifications.length,
                                s: notifications.length !== 1 ? 's' : '',
                            })}
                    </Typography>
                    <Button
                        size="small" variant="text"
                        color={autoRefresh ? 'success' : 'default'}
                        onClick={toggleAutoRefresh}
                        sx={{
                            minWidth: 'auto', px: 1.5, py: 0.5, fontSize: '0.7rem', fontWeight: '600',
                            textTransform: 'none',
                            color: autoRefresh ? '#16a34a' : '#6b7280',
                            '&:hover': { bgcolor: 'transparent' },
                        }}
                    >
                        {autoRefresh ? t('mon.bell.autoRefreshOn') : t('mon.bell.autoRefreshOff')}
                    </Button>
                </Box>

                {error && <Alert severity="error" sx={{ m: 2, borderRadius: 2 }}>{error}</Alert>}

                {loading && notifications.length === 0 ? (
                    <Box display="flex" justifyContent="center" py={6}>
                        <CircularProgress size={36} />
                    </Box>
                ) : notifications.length === 0 ? (
                    <Box textAlign="center" py={6}>
                        <Box sx={{
                            width: 64, height: 64, borderRadius: '50%', bgcolor: '#f3f4f6',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            mx: 'auto', mb: 2,
                        }}>
                            <NotificationsIcon sx={{ fontSize: 32, color: '#9ca3af' }} />
                        </Box>
                        <Typography color="text.secondary" fontWeight="500">{t('mon.bell.allCaughtUp')}</Typography>
                        <Typography variant="caption" color="text.secondary">{t('mon.bell.noPending')}</Typography>
                    </Box>
                ) : (
                    <Box sx={{ overflow: 'auto', maxHeight: { xs: 'calc(100vh - 220px)', sm: 420 } }}>
                        <List disablePadding>
                            {notifications.map((notification, index) => {
                                const isUrgent = notification.is_timeout;
                                const hasTechnician = notification.technician && notification.technician.name;

                                return (
                                    <ListItem
                                        key={index} component="div"
                                        onClick={() => handleNotificationClick(notification)}
                                        sx={{
                                            px: 2.5, py: 2, cursor: 'pointer',
                                            borderBottom: '1px solid #f3f4f6',
                                            backgroundColor: isUrgent ? '#fef2f2' : 'transparent',
                                            transition: 'all 0.2s ease',
                                            '&:hover': { backgroundColor: isUrgent ? '#fde8e8' : '#f8fafc' },
                                            '&:last-child': { borderBottom: 'none' },
                                            position: 'relative',
                                        }}
                                    >
                                        {isUrgent && (
                                            <Box sx={{
                                                position: 'absolute', left: 0, top: 0, bottom: 0,
                                                width: 4, bgcolor: '#ef4444',
                                                borderRadius: '0 2px 2px 0',
                                                animation: 'pulseBar 1.5s infinite',
                                            }} />
                                        )}

                                        <Box display="flex" alignItems="flex-start" gap={2} width="100%">
                                            <ListItemAvatar sx={{ minWidth: 40 }}>
                                                <Avatar sx={{
                                                    width: 40, height: 40,
                                                    bgcolor: isUrgent ? '#fef2f2' : '#f0fdf4',
                                                    color: isUrgent ? '#dc2626' : '#16a34a',
                                                    border: isUrgent ? '2px solid #fca5a5' : '2px solid #86efac',
                                                }}>
                                                    {isUrgent ? <WarningIcon sx={{ fontSize: 20 }} /> : <BuildIcon sx={{ fontSize: 20 }} />}
                                                </Avatar>
                                            </ListItemAvatar>

                                            <Box flex={1} minWidth={0}>
                                                <Box display="flex" justifyContent="space-between" alignItems="flex-start" gap={1}>
                                                    <Box flex={1} minWidth={0}>
                                                        <Typography variant="body2" fontWeight={isUrgent ? '700' : '600'}
                                                                    sx={{
                                                                        overflow: 'hidden', textOverflow: 'ellipsis',
                                                                        whiteSpace: 'nowrap',
                                                                        color: isUrgent ? '#991b1b' : '#111827',
                                                                    }}>
                                                            {notification.customer_name || t('mon.bell.customerFallback')}
                                                        </Typography>
                                                        <Typography variant="caption" color="text.secondary" display="block"
                                                                    sx={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                                            {notification.service_name || t('mon.bell.serviceFallback')}
                                                        </Typography>
                                                    </Box>
                                                    {isUrgent && (
                                                        <Chip
                                                            icon={<WarningIcon sx={{ fontSize: 12 }} />}
                                                            label={t('mon.bell.urgent')}
                                                            size="small"
                                                            sx={{
                                                                height: 20, fontSize: '0.55rem', fontWeight: '700',
                                                                bgcolor: '#ef4444', color: 'white',
                                                                '& .MuiChip-icon': { color: 'white', fontSize: 12 },
                                                                flexShrink: 0,
                                                                animation: 'pulseChip 1.5s infinite',
                                                            }}
                                                        />
                                                    )}
                                                </Box>

                                                {hasTechnician && (
                                                    <Box sx={{
                                                        mt: 0.75, p: 1,
                                                        bgcolor: isUrgent ? '#fef8f8' : '#f8fafc',
                                                        borderRadius: 1.5,
                                                        border: '1px solid',
                                                        borderColor: isUrgent ? '#fecaca' : '#e5e7eb',
                                                        display: 'flex', alignItems: 'center', gap: 1.5, flexWrap: 'wrap',
                                                    }}>
                                                        <Box display="flex" alignItems="center" gap={0.5}>
                                                            <EngineeringIcon sx={{ fontSize: 14, color: '#6b7280' }} />
                                                            <Typography variant="caption" fontWeight="600" color="text.primary">
                                                                {notification.technician.name}
                                                            </Typography>
                                                        </Box>
                                                        {notification.technician.area && (
                                                            <Box display="flex" alignItems="center" gap={0.5}>
                                                                <LocationOnIcon sx={{ fontSize: 12, color: '#6b7280' }} />
                                                                <Typography variant="caption" color="text.secondary">
                                                                    {notification.technician.area}
                                                                </Typography>
                                                            </Box>
                                                        )}
                                                        {notification.technician.rating > 0 && (
                                                            <Chip size="small"
                                                                  label={`⭐ ${notification.technician.rating.toFixed(1)}`}
                                                                  sx={{
                                                                      height: 18, fontSize: '0.55rem',
                                                                      bgcolor: '#fef3c7', color: '#92400e',
                                                                      '& .MuiChip-label': { px: 0.5 },
                                                                  }} />
                                                        )}
                                                    </Box>
                                                )}

                                                <Box display="flex" alignItems="center" gap={1.5} mt={1}>
                                                    <Chip
                                                        size="small"
                                                        label={getStatusLabel(notification)}
                                                        sx={{
                                                            height: 22, fontSize: '0.6rem', fontWeight: '600',
                                                            bgcolor: isUrgent ? '#fee2e2' : '#d1fae5',
                                                            color: isUrgent ? '#991b1b' : '#065f46',
                                                            '& .MuiChip-label': { px: 1 },
                                                        }}
                                                    />
                                                    <Box display="flex" alignItems="center" gap={0.5}>
                                                        <TimerIcon sx={{ fontSize: 12, color: '#9ca3af' }} />
                                                        <Typography variant="caption" color="text.secondary">
                                                            {formatTime(notification.created_at)}
                                                        </Typography>
                                                    </Box>
                                                </Box>
                                            </Box>
                                        </Box>
                                    </ListItem>
                                );
                            })}
                        </List>
                    </Box>
                )}

                <style>{`
                    @keyframes pulse { 0% { transform: scale(1); } 50% { transform: scale(1.15); } 100% { transform: scale(1); } }
                    @keyframes pulseBar { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }
                    @keyframes pulseChip { 0% { transform: scale(1); } 50% { transform: scale(1.05); } 100% { transform: scale(1); } }
                `}</style>
            </Menu>
        </>
    );
};