import React, { useState, useEffect, useCallback } from 'react';
import {
    Box, Paper, Typography, Button, Grid, Card, CardContent, TextField, MenuItem,
    Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination,
    Chip, CircularProgress, Tooltip, Stack, useTheme,
} from '@mui/material';
import { Refresh as RefreshIcon, Description as CsvIcon, TableChart as ExcelIcon } from '@mui/icons-material';
import {
    PieChart, Pie, Cell, Tooltip as ChartTooltip, Legend, ResponsiveContainer,
    BarChart, Bar, XAxis, YAxis, CartesianGrid,
} from 'recharts';
import { usePermissions } from 'hooks/usePermissions';
import { useFinanceSubscriptionManagement } from 'hooks/useFinanceSubscription';
import { useLanguage } from 'context/LanguageContext';
import { tFin } from './financelang';
import { showSnackbar } from 'utils/snackbar';
import appConfig from '../../config';

const colors = appConfig.app.colors;
const STATUS_COLORS = {
    pending: '#f59e0b',
    active: '#10b981',
    expired: '#ef4444',
    cancelled: '#6b7280',
};

const FinanceSubscriptions = () => {
    const theme = useTheme();
    const { can } = usePermissions();
    const canView = can('finance.view');

    const { language } = useLanguage();
    const t = (key, replacements) => tFin(language, key, replacements);

    const {
        summary, trends, table,
        loadingSummary, loadingTrends, loadingTable,
        getSummary, getTrends, getTable, exportFinanceReport,
    } = useFinanceSubscriptionManagement();

    const [range, setRange] = useState('year');
    const [granularity, setGranularity] = useState('');
    const [status, setStatus] = useState('all');
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [exportFmt, setExportFmt] = useState(null);
    const [dailyHistogramData, setDailyHistogramData] = useState([]);
    const [loadingDailyHistogram, setLoadingDailyHistogram] = useState(false);

    const baseParams = useCallback(() => {
        const p = { range, status };
        if (granularity) p.granularity = granularity;
        if (range === 'custom') { p.date_from = dateFrom; p.date_to = dateTo; }
        return p;
    }, [range, granularity, status, dateFrom, dateTo]);

    const getDateRangeForHistogram = useCallback(() => {
        const now = new Date();
        const eastAfricaTime = new Date(now.toLocaleString('en-US', { timeZone: 'Africa/Nairobi' }));
        let startDate, endDate;

        if (range === 'week' || range === 'this_week') {
            const day = eastAfricaTime.getDay();
            const diff = eastAfricaTime.getDate() - day + (day === 0 ? -6 : 1);
            startDate = new Date(eastAfricaTime);
            startDate.setDate(diff);
            startDate.setHours(0, 0, 0, 0);
            endDate = new Date(startDate);
            endDate.setDate(startDate.getDate() + 6);
            endDate.setHours(23, 59, 59, 999);
        } else if (range === 'month' || range === 'this_month') {
            startDate = new Date(eastAfricaTime.getFullYear(), eastAfricaTime.getMonth(), 1);
            startDate.setHours(0, 0, 0, 0);
            endDate = new Date(eastAfricaTime.getFullYear(), eastAfricaTime.getMonth() + 1, 0);
            endDate.setHours(23, 59, 59, 999);
        } else if (range === 'custom') {
            if (dateFrom && dateTo) {
                startDate = new Date(dateFrom);
                startDate.setHours(0, 0, 0, 0);
                endDate = new Date(dateTo);
                endDate.setHours(23, 59, 59, 999);
            } else {
                const day = eastAfricaTime.getDay();
                const diff = eastAfricaTime.getDate() - day + (day === 0 ? -6 : 1);
                startDate = new Date(eastAfricaTime);
                startDate.setDate(diff);
                startDate.setHours(0, 0, 0, 0);
                endDate = new Date(startDate);
                endDate.setDate(startDate.getDate() + 6);
                endDate.setHours(23, 59, 59, 999);
            }
        } else {
            const day = eastAfricaTime.getDay();
            const diff = eastAfricaTime.getDate() - day + (day === 0 ? -6 : 1);
            startDate = new Date(eastAfricaTime);
            startDate.setDate(diff);
            startDate.setHours(0, 0, 0, 0);
            endDate = new Date(startDate);
            endDate.setDate(startDate.getDate() + 6);
            endDate.setHours(23, 59, 59, 999);
        }
        return { startDate, endDate };
    }, [range, dateFrom, dateTo]);

    const fetchDailyHistogram = useCallback(async () => {
        setLoadingDailyHistogram(true);
        try {
            const { startDate, endDate } = getDateRangeForHistogram();
            const now = new Date();
            const eastAfricaNow = new Date(now.toLocaleString('en-US', { timeZone: 'Africa/Nairobi' }));

            const dates = [];
            let currentDate = new Date(startDate);
            while (currentDate <= endDate) {
                const dateStr = currentDate.toISOString().split('T')[0];
                dates.push({
                    date: dateStr,
                    displayDate: currentDate.toLocaleDateString('en-US', {
                        weekday: 'short', month: 'short', day: 'numeric', timeZone: 'Africa/Nairobi',
                    }),
                    count: 0,
                    revenue: 0,
                    dayName: currentDate.toLocaleDateString('en-US', { weekday: 'short', timeZone: 'Africa/Nairobi' }),
                    isToday: currentDate.toDateString() === eastAfricaNow.toDateString(),
                });
                currentDate.setDate(currentDate.getDate() + 1);
            }

            if (table.data && table.data.length > 0) {
                const dateMap = {};
                table.data.forEach(item => {
                    if (item.created_at) {
                        const itemDate = new Date(item.created_at);
                        const eastAfricaItemDate = new Date(itemDate.toLocaleString('en-US', { timeZone: 'Africa/Nairobi' }));
                        const dateKey = eastAfricaItemDate.toISOString().split('T')[0];
                        if (dateMap[dateKey]) {
                            dateMap[dateKey].count += 1;
                            dateMap[dateKey].revenue += parseFloat(item.amount_paid || 0);
                        } else {
                            dateMap[dateKey] = { count: 1, revenue: parseFloat(item.amount_paid || 0) };
                        }
                    }
                });
                dates.forEach(d => {
                    if (dateMap[d.date]) {
                        d.count = dateMap[d.date].count;
                        d.revenue = dateMap[d.date].revenue;
                    }
                });
            }
            setDailyHistogramData(dates);
        } catch (error) {
            console.error('Error fetching daily histogram:', error);
            showSnackbar({ type: 'error', message: t('fin.toast.histogramFailed') });
        } finally {
            setLoadingDailyHistogram(false);
        }
    }, [getDateRangeForHistogram, table.data, language]);

    useEffect(() => { getSummary(baseParams()); }, [baseParams, getSummary]);
    useEffect(() => { getTrends(baseParams()); }, [baseParams, getTrends]);
    useEffect(() => {
        getTable({ ...baseParams(), search: search || undefined, page: page + 1, per_page: rowsPerPage });
    }, [baseParams, search, page, rowsPerPage, getTable]);

    useEffect(() => { fetchDailyHistogram(); }, [fetchDailyHistogram, range, dateFrom, dateTo]);

    const refreshAll = () => {
        getSummary(baseParams());
        getTrends(baseParams());
        getTable({ ...baseParams(), search: search || undefined, page: page + 1, per_page: rowsPerPage });
        fetchDailyHistogram();
    };

    const handleExport = async (format) => {
        setExportFmt(format);
        try {
            const response = await exportFinanceReport({ ...baseParams(), format });
            const blob = new Blob([response.data], { type: format === 'xlsx' ? 'application/vnd.ms-excel' : 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = `finance_subscriptions_${new Date().toISOString().slice(0, 10)}.${format === 'xlsx' ? 'xls' : 'csv'}`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            window.URL.revokeObjectURL(url);
            showSnackbar({ type: 'success', message: t('fin.toast.exportSuccess') });
        } catch {
            showSnackbar({ type: 'error', message: t('fin.toast.exportFailed') });
        } finally {
            setExportFmt(null);
        }
    };

    const formatDate = (d) => { if (!d) return '-'; try { return new Date(d).toLocaleDateString(); } catch { return '-'; } };

    const getStatusChip = (s) => {
        const map = {
            pending: { color: '#f59e0b', bg: '#fef3c7' },
            active: { color: '#10b981', bg: '#d1fae5' },
            expired: { color: '#ef4444', bg: '#fee2e2' },
            cancelled: { color: '#6b7280', bg: '#f3f4f6' },
        };
        const st = map[s] || { color: '#6b7280', bg: '#f3f4f6' };
        const label = t(`fin.status.${s}`) || s;
        return <Chip label={label} size="small" sx={{ backgroundColor: st.bg, color: st.color, fontWeight: 600 }} />;
    };

    if (!canView) {
        return <Paper sx={{ p: 3, textAlign: 'center' }}><Typography color="error">{t('fin.common.accessDenied')}</Typography></Paper>;
    }

    const totals = summary.totals || {};

    return (
        <Box sx={{ width: '100%', maxWidth: '100%' }}>
            {/* ===================== FILTER BAR ===================== */}
            <Paper
                elevation={0}
                sx={{
                    p: 2,
                    mb: 3,
                    borderRadius: 3,
                    border: `1px solid ${theme.palette.divider}`,
                    backgroundColor: 'background.paper' // Theme aware
                }}
            >
                <Stack direction="row" spacing={2} flexWrap="wrap" useFlexGap alignItems="center">
                    <TextField select label={t('fin.filter.range')} size="small" value={range} onChange={(e) => setRange(e.target.value)} sx={{ minWidth: 140 }}>
                        <MenuItem value="week">{t('fin.filter.thisWeek')}</MenuItem>
                        <MenuItem value="month">{t('fin.filter.thisMonth')}</MenuItem>
                        <MenuItem value="year">{t('fin.filter.thisYear')}</MenuItem>
                        <MenuItem value="custom">{t('fin.filter.custom')}</MenuItem>
                    </TextField>

                    {range === 'custom' && (
                        <>
                            <TextField label={t('fin.filter.from')} type="date" size="small" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} InputLabelProps={{ shrink: true }} />
                            <TextField label={t('fin.filter.to')} type="date" size="small" value={dateTo} onChange={(e) => setDateTo(e.target.value)} InputLabelProps={{ shrink: true }} />
                        </>
                    )}

                    <TextField select label={t('fin.filter.granularity')} size="small" value={granularity} onChange={(e) => setGranularity(e.target.value)} sx={{ minWidth: 140 }}>
                        <MenuItem value="">{t('fin.filter.auto')}</MenuItem>
                        <MenuItem value="daily">{t('fin.filter.daily')}</MenuItem>
                        <MenuItem value="weekly">{t('fin.filter.weekly')}</MenuItem>
                        <MenuItem value="monthly">{t('fin.filter.monthly')}</MenuItem>
                    </TextField>

                    <TextField select label={t('fin.filter.status')} size="small" value={status} onChange={(e) => { setStatus(e.target.value); setPage(0); }} sx={{ minWidth: 140 }}>
                        <MenuItem value="all">{t('fin.filter.all')}</MenuItem>
                        <MenuItem value="pending">{t('fin.status.pending')}</MenuItem>
                        <MenuItem value="active">{t('fin.status.active')}</MenuItem>
                        <MenuItem value="expired">{t('fin.status.expired')}</MenuItem>
                        <MenuItem value="cancelled">{t('fin.status.cancelled')}</MenuItem>
                    </TextField>

                    <Box flexGrow={1} />

                    <Tooltip title={t('fin.common.exportCsv')}>
                        <span><Button size="small" variant="outlined" startIcon={<CsvIcon />} onClick={() => handleExport('csv')} disabled={!!exportFmt}>CSV</Button></span>
                    </Tooltip>
                    <Tooltip title={t('fin.common.exportExcel')}>
                        <span><Button size="small" variant="outlined" startIcon={<ExcelIcon />} onClick={() => handleExport('xlsx')} disabled={!!exportFmt}>Excel</Button></span>
                    </Tooltip>
                    <Button variant="contained" startIcon={<RefreshIcon />} onClick={refreshAll}>{t('fin.common.refresh')}</Button>
                </Stack>
            </Paper>

            {/* ===================== KPI CARDS ===================== */}
            <Grid container spacing={2} sx={{ mb: 3 }}>
                {[
                    { label: t('fin.sub.stat.total'), value: totals.count || 0, color: '#3b82f6' },
                    { label: t('fin.sub.stat.active'), value: totals.active || 0, color: '#10b981' },
                    { label: t('fin.sub.stat.revenue'), value: `TZS ${Number(totals.revenue || 0).toLocaleString()}`, color: '#f59e0b' },
                    { label: t('fin.sub.stat.expired'), value: totals.expired || 0, color: '#ef4444' },
                ].map((item, idx) => (
                    <Grid item xs={12} sm={6} md={3} key={idx}>
                        <Card
                            elevation={0}
                            sx={{
                                borderRadius: 3,
                                border: `1px solid ${theme.palette.divider}`,
                                backgroundColor: 'background.paper', // Theme aware
                                height: '100%'
                            }}
                        >
                            <CardContent>
                                <Typography variant="body2" sx={{ color: item.color, fontWeight: 600, mb: 0.5 }}>{item.label}</Typography>
                                <Typography variant="h4" sx={{ color: item.color, fontWeight: 700 }}>{item.value}</Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                ))}
            </Grid>

            {/* ===================== DAILY HISTOGRAM ===================== */}
            <Paper
                elevation={0}
                sx={{
                    p: 3,
                    mb: 3,
                    borderRadius: 3,
                    border: `1px solid ${theme.palette.divider}`,
                    bgcolor: 'background.paper',
                    height: 420
                }}
            >
                <Typography variant="h6" fontWeight={600} mb={2}>
                    {range === 'week' || range === 'this_week' ? t('fin.sub.chart.dailyWeek') :
                        range === 'month' || range === 'this_month' ? t('fin.sub.chart.dailyMonth') :
                            t('fin.sub.chart.dailyRange')}
                </Typography>
                {loadingDailyHistogram ? (
                    <Box sx={{ height: '85%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><CircularProgress /></Box>
                ) : dailyHistogramData.length === 0 ? (
                    <Box sx={{ height: '85%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Typography color="text.secondary">{t('fin.common.noData')}</Typography>
                    </Box>
                ) : (
                    <ResponsiveContainer width="100%" height="90%">
                        <BarChart data={dailyHistogramData} margin={{ top: 10, right: 30, left: 0, bottom: 20 }}>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={theme.palette.divider} />
                            <XAxis
                                dataKey={range === 'week' || range === 'this_week' ? 'dayName' : 'displayDate'}
                                tick={{ fontSize: 12 }}
                                interval={0}
                                angle={range === 'month' || range === 'this_month' ? -45 : 0}
                                textAnchor={range === 'month' || range === 'this_month' ? 'end' : 'middle'}
                                height={range === 'month' || range === 'this_month' ? 60 : 30}
                            />
                            <YAxis yAxisId="left" tick={{ fontSize: 12 }} />
                            <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 12 }} />
                            <ChartTooltip
                                formatter={(value, name) => {
                                    if (name === t('fin.sub.legend.revenue')) return `TZS ${Number(value || 0).toLocaleString()}`;
                                    return value;
                                }}
                            />
                            <Legend />
                            <Bar yAxisId="left" dataKey="count" name={t('fin.sub.legend.subscriptions')} fill="#3b82f6" radius={[6, 6, 0, 0]}>
                                {dailyHistogramData.map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill={entry.isToday ? '#10b981' : '#3b82f6'} fillOpacity={entry.isToday ? 1 : 0.7} />
                                ))}
                            </Bar>
                            <Bar yAxisId="right" dataKey="revenue" name={t('fin.sub.legend.revenue')} fill="#10b981" radius={[6, 6, 0, 0]} fillOpacity={0.6} />
                        </BarChart>
                    </ResponsiveContainer>
                )}
            </Paper>

            {/* ===================== PIE CHART ===================== */}
            <Paper
                elevation={0}
                sx={{
                    p: 3,
                    mb: 3,
                    borderRadius: 3,
                    border: `1px solid ${theme.palette.divider}`,
                    bgcolor: 'background.paper',
                    height: 420
                }}
            >
                <Typography variant="h6" fontWeight={600} mb={2}>{t('fin.sub.chart.byStatus')}</Typography>
                {loadingSummary ? (
                    <Box sx={{ height: '85%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><CircularProgress /></Box>
                ) : (
                    <ResponsiveContainer width="100%" height="90%">
                        <PieChart>
                            <Pie data={summary.status_breakdown || []} dataKey="total" nameKey="status" cx="50%" cy="50%" outerRadius={140} label={({ status, total }) => `${status}: ${total}`}>
                                {(summary.status_breakdown || []).map((entry, idx) => (
                                    <Cell key={idx} fill={STATUS_COLORS[entry.status] || '#94a3b8'} />
                                ))}
                            </Pie>
                            <ChartTooltip />
                            <Legend verticalAlign="bottom" height={36} />
                        </PieChart>
                    </ResponsiveContainer>
                )}
            </Paper>

            {/* ===================== TREND CHART ===================== */}
            <Paper
                elevation={0}
                sx={{
                    p: 3,
                    mb: 3,
                    borderRadius: 3,
                    border: `1px solid ${theme.palette.divider}`,
                    bgcolor: 'background.paper',
                    height: 400
                }}
            >
                <Typography variant="h6" fontWeight={600} mb={2}>
                    {t('fin.sub.chart.trend', { granularity: trends.granularity || 'monthly' })}
                </Typography>
                {loadingTrends ? (
                    <Box sx={{ height: '85%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><CircularProgress /></Box>
                ) : (
                    <ResponsiveContainer width="100%" height="90%">
                        <BarChart data={trends.buckets || []} margin={{ top: 10, right: 30, left: 0, bottom: 5 }}>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={theme.palette.divider} />
                            <XAxis dataKey="label" tick={{ fontSize: 13 }} />
                            <YAxis yAxisId="left" tick={{ fontSize: 13 }} />
                            <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 13 }} />
                            <ChartTooltip />
                            <Legend />
                            <Bar yAxisId="left" dataKey="count" name={t('fin.sub.legend.count')} fill="#3b82f6" radius={[6, 6, 0, 0]} />
                            <Bar yAxisId="right" dataKey="revenue" name={t('fin.sub.legend.revenue')} fill="#10b981" radius={[6, 6, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                )}
            </Paper>

            {/* ===================== TABLE ===================== */}
            <Paper
                elevation={0}
                sx={{
                    borderRadius: 3,
                    border: `1px solid ${theme.palette.divider}`,
                    bgcolor: 'background.paper',
                    overflow: 'hidden'
                }}
            >
                <Box sx={{ p: 2.5, borderBottom: `1px solid ${theme.palette.divider}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 2 }}>
                    <Typography variant="h6" fontWeight={600}>{t('fin.sub.table.title')}</Typography>
                    <TextField size="small" placeholder={t('fin.sub.table.searchPlaceholder')} value={search} onChange={(e) => { setSearch(e.target.value); setPage(0); }} sx={{ minWidth: 240 }} />
                </Box>

                {loadingTable ? (
                    <Box sx={{ py: 6, textAlign: 'center' }}><CircularProgress /></Box>
                ) : (
                    <TableContainer>
                        <Table>
                            <TableHead sx={{ backgroundColor: 'action.hover' }}>
                                <TableRow>
                                    <TableCell sx={{ fontWeight: 700 }}>{t('fin.sub.table.col.user')}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>{t('fin.sub.table.col.plan')}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>{t('fin.sub.table.col.amount')}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>{t('fin.sub.table.col.status')}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>{t('fin.sub.table.col.paymentMethod')}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>{t('fin.sub.table.col.created')}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>{t('fin.sub.table.col.expiry')}</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {table.data.length === 0 ? (
                                    <TableRow><TableCell colSpan={7} align="center" sx={{ py: 5 }}><Typography color="text.secondary">{t('fin.common.noRecords')}</Typography></TableCell></TableRow>
                                ) : (
                                    table.data.map((row) => (
                                        <TableRow key={row.id} hover>
                                            <TableCell>
                                                <Typography variant="body2" fontWeight={500}>{row.user?.name || '-'}</Typography>
                                                <Typography variant="caption" color="text.secondary">{row.user?.email || ''}</Typography>
                                            </TableCell>
                                            <TableCell>{row.rate_card?.name || '-'}</TableCell>
                                            <TableCell>{row.amount_paid || '-'}</TableCell>
                                            <TableCell>{getStatusChip(row.status)}</TableCell>
                                            <TableCell>{row.payment_method || '-'}</TableCell>
                                            <TableCell>{formatDate(row.created_at)}</TableCell>
                                            <TableCell>{formatDate(row.expiry_date)}</TableCell>
                                        </TableRow>
                                    ))
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                )}

                <TablePagination
                    component="div"
                    count={table.pagination.total || 0}
                    rowsPerPage={rowsPerPage}
                    page={page}
                    onPageChange={(e, p) => setPage(p)}
                    onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
                    rowsPerPageOptions={[5, 10, 25, 50]}
                    sx={{ borderTop: `1px solid ${theme.palette.divider}` }}
                />
            </Paper>
        </Box>
    );
};

export default FinanceSubscriptions;