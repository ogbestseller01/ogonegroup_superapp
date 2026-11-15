// src/pages/technicians/TechniciansList.js
import React, { useState, useEffect, useMemo } from 'react';
import {
    Box, Paper, Typography, Button, Table, TableBody, TableCell, TableContainer,
    TableHead, TableRow, TablePagination, TableSortLabel, TextField,
    InputAdornment, IconButton, Chip, CircularProgress, useMediaQuery,
    useTheme, Card, CardContent, Divider, Avatar, Stack, Alert, Tabs, Tab,
} from '@mui/material';
import {
    Search as SearchIcon, Refresh as RefreshIcon, Person as PersonIcon,
    LocationOn as LocationIcon, Star as StarIcon, Verified as VerifiedIcon,
    Work as WorkIcon, Clear as ClearIcon, People as PeopleIcon,
    HourglassEmpty as PendingIcon, CheckCircle as ApprovedIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { technicianService } from 'services/technician.service';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { tTech } from './technicianslang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

/** CSS-grid helper (does not depend on the MUI Grid version). */
const gridSx = (columns, gap = 2) => ({
    display: 'grid',
    gap,
    gridTemplateColumns: columns,
});

const getHeadCells = (t) => [
    { id: 'name',     label: t('tech.list.col.technician') },
    { id: 'services', label: t('tech.list.col.services') },
    { id: 'area',     label: t('tech.list.col.location') },
    { id: 'rating',   label: t('tech.list.col.rating') },
    { id: 'status',   label: t('tech.list.col.status') },
];

// Which endpoint a tab hits
const TAB_ENDPOINTS = {
    pending:  (params) => technicianService.getPendingTechnicians(params),
    approved: (params) => technicianService.getApprovedTechnicians(params),
};

/** Tab label: text + a count pill that sits inside the tab (never clipped). */
const TabLabel = ({ text, count, color }) => (
    <Stack direction="row" spacing={1} alignItems="center">
        <span>{text}</span>
        {count > 0 && (
            <Box
                component="span"
                sx={{
                    minWidth: 22,
                    height: 22,
                    px: 0.75,
                    borderRadius: 11,
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: 12,
                    fontWeight: 700,
                    lineHeight: 1,
                    color: '#fff',
                    bgcolor: color,
                }}
            >
                {count > 999 ? '999+' : count}
            </Box>
        )}
    </Stack>
);

const TechniciansList = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));
    const navigate = useNavigate();

    const { language } = useLanguage();
    const t = (key, replacements) => tTech(language, key, replacements);
    // eslint-disable-next-line react-hooks/exhaustive-deps
    const headCells = useMemo(() => getHeadCells(t), [language]);

    const { can } = usePermissions();
    const canViewAll = can('technicians.view');

    const [tab, setTab] = useState('pending'); // 'pending' | 'approved'
    const [technicians, setTechnicians] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const [search, setSearch] = useState('');
    const [serviceFilter, setServiceFilter] = useState('');
    const [order, setOrder] = useState('asc');
    const [orderBy, setOrderBy] = useState('name');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [pagination, setPagination] = useState({ total: 0, per_page: 10, current_page: 1, last_page: 1 });

    // counts for tab badges — fetched once, refreshed with the list
    const [counts, setCounts] = useState({ pending: 0, approved: 0 });

    const loadCounts = async () => {
        try {
            const [pRes, aRes] = await Promise.all([
                technicianService.getPendingTechnicians({ per_page: 1 }),
                technicianService.getApprovedTechnicians({ per_page: 1 }),
            ]);
            setCounts({
                pending:  pRes?.data?.data?.total  ?? 0,
                approved: aRes?.data?.data?.total ?? 0,
            });
        } catch {
            // non-fatal
        }
    };

    const loadTechnicians = async () => {
        setLoading(true);
        setError(null);
        try {
            const params = {
                page: page + 1,
                per_page: rowsPerPage,
                search: search || undefined,
                ...(serviceFilter ? { service_id: serviceFilter } : {}),
            };
            const res = await TAB_ENDPOINTS[tab](params);
            const payload = res?.data?.data || {};
            setTechnicians(Array.isArray(payload.data) ? payload.data : []);
            setPagination({
                total:        payload.total        ?? 0,
                per_page:     payload.per_page     ?? rowsPerPage,
                current_page: payload.current_page ?? 1,
                last_page:    payload.last_page    ?? 1,
            });
        } catch (err) {
            setError(err?.message || 'Failed to load technicians.');
            setTechnicians([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { loadCounts(); }, []);
    useEffect(() => { loadTechnicians(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ },
        [tab, page, rowsPerPage, search, serviceFilter]);

    // reset paging on filter change
    useEffect(() => { setPage(0); }, [tab, search, serviceFilter]);

    const handleTabChange = (_, v) => setTab(v);

    const handleRequestSort = (property) => {
        const isAsc = orderBy === property && order === 'asc';
        setOrder(isAsc ? 'desc' : 'asc');
        setOrderBy(property);
    };

    const sortData = (data) => {
        if (!data) return [];
        return [...data].sort((a, b) => {
            let aValue, bValue;
            switch (orderBy) {
                case 'name':   aValue = a.user?.name || ''; bValue = b.user?.name || ''; break;
                case 'area':   aValue = a.area || '';       bValue = b.area || ''; break;
                case 'rating': aValue = a.rating || 0;      bValue = b.rating || 0; break;
                default:       aValue = a[orderBy] || '';   bValue = b[orderBy] || '';
            }
            if (typeof aValue === 'string') {
                aValue = aValue.toLowerCase(); bValue = String(bValue).toLowerCase();
            }
            if (aValue < bValue) return order === 'asc' ? -1 : 1;
            if (aValue > bValue) return order === 'asc' ? 1 : -1;
            return 0;
        });
    };

    const getImageUrl = (path) => {
        if (!path) return null;
        if (path.startsWith('http://') || path.startsWith('https://')) return path;
        const baseUrl = process.env.REACT_APP_API_URL || 'http://192.168.100.144:8000';
        return `${baseUrl}/storage/${path.replace(/^\/+/, '')}`;
    };

    const isVerifiedTech = (tc) => tc.verified && tc.verification_status === 'approved';

    const getStatusChip = (technician) => {
        if (isVerifiedTech(technician)) {
            return (
                <Chip
                    label={t('tech.status.verified')} size="small"
                    icon={<VerifiedIcon sx={{ fontSize: 14 }} />}
                    sx={{
                        fontWeight: 700, bgcolor: 'success.light', color: 'success.dark',
                        border: '1.5px solid', borderColor: 'success.main', height: 28,
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
        const s = statusMap[technician.verification_status] || statusMap.pending;
        return (
            <Chip
                label={s.label} size="small"
                sx={{
                    fontWeight: 700, bgcolor: s.bg, color: s.color,
                    border: '1.5px solid', borderColor: s.border, height: 28,
                }}
            />
        );
    };

    const fieldSx = {
        '& .MuiOutlinedInput-root': {
            borderRadius: 2,
            bgcolor: 'action.hover',
            '& fieldset': { borderColor: 'transparent' },
            '&:hover fieldset': { borderColor: 'divider' },
            '&.Mui-focused fieldset': { borderColor: 'primary.main' },
        },
    };

    if (!canViewAll) {
        return (
            <Box p={3}>
                <Paper elevation={0} sx={{ p: 4, textAlign: 'center', borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                    <Typography color="error" fontWeight={600}>{t('tech.list.accessDenied')}</Typography>
                </Paper>
            </Box>
        );
    }

    const sortedData = sortData(technicians);
    const totalCount = pagination.total || 0;

    const statCards = [
        {
            label: t('tech.list.stat.total'),
            value: counts.pending + counts.approved,
            color: '#3b82f6',
            icon: <PeopleIcon sx={{ fontSize: 20 }} />
        },
        {
            label: t('tech.list.stat.verified'),
            value: counts.approved,
            color: '#10b981',
            icon: <VerifiedIcon sx={{ fontSize: 20 }} />
        },
        {
            label: t('tech.list.stat.pending'),
            value: counts.pending,
            color: '#f59e0b',
            icon: <PersonIcon sx={{ fontSize: 20 }} />
        },
    ];

    return (
        <Box sx={{ width: '100%', p: { xs: 1.5, sm: 2.5 }, m: 0, bgcolor: 'background.default' }}>
            <Paper elevation={0} sx={{ width: '100%', borderRadius: 3, overflow: 'hidden', border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}>
                {/* HEADER */}
                <Box sx={{ px: { xs: 2, sm: 3 }, pt: 2.5, pb: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
                    <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} mb={2}>
                        <Box>
                            <Typography variant="h5" fontWeight={800}>{t('tech.list.title')}</Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>{t('tech.list.subtitle')}</Typography>
                        </Box>
                        <Button variant="contained" startIcon={<RefreshIcon />} onClick={() => { loadCounts(); loadTechnicians(); }} disabled={loading}
                                size={isMobile ? 'small' : 'medium'}
                                sx={{ borderRadius: 2, fontWeight: 600, textTransform: 'none', px: 2.5, boxShadow: 'none' }}>
                            {t('tech.common.refresh')}
                        </Button>
                    </Stack>

                    {/* TABS */}
                    <Tabs
                        value={tab}
                        onChange={handleTabChange}
                        variant={isMobile ? 'fullWidth' : 'standard'}
                        sx={{
                            minHeight: 48,
                            borderBottom: `1px solid ${theme.palette.divider}`,
                            '& .MuiTab-root': {
                                fontWeight: 700,
                                textTransform: 'none',
                                minHeight: 48,
                                px: { xs: 1, sm: 2.5 },
                                gap: 0.5,
                                borderRadius: '10px 10px 0 0',
                            },
                            '& .MuiTabs-indicator': { height: 3, borderRadius: '3px 3px 0 0' },
                        }}
                    >
                        <Tab
                            value="pending"
                            icon={<PendingIcon sx={{ fontSize: 18 }} />}
                            iconPosition="start"
                            label={<TabLabel text={t('tech.list.tab.pending')} count={counts.pending} color="#f59e0b" />}
                        />
                        <Tab
                            value="approved"
                            icon={<ApprovedIcon sx={{ fontSize: 18 }} />}
                            iconPosition="start"
                            label={<TabLabel text={t('tech.list.tab.approved')} count={counts.approved} color="#10b981" />}
                        />
                    </Tabs>

                    {/* FILTERS */}
                    <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap" useFlexGap mt={2}>
                        <TextField
                            placeholder={t('tech.list.searchPlaceholder')} size="small" value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            InputProps={{
                                startAdornment: (<InputAdornment position="start"><SearchIcon fontSize="small" color="action" /></InputAdornment>),
                                endAdornment: search ? (
                                    <InputAdornment position="end">
                                        <IconButton size="small" onClick={() => setSearch('')}><ClearIcon fontSize="small" /></IconButton>
                                    </InputAdornment>
                                ) : null,
                            }}
                            sx={{ minWidth: { xs: '100%', sm: 280 }, flexGrow: { xs: 1, sm: 0 }, ...fieldSx }}
                        />
                        <TextField
                            placeholder={t('tech.list.serviceFilterPlaceholder')} size="small" value={serviceFilter}
                            onChange={(e) => setServiceFilter(e.target.value)}
                            sx={{ minWidth: { xs: '100%', sm: 220 }, flexGrow: { xs: 1, sm: 0 }, ...fieldSx }}
                        />
                    </Stack>
                </Box>

                {error && (
                    <Box sx={{ px: { xs: 2, sm: 3 }, pt: 2 }}>
                        <Alert severity="error" sx={{ borderRadius: 2 }}>{error}</Alert>
                    </Box>
                )}

                {/* SUMMARY CARDS — equal-width responsive grid */}
                <Box sx={{ px: { xs: 2, sm: 3 }, pt: 2.5, pb: 2.5 }}>
                    <Box sx={gridSx({ xs: 'repeat(1, 1fr)', sm: 'repeat(3, 1fr)' })}>
                        {statCards.map((item, idx) => (
                            <Card
                                key={idx}
                                elevation={0}
                                sx={{ borderRadius: 2, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', height: '100%' }}
                            >
                                <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
                                    <Stack direction="row" alignItems="center" justifyContent="space-between" spacing={1.5}>
                                        <Box minWidth={0}>
                                            <Typography
                                                variant="caption"
                                                noWrap
                                                sx={{ color: 'text.secondary', fontWeight: 600, display: 'block' }}
                                            >
                                                {item.label}
                                            </Typography>
                                            <Typography variant="h4" sx={{ color: item.color, fontWeight: 700, lineHeight: 1.2, mt: 0.25 }}>
                                                {item.value}
                                            </Typography>
                                        </Box>
                                        <Box
                                            sx={{
                                                width: 40, height: 40, borderRadius: 2, flexShrink: 0,
                                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                color: item.color,
                                                bgcolor: `${item.color}1a`,
                                            }}
                                        >
                                            {item.icon}
                                        </Box>
                                    </Stack>
                                </CardContent>
                            </Card>
                        ))}
                    </Box>
                </Box>

                {/* TABLE (desktop) / CARDS (mobile) */}
                {showTableView ? (
                    <TableContainer>
                        <Table sx={{ minWidth: 800 }}>
                            <TableHead>
                                <TableRow sx={{ bgcolor: 'action.hover', '& th': { fontWeight: 700, fontSize: '0.8125rem', color: 'text.secondary', textTransform: 'uppercase', letterSpacing: 0.6, borderBottom: '1px solid', borderColor: 'divider', py: 1.75 } }}>
                                    {headCells.map((cell) => (
                                        <TableCell key={cell.id} sx={{ whiteSpace: 'nowrap' }}>
                                            <TableSortLabel active={orderBy === cell.id} direction={orderBy === cell.id ? order : 'asc'} onClick={() => handleRequestSort(cell.id)}>
                                                {cell.label}
                                            </TableSortLabel>
                                        </TableCell>
                                    ))}
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {loading ? (
                                    <TableRow><TableCell colSpan={headCells.length} align="center" sx={{ py: 8 }}><CircularProgress size={36} thickness={4} /></TableCell></TableRow>
                                ) : sortedData.length === 0 ? (
                                    <TableRow><TableCell colSpan={headCells.length} align="center" sx={{ py: 8 }}><Typography color="text.secondary" fontWeight={500}>{t('tech.list.noFound')}</Typography></TableCell></TableRow>
                                ) : sortedData.map((technician) => (
                                    <TableRow key={technician.id} hover onClick={() => navigate(`/app/technicians/${technician.id}`)}
                                              sx={{ cursor: 'pointer', '&:last-child td': { borderBottom: 0 }, transition: 'background-color 0.15s' }}>
                                        <TableCell sx={{ py: 2 }}>
                                            <Stack direction="row" spacing={1.5} alignItems="center">
                                                <Avatar src={technician.profile_photo ? getImageUrl(technician.profile_photo) : undefined}
                                                        sx={{ width: 40, height: 40, bgcolor: colors.sea || '#0f766e', fontSize: 15, fontWeight: 700 }}>
                                                    {technician.user?.name?.charAt(0).toUpperCase() || 'T'}
                                                </Avatar>
                                                <Box>
                                                    <Stack direction="row" spacing={0.5} alignItems="center">
                                                        <Typography variant="body2" fontWeight={600}>{technician.user?.name || t('tech.common.unknown')}</Typography>
                                                        {isVerifiedTech(technician) && (
                                                            <VerifiedIcon sx={{ fontSize: 14, color: 'success.main' }} />
                                                        )}
                                                    </Stack>
                                                    <Typography variant="caption" color="text.secondary">{technician.user?.email || ''}</Typography>
                                                </Box>
                                            </Stack>
                                        </TableCell>
                                        <TableCell>
                                            <Chip icon={<WorkIcon sx={{ fontSize: 14 }} />}
                                                  label={t('tech.list.serviceCount', { n: technician.services?.length || 0, s: (technician.services?.length || 0) !== 1 ? 's' : '' })}
                                                  size="small" sx={{ fontWeight: 600, bgcolor: 'action.hover', height: 24 }} />
                                        </TableCell>
                                        <TableCell>
                                            <Box display="flex" alignItems="center" gap={0.5}>
                                                <LocationIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                <Typography variant="body2" fontWeight={500}>{technician.area || t('tech.common.na')}</Typography>
                                            </Box>
                                        </TableCell>
                                        <TableCell>
                                            {technician.rating != null ? (
                                                <Box display="flex" alignItems="center" gap={0.5}>
                                                    <StarIcon sx={{ fontSize: 16, color: 'warning.main' }} />
                                                    <Typography variant="body2" fontWeight={700}>{Number(technician.rating).toFixed(1)}</Typography>
                                                </Box>
                                            ) : (
                                                <Typography variant="body2" color="text.secondary">{t('tech.list.noRating')}</Typography>
                                            )}
                                        </TableCell>
                                        <TableCell>{getStatusChip(technician)}</TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </TableContainer>
                ) : (
                    <Box sx={{ p: { xs: 2, sm: 2.5 } }}>
                        {loading ? (
                            <Box display="flex" justifyContent="center" py={6}><CircularProgress size={36} thickness={4} /></Box>
                        ) : sortedData.length === 0 ? (
                            <Paper variant="outlined" sx={{ p: 5, textAlign: 'center', borderRadius: 3, borderStyle: 'dashed' }}>
                                <Typography color="text.secondary" fontWeight={500}>{t('tech.list.noFound')}</Typography>
                            </Paper>
                        ) : (
                            <Stack spacing={2}>
                                {sortedData.map((technician) => (
                                    <Card key={technician.id} elevation={0}
                                          sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', overflow: 'hidden', cursor: 'pointer', '&:hover': { boxShadow: 2 } }}
                                          onClick={() => navigate(`/app/technicians/${technician.id}`)}>
                                        <CardContent sx={{ p: 2.5 }}>
                                            <Stack direction="row" spacing={2} alignItems="center" mb={2}>
                                                <Avatar src={technician.profile_photo ? getImageUrl(technician.profile_photo) : undefined}
                                                        sx={{ width: 52, height: 52, bgcolor: colors.sea || '#0f766e', fontSize: 18, fontWeight: 700 }}>
                                                    {technician.user?.name?.charAt(0).toUpperCase() || 'T'}
                                                </Avatar>
                                                <Box flex={1} minWidth={0}>
                                                    <Stack direction="row" spacing={0.5} alignItems="center">
                                                        <Typography variant="h6" fontWeight={700} fontSize="1rem" noWrap>{technician.user?.name || t('tech.common.unknown')}</Typography>
                                                        {isVerifiedTech(technician) && (
                                                            <VerifiedIcon sx={{ fontSize: 16, color: 'success.main' }} />
                                                        )}
                                                    </Stack>
                                                    <Typography variant="caption" color="text.secondary" noWrap display="block">{technician.user?.email || ''}</Typography>
                                                </Box>
                                                {getStatusChip(technician)}
                                            </Stack>
                                            <Divider sx={{ mb: 2 }} />
                                            <Box sx={gridSx('repeat(2, 1fr)', 1.5)}>
                                                <Box display="flex" alignItems="center" gap={0.5}>
                                                    <LocationIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                    <Typography variant="body2" fontWeight={500}>{technician.area || t('tech.common.na')}</Typography>
                                                </Box>
                                                <Box display="flex" alignItems="center" gap={0.5}>
                                                    {technician.rating != null && (
                                                        <>
                                                            <StarIcon sx={{ fontSize: 16, color: 'warning.main' }} />
                                                            <Typography variant="body2" fontWeight={700}>{Number(technician.rating).toFixed(1)}</Typography>
                                                        </>
                                                    )}
                                                </Box>
                                            </Box>
                                        </CardContent>
                                    </Card>
                                ))}
                            </Stack>
                        )}
                    </Box>
                )}

                {/* PAGINATION */}
                <Box sx={{ borderTop: '1px solid', borderColor: 'divider', bgcolor: 'action.hover' }}>
                    <TablePagination
                        rowsPerPageOptions={[5, 10, 25, 50]} component="div"
                        count={totalCount} rowsPerPage={rowsPerPage} page={page}
                        onPageChange={(_, newPage) => setPage(newPage)}
                        onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
                        sx={{ '.MuiTablePagination-selectLabel, .MuiTablePagination-displayedRows': { fontWeight: 500 } }}
                    />
                </Box>
            </Paper>
        </Box>
    );
};

export default TechniciansList;