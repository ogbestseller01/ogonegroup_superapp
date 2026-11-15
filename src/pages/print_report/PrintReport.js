// src/pages/print_report/PrintReport.jsx
import React, { useEffect, useState, useMemo } from 'react';
import {
    Box, Paper, Typography, Button, Grid, TextField, MenuItem,
    Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
    CircularProgress, Stack, Divider, InputAdornment, IconButton
} from '@mui/material';
import {
    Print as PrintIcon,
    Description as CsvIcon,
    TableChart as ExcelIcon,
    Refresh as RefreshIcon,
    Search as SearchIcon,
    Clear as ClearIcon,
} from '@mui/icons-material';
import { usePrintReportManagement } from 'hooks/usePrintReport';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import { format } from 'date-fns';
import { tReport } from './printreportslang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

export default function PrintReport() {
    const { language } = useLanguage();
    const t = (key) => tReport(language, key);

    const { loading, getReportData, exportReport, clearError } = usePrintReportManagement();

    const DOMAINS = useMemo(() => [
        { value: 'users', label: t('report.domain.users') },
        { value: 'technicians', label: t('report.domain.technicians') },
        { value: 'requests', label: t('report.domain.requests') },
        { value: 'jobs', label: t('report.domain.jobs') },
        { value: 'reviews', label: t('report.domain.reviews') },
        { value: 'posts', label: t('report.domain.posts') },
    ], [language]);

    const ROLES = [
        { value: 'ADMINISTRATOR', label: 'Administrator' },
        { value: 'MANAGER', label: 'Manager' },
        { value: 'FUNDI', label: 'Fundi' },
        { value: 'CUSTOMER', label: 'Customer' },
        { value: 'MONITORING_OFFICER', label: 'Monitoring Officer' },
        { value: 'FINANCE', label: 'Finance' },
    ];

    const JOB_STATUSES = [
        { value: 'pending', label: 'Pending' },
        { value: 'on-progress', label: 'On Progress' },
        { value: 'completed', label: 'Completed' },
    ];

    const REQUEST_STATUSES = [
        { value: 'pending', label: 'Pending' },
        { value: 'accepted', label: 'Accepted' },
        { value: 'rejected', label: 'Rejected' },
        { value: 'cancelled', label: 'Cancelled' },
    ];

    const [domain, setDomain] = useState('users');
    const [dateFrom, setDateFrom] = useState(format(new Date(), 'yyyy-MM-01'));
    const [dateTo, setDateTo] = useState(format(new Date(), 'yyyy-MM-dd'));
    const [search, setSearch] = useState('');
    const [role, setRole] = useState('');
    const [status, setStatus] = useState('');
    const [exporting, setExporting] = useState(null);
    const [data, setData] = useState(null);

    const reportTitle = useMemo(() => {
        const domainName = DOMAINS.find(d => d.value === domain)?.label || 'Report';
        const roleName = domain === 'users' && role ? ` - ${ROLES.find(r => r.value === role)?.label}` : '';
        const statusName = status ? ` - ${status.toUpperCase()}` : '';
        const dateRange = `(${dateFrom} to ${dateTo})`;
        return `NearbyFundi - ${domainName}${roleName}${statusName} ${dateRange}`;
    }, [domain, role, status, dateFrom, dateTo, DOMAINS]);

    useEffect(() => {
        document.title = reportTitle;
        return () => { document.title = 'Nearby Fundi'; };
    }, [reportTitle]);

    const fetchReport = async () => {
        clearError?.();
        const params = { domain, from: dateFrom, to: dateTo, search: search || undefined };
        if (domain === 'users' && role) params.role = role;
        if (status) params.status = status;
        const result = await getReportData(params);
        setData(result || { columns: [], rows: [] });
    };

    useEffect(() => {
        fetchReport();
    }, [domain, dateFrom, dateTo, role, status]);

    const handleExport = async (fmt) => {
        setExporting(fmt);
        try {
            const params = { domain, from: dateFrom, to: dateTo, search: search || undefined, format: fmt };
            if (domain === 'users' && role) params.role = role;
            if (status) params.status = status;
            const res = await exportReport(params);
            const url = window.URL.createObjectURL(new Blob([res.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `report_${domain}_${format(new Date(), 'yyyyMMdd')}.${fmt}`);
            document.body.appendChild(link);
            link.click();
            link.remove();
            window.URL.revokeObjectURL(url);
            showSnackbar({ type: 'success', message: 'Report downloaded successfully.' });
        } catch (err) {
            showSnackbar({ type: 'error', message: 'Export failed. Please try again.' });
        } finally {
            setExporting(null);
        }
    };

    const handlePrint = () => window.print();

    const columns = data?.columns || [];
    const rows = data?.rows || [];
    const showJobStatus = domain === 'jobs';
    const showRequestStatus = domain === 'requests';

    return (
        <Box sx={{ width: '100%', p: { xs: 1.5, sm: 2.5 }, m: 0, bgcolor: 'background.default' }}>

            {/* Filter Bar */}
            <Paper
                elevation={0} className="no-print"
                sx={{ width: '100%', borderRadius: 3, overflow: 'hidden', border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', mb: 3, p: { xs: 2, sm: 3 } }}
            >
                <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} mb={2.5}>
                    <Box>
                        <Typography variant="h5" fontWeight={800} color="text.primary">{t('report.title')}</Typography>
                        <Typography variant="body2" color="text.secondary" fontWeight={500}>{t('report.subtitle')}</Typography>
                    </Box>
                    <Stack direction="row" spacing={1} flexWrap="wrap">
                        <Button variant="outlined" size="small" startIcon={<PrintIcon />} onClick={handlePrint} sx={{ borderRadius: 2, fontWeight: 600 }}>
                            {t('report.print')}
                        </Button>
                        <Button variant="outlined" size="small" startIcon={<CsvIcon />} onClick={() => handleExport('csv')} disabled={exporting === 'csv'} sx={{ borderRadius: 2, fontWeight: 600 }}>
                            {exporting === 'csv' ? t('report.exporting') : t('report.exportCsv')}
                        </Button>
                        <Button variant="outlined" size="small" startIcon={<ExcelIcon />} onClick={() => handleExport('xlsx')} disabled={exporting === 'xlsx'} sx={{ borderRadius: 2, fontWeight: 600 }}>
                            {exporting === 'xlsx' ? t('report.exporting') : t('report.exportExcel')}
                        </Button>
                    </Stack>
                </Stack>

                <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.5} alignItems={{ xs: 'stretch', md: 'center' }} flexWrap="wrap" useFlexGap>
                    <TextField
                        select size="small" value={domain} onChange={(e) => { setDomain(e.target.value); setRole(''); setStatus(''); }}
                        sx={{ minWidth: { xs: '100%', sm: 200 }, '& .MuiOutlinedInput-root': { borderRadius: 2, bgcolor: 'action.hover', '& fieldset': { borderColor: 'transparent' }, '&:hover fieldset': { borderColor: 'divider' } } }}
                    >
                        {DOMAINS.map(d => <MenuItem key={d.value} value={d.value}>{d.label}</MenuItem>)}
                    </TextField>

                    {domain === 'users' && (
                        <TextField
                            select size="small" value={role} onChange={(e) => setRole(e.target.value)}
                            sx={{ minWidth: { xs: '100%', sm: 180 }, '& .MuiOutlinedInput-root': { borderRadius: 2, bgcolor: 'action.hover', '& fieldset': { borderColor: 'transparent' }, '&:hover fieldset': { borderColor: 'divider' } } }}
                            label="Role" InputLabelProps={{ shrink: true }}
                        >
                            <MenuItem value="">All Roles</MenuItem>
                            {ROLES.map(r => <MenuItem key={r.value} value={r.value}>{r.label}</MenuItem>)}
                        </TextField>
                    )}

                    {(showJobStatus || showRequestStatus) && (
                        <TextField
                            select size="small" value={status} onChange={(e) => setStatus(e.target.value)}
                            sx={{ minWidth: { xs: '100%', sm: 180 }, '& .MuiOutlinedInput-root': { borderRadius: 2, bgcolor: 'action.hover', '& fieldset': { borderColor: 'transparent' }, '&:hover fieldset': { borderColor: 'divider' } } }}
                            label="Status" InputLabelProps={{ shrink: true }}
                        >
                            <MenuItem value="">All Statuses</MenuItem>
                            {(showJobStatus ? JOB_STATUSES : REQUEST_STATUSES).map(s => (
                                <MenuItem key={s.value} value={s.value}>{s.label}</MenuItem>
                            ))}
                        </TextField>
                    )}

                    <TextField type="date" size="small" label={t('report.dateFrom')} InputLabelProps={{ shrink: true }} value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} sx={{ minWidth: { xs: '100%', sm: 160 } }} />
                    <TextField type="date" size="small" label={t('report.dateTo')} InputLabelProps={{ shrink: true }} value={dateTo} onChange={(e) => setDateTo(e.target.value)} sx={{ minWidth: { xs: '100%', sm: 160 } }} />

                    <TextField
                        size="small" placeholder={t('report.searchPlaceholder')} value={search} onChange={(e) => setSearch(e.target.value)}
                        InputProps={{
                            startAdornment: (<InputAdornment position="start"><SearchIcon fontSize="small" color="action" /></InputAdornment>),
                            endAdornment: search ? (<InputAdornment position="end"><IconButton size="small" onClick={() => setSearch('')}><ClearIcon fontSize="small" /></IconButton></InputAdornment>) : null,
                        }}
                        sx={{ minWidth: { xs: '100%', sm: 200 }, '& .MuiOutlinedInput-root': { borderRadius: 2, bgcolor: 'action.hover', '& fieldset': { borderColor: 'transparent' }, '&:hover fieldset': { borderColor: 'divider' } } }}
                    />

                    <Box flexGrow={1} />
                    <Button
                        variant="contained" startIcon={<RefreshIcon />} onClick={fetchReport}
                        sx={{ borderRadius: 2, fontWeight: 700, textTransform: 'none', px: 3, boxShadow: 'none', bgcolor: colors.sea || '#0f766e', '&:hover': { bgcolor: colors.dark || '#0d5c56' } }}
                    >
                        {t('report.apply')}
                    </Button>
                </Stack>
            </Paper>

            {/* The Report Document */}
            <Paper
                elevation={0} className="print-container"
                sx={{
                    p: { xs: 4, sm: 6 }, borderRadius: 2, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper', color: 'text.primary',
                    '@media print': { bgcolor: 'white !important', color: 'black !important', border: 'none !important', boxShadow: 'none !important', p: '0 !important', m: '0 !important' }
                }}
            >
                {/* HEADER */}
                <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={4} pb={3} borderBottom="2px solid" borderColor="divider">
                    <Stack direction="row" spacing={2.5} alignItems="center">
                        <img src="/logo.png" alt="OG ONE GROUP" style={{ height: 65, objectFit: 'contain' }} />
                        <Box>
                            <Typography variant="h5" fontWeight={900} color="text.primary" sx={{ '@media print': { color: 'black !important' }, letterSpacing: 0.5 }}>
                                OG ONE GROUP
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ '@media print': { color: '#555 !important' } }}>
                                Nearby Fundi Management System
                            </Typography>
                        </Box>
                    </Stack>
                    <Box textAlign="right">
                        <Typography variant="caption" color="text.secondary" fontWeight={600} sx={{ '@media print': { color: '#666 !important' }, textTransform: 'uppercase' }}>
                            Generated On
                        </Typography>
                        <Typography variant="body2" fontWeight={600} sx={{ '@media print': { color: 'black !important' } }}>
                            {format(new Date(), 'MMMM dd, yyyy — HH:mm')}
                        </Typography>
                    </Box>
                </Box>

                {/* TITLE BLOCK */}
                <Box mb={4} display="flex" justifyContent="space-between" alignItems="flex-end">
                    <Box>
                        <Typography variant="h5" fontWeight={800} color={colors.sea || 'primary.main'} sx={{ '@media print': { color: 'black !important' }, mb: 0.5 }}>
                            {DOMAINS.find(d => d.value === domain)?.label}
                            {domain === 'users' && role && ` — ${ROLES.find(r => r.value === role)?.label}`}
                            {status && ` — ${status.toUpperCase()}`}
                        </Typography>
                        <Typography variant="body1" color="text.secondary" sx={{ '@media print': { color: '#555 !important' } }}>
                            Report Period: <strong>{dateFrom}</strong> to <strong>{dateTo}</strong>
                        </Typography>
                    </Box>
                </Box>

                {/* DATA TABLE (FIXED LAYOUT & OVERFLOW) */}
                {loading ? (
                    <Box display="flex" justifyContent="center" py={8}><CircularProgress /></Box>
                ) : rows.length === 0 ? (
                    <Box textAlign="center" py={8} border="1px dashed" borderColor="divider" borderRadius={2}>
                        <Typography color="text.secondary">{t('report.noRecords')}</Typography>
                    </Box>
                ) : (
                    <TableContainer
                        sx={{
                            border: '1px solid', borderColor: 'divider', borderRadius: 1,
                            '@media print': { width: '100% !important', border: '1px solid #ddd !important', overflow: 'visible !important' }
                        }}
                    >
                        {/* ✅ tableLayout="fixed" prevents columns from pushing each other off the page */}
                        <Table size="small" sx={{ width: '100%', tableLayout: 'fixed' }}>
                            <TableHead>
                                <TableRow>
                                    {columns.map((col) => (
                                        <TableCell
                                            key={col.key}
                                            sx={{
                                                fontWeight: 700, bgcolor: 'action.hover', py: 1.5, borderBottom: '2px solid', borderColor: 'divider',
                                                wordBreak: 'break-word', // ✅ Allows long headers to wrap
                                                '@media print': { bgcolor: '#f5f5f5 !important', color: 'black !important', borderBottom: '2px solid #bbb !important', whiteSpace: 'normal' }
                                            }}
                                        >
                                            {col.label}
                                        </TableCell>
                                    ))}
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {rows.map((row, idx) => (
                                    <TableRow key={idx} sx={{ '&:nth-of-type(even)': { bgcolor: 'action.hover' }, '@media print': { pageBreakInside: 'avoid', '&:nth-of-type(even)': { bgcolor: '#fafafa !important' } } }}>
                                        {columns.map((col) => (
                                            <TableCell
                                                key={col.key}
                                                sx={{
                                                    py: 1.5, borderBottom: '1px solid', borderColor: 'divider',
                                                    wordBreak: 'break-word', // ✅ Allows dates like '2026-11-14' to wrap if needed
                                                    fontSize: '0.85rem', // ✅ Slightly smaller text to fit more
                                                    '@media print': { color: 'black !important', borderBottom: '1px solid #eee !important', whiteSpace: 'normal', fontSize: '0.8rem' }
                                                }}
                                            >
                                                {String(row[col.key] ?? '—')}
                                            </TableCell>
                                        ))}
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </TableContainer>
                )}

                {/* FOOTER */}
                <Box mt={5} pt={3} borderTop="1px solid" borderColor="divider" display="flex" justifyContent="space-between" alignItems="center" sx={{ '@media print': { borderTop: '1px solid #ccc !important' } }}>
                    <Box>
                        <Typography variant="caption" color="text.secondary" sx={{ '@media print': { color: '#888 !important' } }}>
                            Confidential — For Management Use Only
                        </Typography>
                    </Box>
                    <Box>
                        <Typography variant="caption" color="text.secondary" fontWeight={600} sx={{ '@media print': { color: '#888 !important' } }}>
                            {t('report.totalRecords')}: <span style={{ color: 'black' }}>{rows.length}</span>
                        </Typography>
                    </Box>
                </Box>
            </Paper>

            {/* Print CSS */}
            <style>{`
                @media print {
                    .no-print, .MuiDrawer-root, header, aside, nav { display: none !important; }
                    body, html { background: white !important; margin: 0 !important; padding: 0 !important; -webkit-print-color-adjust: exact; }
                    @page { size: A4 landscape; margin: 0; }
                    .print-container { padding: 15mm !important; margin: 0 !important; width: 100% !important; max-width: 100% !important; }
                }
            `}</style>
        </Box>
    );
}