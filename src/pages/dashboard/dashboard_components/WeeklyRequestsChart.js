// src/pages/dashboard/dashboard_components/WeeklyRequestsChart.js
import React from 'react';
import { Box, Typography, useTheme } from '@mui/material';
import { Bar } from 'react-chartjs-2';

const WeeklyRequestsChart = ({ data }) => {
    const theme = useTheme();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const counts = days.map(day => {
        const found = data?.find(d => d.day === day);
        return found ? found.total : 0;
    });
    const chartData = {
        labels: days,
        datasets: [{
            label: 'Requests',
            data: counts,
            backgroundColor: theme.palette.primary.main,
            borderRadius: 6,
        }],
    };
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            title: { display: true, text: 'Requests per Day (Mon–Sun)', font: { size: 14, weight: '600' } },
        },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } },
    };
    return (
        <Box sx={{ height: 250 }}>
            {data && data.length > 0 ? <Bar data={chartData} options={options} /> :
                <Box display="flex" justifyContent="center" alignItems="center" height="100%"><Typography color="text.secondary">No weekly data</Typography></Box>}
        </Box>
    );
};

export default WeeklyRequestsChart;