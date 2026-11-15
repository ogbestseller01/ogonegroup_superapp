// src/pages/dashboard/dashboard_components/StatusDistribution.js
import React from 'react';
import { Box, Grid, Paper, Typography, Stack, LinearProgress, useTheme, alpha } from '@mui/material';
import { Pie } from 'react-chartjs-2';

const StatusDistribution = ({ data, title }) => {
    const theme = useTheme();
    const statusColors = {
        pending: theme.palette.warning.main,
        accepted: theme.palette.info.main,
        in_progress: theme.palette.primary.main,
        completed: theme.palette.success.main,
        cancelled: theme.palette.grey[500],
        rejected: theme.palette.error.main,
    };
    const statusLabels = {
        pending: 'Pending',
        accepted: 'Accepted',
        in_progress: 'In Progress',
        completed: 'Completed',
        cancelled: 'Cancelled',
        rejected: 'Rejected',
    };
    const total = data?.reduce((sum, item) => sum + item.total, 0) || 0;
    const pieData = {
        labels: data?.map(item => statusLabels[item.status] || item.status) || [],
        datasets: [{
            data: data?.map(item => item.total) || [],
            backgroundColor: data?.map(item => statusColors[item.status] || theme.palette.grey[500]) || [],
            borderWidth: 2,
            borderColor: theme.palette.background.paper,
        }],
    };
    const pieOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: { position: 'bottom', labels: { padding: 20, usePointStyle: true, pointStyle: 'circle' } },
        },
    };
    return (
        <Paper sx={{ p: 3, borderRadius: 3, height: '100%' }}>
            <Typography variant="h6" fontWeight="600" gutterBottom>{title || 'Status Distribution'}</Typography>
            <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                    <Box sx={{ height: 200 }}>
                        {data && data.length > 0 ? <Pie data={pieData} options={pieOptions} /> :
                            <Box display="flex" justifyContent="center" alignItems="center" height="100%">
                                <Typography color="text.secondary">No data available</Typography>
                            </Box>}
                    </Box>
                </Grid>
                <Grid item xs={12} md={6}>
                    <Stack spacing={2}>
                        {data?.map((item) => {
                            const percentage = total > 0 ? (item.total / total) * 100 : 0;
                            return (
                                <Box key={item.status}>
                                    <Box display="flex" justifyContent="space-between" alignItems="center" mb={0.5}>
                                        <Box display="flex" alignItems="center" gap={1}>
                                            <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: statusColors[item.status] || theme.palette.grey[500] }} />
                                            <Typography variant="body2">{statusLabels[item.status] || item.status}</Typography>
                                        </Box>
                                        <Typography variant="body2" fontWeight="500">{item.total} ({percentage.toFixed(1)}%)</Typography>
                                    </Box>
                                    <LinearProgress variant="determinate" value={percentage} sx={{
                                        height: 8, borderRadius: 4,
                                        bgcolor: alpha(statusColors[item.status] || theme.palette.grey[500], 0.15),
                                        '& .MuiLinearProgress-bar': { bgcolor: statusColors[item.status] || theme.palette.grey[500], borderRadius: 4 },
                                    }} />
                                </Box>
                            );
                        })}
                        {(!data || data.length === 0) && <Typography color="text.secondary">No data available</Typography>}
                    </Stack>
                </Grid>
            </Grid>
        </Paper>
    );
};

export default StatusDistribution;