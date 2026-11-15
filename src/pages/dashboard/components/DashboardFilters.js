// src/pages/dashboard/components/DashboardFilters.js
import { Paper, Stack, FormControl, InputLabel, Select, MenuItem, TextField, Button, useTheme, alpha } from '@mui/material';
import { Refresh } from '@mui/icons-material';

const DashboardFilters = ({ period, setPeriod, date, setDate, refetch }) => {
    const theme = useTheme();

    const handlePeriodChange = (newPeriod) => {
        setPeriod(newPeriod);
        // Reset date when period changes to avoid mismatched formats
        if (newPeriod === 'daily' || newPeriod === 'monthly' || newPeriod === 'yearly') {
            setDate(new Date());
        } else {
            setDate(null);
        }
        // No automatic refetch – user must click "Refresh" or select a date
    };

    const handleDateChange = (newDate) => {
        setDate(newDate);
        // Auto‑refetch after a short delay to let state settle
        setTimeout(() => refetch(), 100);
    };

    return (
        <Paper sx={{ p: 2, mb: 4, borderRadius: 4, backdropFilter: 'blur(8px)', bgcolor: alpha(theme.palette.background.paper, 0.7) }}>
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center">
                <FormControl size="small" sx={{ minWidth: 130 }}>
                    <InputLabel>Time period</InputLabel>
                    <Select
                        value={period}
                        label="Time period"
                        onChange={(e) => handlePeriodChange(e.target.value)}
                    >
                        <MenuItem value="">All time</MenuItem>
                        <MenuItem value="daily">Daily</MenuItem>
                        <MenuItem value="monthly">Monthly</MenuItem>
                        <MenuItem value="yearly">Yearly</MenuItem>
                    </Select>
                </FormControl>

                {period === 'daily' && (
                    <TextField
                        type="date"
                        label="Date"
                        size="small"
                        value={date ? date.toISOString().split('T')[0] : ''}
                        onChange={(e) => handleDateChange(new Date(e.target.value))}
                        InputLabelProps={{ shrink: true }}
                    />
                )}

                {period === 'monthly' && (
                    <TextField
                        type="month"
                        label="Month"
                        size="small"
                        value={date ? date.toISOString().slice(0, 7) : ''}
                        onChange={(e) => handleDateChange(new Date(e.target.value + '-01'))}
                        InputLabelProps={{ shrink: true }}
                    />
                )}

                {period === 'yearly' && (
                    <TextField
                        type="number"
                        label="Year"
                        size="small"
                        value={date ? date.getFullYear() : ''}
                        onChange={(e) => handleDateChange(new Date(parseInt(e.target.value, 10), 0, 1))}
                        InputLabelProps={{ shrink: true }}
                    />
                )}

                <Button variant="outlined" startIcon={<Refresh />} onClick={refetch} size="small">
                    Refresh
                </Button>
            </Stack>
        </Paper>
    );
};

export default DashboardFilters;