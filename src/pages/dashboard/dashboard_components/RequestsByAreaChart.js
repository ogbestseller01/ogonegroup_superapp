// src/pages/dashboard/dashboard_components/RequestsByAreaChart.js
import React from 'react';
import { Box, Typography, useTheme } from '@mui/material';
import { Bar } from 'react-chartjs-2';

const RequestsByAreaChart = ({ data }) => {
    const theme = useTheme();
    const labels = data?.map(item => item.area) || [];
    const values = data?.map(item => item.total_requests) || [];
    const chartData = {
        labels,
        datasets: [{
            label: 'Requests',
            data: values,
            backgroundColor: labels.map((_, i) => theme.palette.primary.main),
            borderRadius: 6,
        }],
    };
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            title: { display: true, text: 'Requests by Area', font: { size: 14, weight: '600' } },
            legend: { display: false },
        },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } },
    };
    return (
        <Box sx={{ height: 250 }}>
            {data && data.length > 0 ? <Bar data={chartData} options={options} /> :
                <Box display="flex" justifyContent="center" alignItems="center" height="100%"><Typography color="text.secondary">No area data</Typography></Box>}
        </Box>
    );
};

export default RequestsByAreaChart;