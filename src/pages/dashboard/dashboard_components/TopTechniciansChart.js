// src/pages/dashboard/dashboard_components/TopTechniciansChart.js
import React from 'react';
import { Box, Typography } from '@mui/material';
import { Bar } from 'react-chartjs-2';

const TopTechniciansChart = ({ data }) => {
    const labels = data?.map(t => t.name) || [];
    const values = data?.map(t => t.requests_count) || [];
    const chartData = {
        labels,
        datasets: [{
            label: 'Requests',
            data: values,
            backgroundColor: 'rgba(255,152,0,0.8)',
            borderRadius: 6,
        }],
    };
    const options = {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            title: { display: true, text: 'Top Technicians by Requests', font: { size: 14, weight: '600' } },
        },
        scales: { x: { beginAtZero: true, ticks: { stepSize: 1 } } },
    };
    return (
        <Box sx={{ height: 250 }}>
            {data && data.length > 0 ? <Bar data={chartData} options={options} /> :
                <Box display="flex" justifyContent="center" alignItems="center" height="100%"><Typography color="text.secondary">No top technicians</Typography></Box>}
        </Box>
    );
};

export default TopTechniciansChart;