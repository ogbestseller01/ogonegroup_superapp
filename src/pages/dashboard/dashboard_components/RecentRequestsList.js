// src/pages/dashboard/dashboard_components/RecentRequestsList.js
import React from 'react';
import { Box, Paper, Typography, Stack, Chip, alpha, useTheme } from '@mui/material';

const formatEAT = (dateString) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleString('en-TZ', {
        timeZone: 'Africa/Dar_es_Salaam',
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });
};

const RecentRequestsList = ({ requests }) => {
    const theme = useTheme();
    if (!requests || requests.length === 0) return null;

    return (
        <Paper sx={{ p: 3, borderRadius: 3 }}>
            <Typography variant="h6" fontWeight="600" gutterBottom>🕒 Recent Requests</Typography>
            <Stack spacing={2}>
                {requests.slice(0, 5).map((req) => (
                    <Box
                        key={req.id}
                        sx={{
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center',
                            p: 2,
                            bgcolor: alpha(theme.palette.grey[500], 0.05),
                            borderRadius: 2,
                            flexWrap: 'wrap',
                            gap: 1,
                            transition: 'all 0.2s',
                            '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.05) },
                        }}
                    >
                        <Box>
                            <Typography variant="body2" fontWeight="500">Request #{req.id}</Typography>
                            <Typography variant="caption" color="text.secondary">
                                {req.customer?.name || 'Unknown'} → {req.technician?.user?.name || 'Unknown'}
                            </Typography>
                            <Typography variant="caption" display="block" color="text.secondary">
                                Service: {req.service?.name || 'N/A'} &nbsp;•&nbsp; Area: {req.area || 'N/A'}
                            </Typography>
                            <Typography variant="caption" display="block" color="text.secondary" sx={{ mt: 0.5 }}>
                                📅 {formatEAT(req.created_at)}
                            </Typography>
                        </Box>
                        <Box display="flex" alignItems="center" gap={1}>
                            <Chip label={req.status} size="small" variant="outlined"
                                  color={
                                      req.status === 'pending' ? 'warning' :
                                          req.status === 'accepted' ? 'info' :
                                              req.status === 'in_progress' ? 'primary' :
                                                  req.status === 'completed' ? 'success' :
                                                      req.status === 'cancelled' ? 'default' :
                                                          req.status === 'rejected' ? 'error' : 'default'
                                  }
                            />
                        </Box>
                    </Box>
                ))}
            </Stack>
        </Paper>
    );
};

export default RecentRequestsList;