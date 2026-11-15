// src/pages/dashboard/dashboard_components/WeeklyRevenueChart.js
import React from 'react';
import { Box, Typography, useTheme } from '@mui/material';
import { Bar } from 'react-chartjs-2';

const WeeklyRevenueChart = ({ data }) => {
    const theme = useTheme();
    const labels = data?.map(item => item.week) || [];
    const values = data?.map(item => item.total) || [];

    const chartData = {
        labels,
        datasets: [{
            label: 'Revenue (Tshs)',
            data: values,
            backgroundColor: theme.palette.success.main,
            borderRadius: 6,
        }],
    };

    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            title: { display: true, text: 'Weekly Revenue (Current Month)', font: { size: 14, weight: '600' } },
            legend: { display: false },
        },
        scales: {
            y: {
                beginAtZero: true,
                ticks: {
                    callback: function(value) {
                        return 'Tshs' + value.toFixed(2);
                    }
                }
            }
        },
    };

    return (
        <Box sx={{ height: 250 }}>
            {data && data.length > 0 ? (
                <Bar data={chartData} options={options} />
            ) : (
                <Box display="flex" justifyContent="center" alignItems="center" height="100%">
                    <Typography color="text.secondary">No revenue data available</Typography>
                </Box>
            )}
        </Box>
    );
};

export default WeeklyRevenueChart;