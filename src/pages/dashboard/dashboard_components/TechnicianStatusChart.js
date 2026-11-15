// src/pages/dashboard/dashboard_components/TechnicianStatusChart.js
import React from 'react';
import { Box, Paper, Typography, useTheme } from '@mui/material';
import { Bar } from 'react-chartjs-2';

const TechnicianStatusChart = ({ data }) => {
    const theme = useTheme();
    const statusColors = {
        pending: theme.palette.warning.main,
        accepted: theme.palette.info.main,
        in_progress: theme.palette.primary.main,
        completed: theme.palette.success.main,
        cancelled: theme.palette.grey[500],
        rejected: theme.palette.error.main,
    };
    const statusLabels = {
        pending: 'Pending',
        accepted: 'Accepted',
        in_progress: 'In Progress',
        completed: 'Completed',
        cancelled: 'Cancelled',
        rejected: 'Rejected',
    };

    const technicians = data?.map(t => t.technician_name) || [];
    const datasets = Object.keys(statusColors).map(status => ({
        label: statusLabels[status],
        data: data?.map(t => t[status] || 0) || [],
        backgroundColor: statusColors[status],
        borderRadius: 2,
    }));

    const chartData = {
        labels: technicians,
        datasets,
    };

    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            title: { display: true, text: 'Technician Request Breakdown by Status', font: { size: 14, weight: '600' } },
            legend: { position: 'bottom', labels: { usePointStyle: true, pointStyle: 'circle' } },
            tooltip: {
                callbacks: {
                    afterBody: function(tooltipItems) {
                        const index = tooltipItems[0].dataIndex;
                        const item = data?.[index];
                        if (item) {
                            return `Area: ${item.area || 'N/A'} | Unique Customers: ${item.unique_customers || 0}`;
                        }
                        return '';
                    }
                }
            }
        },
        scales: {
            x: { stacked: true },
            y: { stacked: true, beginAtZero: true, ticks: { stepSize: 1 } },
        },
    };

    return (
        <Paper sx={{ p: 3, borderRadius: 3, height: '100%' }}>
            <Box sx={{ height: 300 }}>
                {data && data.length > 0 ? <Bar data={chartData} options={options} /> :
                    <Box display="flex" justifyContent="center" alignItems="center" height="100%">
                        <Typography color="text.secondary">No technician breakdown data</Typography>
                    </Box>}
            </Box>
        </Paper>
    );
};

export default TechnicianStatusChart;