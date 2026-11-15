// src/pages/dashboard/Dashboard.js
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
    Box, Paper, Typography, Button, Grid, Card, CardContent, TextField, MenuItem,
    Chip, CircularProgress, Tooltip, Stack, Tabs, Tab, Divider, Skeleton, useMediaQuery,
} from '@mui/material';
import { useTheme } from '@mui/material/styles';
import {
    Refresh as RefreshIcon,
    Description as CsvIcon,
    TableChart as ExcelIcon,
    People as PeopleIcon,
    Assignment as RequestIcon,
    Engineering as TechIcon,
    Today as TodayIcon,
    DateRange as WeekIcon,
    ShowChart as LineIcon,
    BarChart as BarIcon,
    Work as JobIcon,
    ConfirmationNumber as TicketIcon,
} from '@mui/icons-material';
import {
    PieChart, Pie, Cell, Tooltip as ChartTooltip, Legend, ResponsiveContainer,
    XAxis, YAxis, CartesianGrid, Area, AreaChart, BarChart, Bar,
} from 'recharts';
import { usePermissions } from 'hooks/usePermissions';
import { useReportManagement } from 'hooks/useReport';
import { showSnackbar } from 'utils/snackbar';
import { useLanguage } from 'context/LanguageContext';
import { tDashboard } from './components/dashlang';
import appConfig from '../../config';

const colors = appConfig.app.colors || {
    middle: '#e2e8f0',
    primary: '#3b82f6',
};

