// src/pages/monitoring/MonitoringMap.jsx
import React, { useState, useEffect, useCallback, useRef } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {
    Box, Paper, Typography, Chip, IconButton, Button, Drawer, Avatar,
    Divider, CircularProgress, Alert, Snackbar, Fab, Zoom,
    useMediaQuery, useTheme, Tooltip, FormControl, InputLabel, Select, MenuItem,
} from '@mui/material';
import {
    Refresh as RefreshIcon,
    Phone as PhoneIcon,
    WhatsApp as WhatsAppIcon,
    Close as CloseIcon,
    Warning as WarningIcon,
    ArrowUpward as ArrowUpwardIcon,
    MyLocation as MyLocationIcon,
    Star as StarIcon,
    Route as RouteIcon,
    Timer as TimerIcon,
    Add as AddIcon,
    Remove as RemoveIcon,
    Fullscreen as FullscreenIcon,
    FullscreenExit as FullscreenExitIcon,
} from '@mui/icons-material';
import { usePermissions } from 'hooks';
import { monitoringService } from 'services/monitoring.service';
import { useLanguage } from 'context/LanguageContext';
import { tMon } from './monitoringlang';
import { NotificationBell } from './components/NotificationBell';

// ─── Constants ───────────────────────────────────────────────
const RED = '#ea4335';
const GREEN = '#22c55e';
const BLUE = '#3b82f6';
const ORANGE = '#f59e0b';
const PURPLE = '#8b5cf6';
const DAR_ES_SALAAM = [-6.7924, 39.2083];
const TIMEOUT_MINUTES = 5;
const POLL_MS = 15000;
const TRACKING_POLL_MS = 10000;
const OSRM_BASE_URL = 'https://router.project-osrm.org/route/v1/driving';

const TRACKABLE_STATUSES = ['accepted', 'on_the_way', 'arrived', 'in_progress'];

// ─── Pulse animations ────────────────────────────────────────
const pulseStyles = `
  @keyframes pulseRed {
    0%   { box-shadow: 0 0 0 0 rgba(234, 67, 53, 0.7); }
    70%  { box-shadow: 0 0 0 16px rgba(234, 67, 53, 0); }
    100% { box-shadow: 0 0 0 0 rgba(234, 67, 53, 0); }
  }
  @keyframes pulseGreen {
    0%   { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.5); }
    70%  { box-shadow: 0 0 0 12px rgba(34, 197, 94, 0); }
    100% { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0); }
  }
  @keyframes pulseOrange {
    0%   { box-shadow: 0 0 0 0 rgba(245, 158, 11, 0.6); }
    70%  { box-shadow: 0 0 0 14px rgba(245, 158, 11, 0); }
    100% { box-shadow: 0 0 0 0 rgba(245, 158, 11, 0); }
  }
  @keyframes pulsePurple {
    0%   { box-shadow: 0 0 0 0 rgba(139, 92, 246, 0.6); }
    70%  { box-shadow: 0 0 0 14px rgba(139, 92, 246, 0); }
    100% { box-shadow: 0 0 0 0 rgba(139, 92, 246, 0); }
  }
  @keyframes pulseLiveDot {
    0%   { opacity: 1; transform: scale(1); }
    50%  { opacity: 0.4; transform: scale(1.3); }
    100% { opacity: 1; transform: scale(1); }
  }
  .leaflet-container {
    width: 100% !important;
    height: 100% !important;
  }
`;

// ─── Marker icon ─────────────────────────────────────────────
const createMarkerIcon = (status, isTimeout, dayAgo, dimmed, techPhoto = null) => {
    let color = RED;
    let icon = '⚡';
    let size = 30;
    let animation = '';

    if (status === 'accepted') {
        color = GREEN;
        icon = '✓';
        size = 30;
        animation = 'pulseGreen 2s infinite';
    } else if (status === 'on_the_way') {
        color = ORANGE;
        icon = '🚗';
        size = 32;
        animation = 'pulseOrange 2s infinite';
    } else if (status === 'arrived') {
        color = PURPLE;
        icon = '📍';
        size = 32;
        animation = 'pulsePurple 2s infinite';
    } else if (status === 'completed') {
        color = BLUE;
        icon = '✅';
        size = 28;
    } else if (status === 'pending') {
        if (dayAgo > 0) {
            color = ORANGE;
            icon = '⏳';
            size = 32;
            animation = 'pulseOrange 2s infinite';
        } else {
            color = RED;
            icon = isTimeout ? '⚠️' : '⚡';
            size = isTimeout ? 36 : 30;
            animation = isTimeout ? 'pulseRed 1.8s infinite' : '';
        }
    }

    if (techPhoto && (status === 'accepted' || status === 'on_the_way' || status === 'arrived' || status === 'in_progress')) {
        const photoSize = 88;
        const borderColor = status === 'in_progress' ? '#8b5cf6' : status === 'on_the_way' ? '#f97316' : status === 'arrived' ? '#8b5cf6' : '#22c55e';
        return L.divIcon({
            className: 'tech-marker',
            html: `
        <div style="
          width:${photoSize}px;height:${photoSize}px;border-radius:50%;
          border:5px solid ${borderColor};
          box-shadow:0 0 0 8px rgba(0,0,0,0.2), 0 6px 18px rgba(0,0,0,0.35);
          background-image:url(${techPhoto});
          background-size:cover;
          background-position:center;
          ${dimmed ? 'opacity:0.45;' : ''}
          transition:opacity 0.2s;
        "></div>
      `,
            iconSize: [photoSize, photoSize],
            iconAnchor: [photoSize / 2, photoSize / 2],
            popupAnchor: [0, -(photoSize / 2)],
        });
    }

    const markerStyle = {
        backgroundColor: color,
        width: `${size}px`,
        height: `${size}px`,
        borderRadius: '50%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        border: '3px solid white',
        color: 'white',
        fontSize: isTimeout ? '14px' : '12px',
        boxShadow: '0 2px 10px rgba(0,0,0,0.35)',
        animation,
        opacity: dimmed ? 0.45 : 1,
        transition: 'opacity 0.2s ease',
    };

    const styleString = Object.entries(markerStyle)
        .map(([k, v]) => `${k.replace(/([A-Z])/g, '-$1').toLowerCase()}:${v}`)
        .join(';');

    return L.divIcon({
        className: 'monitoring-marker',
        html: `<div style="${styleString}">${icon}</div>`,
        iconSize: [size, size],
        iconAnchor: [size / 2, size / 2],
        popupAnchor: [0, -size / 2],
    });
};

