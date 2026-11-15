// src/pages/jobs/JobsList.js
import React, { useEffect, useMemo, useState } from 'react';
import {
    Box, Paper, Typography, Button, Grid, Card, CardContent, TextField, MenuItem,
    Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination,
    Chip, CircularProgress, Tooltip, Stack, Avatar, Dialog, DialogTitle,
    DialogContent, DialogActions, Divider, TableSortLabel, IconButton,
} from '@mui/material';
import {
    Refresh as RefreshIcon,
    Person as PersonIcon,
    LocationOn as LocationIcon,
    Build as BuildIcon,
    Visibility as ViewIcon,
    CheckCircle as CheckCircleIcon,
    Pending as PendingIcon,
    HourglassEmpty as HourglassIcon,
    Phone as PhoneIcon,
    Email as EmailIcon,
    Close as CloseIcon,
    Receipt as ReceiptIcon,
    CalendarToday as CalendarIcon,
    Notes as NotesIcon,
    Print as PrintIcon,
    Search as SearchIcon,
} from '@mui/icons-material';
import {
    LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer
} from 'recharts';
import { toast } from 'react-toastify';

import { useJobManagement } from 'hooks/useJob';
import { useLanguage } from 'context/LanguageContext';
import { usePermissions } from 'hooks/usePermissions';
import { jobService } from 'services/job.service';
import { tJobs } from './jobslang';
import { format } from 'date-fns';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const getStatusColors = (t) => ({
    pending: { color: '#f59e0b', bg: '#fef3c7', label: t('statusPending'), icon: <PendingIcon sx={{ fontSize: 14 }} /> },
    'on-progress': { color: '#3b82f6', bg: '#eff6ff', label: t('statusProgress'), icon: <HourglassIcon sx={{ fontSize: 14 }} /> },
    completed: { color: '#10b981', bg: '#d1fae5', label: t('statusCompleted'), icon: <CheckCircleIcon sx={{ fontSize: 14 }} /> },
});