// ---------------------------------------------------------------------------
// Status colors (shared)
// ---------------------------------------------------------------------------
const STATUS_COLORS = {
    active: { color: '#10b981', bg: '#d1fae5' },
    approved: { color: '#10b981', bg: '#d1fae5' },
    completed: { color: '#10b981', bg: '#d1fae5' },
    pending: { color: '#f59e0b', bg: '#fef3c7' },
    accepted: { color: '#3b82f6', bg: '#eff6ff' },
    on_the_way: { color: '#6366f1', bg: '#eef2ff' },
    'on-progress': { color: '#6366f1', bg: '#eef2ff' },
    expired: { color: '#ef4444', bg: '#fee2e2' },
    rejected: { color: '#ef4444', bg: '#fee2e2' },
    suspended: { color: '#ef4444', bg: '#fee2e2' },
    cancelled: { color: '#6b7280', bg: '#f3f4f6' },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function buildDailyInsights(buckets = []) {
    if (!buckets.length) {
        return { today: null, yesterday: null, weekSoFar: null, lastLabel: null };
    }

    const sumKeys = (b) => ({
        customers: b?.customers ?? 0,
        requests: b?.requests ?? 0,
        technicians: b?.technicians ?? 0,
        jobs: b?.jobs ?? 0,
        tickets: b?.tickets ?? 0,
    });

    const last = buckets[buckets.length - 1];
    const prev = buckets.length > 1 ? buckets[buckets.length - 2] : null;

    const today = sumKeys(last);
    const yesterday = prev ? sumKeys(prev) : null;

    const weekBuckets = buckets.slice(-7);
    const weekSoFar = weekBuckets.reduce(
        (acc, b) => ({
            customers: acc.customers + (b.customers || 0),
            requests: acc.requests + (b.requests || 0),
            technicians: acc.technicians + (b.technicians || 0),
            jobs: acc.jobs + (b.jobs || 0),
            tickets: acc.tickets + (b.tickets || 0),
        }),
        { customers: 0, requests: 0, technicians: 0, jobs: 0, tickets: 0 }
    );

    return { today, yesterday, weekSoFar, lastLabel: last?.label };
}

// ---------------------------------------------------------------------------
// Main Dashboard
// ---------------------------------------------------------------------------
const Dashboard = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

    const { language } = useLanguage();
    const t = (key) => tDashboard(language, key);

    const { can } = usePermissions();
    const canView = can('reports.view');

    const {
        summary,
        trends,
        overview,
        loadingSummary,
        loadingTrends,
        loadingOverview,
        getSummary,
        getTrends,
        getOverview,
        exportFinanceReport,
    } = useReportManagement();

    // Filters
    const [range, setRange] = useState('week');
    const [granularity, setGranularity] = useState('');
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');

    // Domain
    const [domain, setDomain] = useState('requests');
    const [status, setStatus] = useState('all');
    const [exportFmt, setExportFmt] = useState(null);

    // Chart type
    const [chartType, setChartType] = useState('line');

    // Domain config (language-aware)
    const DOMAINS = useMemo(
        () => ({
            customers: {
                label: t('dashboard.domain.customers') || 'Customers',
                chartColor: '#3b82f6',
                icon: PeopleIcon,
                statuses: ['active', 'pending', 'suspended'],
            },
            requests: {
                label: t('dashboard.domain.requests') || 'Requests',
                chartColor: '#8b5cf6',
                icon: RequestIcon,
                statuses: ['pending', 'accepted', 'cancelled', 'rejected'],
            },
            technicians: {
                label: t('dashboard.domain.technicians') || 'Technicians',
                chartColor: '#f59e0b',
                icon: TechIcon,
                statuses: ['approved', 'pending', 'rejected'],
            },
            jobs: {
                label: 'Jobs',
                chartColor: '#10b981',
                icon: JobIcon,
                statuses: ['pending', 'on-progress', 'completed'],
            },
            tickets: {
                label: 'Tickets',
                chartColor: '#ef4444',
                icon: TicketIcon,
                statuses: ['on-progress', 'completed'],
            },
        }),
        [language]
    );

    const domainConfig = DOMAINS[domain];

    const effectiveGranularity = useMemo(() => {
        if (granularity) return granularity;
        if (range === 'week' || range === 'month') return 'daily';
        if (range === 'year') return 'monthly';
        return 'daily';
    }, [range, granularity]);

    const rangeParams = useCallback(() => {
        const p = { range, granularity: effectiveGranularity };
        if (range === 'custom') {
            p.date_from = dateFrom;
            p.date_to = dateTo;
        }
        return p;
    }, [range, effectiveGranularity, dateFrom, dateTo]);

    // Data fetching
    useEffect(() => {
        getOverview(rangeParams());
    }, [rangeParams, getOverview]);

    useEffect(() => {
        getTrends(rangeParams());
    }, [rangeParams, getTrends]);

    useEffect(() => {
        setStatus('all');
    }, [domain]);

    useEffect(() => {
        getSummary({ ...rangeParams(), type: domain, status });
    }, [rangeParams, domain, status, getSummary]);

    const refreshAll = () => {
        getOverview(rangeParams());
        getTrends(rangeParams());
        getSummary({ ...rangeParams(), type: domain, status });
    };

    const handleExport = async (format, scope = domain) => {
        setExportFmt(`${scope}-${format}`);
        try {
            const response = await exportFinanceReport({
                ...rangeParams(),
                type: scope,
                status: scope === 'all' ? undefined : status,
                format,
            });
            const blob = new Blob([response.data], {
                type:
                    format === 'xlsx'
                        ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                        : 'text/csv',
            });
            const url = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = `report_${scope}_${new Date().toISOString().slice(0, 10)}.${
                format === 'xlsx' ? 'xlsx' : 'csv'
            }`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            window.URL.revokeObjectURL(url);
            showSnackbar({ type: 'success', message: 'Report exported successfully' });
        } catch {
            // handled by context
        } finally {
            setExportFmt(null);
        }
    };

    const headline = overview.headline || {};
    const trendBuckets = trends.buckets || [];
    const pieData = summary.status_breakdown || [];
    const dailyInsights = useMemo(() => buildDailyInsights(trendBuckets), [trendBuckets]);

    // Dynamic Totals based on selected domain
    const summaryTotals = useMemo(() => {
        if (!summary.totals) return {};

        const totals = {
            count: summary.totals.count ?? 0,
        };

        domainConfig.statuses.forEach(s => {
            if (summary.totals[s] !== undefined) {
                totals[s] = summary.totals[s];
            }
        });

        return totals;
    }, [summary.totals, domainConfig]);

    const headlineCards = useMemo(
        () => [
            {
                key: 'customers',
                label: t('dashboard.domain.customers') || 'Customers',
                color: DOMAINS.customers.chartColor,
                bg: 'background.paper',
                icon: PeopleIcon,
            },
            {
                key: 'requests',
                label: t('dashboard.domain.requests') || 'Requests',
                color: DOMAINS.requests.chartColor,
                bg: 'background.paper',
                icon: RequestIcon,
            },
            {
                key: 'technicians',
                label: t('dashboard.domain.technicians') || 'Technicians',
                color: DOMAINS.technicians.chartColor,
                bg: 'background.paper',
                icon: TechIcon,
            },
            {
                key: 'jobs',
                label: 'Jobs',
                color: DOMAINS.jobs.chartColor,
                bg: 'background.paper',
                icon: JobIcon,
            },
            {
                key: 'tickets',
                label: 'Tickets',
                color: DOMAINS.tickets.chartColor,
                bg: 'background.paper',
                icon: TicketIcon,
            },
        ],
        [language]
    );

    if (!canView) {
        return (
            <Paper sx={{ p: 4, textAlign: 'center', borderRadius: 3, m: 2 }}>
                <Typography color="error" variant="h6">
                    {t('dashboard.noPermission')}
                </Typography>
            </Paper>
        );
    }

    return (
        <Box
            sx={{
                width: '100%',
                maxWidth: '100%',
                px: { xs: 1.5, sm: 2, md: 3 },
                py: { xs: 2, md: 3 },
                bgcolor: 'background.default',
                minHeight: '100%',
            }}
        >
            {/* ===================== FILTER BAR ===================== */}
            <Paper
                elevation={0}
                sx={{
                    p: { xs: 2, sm: 2.5 },
                    mb: 3,
                    borderRadius: 3,
                    border: `1px solid ${theme.palette.divider}`,
                    bgcolor: 'background.paper',
                    boxShadow: theme.palette.mode === 'dark' ? 'none' : '0 1px 3px rgba(0,0,0,0.04)',
                }}
            >
                <Stack
                    direction={{ xs: 'column', md: 'row' }}
                    spacing={2}
                    alignItems={{ xs: 'stretch', md: 'center' }}
                    flexWrap="wrap"
                    useFlexGap
                >
                    <TextField
                        select
                        label={t('dashboard.range')}
                        size="small"
                        value={range}
                        onChange={(e) => setRange(e.target.value)}
                        sx={{ minWidth: { xs: '100%', sm: 140 } }}
                    >
                        <MenuItem value="week">{t('dashboard.thisWeek')}</MenuItem>
                        <MenuItem value="month">{t('dashboard.thisMonth')}</MenuItem>
                        <MenuItem value="year">{t('dashboard.thisYear')}</MenuItem>
                        <MenuItem value="custom">{t('dashboard.custom')}</MenuItem>
                    </TextField>

                    {range === 'custom' && (
                        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} sx={{ width: { xs: '100%', sm: 'auto' } }}>
                            <TextField
                                label={t('dashboard.from')}
                                type="date"
                                size="small"
                                value={dateFrom}
                                onChange={(e) => setDateFrom(e.target.value)}
                                InputLabelProps={{ shrink: true }}
                                fullWidth={isMobile}
                            />
                            <TextField
                                label={t('dashboard.to')}
                                type="date"
                                size="small"
                                value={dateTo}
                                onChange={(e) => setDateTo(e.target.value)}
                                InputLabelProps={{ shrink: true }}
                                fullWidth={isMobile}
                            />
                        </Stack>
                    )}

                    <TextField
                        select
                        label={t('dashboard.granularity')}
                        size="small"
                        value={granularity}
                        onChange={(e) => setGranularity(e.target.value)}
                        sx={{ minWidth: { xs: '100%', sm: 150 } }}
                        helperText={!granularity ? `${t('dashboard.auto')} → ${effectiveGranularity}` : ' '}
                        FormHelperTextProps={{ sx: { mt: 0.25, mb: 0 } }}
                    >
                        <MenuItem value="">{t('dashboard.auto')} ({effectiveGranularity})</MenuItem>
                        <MenuItem value="daily">{t('dashboard.daily')}</MenuItem>
                        <MenuItem value="weekly">{t('dashboard.weekly')}</MenuItem>
                        <MenuItem value="monthly">{t('dashboard.monthly')}</MenuItem>
                    </TextField>

                    <Box flexGrow={1} sx={{ display: { xs: 'none', md: 'block' } }} />

                    <Stack direction="row" spacing={1.5} justifyContent={{ xs: 'flex-end', md: 'flex-start' }}>
                        <Tooltip title="Export all domains as one Excel workbook">
                            <span>
                                <Button
                                    size="small"
                                    variant="outlined"
                                    startIcon={<ExcelIcon />}
                                    onClick={() => handleExport('xlsx', 'all')}
                                    disabled={!!exportFmt}
                                    sx={{ borderRadius: 2 }}
                                >
                                    {t('dashboard.exportAll')}
                                </Button>
                            </span>
                        </Tooltip>
                        <Button
                            variant="contained"
                            startIcon={<RefreshIcon />}
                            onClick={refreshAll}
                            disabled={loadingOverview || loadingTrends}
                            sx={{ borderRadius: 2 }}
                        >
                            {t('dashboard.refresh')}
                        </Button>
                    </Stack>
                </Stack>
            </Paper>

            {/* ===================== DAILY SUMMARY ===================== */}
            {(range === 'week' || range === 'month' || effectiveGranularity === 'daily') && (
                <Paper
                    elevation={0}
                    sx={{
                        p: { xs: 2, sm: 2.5 },
                        mb: 3,
                        borderRadius: 3,
                        border: `1px solid ${theme.palette.divider}`,
                        background: theme.palette.mode === 'dark'
                            ? theme.palette.background.paper
                            : 'linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%)',
                    }}
                >
                    <Stack direction="row" alignItems="center" spacing={1} mb={2}>
                        <TodayIcon sx={{ color: colors.primary, fontSize: 22 }} />
                        <Typography variant="h6" fontWeight={700}>
                            {t('dashboard.dailySummary')}
                        </Typography>
                        {dailyInsights.lastLabel && (
                            <Chip
                                size="small"
                                label={`${t('dashboard.latest')}: ${dailyInsights.lastLabel}`}
                                sx={{ height: 22, fontWeight: 600 }}
                            />
                        )}
                    </Stack>

                    {loadingTrends ? (
                        <Grid container spacing={2}>
                            {[1, 2, 3].map((i) => (
                                <Grid item xs={12} sm={4} key={i}>
                                    <Skeleton variant="rounded" height={110} sx={{ borderRadius: 2 }} />
                                </Grid>
                            ))}
                        </Grid>
                    ) : (
                        <Grid container spacing={2}>
                            {[
                                { title: t('dashboard.todayLatestDay'), data: dailyInsights.today, icon: TodayIcon },
                                { title: t('dashboard.previousDay'), data: dailyInsights.yesterday, icon: null },
                                { title: t('dashboard.last7Days'), data: dailyInsights.weekSoFar, icon: WeekIcon },
                            ].map((block) => (
                                <Grid item xs={12} sm={4} key={block.title}>
                                    <Box
                                        sx={{
                                            p: 2,
                                            borderRadius: 2.5,
                                            bgcolor: 'background.paper',
                                            border: `1px solid ${theme.palette.divider}`,
                                            height: '100%',
                                            boxShadow: theme.palette.mode === 'dark' ? 'none' : '0 1px 2px rgba(0,0,0,0.03)',
                                        }}
                                    >
                                        <Stack direction="row" alignItems="center" spacing={0.75} mb={1}>
                                            {block.icon && <block.icon sx={{ fontSize: 16, color: 'text.secondary' }} />}
                                            <Typography
                                                variant="caption"
                                                color="text.secondary"
                                                fontWeight={700}
                                                textTransform="uppercase"
                                                letterSpacing={0.4}
                                            >
                                                {block.title}
                                            </Typography>
                                        </Stack>
                                        {block.data ? (
                                            <Stack spacing={0.4}>
                                                <Typography variant="body2">
                                                    {t('dashboard.customers')}: <strong>{block.data.customers}</strong>
                                                </Typography>
                                                <Typography variant="body2">
                                                    {t('dashboard.requests')}: <strong>{block.data.requests}</strong>
                                                </Typography>
                                                <Typography variant="body2">
                                                    {t('dashboard.technicians')}: <strong>{block.data.technicians}</strong>
                                                </Typography>
                                                <Typography variant="body2">
                                                    Jobs: <strong>{block.data.jobs}</strong>
                                                </Typography>
                                                <Typography variant="body2">
                                                    Tickets: <strong>{block.data.tickets}</strong>
                                                </Typography>
                                            </Stack>
                                        ) : (
                                            <Typography variant="body2" color="text.secondary">
                                                {t('dashboard.noData')}
                                            </Typography>
                                        )}
                                    </Box>
                                </Grid>
                            ))}
                        </Grid>
                    )}
                </Paper>
            )}

            {/* ===================== KPI CARDS ===================== */}
            <Grid container spacing={2} sx={{ mb: 3 }}>
                {headlineCards.map((item) => {
                    const Icon = item.icon;
                    return (
                        <Grid item xs={12} sm={6} lg={2.4} key={item.key}>
                            <Card
                                elevation={0}
                                sx={{
                                    borderRadius: 3,
                                    border: `1px solid ${theme.palette.divider}`,
                                    background: 'background.paper',
                                    height: '100%',
                                    transition: 'all 0.22s ease',
                                    '&:hover': {
                                        boxShadow: '0 8px 20px rgba(0,0,0,0.07)',
                                        transform: 'translateY(-2px)',
                                    },
                                }}
                            >
                                <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
                                    <Stack direction="row" justifyContent="space-between" alignItems="flex-start">
                                        <Box sx={{ flex: 1, minWidth: 0 }}>
                                            <Typography
                                                variant="body2"
                                                sx={{ color: item.color, fontWeight: 700, mb: 0.5 }}
                                            >
                                                {item.label}
                                            </Typography>
                                            {loadingOverview ? (
                                                <Skeleton width={70} height={38} />
                                            ) : (
                                                <Typography
                                                    variant="h4"
                                                    sx={{
                                                        color: item.color,
                                                        fontWeight: 800,
                                                        lineHeight: 1.15,
                                                        fontSize: { xs: '1.75rem', sm: '2rem' },
                                                    }}
                                                >
                                                    {headline[item.key]?.count ?? 0}
                                                </Typography>
                                            )}
                                        </Box>
                                        <Box
                                            sx={{
                                                width: 44,
                                                height: 44,
                                                borderRadius: 2.5,
                                                bgcolor: theme.palette.mode === 'dark'
                                                    ? 'action.selected'
                                                    : 'rgba(255,255,255,0.75)',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                flexShrink: 0,
                                                ml: 1,
                                            }}
                                        >
                                            <Icon sx={{ color: item.color, fontSize: 24 }} />
                                        </Box>
                                    </Stack>
                                </CardContent>
                            </Card>
                        </Grid>
                    );
                })}
            </Grid>

            {/* ===================== COMBINED TREND ===================== */}
            <Paper
                elevation={0}
                sx={{
                    p: { xs: 2, sm: 3 },
                    mb: 3,
                    borderRadius: 3,
                    border: `1px solid ${theme.palette.divider}`,
                    bgcolor: 'background.paper',
                    minHeight: { xs: 420, sm: 480 },
                }}
            >
                <Stack
                    direction={{ xs: 'column', sm: 'row' }}
                    justifyContent="space-between"
                    alignItems={{ xs: 'flex-start', sm: 'center' }}
                    spacing={1.5}
                    mb={2.5}
                >
                    <Box>
                        <Typography variant="h6" fontWeight={700}>
                            {t('dashboard.combinedTrend')}
                            <Typography
                                component="span"
                                variant="body2"
                                color="text.secondary"
                                ml={1}
                                fontWeight={500}
                            >
                                ({trends.granularity || effectiveGranularity})
                            </Typography>
                        </Typography>
                        {(range === 'week' || range === 'month') && (
                            <Chip
                                size="small"
                                label={t('dashboard.dailyView')}
                                color="primary"
                                variant="outlined"
                                sx={{ mt: 0.75, height: 22, fontWeight: 600 }}
                            />
                        )}
                    </Box>

                    <Stack direction="row" spacing={1}>
                        <Button
                            size="small"
                            variant={chartType === 'line' ? 'contained' : 'outlined'}
                            startIcon={<LineIcon />}
                            onClick={() => setChartType('line')}
                            sx={{ borderRadius: 2, textTransform: 'none', px: 1.5 }}
                        >
                            {t('dashboard.line')}
                        </Button>
                        <Button
                            size="small"
                            variant={chartType === 'bar' ? 'contained' : 'outlined'}
                            startIcon={<BarIcon />}
                            onClick={() => setChartType('bar')}
                            sx={{ borderRadius: 2, textTransform: 'none', px: 1.5 }}
                        >
                            {t('dashboard.histogram')}
                        </Button>
                    </Stack>
                </Stack>

                {loadingTrends ? (
                    <Box sx={{ height: 360, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <CircularProgress />
                    </Box>
                ) : trendBuckets.length === 0 ? (
                    <Box sx={{ height: 360, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Typography color="text.secondary">{t('dashboard.noDataPeriod')}</Typography>
                    </Box>
                ) : chartType === 'line' ? (
                    <ResponsiveContainer width="100%" height={isMobile ? 300 : 380}>
                        <AreaChart data={trendBuckets} margin={{ top: 8, right: 12, left: -10, bottom: 0 }}>
                            <defs>
                                {Object.values(DOMAINS).map((d) => (
                                    <linearGradient key={d.label} id={`grad-${d.label}`} x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor={d.chartColor} stopOpacity={0.3} />
                                        <stop offset="95%" stopColor={d.chartColor} stopOpacity={0} />
                                    </linearGradient>
                                ))}
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={theme.palette.divider} />
                            <XAxis dataKey="label" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
                            <YAxis tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
                            <ChartTooltip
                                contentStyle={{
                                    borderRadius: 10,
                                    border: `1px solid ${theme.palette.divider}`,
                                    boxShadow: '0 4px 14px rgba(0,0,0,0.08)',
                                }}
                            />
                            <Legend wrapperStyle={{ paddingTop: 14 }} />
                            {Object.entries(DOMAINS).map(([key, d]) => (
                                <Area
                                    key={key}
                                    type="monotone"
                                    dataKey={key}
                                    name={d.label}
                                    stroke={d.chartColor}
                                    fill={`url(#grad-${d.label})`}
                                    strokeWidth={2.5}
                                    dot={false}
                                    activeDot={{ r: 5 }}
                                />
                            ))}
                        </AreaChart>
                    </ResponsiveContainer>
                ) : (
                    <ResponsiveContainer width="100%" height={isMobile ? 300 : 380}>
                        <BarChart
                            data={trendBuckets}
                            margin={{ top: 8, right: 12, left: -10, bottom: 0 }}
                            barCategoryGap="16%"
                            barGap={2}
                        >
                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={theme.palette.divider} />
                            <XAxis dataKey="label" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
                            <YAxis tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
                            <ChartTooltip
                                contentStyle={{
                                    borderRadius: 10,
                                    border: `1px solid ${theme.palette.divider}`,
                                    boxShadow: '0 4px 14px rgba(0,0,0,0.08)',
                                }}
                                cursor={{ fill: 'rgba(0,0,0,0.04)' }}
                            />
                            <Legend wrapperStyle={{ paddingTop: 14 }} />
                            {Object.entries(DOMAINS).map(([key, d]) => (
                                <Bar
                                    key={key}
                                    dataKey={key}
                                    name={d.label}
                                    fill={d.chartColor}
                                    radius={[4, 4, 0, 0]}
                                    maxBarSize={26}
                                />
                            ))}
                        </BarChart>
                    </ResponsiveContainer>
                )}
            </Paper>

            {/* ===================== DOMAIN TABS + PIE + TOTALS ===================== */}
            <Paper
                elevation={0}
                sx={{
                    borderRadius: 3,
                    border: `1px solid ${theme.palette.divider}`,
                    mb: 3,
                    overflow: 'hidden',
                    bgcolor: 'background.paper',
                }}
            >
                <Tabs
                    value={domain}
                    onChange={(e, v) => setDomain(v)}
                    variant="scrollable"
                    scrollButtons="auto"
                    allowScrollButtonsMobile
                    sx={{
                        borderBottom: `1px solid ${theme.palette.divider}`,
                        px: 1,
                        minHeight: 48,
                        '& .MuiTab-root': { fontWeight: 600, textTransform: 'none', minHeight: 48 },
                    }}
                >
                    {Object.entries(DOMAINS).map(([key, cfg]) => (
                        <Tab key={key} value={key} label={cfg.label} />
                    ))}
                </Tabs>

                <Grid container>
                    {/* Pie Chart (Donut) */}
                    <Grid
                        item
                        xs={12}
                        md={5}
                        sx={{
                            p: { xs: 2, sm: 3 },
                            borderRight: { md: `1px solid ${theme.palette.divider}` },
                            borderBottom: { xs: `1px solid ${theme.palette.divider}`, md: 'none' },
                            display: 'flex',
                            flexDirection: 'column',
                            alignItems: 'center',
                        }}
                    >
                        <Typography variant="h6" fontWeight={700} mb={2} alignSelf="flex-start">
                            {domainConfig.label} {t('dashboard.byStatus')}
                        </Typography>
                        {loadingSummary ? (
                            <Box sx={{ height: 320, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <CircularProgress />
                            </Box>
                        ) : pieData.length === 0 ? (
                            <Box sx={{ height: 320, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Typography color="text.secondary">{t('dashboard.noData')}</Typography>
                            </Box>
                        ) : (
                            <ResponsiveContainer width="100%" height={320}>
                                <PieChart>
                                    <Pie
                                        data={pieData}
                                        dataKey="total"
                                        nameKey="status"
                                        cx="50%"
                                        cy="50%"
                                        innerRadius="60%"
                                        outerRadius="90%"
                                        paddingAngle={2}
                                        labelLine={false}
                                    >
                                        {pieData.map((entry, idx) => (
                                            <Cell
                                                key={idx}
                                                fill={(STATUS_COLORS[entry.status] || {}).color || '#94a3b8'}
                                            />
                                        ))}
                                    </Pie>
                                    <ChartTooltip
                                        formatter={(value, name) => [`${value}`, name.replace(/_/g, ' ')]}
                                        contentStyle={{
                                            borderRadius: 10,
                                            border: `1px solid ${theme.palette.divider}`,
                                            boxShadow: '0 4px 14px rgba(0,0,0,0.08)',
                                        }}
                                    />
                                    <Legend
                                        verticalAlign="bottom"
                                        height={36}
                                        formatter={(value) => value.replace(/_/g, ' ')}
                                    />
                                </PieChart>
                            </ResponsiveContainer>
                        )}
                    </Grid>

                    {/* Totals + Export */}
                    <Grid item xs={12} md={7} sx={{ p: { xs: 2, sm: 3 } }}>
                        <Typography variant="h6" fontWeight={700} mb={2}>
                            {t('dashboard.totals')}
                        </Typography>

                        <Grid container spacing={1.5}>
                            {Object.entries(summaryTotals).map(([key, value]) => (
                                <Grid item xs={6} sm={4} key={key}>
                                    <Box
                                        sx={{
                                            p: 1.75,
                                            borderRadius: 2.5,
                                            bgcolor: theme.palette.mode === 'dark' ? 'action.hover' : '#f8fafc',
                                            border: `1px solid ${theme.palette.divider}`,
                                            height: '100%',
                                        }}
                                    >
                                        <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'capitalize', fontWeight: 600 }}>
                                            {key.replace(/_/g, ' ')}
                                        </Typography>
                                        <Typography variant="subtitle1" fontWeight={800} mt={0.25}>
                                            {value}
                                        </Typography>
                                    </Box>
                                </Grid>
                            ))}
                        </Grid>

                        <Divider sx={{ my: 2.5 }} />

                        <Stack direction="row" spacing={1.5} flexWrap="wrap" useFlexGap>
                            <Tooltip title={`Export ${domainConfig.label} as CSV`}>
                                <span>
                                    <Button
                                        size="small"
                                        variant="outlined"
                                        startIcon={<CsvIcon />}
                                        onClick={() => handleExport('csv')}
                                        disabled={!!exportFmt}
                                        sx={{ borderRadius: 2 }}
                                    >
                                        {t('dashboard.exportCsv')}
                                    </Button>
                                </span>
                            </Tooltip>
                            <Tooltip title={`Export ${domainConfig.label} as Excel`}>
                                <span>
                                    <Button
                                        size="small"
                                        variant="outlined"
                                        startIcon={<ExcelIcon />}
                                        onClick={() => handleExport('xlsx')}
                                        disabled={!!exportFmt}
                                        sx={{ borderRadius: 2 }}
                                    >
                                        {t('dashboard.exportExcel')}
                                    </Button>
                                </span>
                            </Tooltip>
                        </Stack>
                    </Grid>
                </Grid>
            </Paper>
        </Box>
    );
};

export default Dashboard;