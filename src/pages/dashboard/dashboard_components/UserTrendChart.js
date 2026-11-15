// src/pages/dashboard/dashboard_components/UserTrendChart.js
import React from 'react';
import { Box, Typography, alpha, useTheme } from '@mui/material';
import { Line } from 'react-chartjs-2';

const UserTrendChart = ({ data }) => {
    const theme = useTheme();
    const labels = data?.map(d => d.date) || [];
    const techs = data?.map(d => d.technicians) || [];
    const custs = data?.map(d => d.customers) || [];
    const chartData = {
        labels,
        datasets: [
            { label: 'Technicians', data: techs, borderColor: '#4caf50', backgroundColor: alpha('#4caf50', 0.1), fill: true, tension: 0.4 },
            { label: 'Customers', data: custs, borderColor: '#2196f3', backgroundColor: alpha('#2196f3', 0.1), fill: true, tension: 0.4 },
        ],
    };
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            title: { display: true, text: 'New Users Over Time', font: { size: 14, weight: '600' } },
            legend: { position: 'top' },
        },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } },
    };
    return (
        <Box sx={{ height: 250 }}>
            {data && data.length > 0 ? <Line data={chartData} options={options} /> :
                <Box display="flex" justifyContent="center" alignItems="center" height="100%"><Typography color="text.secondary">No user trend data</Typography></Box>}
        </Box>
    );
};

export default UserTrendChart;