// ─── Helpers ─────────────────────────────────────────────────
const formatPhoneDisplay = (phone) => {
    if (!phone) return 'No phone';
    const clean = phone.replace(/\D/g, '');
    if (clean.length === 10) return `0${clean.slice(1, 4)} ${clean.slice(4, 7)} ${clean.slice(7)}`;
    if (clean.length === 9) return `0${clean.slice(0, 3)} ${clean.slice(3, 6)} ${clean.slice(6)}`;
    return phone;
};

const routeCache = {};
const fetchOsrmRoute = async (origin, destination) => {
    const key = `${origin.lat},${origin.lng}|${destination.lat},${destination.lng}`;
    if (routeCache[key]) return routeCache[key];

    try {
        const url = `${OSRM_BASE_URL}/${origin.lng},${origin.lat};${destination.lng},${destination.lat}?overview=full&geometries=geojson`;
        const res = await fetch(url);
        if (!res.ok) throw new Error(`OSRM error ${res.status}`);
        const data = await res.json();

        if (data.code !== 'Ok' || !data.routes?.length) {
            console.warn('OSRM returned no route, falling back to straight line');
            return null;
        }

        const route = data.routes[0];
        const coords = route.geometry.coordinates.map(([lng, lat]) => [lat, lng]);
        const result = {
            coords,
            distanceKm: route.distance / 1000,
            durationMin: route.duration / 60,
        };
        routeCache[key] = result;
        return result;
    } catch (err) {
        console.error('OSRM fetch error:', err);
        return null;
    }
};

