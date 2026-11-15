// src/pages/dashboard/dashboard_components/TechnicianEngagementTable.js
import React from 'react';
import { Paper, Typography, Table, TableHead, TableRow, TableCell, TableBody } from '@mui/material';

const TechnicianEngagementTable = ({ data }) => {
    return (
        <Paper sx={{ p: 3, borderRadius: 3, height: '100%' }}>
            <Typography variant="h6" fontWeight="600" gutterBottom>Technician Engagement</Typography>
            <Table size="small">
                <TableHead>
                    <TableRow>
                        <TableCell>Technician</TableCell>
                        <TableCell align="right">Likes</TableCell>
                        <TableCell align="right">Comments</TableCell>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {data?.map((t, i) => (
                        <TableRow key={i}>
                            <TableCell>{t.technician_name}</TableCell>
                            <TableCell align="right">{t.total_likes}</TableCell>
                            <TableCell align="right">{t.total_comments}</TableCell>
                        </TableRow>
                    ))}
                    {(!data || data.length === 0) && (
                        <TableRow><TableCell colSpan={3} align="center">No data</TableCell></TableRow>
                    )}
                </TableBody>
            </Table>
        </Paper>
    );
};

export default TechnicianEngagementTable;