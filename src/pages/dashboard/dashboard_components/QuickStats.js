// src/pages/dashboard/dashboard_components/QuickStats.js
import React from 'react';
import { Box, Grid, Paper, Typography, alpha, useTheme } from '@mui/material';

const QuickStats = ({ users, technicians, services, requests }) => {
    const theme = useTheme();
    return (
        <Paper sx={{ p: 3, borderRadius: 3 }}>
            <Typography variant="h6" fontWeight="600" gutterBottom>Quick Stats</Typography>
            <Grid container spacing={2}>
                <Grid item xs={6} sm={3}>
                    <Box sx={{ p: 2, bgcolor: alpha(theme.palette.primary.main, 0.08), borderRadius: 2 }}>
                        <Typography variant="caption" color="text.secondary">Total Users</Typography>
                        <Typography variant="h5" fontWeight="700">{users?.total || 0}</Typography>
                    </Box>
                </Grid>
                <Grid item xs={6} sm={3}>
                    <Box sx={{ p: 2, bgcolor: alpha(theme.palette.success.main, 0.08), borderRadius: 2 }}>
                        <Typography variant="caption" color="text.secondary">Total Technicians</Typography>
                        <Typography variant="h5" fontWeight="700">{technicians?.total || 0}</Typography>
                    </Box>
                </Grid>
                <Grid item xs={6} sm={3}>
                    <Box sx={{ p: 2, bgcolor: alpha(theme.palette.warning.main, 0.08), borderRadius: 2 }}>
                        <Typography variant="caption" color="text.secondary">Total Services</Typography>
                        <Typography variant="h5" fontWeight="700">{services?.total || 0}</Typography>
                    </Box>
                </Grid>
                <Grid item xs={6} sm={3}>
                    <Box sx={{ p: 2, bgcolor: alpha(theme.palette.info.main, 0.08), borderRadius: 2 }}>
                        <Typography variant="caption" color="text.secondary">Total Requests</Typography>
                        <Typography variant="h5" fontWeight="700">{requests?.total || 0}</Typography>
                    </Box>
                </Grid>
            </Grid>
        </Paper>
    );
};

export default QuickStats;