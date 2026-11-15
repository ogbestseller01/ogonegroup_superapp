// src/pages/dashboard/dashboard_components/UsersByRole.js
import React from 'react';
import { Box, Grid, Paper, Typography, alpha, useTheme } from '@mui/material';

const UsersByRole = ({ roles }) => {
    const theme = useTheme();
    if (!roles || roles.length === 0) return null;

    return (
        <Paper sx={{ p: 3, borderRadius: 3, mb: 3 }}>
            <Typography variant="h6" fontWeight="600" gutterBottom>Users by Role</Typography>
            <Grid container spacing={2}>
                {roles.map((role) => (
                    <Grid item xs={6} sm={4} md={3} key={role.id}>
                        <Box sx={{ p: 2, bgcolor: alpha(theme.palette.primary.main, 0.06), borderRadius: 2, textAlign: 'center' }}>
                            <Typography variant="h4" fontWeight="700">{role.users_count || 0}</Typography>
                            <Typography variant="caption" color="text.secondary">{role.display_name || role.name}</Typography>
                        </Box>
                    </Grid>
                ))}
            </Grid>
        </Paper>
    );
};

export default UsersByRole;