export default function JobsList() {
    const { language } = useLanguage();
    const { can } = usePermissions();
    const t = (key) => tJobs(language, key);
    const STATUS_COLORS = useMemo(() => getStatusColors(t), [language]);

    const {
        jobs, loading, error, getJobs, getJob,
        reviewJob, clearError,
    } = useJobManagement();

    // Chart & Stats States
    const [chartType, setChartType] = useState('histogram');
    const [chartData, setChartData] = useState([]);
    const [chartPeriod, setChartPeriod] = useState('month');
    const [chartLoading, setChartLoading] = useState(false);
    const [statsData, setStatsData] = useState({ total: 0, pending: 0, on_progress: 0, completed: 0 });

    // ── Filters State ──
    // 1. filters: The temporary state tied to inputs (doesn't trigger fetch)
    const [filters, setFilters] = useState({
        status: '', search: '', from: '', to: ''
    });
    // 2. appliedFilters: The "committed" state that triggers the fetch
    const [appliedFilters, setAppliedFilters] = useState({
        status: '', search: '', from: '', to: '', sort: 'created_at', order: 'desc'
    });

    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(20);
    const [selected, setSelected] = useState(null);
    const [loadingDetails, setLoadingDetails] = useState(false);
    const [review, setReview] = useState({ rating: 5, comment: '' });
    const [busy, setBusy] = useState(false);

    // ── Fetch Chart Data ──
    const loadChartData = async () => {
        setChartLoading(true);
        try {
            const params = {
                period: chartPeriod,
                from: appliedFilters.from || undefined,
                to: appliedFilters.to || undefined,
                status: appliedFilters.status || undefined,
            };

            if (chartType === 'line') {
                const res = await jobService.getJobHistogram(params);
                setChartData(res.data.data || []);
            } else {
                const res = await jobService.getJobChartData(params);
                setChartData(res.data.data || []);
            }
        } catch (e) {
            console.error('Failed to load chart data', e);
        } finally {
            setChartLoading(false);
        }
    };

    // ── Fetch Stats Data ──
    const loadStatsData = async () => {
        try {
            const res = await jobService.getJobStats({
                from: appliedFilters.from || undefined,
                to: appliedFilters.to || undefined,
                status: appliedFilters.status || undefined,
            });
            setStatsData(res.data.data || { total: 0, pending: 0, on_progress: 0, completed: 0 });
        } catch (e) {
            console.error('Failed to load stats', e);
        }
    };

    useEffect(() => {
        loadChartData();
        loadStatsData();
    }, [chartType, chartPeriod, appliedFilters]);

    // ── Fetch Table Data (Only triggers on appliedFilters, page, rowsPerPage) ──
    const load = () => {
        clearError?.();
        getJobs({
            status: appliedFilters.status,
            search: appliedFilters.search,
            sort: appliedFilters.sort,
            order: appliedFilters.order,
            from: appliedFilters.from || undefined,
            to: appliedFilters.to || undefined,
            limit: rowsPerPage,
            page: page + 1
        });
    };

    useEffect(() => {
        load();
    }, [appliedFilters, page, rowsPerPage]);

    // ── Apply Filters on Search Click ──
    const handleSearchSubmit = () => {
        setPage(0);
        setAppliedFilters({
            ...appliedFilters,
            status: filters.status,
            search: filters.search,
            from: filters.from,
            to: filters.to
        });
    };

    // ── Handle Sort ──
    const handleRequestSort = (property) => {
        const isAsc = appliedFilters.sort === property && appliedFilters.order === 'asc';
        setAppliedFilters((f) => ({ ...f, sort: property, order: isAsc ? 'desc' : 'asc' }));
    };

    const openDetails = async (job) => {
        setSelected(job);
        setReview({ rating: 5, comment: '' });
        setLoadingDetails(true);
        try {
            const fresh = await getJob(job.id);
            if (fresh) setSelected(fresh);
        } catch {} finally {
            setLoadingDetails(false);
        }
    };

    const handleReview = async () => {
        if (!selected) return;
        setBusy(true);
        try {
            await reviewJob(selected.id, review);
            toast.success(t('reviewSuccess'));
            const fresh = await getJob(selected.id);
            if (fresh) setSelected(fresh);
        } catch (e) {
            toast.error(e?.response?.data?.message || t('reviewFail'));
        } finally { setBusy(false); }
    };

    // ── Print ticket (Clean & Fixed) ──
    const handlePrint = () => {
        if (!selected) return;
        const job = selected;
        const tech = job.technician || {};
        const cust = job.customer || {};
        const req  = job.request || {};
        const svc  = req.service || {};
        const cat  = req.category || {};
        const ticket = job.ticket || {};

        // Ensure we grab the technician name correctly
        const techName = tech.name || 'Fundi';
        const jobNo = job.job_number || 'Job';

        const html = `
            <html>
            <head>
                <title>${jobNo} - ${techName}</title>
                <style>
                    body { font-family: Arial, Helvetica, sans-serif; padding: 24px; color: #111; }
                    h1 { font-size: 22px; margin: 0 0 4px; }
                    .tech-name { font-size: 16px; font-weight: bold; color: #333; margin-bottom: 8px; }
                    h2 { font-size: 14px; margin: 16px 0 6px; border-bottom: 1px solid #ccc; padding-bottom: 4px; }
                    .row { display: flex; gap: 24px; flex-wrap: wrap; }
                    .col { flex: 1 1 260px; }
                    .muted { color: #666; font-size: 12px; }
                    .kv { margin: 2px 0; font-size: 13px; }
                    .label { color: #555; font-weight: 600; }
                    .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; background: #eee; font-size: 12px; }
                    .footer { margin-top: 24px; font-size: 11px; color: #888; }
                </style>
            </head>
            <body>
                <h1>${jobNo}</h1>
                <div class="tech-name">Fundi: ${techName}</div>
                
                <div class="muted">${t('printCreated')}: ${job.created_at || '—'}${job.completed_at ? ' · ' + t('printCompleted') + ': ' + job.completed_at : ''}</div>
                <div class="muted" style="margin-bottom: 16px;">Status: <span class="badge">${job.status || '—'}</span></div>

                <div class="row">
                    <div class="col">
                        <h2>${t('customer')}</h2>
                        <div class="kv"><span class="label">${t('printName')}:</span> ${cust.name || '—'}</div>
                    </div>
                    <div class="col">
                        <h2>${t('fundi')}</h2>
                        <div class="kv"><span class="label">${t('printName')}:</span> ${techName}</div>
                        <div class="kv"><span class="label">${t('printPhone')}:</span> ${tech.phone || '—'}</div>
                        <div class="kv"><span class="label">${t('printEmail')}:</span> ${tech.email || '—'}</div>
                        <div class="kv"><span class="label">${t('area')}:</span> ${tech.area || '—'}</div>
                        <div class="kv"><span class="label">${t('printRating')}:</span> ⭐ ${tech.rating ?? 0}</div>
                    </div>
                </div>

                <h2>${t('request')}</h2>
                <div class="kv"><span class="label">${t('service')}:</span> ${svc.name || '—'}</div>
                <div class="kv"><span class="label">${t('category')}:</span> ${cat.name || '—'}</div>
                <div class="kv"><span class="label">${t('printDescription')}:</span> ${req.description || '—'}</div>

                <h2>${t('ticket')}</h2>
                <div class="kv"><span class="label">${t('printNumber')}:</span> ${ticket.ticket_number || '—'}</div>
                <div class="kv"><span class="label">${t('printStatus')}:</span> <span class="badge">${ticket.status || '—'}</span></div>
                <div class="kv"><span class="label">${t('printTitle')}:</span> ${ticket.title || '—'}</div>
                <div class="kv"><span class="label">${t('printDescription')}:</span> ${ticket.description || '—'}</div>
                <div class="kv"><span class="label">${t('printCompleted')}:</span> ${ticket.completed_at || '—'}</div>

                ${job.review ? `
                    <h2>${t('review')}</h2>
                    <div class="kv"><span class="label">${t('printRating')}:</span> ⭐ ${job.review.rating}</div>
                    <div class="kv"><span class="label">${t('printComment')}:</span> ${job.review.comment || '—'}</div>
                ` : ''}

                <div class="footer">${t('printPrintedOn')} ${new Date().toLocaleString()}</div>
            </body>
            </html>
        `;

        const w = window.open('', '_blank', 'width=800,height=900');
        if (!w) { toast.error(t('popupBlocked')); return; }
        w.document.open();
        w.document.write(html);
        w.document.close();
        w.focus();
        setTimeout(() => w.print(), 250);
    };

    const formatDate = (dateStr) => {
        if (!dateStr) return '-';
        try { return format(new Date(dateStr), 'MMM d, yyyy'); } catch { return '-'; }
    };

    const formatDateFull = (dateStr) => {
        if (!dateStr) return '-';
        try { return format(new Date(dateStr), 'MMM d, yyyy h:mm a'); } catch { return '-'; }
    };

    const rows = useMemo(() => jobs || [], [jobs]);

    return (
        <Box sx={{ width: '100%', maxWidth: '100%' }}>
            {/* Filter Bar */}
            <Paper elevation={0} sx={{ p: 2, mb: 3, borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}>
                <Stack direction="row" spacing={2} flexWrap="wrap" useFlexGap alignItems="center">
                    <TextField select label={t('statusAll')} size="small" value={filters.status} onChange={(e) => setFilters((f) => ({ ...f, status: e.target.value }))} sx={{ minWidth: 140 }}>
                        <MenuItem value="">{t('statusAll')}</MenuItem>
                        <MenuItem value="pending">{t('statusPending')}</MenuItem>
                        <MenuItem value="on-progress">{t('statusProgress')}</MenuItem>
                        <MenuItem value="completed">{t('statusCompleted')}</MenuItem>
                    </TextField>

                    <TextField size="small" placeholder={t('searchPlaceholder')} value={filters.search} onChange={(e) => setFilters((f) => ({ ...f, search: e.target.value }))} sx={{ minWidth: 200 }} />

                    <TextField type="date" size="small" label="From" InputLabelProps={{ shrink: true }} value={filters.from} onChange={(e) => setFilters((f) => ({ ...f, from: e.target.value }))} sx={{ width: 150 }} />
                    <TextField type="date" size="small" label="To" InputLabelProps={{ shrink: true }} value={filters.to} onChange={(e) => setFilters((f) => ({ ...f, to: e.target.value }))} sx={{ width: 150 }} />

                    <Button variant="contained" startIcon={<SearchIcon />} onClick={handleSearchSubmit}>Search</Button>
                    <Box flexGrow={1} />
                    <Button variant="outlined" startIcon={<RefreshIcon />} onClick={() => { load(); loadChartData(); loadStatsData(); }}>{t('tooltipRefresh')}</Button>
                </Stack>
            </Paper>

            {/* Summary Cards */}
            <Grid container spacing={2} sx={{ mb: 3 }}>
                {[
                    { label: t('title'), value: statsData.total, color: '#3b82f6' },
                    { label: t('statusPending'), value: statsData.pending, color: '#f59e0b' },
                    { label: t('statusProgress'), value: statsData.on_progress, color: '#8b5cf6' },
                    { label: t('statusCompleted'), value: statsData.completed, color: '#10b981' },
                ].map((item, idx) => (
                    <Grid item xs={12} sm={6} md={3} key={idx}>
                        <Card elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', height: '100%' }}>
                            <CardContent>
                                <Typography variant="body2" sx={{ color: item.color, fontWeight: 600, mb: 0.5 }}>{item.label}</Typography>
                                <Typography variant="h4" sx={{ color: item.color, fontWeight: 700 }}>{item.value}</Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                ))}
            </Grid>

            {/* Chart Section */}
            <Paper elevation={0} sx={{ p: 3, mb: 3, borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}>
                <Box display="flex" justifyContent="space-between" alignItems="center" mb={2} flexWrap="wrap" gap={2}>
                    <Typography variant="h6" fontWeight={600}>Jobs Analytics</Typography>

                    <Stack direction="row" spacing={2}>
                        <TextField select size="small" value={chartType} onChange={(e) => setChartType(e.target.value)} sx={{ width: 140 }}>
                            <MenuItem value="histogram">Histogram</MenuItem>
                            <MenuItem value="line">Line Chart</MenuItem>
                        </TextField>

                        {chartType === 'line' && (
                            <TextField select size="small" value={chartPeriod} onChange={(e) => setChartPeriod(e.target.value)} sx={{ width: 140 }}>
                                <MenuItem value="week">This Week</MenuItem>
                                <MenuItem value="month">This Month</MenuItem>
                                <MenuItem value="year">This Year</MenuItem>
                            </TextField>
                        )}
                    </Stack>
                </Box>
                <Box sx={{ height: 320, width: '100%' }}>
                    {chartLoading ? (
                        <Box display="flex" justifyContent="center" alignItems="center" height="100%"><CircularProgress /></Box>
                    ) : chartData.length === 0 ? (
                        <Box display="flex" justifyContent="center" alignItems="center" height="100%"><Typography color="text.secondary">No data for this period</Typography></Box>
                    ) : chartType === 'histogram' ? (
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={chartData} margin={{ top: 10, right: 20, left: -20, bottom: 0 }}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e0e0e0" />
                                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#666', fontSize: 12 }} />
                                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#666', fontSize: 12 }} allowDecimals={false} />
                                <RechartsTooltip cursor={{ fill: 'rgba(0,0,0,0.05)' }} contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }} />
                                <Bar dataKey="count" radius={[4, 4, 0, 0]} barSize={60} fill={colors.sea || '#0f766e'} />
                            </BarChart>
                        </ResponsiveContainer>
                    ) : (
                        <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={chartData} margin={{ top: 10, right: 20, left: -20, bottom: 0 }}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e0e0e0" />
                                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#666', fontSize: 12 }} />
                                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#666', fontSize: 12 }} allowDecimals={false} />
                                <RechartsTooltip cursor={{ stroke: 'rgba(0,0,0,0.1)', strokeWidth: 2 }} contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }} />
                                <Line type="monotone" dataKey="count" stroke={colors.sea || '#0f766e'} strokeWidth={3} dot={{ r: 4, fill: colors.sea || '#0f766e', strokeWidth: 2, stroke: '#fff' }} activeDot={{ r: 6 }} />
                            </LineChart>
                        </ResponsiveContainer>
                    )}
                </Box>
            </Paper>

            {/* Table */}
            <Paper elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', overflow: 'hidden' }}>
                <Box sx={{ p: 2.5, borderBottom: '1px solid', borderColor: 'divider' }}>
                    <Typography variant="h6" fontWeight={600}>{t('title')}</Typography>
                </Box>
                {loading ? (
                    <Box sx={{ py: 6, textAlign: 'center' }}><CircularProgress /></Box>
                ) : rows.length === 0 ? (
                    <Box sx={{ py: 6, textAlign: 'center' }}><Typography color="text.secondary">{t('noJobs')}</Typography></Box>
                ) : (
                    <>
                        <TableContainer>
                            <Table>
                                <TableHead sx={{ backgroundColor: 'action.hover' }}>
                                    <TableRow>
                                        <TableCell sx={{ fontWeight: 700 }}>{t('colJob')}</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>{t('colCustomer')}</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>{t('colFundi')}</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>{t('colService')}</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>{t('colStatus')}</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>
                                            <TableSortLabel active={appliedFilters.sort === 'created_at'} direction={appliedFilters.sort === 'created_at' ? appliedFilters.order : 'asc'} onClick={() => handleRequestSort('created_at')}>{t('colCreated')}</TableSortLabel>
                                        </TableCell>
                                        <TableCell sx={{ fontWeight: 700 }} align="center">{t('colActions')}</TableCell>
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                    {rows.map((job) => {
                                        const st = STATUS_COLORS[job.status] || STATUS_COLORS.pending;
                                        return (
                                            <TableRow key={job.id} hover>
                                                <TableCell>
                                                    <Typography variant="body2" fontWeight={600}>{job.job_number}</Typography>
                                                    {job.ticket && <Typography variant="caption" color="text.secondary">{job.ticket.ticket_number}</Typography>}
                                                </TableCell>
                                                <TableCell>
                                                    <Box display="flex" alignItems="center" gap={1}>
                                                        <Avatar sx={{ width: 32, height: 32, bgcolor: colors.sea, fontSize: 14 }}>{job.customer?.name?.charAt(0).toUpperCase() || <PersonIcon />}</Avatar>
                                                        <Typography variant="body2" fontWeight={500}>{job.customer?.name || '-'}</Typography>
                                                    </Box>
                                                </TableCell>
                                                <TableCell>
                                                    <Box display="flex" alignItems="center" gap={1}>
                                                        <Avatar src={job.technician?.profile_photo || undefined} sx={{ width: 32, height: 32, bgcolor: colors.sea, fontSize: 14 }}>{job.technician?.name?.charAt(0).toUpperCase() || <PersonIcon />}</Avatar>
                                                        <Box>
                                                            <Typography variant="body2" fontWeight={500}>{job.technician?.name || '-'}</Typography>
                                                            <Typography variant="caption" color="text.secondary">{job.technician?.area || ''}</Typography>
                                                        </Box>
                                                    </Box>
                                                </TableCell>
                                                <TableCell>
                                                    <Chip icon={<BuildIcon sx={{ fontSize: 14 }} />} label={job.request?.service?.name || '-'} size="small" variant="outlined" sx={{ borderColor: 'divider' }} />
                                                </TableCell>
                                                <TableCell>
                                                    <Chip icon={st.icon} label={st.label} size="small" sx={{ backgroundColor: st.bg, color: st.color, fontWeight: 600, '& .MuiChip-icon': { color: st.color } }} />
                                                </TableCell>
                                                <TableCell>{formatDate(job.created_at)}</TableCell>
                                                <TableCell align="center">
                                                    <Tooltip title={t('tooltipDetails')}>
                                                        <Button size="small" variant="outlined" startIcon={<ViewIcon />} onClick={() => openDetails(job)} sx={{ borderColor: 'divider', color: colors.sea, '&:hover': { borderColor: colors.sea, backgroundColor: 'primary.50' } }}>
                                                            {language === 'sw' ? 'Tazama' : 'View'}
                                                        </Button>
                                                    </Tooltip>
                                                </TableCell>
                                            </TableRow>
                                        );
                                    })}
                                </TableBody>
                            </Table>
                        </TableContainer>
                        <TablePagination component="div" count={statsData.total || 0} rowsPerPage={rowsPerPage} page={page} onPageChange={(e, p) => setPage(p)} onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }} rowsPerPageOptions={[5, 10, 25, 50]} sx={{ borderTop: '1px solid', borderColor: 'divider' }} />
                    </>
                )}
            </Paper>

            {/* Dialog */}
            <Dialog open={!!selected} onClose={() => setSelected(null)} maxWidth="md" fullWidth PaperProps={{ sx: { borderRadius: 3, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', maxHeight: '90vh' } }}>
                {selected && (
                    <>
                        <DialogTitle sx={{ pb: 1, borderBottom: '1px solid', borderColor: 'divider' }}>
                            <Box display="flex" justifyContent="space-between" alignItems="flex-start">
                                <Box>
                                    <Typography variant="h6" fontWeight={600} color="text.primary">{selected.job_number}</Typography>
                                    <Box display="flex" alignItems="center" gap={2} mt={1}>
                                        <Chip icon={STATUS_COLORS[selected.status]?.icon} label={STATUS_COLORS[selected.status]?.label || selected.status} size="small" sx={{ backgroundColor: STATUS_COLORS[selected.status]?.bg, color: STATUS_COLORS[selected.status]?.color, fontWeight: 600, '& .MuiChip-icon': { color: STATUS_COLORS[selected.status]?.color } }} />
                                        <Typography variant="caption" color="text.secondary"><CalendarIcon sx={{ fontSize: 14, mr: 0.5, verticalAlign: 'middle' }} />{formatDateFull(selected.created_at)}</Typography>
                                        <Typography variant="caption" color="text.secondary"><ReceiptIcon sx={{ fontSize: 14, mr: 0.5, verticalAlign: 'middle' }} />#{selected.id}</Typography>
                                    </Box>
                                </Box>
                                <IconButton onClick={() => setSelected(null)} size="small" sx={{ color: 'text.secondary' }}><CloseIcon /></IconButton>
                            </Box>
                        </DialogTitle>
                        <DialogContent sx={{ p: 3 }}>
                            {loadingDetails && <Box display="flex" alignItems="center" gap={1} mb={2}><CircularProgress size={18} /><Typography variant="body2" color="text.secondary">{t('loadingDetails')}</Typography></Box>}

                            <Box mb={3}>
                                <Typography variant="subtitle2" fontWeight={600} gutterBottom sx={{ color: 'text.primary', display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <NotesIcon sx={{ fontSize: 18, color: colors.sea }} />{t('request')}
                                </Typography>
                                <Paper variant="outlined" sx={{ p: 2.5, backgroundColor: 'action.hover', borderColor: 'divider', borderRadius: 2 }}>
                                    <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>{selected.request?.description || '-'}</Typography>
                                    <Box display="flex" gap={2} mt={1}>
                                        <Typography variant="caption" color="text.secondary">{t('service')}: {selected.request?.service?.name || '-'}</Typography>
                                        <Typography variant="caption" color="text.secondary">{t('category')}: {selected.request?.category?.name || '-'}</Typography>
                                    </Box>
                                </Paper>
                            </Box>

                            <Divider sx={{ mb: 3, borderColor: 'divider' }} />

                            <Grid container spacing={3}>
                                <Grid item xs={12} md={6}>
                                    <Typography variant="subtitle2" fontWeight={600} gutterBottom sx={{ color: 'text.primary' }}>{t('customer')}</Typography>
                                    <Paper variant="outlined" sx={{ p: 2.5, borderColor: 'divider', borderRadius: 2 }}>
                                        <Box display="flex" alignItems="center" gap={1.5}>
                                            <Avatar sx={{ bgcolor: colors.sea, width: 40, height: 40 }}>{selected.customer?.name?.charAt(0).toUpperCase() || <PersonIcon />}</Avatar>
                                            <Typography variant="body1" fontWeight={500}>{selected.customer?.name || '-'}</Typography>
                                        </Box>
                                    </Paper>
                                </Grid>
                                <Grid item xs={12} md={6}>
                                    <Typography variant="subtitle2" fontWeight={600} gutterBottom sx={{ color: 'text.primary' }}>{t('fundi')}</Typography>
                                    <Paper variant="outlined" sx={{ p: 2.5, borderColor: 'divider', borderRadius: 2 }}>
                                        <Stack spacing={1.5}>
                                            <Box display="flex" alignItems="center" gap={1.5}>
                                                <Avatar src={selected.technician?.profile_photo || undefined} sx={{ bgcolor: colors.sea, width: 40, height: 40 }}>{selected.technician?.name?.charAt(0).toUpperCase() || <PersonIcon />}</Avatar>
                                                <Typography variant="body1" fontWeight={500}>{selected.technician?.name || '-'}</Typography>
                                            </Box>
                                            <Divider sx={{ borderColor: 'divider' }} />
                                            <Box display="flex" alignItems="center" gap={1.5}><PhoneIcon fontSize="small" sx={{ color: 'text.secondary', width: 20 }} /><Typography variant="body2">{selected.technician?.phone || '-'}</Typography></Box>
                                            <Box display="flex" alignItems="center" gap={1.5}><EmailIcon fontSize="small" sx={{ color: 'text.secondary', width: 20 }} /><Typography variant="body2">{selected.technician?.email || '-'}</Typography></Box>
                                            <Box display="flex" alignItems="center" gap={1.5}><LocationIcon fontSize="small" sx={{ color: 'text.secondary', width: 20 }} /><Typography variant="body2">{selected.technician?.area || '-'}</Typography></Box>
                                        </Stack>
                                    </Paper>
                                </Grid>
                            </Grid>

                            {selected.ticket && (
                                <>
                                    <Divider sx={{ my: 3, borderColor: 'divider' }} />
                                    <Box>
                                        <Typography variant="subtitle2" fontWeight={600} gutterBottom sx={{ color: 'text.primary', display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <ReceiptIcon sx={{ fontSize: 18, color: colors.sea }} />{t('ticket')}
                                        </Typography>
                                        <Paper variant="outlined" sx={{ p: 2.5, backgroundColor: 'action.hover', borderColor: 'divider', borderRadius: 2 }}>
                                            <Typography variant="subtitle1" fontWeight={600}>{selected.ticket.title}</Typography>
                                            <Typography variant="body2" color="text.secondary" mb={1}>{selected.ticket.description}</Typography>
                                            <Chip size="small" label={selected.ticket.ticket_number} variant="outlined" />
                                        </Paper>
                                    </Box>
                                </>
                            )}

                            <Grid item xs={12}>
                                <Divider sx={{ my: 2 }} />
                                {selected.status === 'completed' && !selected.review && can('jobs.review') && (
                                    <>
                                        <Typography variant="subtitle2" gutterBottom>{t('leaveReview')}</Typography>
                                        <Box display="flex" gap={2} alignItems="center" flexWrap="wrap">
                                            <TextField select size="small" value={review.rating} onChange={(e) => setReview((r) => ({ ...r, rating: Number(e.target.value) }))}>
                                                {[5, 4, 3, 2, 1].map((n) => <MenuItem key={n} value={n}>{'⭐'.repeat(n)} ({n})</MenuItem>)}
                                            </TextField>
                                            <TextField size="small" label={t('printComment')} value={review.comment} onChange={(e) => setReview((r) => ({ ...r, comment: e.target.value }))} sx={{ minWidth: 260 }} />
                                            <Button variant="contained" onClick={handleReview} disabled={busy}>{t('submitReview')}</Button>
                                        </Box>
                                    </>
                                )}
                                {selected.review && (
                                    <>
                                        <Typography variant="subtitle2" gutterBottom>{t('review')}</Typography>
                                        <Typography variant="body2">⭐ {selected.review.rating} — {selected.review.comment || t('noRemark')}</Typography>
                                    </>
                                )}
                            </Grid>
                        </DialogContent>
                        <DialogActions sx={{ p: 2.5, borderTop: '1px solid', borderColor: 'divider' }}>

                            {/* Print Button */}
                            <Button
                                startIcon={<PrintIcon />}
                                onClick={handlePrint}
                                variant="outlined"
                                sx={{ borderColor: 'divider', color: colors.sea, mr: 'auto' }}
                            >
                                {t('printTicket')}
                            </Button>

                            <Button onClick={() => setSelected(null)} variant="contained" sx={{ backgroundColor: colors.sea, '&:hover': { backgroundColor: colors.dark }, px: 4 }}>
                                {t('close')}
                            </Button>
                        </DialogActions>
                    </>
                )}
            </Dialog>
        </Box>
    );
}