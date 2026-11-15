// src/pages/dashboard/dashboard_components/ServicesBarChart.js
import React from 'react';
import { Box, Typography, useTheme } from '@mui/material';
import { Bar } from 'react-chartjs-2';

const ServicesBarChart = ({ data }) => {
    const theme = useTheme();
    const chartData = {
        labels: data?.map(item => item.name) || [],
        datasets: [{
            label: 'Service Requests',
            data: data?.map(item => item.requests_count || 0) || [],
            backgroundColor: data?.map((_, index) => {
                const colors = [theme.palette.primary.main, theme.palette.secondary.main, theme.palette.success.main,
                    theme.palette.warning.main, theme.palette.info.main, theme.palette.error.main];
                return colors[index % colors.length];
            }) || [],
            borderRadius: 8,
            borderSkipped: false,
        }],
    };
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false }, title: { display: true, text: 'Service Usage', font: { size: 14, weight: '600' } } },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } },
    };
    return (
        <Box sx={{ height: 250 }}>
            {data && data.length > 0 ? <Bar data={chartData} options={options} /> :
                <Box display="flex" justifyContent="center" alignItems="center" height="100%"><Typography color="text.secondary">No service data available</Typography></Box>}
        </Box>
    );
};

export default ServicesBarChart;