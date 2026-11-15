// src/pages/faqs/FaqList.js
import React, { useState, useEffect } from 'react';
import {
    Box, Paper, Typography, Button, Table, TableBody, TableCell, TableContainer,
    TableHead, TableRow, TablePagination, TableSortLabel, IconButton, CircularProgress,
    Alert, Card, CardContent, Divider, Chip, TextField, InputAdornment, Menu, MenuItem,
    Stack, Grid, alpha, useMediaQuery, useTheme,
} from '@mui/material';
import {
    Add as AddIcon, Edit as EditIcon, Refresh as RefreshIcon, Search as SearchIcon,
    MoreVert as MoreVertIcon, Description as DescriptionIcon, Clear as ClearIcon,
    QuestionAnswer as QuestionAnswerIcon, Sort as SortIcon,
} from '@mui/icons-material';
import { useFaqManagement } from 'hooks/useFaq';
import { usePermissions } from 'hooks/usePermissions';
import { useLanguage } from 'context/LanguageContext';
import { showSnackbar } from 'utils/snackbar';
import FaqFormModal from './FaqFormModal';
import { tFaq } from './faqlang';
import appConfig from '../../config';

const colors = appConfig.app.colors;

const FaqList = () => {
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const showTableView = useMediaQuery(theme.breakpoints.up('md'));
    const { language } = useLanguage();
    const t = (key) => tFaq(language, key);

    const { faqs, loading, error, getFaqs, createFaq, updateFaq, clearError } = useFaqManagement();
    const { can } = usePermissions();
    const canCreate = can('faqs.create');
    const canEdit = can('faqs.edit');

    const [openFormModal, setOpenFormModal] = useState(false);
    const [editingFaq, setEditingFaq] = useState(null);
    const [actionMenu, setActionMenu] = useState(null);
    const [selectedFaq, setSelectedFaq] = useState(null);
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [order, setOrder] = useState('asc');
    const [orderBy, setOrderBy] = useState('order');

    const headCells = [
        { id: 'index', label: t('faq.col.index'), disableSort: true },
        { id: 'question', label: t('faq.col.question') },
        { id: 'answer', label: t('faq.col.answer'), disableSort: true },
        { id: 'order', label: t('faq.col.order') },
        { id: 'actions', label: t('faq.col.actions'), disableSort: true },
    ];

    const loadFaqs = async () => {
        try {
            await getFaqs({ page: page + 1, per_page: rowsPerPage, search: search || undefined });
        } catch {
            showSnackbar({ type: 'error', message: t('faq.loadFailed') });
        }
    };

    useEffect(() => {
        loadFaqs();
    }, [page, rowsPerPage, search]);

    const handleRequestSort = (property) => {
        const isAsc = orderBy === property && order === 'asc';
        setOrder(isAsc ? 'desc' : 'asc');
        setOrderBy(property);
    };

    const sortedFaqs = Array.isArray(faqs)
        ? [...faqs].sort((a, b) => {
            let aValue = a[orderBy] || '';
            let bValue = b[orderBy] || '';
            if (typeof aValue === 'string') {
                aValue = aValue.toLowerCase();
                bValue = bValue.toLowerCase();
            }
            if (aValue < bValue) return order === 'asc' ? -1 : 1;
            if (aValue > bValue) return order === 'asc' ? 1 : -1;
            return 0;
        })
        : [];

    const handleMenuOpen = (event, faq) => {
        setSelectedFaq(faq);
        setActionMenu(event.currentTarget);
    };

    const handleMenuClose = () => setActionMenu(null);

    const handleEdit = () => {
        setEditingFaq(selectedFaq);
        setOpenFormModal(true);
        handleMenuClose();
    };

    const handleCreate = () => {
        setEditingFaq(null);
        setOpenFormModal(true);
    };

    const handleFormModalClose = (refresh = false) => {
        setOpenFormModal(false);
        setEditingFaq(null);
        if (refresh) loadFaqs();
    };

    if (error) {
        return (
            <Box p={3}>
                <Alert
                    severity="error"
                    action={
                        <Button color="inherit" size="small" onClick={() => { clearError(); loadFaqs(); }}>
                            {t('faq.retry')}
                        </Button>
                    }
                    sx={{ borderRadius: 2 }}
                >
                    {error}
                </Alert>
            </Box>
        );
    }

    const faqList = sortedFaqs;
    const totalCount = faqList.length;

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
                                {t('faq.title')}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" fontWeight={500}>
                                {t('faq.subtitle')}
                            </Typography>
                        </Box>

                        <Stack direction="row" spacing={1.5} alignItems="center" justifyContent={{ xs: 'space-between', sm: 'flex-end' }}>
                            {canCreate && (
                                <Button
                                    variant="contained"
                                    startIcon={<AddIcon />}
                                    onClick={handleCreate}
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
                                    {t('faq.add')}
                                </Button>
                            )}
                        </Stack>
                    </Stack>

                    {/* FILTERS */}
                    <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} alignItems={{ xs: 'stretch', sm: 'center' }}>
                        <TextField
                            placeholder={t('faq.searchPlaceholder')}
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

                        <Button
                            variant="outlined"
                            startIcon={<RefreshIcon />}
                            onClick={loadFaqs}
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
                            {t('faq.refresh')}
                        </Button>
                    </Stack>
                </Box>

                {/* SUMMARY CARDS */}
                <Box sx={{ px: { xs: 2, sm: 3 }, pt: 2.5, pb: 1 }}>
                    <Grid container spacing={2}>
                        {[
                            {
                                label: t('faq.total'),
                                value: totalCount,
                                color: '#3b82f6',
                                icon: <QuestionAnswerIcon sx={{ fontSize: 18 }} />,
                            },
                            {
                                label: t('faq.withAnswers'),
                                value: faqList.filter((f) => f.answer?.trim()).length,
                                color: '#10b981',
                                icon: <DescriptionIcon sx={{ fontSize: 18 }} />,
                            },
                            {
                                label: t('faq.lastUpdated'),
                                value:
                                    faqList.length > 0 && faqList[0]?.updated_at
                                        ? new Date(faqList[0].updated_at).toLocaleDateString()
                                        : t('faq.never'),
                                color: '#8b5cf6',
                                icon: <SortIcon sx={{ fontSize: 18 }} />,
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

                {/* TABLE (DESKTOP) */}
                {showTableView ? (
                    <TableContainer>
                        <Table sx={{ minWidth: 700 }}>
                            <TableHead>
                                <TableRow
                                    sx={{
                                        bgcolor: 'action.hover',
                                        '& th': {
                                            fontWeight: 700,
                                            fontSize: '0.8125rem',
                                            color: 'text.secondary',
                                            textTransform: 'uppercase',
                                            letterSpacing: 0.6,
                                            borderBottom: '1px solid',
                                            borderColor: 'divider',
                                            py: 1.75,
                                        },
                                    }}
                                >
                                    {headCells.map((cell) => (
                                        <TableCell key={cell.id} sx={{ whiteSpace: 'nowrap' }}>
                                            {!cell.disableSort ? (
                                                <TableSortLabel
                                                    active={orderBy === cell.id}
                                                    direction={orderBy === cell.id ? order : 'asc'}
                                                    onClick={() => handleRequestSort(cell.id)}
                                                >
                                                    {cell.label}
                                                </TableSortLabel>
                                            ) : (
                                                cell.label
                                            )}
                                        </TableCell>
                                    ))}
                                </TableRow>
                            </TableHead>

                            <TableBody>
                                {loading ? (
                                    <TableRow>
                                        <TableCell colSpan={headCells.length} align="center" sx={{ py: 8 }}>
                                            <CircularProgress size={36} thickness={4} />
                                        </TableCell>
                                    </TableRow>
                                ) : faqList.length === 0 ? (
                                    <TableRow>
                                        <TableCell colSpan={headCells.length} align="center" sx={{ py: 8 }}>
                                            <Typography color="text.secondary" fontWeight={500}>
                                                {search ? t('faq.noMatch') : t('faq.noFound')}
                                            </Typography>
                                        </TableCell>
                                    </TableRow>
                                ) : (
                                    faqList.map((faq, index) => {
                                        const rowNumber = page * rowsPerPage + index + 1;
                                        return (
                                            <TableRow
                                                key={faq.id}
                                                hover
                                                sx={{
                                                    '&:last-child td': { borderBottom: 0 },
                                                    transition: 'background-color 0.15s',
                                                }}
                                            >
                                                <TableCell>
                                                    <Typography variant="body2" fontWeight={500} color="text.secondary">
                                                        {rowNumber}
                                                    </Typography>
                                                </TableCell>
                                                <TableCell>
                                                    <Typography variant="body2" fontWeight={600} color="text.primary">
                                                        {faq.question}
                                                    </Typography>
                                                </TableCell>
                                                <TableCell>
                                                    <Typography
                                                        variant="body2"
                                                        color="text.secondary"
                                                        sx={{
                                                            display: '-webkit-box',
                                                            WebkitLineClamp: 2,
                                                            WebkitBoxOrient: 'vertical',
                                                            overflow: 'hidden',
                                                            maxWidth: 300,
                                                        }}
                                                    >
                                                        {faq.answer}
                                                    </Typography>
                                                </TableCell>
                                                <TableCell>
                                                    <Chip
                                                        label={faq.order || 0}
                                                        size="small"
                                                        sx={{
                                                            fontWeight: 700,
                                                            bgcolor: alpha(colors.sea, 0.08),
                                                            color: colors.sea,
                                                            minWidth: 36,
                                                        }}
                                                    />
                                                </TableCell>
                                                <TableCell align="center">
                                                    <IconButton
                                                        size="small"
                                                        onClick={(e) => handleMenuOpen(e, faq)}
                                                        sx={{
                                                            color: 'text.secondary',
                                                            '&:hover': { bgcolor: 'action.hover', color: 'text.primary' },
                                                        }}
                                                    >
                                                        <MoreVertIcon />
                                                    </IconButton>
                                                </TableCell>
                                            </TableRow>
                                        );
                                    })
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                ) : (
                    /* MOBILE CARDS */
                    <Box sx={{ p: { xs: 2, sm: 2.5 } }}>
                        {loading ? (
                            <Box display="flex" justifyContent="center" py={6}>
                                <CircularProgress size={36} thickness={4} />
                            </Box>
                        ) : faqList.length === 0 ? (
                            <Paper
                                variant="outlined"
                                sx={{
                                    p: 5, textAlign: 'center', borderRadius: 3, borderStyle: 'dashed',
                                    bgcolor: 'background.paper', // ✅ Theme aware
                                }}
                            >
                                <QuestionAnswerIcon sx={{ fontSize: 56, color: 'text.disabled', mb: 2 }} />
                                <Typography color="text.secondary" fontWeight={500}>
                                    {search ? t('faq.noMatch') : t('faq.noFound')}
                                </Typography>
                            </Paper>
                        ) : (
                            <Stack spacing={2}>
                                {faqList.map((faq, index) => (
                                    <Card
                                        key={faq.id}
                                        elevation={0}
                                        sx={{
                                            borderRadius: 3,
                                            border: '1px solid',
                                            borderColor: 'divider',
                                            bgcolor: 'background.paper', // ✅ Theme aware
                                            overflow: 'hidden',
                                        }}
                                    >
                                        <CardContent sx={{ p: 2.5 }}>
                                            <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={1.5}>
                                                <Stack direction="row" spacing={1} alignItems="center">
                                                    <Chip
                                                        label={`#${index + 1}`}
                                                        size="small"
                                                        sx={{
                                                            fontWeight: 700,
                                                            bgcolor: alpha(colors.sea, 0.08),
                                                            color: colors.sea,
                                                        }}
                                                    />
                                                    <Chip
                                                        label={`${t('faq.order')}: ${faq.order || 0}`}
                                                        size="small"
                                                        variant="outlined"
                                                        sx={{ borderColor: 'divider' }}
                                                    />
                                                </Stack>
                                                <IconButton
                                                    size="small"
                                                    onClick={(e) => handleMenuOpen(e, faq)}
                                                    sx={{ color: 'text.secondary' }}
                                                >
                                                    <MoreVertIcon fontSize="small" />
                                                </IconButton>
                                            </Stack>

                                            <Typography variant="subtitle1" fontWeight={700} color="text.primary" sx={{ mb: 1 }}>
                                                {faq.question}
                                            </Typography>

                                            <Typography variant="body2" color="text.secondary" sx={{ lineHeight: 1.7 }}>
                                                {faq.answer}
                                            </Typography>

                                            <Divider sx={{ my: 1.5, borderColor: 'divider' }} />

                                            <Stack direction="row" spacing={1.5} alignItems="center" flexWrap="wrap">
                                                <Typography variant="caption" color="text.secondary">
                                                    {t('faq.created')}:{' '}
                                                    {faq.created_at ? new Date(faq.created_at).toLocaleDateString() : 'N/A'}
                                                </Typography>
                                                {faq.updated_at && faq.updated_at !== faq.created_at && (
                                                    <Typography variant="caption" color="text.secondary">
                                                        {t('faq.updated')}: {new Date(faq.updated_at).toLocaleDateString()}
                                                    </Typography>
                                                )}
                                            </Stack>
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
                        rowsPerPageOptions={[5, 10, 25, 50]}
                        component="div"
                        count={totalCount}
                        rowsPerPage={rowsPerPage}
                        page={page}
                        onPageChange={(e, newPage) => setPage(newPage)}
                        onRowsPerPageChange={(e) => {
                            setRowsPerPage(parseInt(e.target.value, 10));
                            setPage(0);
                        }}
                        sx={{
                            '.MuiTablePagination-selectLabel, .MuiTablePagination-displayedRows': {
                                fontWeight: 500,
                            },
                        }}
                    />
                </Box>
            </Paper>

            {/* ACTION MENU */}
            <Menu
                anchorEl={actionMenu}
                open={Boolean(actionMenu)}
                onClose={handleMenuClose}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                transformOrigin={{ vertical: 'top', horizontal: 'right' }}
                PaperProps={{ elevation: 8, sx: { borderRadius: 2, minWidth: 180, mt: 0.5, bgcolor: 'background.paper' } }}
            >
                {canEdit && (
                    <MenuItem onClick={handleEdit} sx={{ fontWeight: 500 }}>
                        <EditIcon sx={{ mr: 1.5, fontSize: 20, color: colors.sea || '#0f766e' }} />
                        {t('faq.edit')}
                    </MenuItem>
                )}
            </Menu>

            {/* FAQ FORM MODAL */}
            <FaqFormModal
                open={openFormModal}
                onClose={handleFormModalClose}
                faq={editingFaq}
                createFaq={createFaq}
                updateFaq={updateFaq}
            />
        </Box>
    );
};

export default FaqList;