// ─── Main Component ──────────────────────────────────────────
const MonitoringMap = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const { can } = usePermissions();

    // ✅ LANGUAGE HOOKS
    const { language } = useLanguage();
    const t = (key, replacements) => tMon(language, key, replacements);

    const canView = can('monitoring.view');
    const canCall = can('technicians.call');

    const [requests, setRequests] = useState([]);
    const [counts, setCounts] = useState({});
    const [statusFilter, setStatusFilter] = useState('all');
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [selected, setSelected] = useState(null);
    const [callInfo, setCallInfo] = useState(null);
    const [toast, setToast] = useState(null);
    const [showScrollTop, setShowScrollTop] = useState(false);
    const [routeInfo, setRouteInfo] = useState(null);
    const [routeLoading, setRouteLoading] = useState(false);
    const [isFullscreen, setIsFullscreen] = useState(false);

    const [trackingData, setTrackingData] = useState(null);
    const [trackingError, setTrackingError] = useState(null);
    const trackingIntervalRef = useRef(null);

    const mapRef = useRef(null);
    const containerRef = useRef(null);

    // ─── Load map data ─────────────────────────────────────────
    const load = useCallback(async () => {
        setError(null);
        try {
            const statusParam = statusFilter === 'all'
                ? 'pending,accepted,on_the_way,arrived,in_progress,completed'
                : statusFilter;
            const res = await monitoringService.getMap(statusParam);
            const data = res.data?.data || res.data || {};
            setRequests(data.requests || []);
            setCounts(data.counts || {});
        } catch (err) {
            setError(err.response?.data?.message || t('mon.map.loadFailed'));
        } finally {
            setLoading(false);
        }
    }, [statusFilter, language]);

    useEffect(() => {
        setLoading(true);
        load();
        const interval = setInterval(load, POLL_MS);
        return () => clearInterval(interval);
    }, [load]);

    useEffect(() => {
        const handleScroll = () => setShowScrollTop(window.scrollY > 400);
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    // ─── Fullscreen ────────────────────────────────────────────
    const toggleFullscreen = () => {
        if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen?.();
            setIsFullscreen(true);
        } else {
            document.exitFullscreen?.();
            setIsFullscreen(false);
        }
    };

    // ─── Map helpers ───────────────────────────────────────────
    const fitToBounds = useCallback((points, options = {}) => {
        const map = mapRef.current;
        if (!map || !points || points.length === 0) return;

        if (points.length === 1) {
            map.flyTo(points[0], 15, { duration: 0.75 });
            return;
        }

        const bounds = L.latLngBounds(points);
        map.flyToBounds(bounds, {
            padding: [80, 80],
            maxZoom: 16,
            duration: 0.75,
            ...options,
        });
    }, []);

    const handleRecenter = () => {
        const map = mapRef.current;
        if (!map) return;

        const valid = requests.filter((r) => r.latitude && r.longitude);
        if (valid.length > 0) {
            fitToBounds(
                valid.map((r) => [r.latitude, r.longitude]),
                { maxZoom: 15 }
            );
        } else {
            map.flyTo(DAR_ES_SALAAM, 13, { duration: 0.75 });
        }
    };

    const handleZoomIn = () => mapRef.current?.zoomIn(1);
    const handleZoomOut = () => mapRef.current?.zoomOut(1);

    // ─── Call technician ───────────────────────────────────────
    const handleCallTechnician = async (technicianId, requestId) => {
        if (!canCall) return;
        try {
            const res = await monitoringService.callTechnician(technicianId, requestId);
            setCallInfo(res.data.data);
        } catch (err) {
            setToast({
                severity: 'error',
                message: err.response?.data?.message || t('mon.map.toast.callFailed'),
            });
        }
    };

    // ─── OSRM road route ──────────────────────────────────────
    useEffect(() => {
        let cancelled = false;

        const loadRoute = async () => {
            const tech = selected?.technician;
            const hasTechLoc = tech?.latitude && tech?.longitude;
            const hasCustLoc = selected?.latitude && selected?.longitude;

            if (!selected || !hasTechLoc || !hasCustLoc) {
                setRouteInfo(null);
                setRouteLoading(false);
                if (selected && hasCustLoc) {
                    fitToBounds([[selected.latitude, selected.longitude]], { maxZoom: 15 });
                }
                return;
            }

            setRouteLoading(true);

            const origin = { lat: tech.latitude, lng: tech.longitude };
            const destination = { lat: selected.latitude, lng: selected.longitude };

            const result = await fetchOsrmRoute(origin, destination);
            if (cancelled) return;

            setRouteLoading(false);

            if (result) {
                setRouteInfo({ ...result, requestId: selected.id, isFallback: false });
                fitToBounds(result.coords);
            } else {
                const fallbackCoords = [
                    [origin.lat, origin.lng],
                    [destination.lat, destination.lng],
                ];
                setRouteInfo({
                    coords: fallbackCoords,
                    distanceKm: 0,
                    durationMin: 0,
                    requestId: selected.id,
                    isFallback: true,
                });
                fitToBounds(fallbackCoords);
                console.warn('Using fallback straight line route');
            }
        };

        loadRoute();
        return () => {
            cancelled = true;
        };
    }, [selected?.id, selected?.technician?.latitude, selected?.technician?.longitude, fitToBounds]);

    // ─── Live technician tracking ─────────────────────────────
    const fetchTracking = useCallback(async (requestId) => {
        try {
            const res = await monitoringService.getRequestTracking(requestId);
            const data = res.data?.data || res.data;
            setTrackingData(data);
            setTrackingError(null);

            const lat = data?.technician_location?.lat;
            const lng = data?.technician_location?.lng;
            if (lat && lng) {
                setRequests((prev) =>
                    prev.map((r) => {
                        if (r.id !== requestId || !r.technician) return r;
                        if (r.technician.latitude === lat && r.technician.longitude === lng) return r;
                        return {
                            ...r,
                            technician: { ...r.technician, latitude: lat, longitude: lng },
                        };
                    })
                );

                setSelected((prev) => {
                    if (!prev || prev.id !== requestId || !prev.technician) return prev;
                    if (prev.technician.latitude === lat && prev.technician.longitude === lng) return prev;
                    return {
                        ...prev,
                        technician: { ...prev.technician, latitude: lat, longitude: lng },
                    };
                });
            }
        } catch (err) {
            setTrackingError(err.response?.data?.message || t('mon.map.toast.trackingFailed'));
        }
    }, [language]);

    useEffect(() => {
        if (trackingIntervalRef.current) {
            clearInterval(trackingIntervalRef.current);
            trackingIntervalRef.current = null;
        }
        setTrackingData(null);
        setTrackingError(null);

        if (!selected?.id || !selected?.technician || !TRACKABLE_STATUSES.includes(selected.status)) {
            return;
        }

        fetchTracking(selected.id);
        trackingIntervalRef.current = setInterval(() => fetchTracking(selected.id), TRACKING_POLL_MS);

        return () => {
            if (trackingIntervalRef.current) {
                clearInterval(trackingIntervalRef.current);
                trackingIntervalRef.current = null;
            }
        };
    }, [selected?.id, selected?.status, fetchTracking]);

    // ─── Permission guard ──────────────────────────────────────
    if (!canView) {
        return (
            <Box p={3}>
                <Alert severity="error">{t('mon.map.accessDenied')}</Alert>
            </Box>
        );
    }

    const center =
        requests.length > 0 && requests[0].latitude && requests[0].longitude
            ? [requests[0].latitude, requests[0].longitude]
            : DAR_ES_SALAAM;

    const routeColor =
        selected?.status === 'accepted' || selected?.status === 'on_the_way' || selected?.status === 'arrived'
            ? GREEN
            : selected?.status === 'completed'
                ? BLUE
                : RED;

    return (
        <Box
            ref={containerRef}
            sx={{
                position: 'relative',
                width: '100%',
                height: '100vh',
                overflow: 'hidden',
                bgcolor: '#f5f5f5',
            }}
        >
            <style>{pulseStyles}</style>

            {loading && requests.length === 0 ? (
                <Box display="flex" justifyContent="center" alignItems="center" height="100%">
                    <CircularProgress />
                </Box>
            ) : (
                <MapContainer
                    center={center}
                    zoom={13}
                    style={{ height: '100%', width: '100%' }}
                    zoomControl={false}
                    ref={mapRef}
                >
                    <TileLayer
                        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                    />

                    {/* Route line */}
                    {routeInfo?.coords?.length > 1 && (
                        <Polyline
                            positions={routeInfo.coords}
                            pathOptions={{
                                color: routeColor,
                                weight: 5,
                                opacity: 0.85,
                                dashArray: routeInfo.isFallback
                                    ? null
                                    : selected?.status === 'pending'
                                        ? '10, 8'
                                        : null,
                                lineCap: 'round',
                            }}
                        />
                    )}

                    {/* Request markers */}
                    {requests.map((r) => {
                        if (!r.latitude || !r.longitude) return null;

                        const dimmed = !!selected && selected.id !== r.id;
                        const dayAgo = r.status === 'pending' ? r.day_ago || 0 : 0;
                        const icon = createMarkerIcon(
                            r.status,
                            r.is_timeout,
                            dayAgo,
                            dimmed,
                            r.technician?.profile_photo
                        );

                        return (
                            <Marker
                                key={r.id}
                                position={[r.latitude, r.longitude]}
                                icon={icon}
                                eventHandlers={{ click: () => setSelected(r) }}
                            >
                                <Popup>
                                    <Box sx={{ minWidth: 220 }}>
                                        <Typography variant="subtitle2" fontWeight="bold">
                                            {r.customer?.name || t('mon.common.unknownCustomer')}
                                        </Typography>
                                        <Typography variant="caption" display="block" color="text.secondary">
                                            {r.service?.name || t('mon.common.service')} · {r.status}
                                            {r.is_timeout ? ` · ⚠️ ${r.minutes_elapsed}m` : ''}
                                        </Typography>

                                        {r.technician && (
                                            <Box sx={{ mt: 0.75, pt: 0.75, borderTop: '1px solid #e5e7eb' }}>
                                                <Box display="flex" alignItems="center" gap={1}>
                                                    <Avatar
                                                        src={r.technician.profile_photo}
                                                        sx={{
                                                            width: 52,
                                                            height: 52,
                                                            border: '2px solid #22c55e',
                                                        }}
                                                    />
                                                    <Box>
                                                        <Typography variant="caption" fontWeight="600" display="block">
                                                            {r.technician.name}
                                                        </Typography>
                                                        <Typography variant="caption" color="text.secondary">
                                                            {r.technician.area || t('mon.common.technician')}
                                                        </Typography>
                                                    </Box>
                                                </Box>
                                            </Box>
                                        )}
                                    </Box>
                                </Popup>
                            </Marker>
                        );
                    })}
                </MapContainer>
            )}

            {/* ─── Top Overlay ─────────────────────────────────────── */}
            <Paper
                elevation={4}
                sx={{
                    position: 'absolute',
                    top: 16,
                    left: 16,
                    right: 16,
                    zIndex: 1000,
                    p: { xs: 1.5, sm: 2 },
                    borderRadius: 2,
                    bgcolor: 'rgba(255,255,255,0.97)',
                    maxHeight: { xs: 'auto', sm: 140 },
                }}
            >
                <Box
                    display="flex"
                    alignItems="center"
                    justifyContent="space-between"
                    flexWrap="wrap"
                    gap={1}
                >
                    <Box display="flex" alignItems="center" gap={1} flexWrap="wrap">
                        <Typography variant="subtitle1" fontWeight="bold">
                            {t('mon.map.title')}
                        </Typography>

                        <FormControl size="small" sx={{ minWidth: 120 }}>
                            <InputLabel>{t('mon.map.filter')}</InputLabel>
                            <Select
                                value={statusFilter}
                                label={t('mon.map.filter')}
                                onChange={(e) => setStatusFilter(e.target.value)}
                            >
                                <MenuItem value="all">{t('mon.map.filterAll')}</MenuItem>
                                <MenuItem value="pending">{t('mon.map.filterPending')}</MenuItem>
                                <MenuItem value="accepted">{t('mon.map.filterAccepted')}</MenuItem>
                                <MenuItem value="on_the_way">{t('mon.map.filterOnTheWay')}</MenuItem>
                                <MenuItem value="arrived">{t('mon.map.filterArrived')}</MenuItem>
                                <MenuItem value="in_progress">{t('mon.map.filterInProgress')}</MenuItem>
                                <MenuItem value="completed">{t('mon.map.filterCompleted')}</MenuItem>
                            </Select>
                        </FormControl>

                        <Chip label={t('mon.map.chipTotal', { n: counts.total || 0 })} size="small" />
                        <Chip
                            label={t('mon.map.chipPending', { n: counts.pending || 0 })}
                            size="small"
                            sx={{ bgcolor: '#fee2e2', color: '#991b1b' }}
                        />
                        <Chip
                            label={t('mon.map.chipAccepted', { n: counts.accepted || 0 })}
                            size="small"
                            sx={{ bgcolor: '#d1fae5', color: '#065f46' }}
                        />
                        <Chip
                            label={t('mon.map.chipOnWay', { n: counts.on_the_way || 0 })}
                            size="small"
                            sx={{ bgcolor: '#ffedd5', color: '#9a3412' }}
                        />
                        <Chip
                            label={t('mon.map.chipArrived', { n: counts.arrived || 0 })}
                            size="small"
                            sx={{ bgcolor: '#ede9fe', color: '#4c1d95' }}
                        />
                        <Chip
                            label={t('mon.map.chipCompleted', { n: counts.completed || 0 })}
                            size="small"
                            sx={{ bgcolor: '#dbeafe', color: '#1e40af' }}
                        />
                    </Box>

                    <Box display="flex" alignItems="center" gap={1}>
                        <Tooltip title={isFullscreen ? t('mon.map.exitFullscreen') : t('mon.map.fullscreen')}>
                            <IconButton size="small" onClick={toggleFullscreen} sx={{ color: '#1a73e8' }}>
                                {isFullscreen ? <FullscreenExitIcon /> : <FullscreenIcon />}
                            </IconButton>
                        </Tooltip>
                        <NotificationBell onNotificationClick={() => {}} />
                        <IconButton size="small" onClick={load} disabled={loading}>
                            <RefreshIcon fontSize="small" />
                        </IconButton>
                    </Box>
                </Box>
            </Paper>

            {/* Error */}
            {error && (
                <Alert
                    severity="error"
                    sx={{
                        position: 'absolute',
                        top: { xs: 130, sm: 150 },
                        left: 16,
                        right: 16,
                        zIndex: 1000,
                    }}
                    action={
                        <Button color="inherit" size="small" onClick={load}>
                            {t('mon.map.retry')}
                        </Button>
                    }
                >
                    {error}
                </Alert>
            )}

            {/* Route + live tracking info badge */}
            {selected && (routeLoading || routeInfo || trackingData || trackingError) && (
                <Paper
                    elevation={3}
                    sx={{
                        position: 'absolute',
                        top: { xs: 'auto', sm: 170 },
                        bottom: { xs: 90, sm: 'auto' },
                        left: 16,
                        zIndex: 1000,
                        px: 1.5,
                        py: 1,
                        borderRadius: 2,
                        bgcolor: 'rgba(255,255,255,0.97)',
                        display: 'flex',
                        flexDirection: 'column',
                        gap: 0.5,
                        maxWidth: 260,
                    }}
                >
                    {/* OSRM road route */}
                    <Box display="flex" alignItems="center" gap={1}>
                        {routeLoading ? (
                            <>
                                <CircularProgress size={14} />
                                <Typography variant="caption">{t('mon.map.calculatingRoute')}</Typography>
                            </>
                        ) : routeInfo ? (
                            <>
                                <RouteIcon sx={{ fontSize: 16, color: routeColor }} />
                                {!routeInfo.isFallback ? (
                                    <>
                                        <Typography variant="caption" fontWeight="600">
                                            {t('mon.map.kmRoad', { km: routeInfo.distanceKm.toFixed(1) })}
                                        </Typography>
                                        <TimerIcon sx={{ fontSize: 14, color: '#6b7280' }} />
                                        <Typography variant="caption" color="text.secondary">
                                            {t('mon.map.min', { n: Math.round(routeInfo.durationMin) })}
                                        </Typography>
                                    </>
                                ) : (
                                    <Typography variant="caption" color="text.secondary">
                                        {t('mon.map.directLine')}
                                    </Typography>
                                )}
                            </>
                        ) : null}
                    </Box>

                    {/* Live tracking */}
                    {trackingData?.distance_km != null && (
                        <Box display="flex" alignItems="center" gap={1}>
                            <Box
                                sx={{
                                    width: 8,
                                    height: 8,
                                    borderRadius: '50%',
                                    bgcolor: '#22c55e',
                                    animation: 'pulseLiveDot 1.6s infinite',
                                }}
                            />
                            <Typography variant="caption" fontWeight="600" sx={{ color: '#16a34a' }}>
                                {t('mon.map.kmLive', { km: trackingData.distance_km })}
                            </Typography>
                            {trackingData.eta_minutes != null && (
                                <Typography variant="caption" color="text.secondary">
                                    {t('mon.map.eta', { n: trackingData.eta_minutes })}
                                </Typography>
                            )}
                        </Box>
                    )}
                    {trackingError && (
                        <Typography variant="caption" color="error">
                            ⚠️ {trackingError}
                        </Typography>
                    )}
                </Paper>
            )}

            {/* ─── Zoom & Recenter — now centered on the right side ─── */}
            <Box
                sx={{
                    position: 'absolute',
                    top: '50%',
                    transform: 'translateY(-50%)',
                    right: { xs: 16, sm: 20 },
                    zIndex: 1000,
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 1,
                }}
            >
                <Paper elevation={3} sx={{ borderRadius: 2, overflow: 'hidden' }}>
                    <Tooltip title={t('mon.map.zoomIn')}>
                        <IconButton size="small" onClick={handleZoomIn} sx={{ borderRadius: 0, py: 1 }}>
                            <AddIcon />
                        </IconButton>
                    </Tooltip>
                    <Divider />
                    <Tooltip title={t('mon.map.zoomOut')}>
                        <IconButton size="small" onClick={handleZoomOut} sx={{ borderRadius: 0, py: 1 }}>
                            <RemoveIcon />
                        </IconButton>
                    </Tooltip>
                </Paper>

                <Tooltip title={t('mon.map.recenter')}>
                    <Fab
                        size="small"
                        onClick={handleRecenter}
                        sx={{
                            bgcolor: '#fff',
                            color: '#1a73e8',
                            boxShadow: '0 4px 14px rgba(0,0,0,0.25)',
                        }}
                    >
                        <MyLocationIcon />
                    </Fab>
                </Tooltip>

                <Zoom in={showScrollTop}>
                    <Fab
                        size="small"
                        onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
                        sx={{ bgcolor: '#1a73e8', color: '#fff' }}
                    >
                        <ArrowUpwardIcon />
                    </Fab>
                </Zoom>
            </Box>

            {/* Legend */}
            {!isMobile && (
                <Paper
                    elevation={3}
                    sx={{
                        position: 'absolute',
                        bottom: 20,
                        left: 20,
                        zIndex: 1000,
                        p: 1.5,
                        bgcolor: 'rgba(255,255,255,0.95)',
                        borderRadius: 2,
                    }}
                >
                    <Box display="flex" alignItems="center" gap={1.5}>
                        <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: RED }} />
                        <Typography variant="caption">{t('mon.map.legendPending')}</Typography>
                    </Box>
                    <Box display="flex" alignItems="center" gap={1.5}>
                        <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: GREEN }} />
                        <Typography variant="caption">{t('mon.map.legendAccepted')}</Typography>
                    </Box>
                    <Box display="flex" alignItems="center" gap={1.5}>
                        <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: ORANGE }} />
                        <Typography variant="caption">{t('mon.map.legendOnWay')}</Typography>
                    </Box>
                    <Box display="flex" alignItems="center" gap={1.5}>
                        <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: PURPLE }} />
                        <Typography variant="caption">{t('mon.map.legendArrived')}</Typography>
                    </Box>
                    <Box display="flex" alignItems="center" gap={1.5}>
                        <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: BLUE }} />
                        <Typography variant="caption">{t('mon.map.legendCompleted')}</Typography>
                    </Box>
                    <Box display="flex" alignItems="center" gap={1.5}>
                        <Typography variant="caption">⚠️</Typography>
                        <Typography variant="caption">{t('mon.map.legendWaiting')}</Typography>
                    </Box>
                    <Box display="flex" alignItems="center" gap={1.5}>
                        <Box sx={{ width: 16, height: 3, bgcolor: '#9ca3af', borderRadius: 1 }} />
                        <Typography variant="caption">{t('mon.map.legendRoute')}</Typography>
                    </Box>
                    <Box display="flex" alignItems="center" gap={1.5}>
                        <Box
                            sx={{
                                width: 8,
                                height: 8,
                                borderRadius: '50%',
                                bgcolor: '#22c55e',
                                animation: 'pulseLiveDot 1.6s infinite',
                            }}
                        />
                        <Typography variant="caption">{t('mon.map.legendLiveGps')}</Typography>
                    </Box>
                </Paper>
            )}

            {/* ─── Detail Drawer ───────────────────────────────────── */}
            <Drawer
                anchor="right"
                open={!!selected}
                onClose={() => setSelected(null)}
                PaperProps={{
                    sx: {
                        width: { xs: '100vw', sm: 480 },
                        maxWidth: { xs: '100vw', sm: 520 },
                        borderRadius: { xs: 0, sm: '16px 0 0 16px' },
                        boxShadow: '0 10px 40px rgba(0,0,0,0.2)',
                        overflow: 'hidden',
                    },
                }}
            >
                {selected && (
                    <Box sx={{ p: 3, overflowY: 'auto', height: '100%' }}>
                        {/* Header */}
                        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                            <Typography variant="h6">
                                {t('mon.map.detail.title', { id: selected.id })}
                            </Typography>
                            <IconButton onClick={() => setSelected(null)}>
                                <CloseIcon />
                            </IconButton>
                        </Box>

                        {/* Status chips */}
                        <Box display="flex" gap={1} flexWrap="wrap" mb={2}>
                            <Chip
                                label={selected.service?.name || t('mon.common.service')}
                                size="small"
                                variant="outlined"
                            />
                            <Chip
                                label={selected.status}
                                size="small"
                                sx={{
                                    bgcolor:
                                        selected.status === 'accepted' ? '#d1fae5'
                                            : selected.status === 'on_the_way' ? '#ffedd5'
                                                : selected.status === 'arrived' ? '#ede9fe'
                                                    : selected.status === 'completed' ? '#dbeafe'
                                                        : selected.status === 'pending' ? '#fee2e2'
                                                            : '#f3f4f6',
                                    color:
                                        selected.status === 'accepted' ? '#065f46'
                                            : selected.status === 'on_the_way' ? '#9a3412'
                                                : selected.status === 'arrived' ? '#4c1d95'
                                                    : selected.status === 'completed' ? '#1e40af'
                                                        : selected.status === 'pending' ? '#991b1b'
                                                            : '#374151',
                                }}
                            />
                            {selected.is_timeout && (
                                <Chip
                                    icon={<WarningIcon sx={{ fontSize: 14 }} />}
                                    label={`${selected.minutes_elapsed}m waiting`}
                                    size="small"
                                    color="error"
                                />
                            )}
                        </Box>

                        {/* Route + live tracking summary */}
                        {(routeLoading || routeInfo || trackingData) && (
                            <Box
                                sx={{
                                    p: 1.5,
                                    mb: 2,
                                    borderRadius: 2,
                                    bgcolor: '#f9fafb',
                                    border: '1px solid #e5e7eb',
                                }}
                            >
                                <Box display="flex" alignItems="center" gap={1}>
                                    <RouteIcon sx={{ fontSize: 18, color: routeColor }} />
                                    {routeLoading ? (
                                        <Typography variant="body2" color="text.secondary">
                                            {t('mon.map.detail.routeCalc')}
                                        </Typography>
                                    ) : routeInfo?.isFallback ? (
                                        <Typography variant="body2">
                                            {t('mon.map.detail.directLine')}
                                        </Typography>
                                    ) : routeInfo ? (
                                        <Typography variant="body2">
                                            {t('mon.map.detail.kmRoadEta', {
                                                km: routeInfo.distanceKm.toFixed(1),
                                                min: Math.round(routeInfo.durationMin),
                                            })}
                                        </Typography>
                                    ) : null}
                                </Box>

                                {trackingData?.distance_km != null && (
                                    <Box display="flex" alignItems="center" gap={1} sx={{ mt: routeInfo ? 1 : 0 }}>
                                        <Box
                                            sx={{
                                                width: 8,
                                                height: 8,
                                                borderRadius: '50%',
                                                bgcolor: '#22c55e',
                                                animation: 'pulseLiveDot 1.6s infinite',
                                            }}
                                        />
                                        <Typography variant="body2" fontWeight="600" sx={{ color: '#16a34a' }}>
                                            {trackingData.eta_minutes != null
                                                ? t('mon.map.detail.kmLiveEta', {
                                                    km: trackingData.distance_km,
                                                    min: trackingData.eta_minutes,
                                                })
                                                : t('mon.map.detail.kmLive', { km: trackingData.distance_km })}
                                        </Typography>
                                    </Box>
                                )}

                                {trackingData?.last_updated && (
                                    <Typography
                                        variant="caption"
                                        color="text.secondary"
                                        sx={{ display: 'block', mt: 0.5 }}
                                    >
                                        {t('mon.map.detail.lastGpsUpdate', {
                                            time: new Date(trackingData.last_updated).toLocaleTimeString(),
                                        })}
                                    </Typography>
                                )}
                            </Box>
                        )}

                        {/* Description */}
                        <Typography variant="subtitle2" color="text.secondary" sx={{ fontWeight: 600, mt: 1 }}>
                            {t('mon.map.detail.description')}
                        </Typography>
                        <Typography sx={{ mb: 2, fontSize: '0.9rem', color: '#374151' }}>
                            {selected.description || t('mon.map.detail.noDescription')}
                        </Typography>

                        <Divider sx={{ my: 2 }} />

                        {/* Customer */}
                        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1, color: '#1a73e8' }}>
                            {t('mon.map.detail.customer')}
                        </Typography>
                        <Box display="flex" alignItems="center" gap={2} mb={2}>
                            <Avatar sx={{ width: 96, height: 96, bgcolor: '#e5e7eb', fontSize: '2rem' }}>
                                {selected.customer?.name?.charAt(0) || '?'}
                            </Avatar>
                            <Box>
                                <Typography fontWeight="600" fontSize="1.1rem">
                                    {selected.customer?.name || t('mon.common.unknown')}
                                </Typography>
                                <Typography variant="body2" color="text.secondary">
                                    {t('mon.map.detail.customerPhone', {
                                        phone: selected.customer?.phone || t('mon.common.noPhone'),
                                    })}
                                </Typography>
                                <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                                    {t('mon.map.detail.customerArea', {
                                        area: selected.customer?.area || selected.area || t('mon.map.detail.locationNA'),
                                    })}
                                </Typography>
                            </Box>
                        </Box>

                        <Divider sx={{ my: 2 }} />

                        {/* Technician */}
                        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1, color: '#22c55e' }}>
                            {t('mon.map.detail.technician')}
                            {trackingData && TRACKABLE_STATUSES.includes(selected.status) && (
                                <Chip
                                    label={t('mon.map.detail.live')}
                                    size="small"
                                    sx={{
                                        ml: 1,
                                        height: 18,
                                        fontSize: 10,
                                        fontWeight: 700,
                                        bgcolor: '#dcfce7',
                                        color: '#16a34a',
                                        animation: 'pulseLiveDot 2s infinite',
                                    }}
                                />
                            )}
                        </Typography>

                        {selected.technician ? (
                            <>
                                <Box display="flex" alignItems="center" gap={2} mb={2}>
                                    <Avatar
                                        src={selected.technician.profile_photo}
                                        sx={{ width: 96, height: 96, bgcolor: '#e5e7eb' }}
                                    >
                                        {!selected.technician.profile_photo &&
                                            (selected.technician.name?.charAt(0) || '?')}
                                    </Avatar>
                                    <Box>
                                        <Typography fontWeight="600" fontSize="1.1rem">
                                            {selected.technician.name}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            {t('mon.map.detail.techArea', {
                                                area: selected.technician.area || t('mon.map.detail.areaNotSet'),
                                            })}
                                        </Typography>
                                        {selected.technician.phone && (
                                            <Typography variant="body2" color="text.secondary">
                                                {t('mon.map.detail.techPhone', {
                                                    phone: formatPhoneDisplay(selected.technician.phone),
                                                })}
                                            </Typography>
                                        )}
                                        {selected.technician.rating > 0 && (
                                            <Box display="flex" alignItems="center" gap={0.5}>
                                                <StarIcon sx={{ fontSize: 16, color: '#f59e0b' }} />
                                                <Typography variant="body2" fontWeight="500">
                                                    {selected.technician.rating.toFixed(1)}
                                                </Typography>
                                            </Box>
                                        )}
                                    </Box>
                                </Box>

                                {canCall && selected.technician.phone && (
                                    <Box display="flex" gap={1} mb={2}>
                                        <Button
                                            variant="contained"
                                            startIcon={<PhoneIcon />}
                                            onClick={() =>
                                                handleCallTechnician(selected.technician.id, selected.id)
                                            }
                                            sx={{
                                                bgcolor: '#22c55e',
                                                '&:hover': { bgcolor: '#16a34a' },
                                                flex: 1,
                                                textTransform: 'none',
                                            }}
                                        >
                                            {t('mon.common.call')}
                                        </Button>
                                        <Button
                                            variant="contained"
                                            startIcon={<WhatsAppIcon />}
                                            href={`https://wa.me/${selected.technician.phone.replace(/\D/g, '')}`}
                                            target="_blank"
                                            sx={{
                                                bgcolor: '#25d366',
                                                '&:hover': { bgcolor: '#1da851' },
                                                flex: 1,
                                                textTransform: 'none',
                                            }}
                                        >
                                            {t('mon.common.whatsapp')}
                                        </Button>
                                    </Box>
                                )}
                            </>
                        ) : (
                            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                                {t('mon.common.noTechnicianAssignedYet')}
                            </Typography>
                        )}
                    </Box>
                )}
            </Drawer>

            {/* Call Info Drawer */}
            <Drawer anchor="bottom" open={!!callInfo} onClose={() => setCallInfo(null)}>
                {callInfo && (
                    <Box textAlign="center" p={4}>
                        <Avatar sx={{ width: 88, height: 88, mx: 'auto', mb: 2, fontSize: '2rem' }}>
                            {callInfo.technician_name?.charAt(0) || '?'}
                        </Avatar>
                        <Typography variant="h6">{callInfo.technician_name}</Typography>
                        <Typography variant="body2" color="text.secondary">
                            {callInfo.phone_number}
                        </Typography>
                        <Box display="flex" gap={2} justifyContent="center" sx={{ mt: 2 }}>
                            <Button
                                variant="contained"
                                startIcon={<PhoneIcon />}
                                href={callInfo.call_url}
                                sx={{ bgcolor: '#22c55e' }}
                            >
                                {t('mon.common.call')}
                            </Button>
                            <Button
                                variant="contained"
                                startIcon={<WhatsAppIcon />}
                                href={callInfo.whatsapp_url}
                                target="_blank"
                                sx={{ bgcolor: '#25d366' }}
                            >
                                {t('mon.common.whatsapp')}
                            </Button>
                        </Box>
                    </Box>
                )}
            </Drawer>

            {/* Toast */}
            <Snackbar
                open={!!toast}
                autoHideDuration={4000}
                onClose={() => setToast(null)}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
            >
                {toast && (
                    <Alert severity={toast.severity} onClose={() => setToast(null)}>
                        {toast.message}
                    </Alert>
                )}
            </Snackbar>
        </Box>
    );
};

export default MonitoringMap;