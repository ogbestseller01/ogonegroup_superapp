// src/pages/dashboard/dashboard_components/StatCard.js
import React from 'react';
import { Box, Card, CardContent, Avatar, Typography, useTheme, alpha } from '@mui/material';
import { TrendingUp, TrendingDown } from '@mui/icons-material';

const StatCard = ({ title, value, icon, color, subtitle, trend }) => {
    const theme = useTheme();
    return (
        <Card sx={{
            height: '100%',
            borderRadius: 3,
            transition: 'all 0.3s',
            '&:hover': { transform: 'translateY(-4px)', boxShadow: 6 },
        }}>
            <CardContent>
                <Box display="flex" alignItems="center" justifyContent="space-between">
                    <Box>
                        <Typography variant="caption" color="text.secondary" fontWeight="500">{title}</Typography>
                        <Typography variant="h4" fontWeight="700" sx={{ mt: 1 }}>{value || 0}</Typography>
                        {subtitle && <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 0.5 }}>{subtitle}</Typography>}
                        {trend !== undefined && (
                            <Box display="flex" alignItems="center" gap={0.5} sx={{ mt: 1 }}>
                                {trend > 0 ? <TrendingUp sx={{ color: 'success.main', fontSize: 16 }} /> :
                                    trend < 0 ? <TrendingDown sx={{ color: 'error.main', fontSize: 16 }} /> : null}
                                <Typography variant="caption" color={trend > 0 ? 'success.main' : trend < 0 ? 'error.main' : 'text.secondary'}>
                                    {trend > 0 ? '+' : ''}{trend}%
                                </Typography>
                            </Box>
                        )}
                    </Box>
                    <Avatar sx={{ width: 56, height: 56, bgcolor: alpha(color || theme.palette.primary.main, 0.15), color: color || theme.palette.primary.main }}>
                        {icon}
                    </Avatar>
                </Box>
            </CardContent>
        </Card>
    );
};

export default StatCard;