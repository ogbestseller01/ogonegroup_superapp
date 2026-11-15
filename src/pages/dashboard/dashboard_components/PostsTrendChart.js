// src/pages/dashboard/dashboard_components/PostsTrendChart.js
import React from 'react';
import { Box, Typography, alpha, useTheme } from '@mui/material';
import { Line } from 'react-chartjs-2';

const PostsTrendChart = ({ data }) => {
    const theme = useTheme();
    const labels = data?.map(d => d.date) || [];
    const posts = data?.map(d => d.posts) || [];
    const chartData = {
        labels,
        datasets: [{
            label: 'Blog Posts',
            data: posts,
            borderColor: theme.palette.secondary.main,
            backgroundColor: alpha(theme.palette.secondary.main, 0.1),
            fill: true,
            tension: 0.4,
            pointBackgroundColor: theme.palette.secondary.main,
        }],
    };
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            title: { display: true, text: 'Blog Posts Trend', font: { size: 14, weight: '600' } },
        },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } },
    };
    return (
        <Box sx={{ height: 250 }}>
            {data && data.length > 0 ? <Line data={chartData} options={options} /> :
                <Box display="flex" justifyContent="center" alignItems="center" height="100%"><Typography color="text.secondary">No posts trend data</Typography></Box>}
        </Box>
    );
};

export default PostsTrendChart;