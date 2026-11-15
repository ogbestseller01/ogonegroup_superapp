// src/context/MonitoringContext.jsx
import React, { createContext, useContext, useState, useCallback } from 'react';
import api from '../services/api';

const MonitoringContext = createContext();

export const MonitoringProvider = ({ children }) => {
    const [dashboard, setDashboard] = useState(null);
    const [requests, setRequests] = useState([]);
    const [technicians, setTechnicians] = useState([]);
    const [notifications, setNotifications] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [pagination, setPagination] = useState({ total: 0, per_page: 20, current_page: 1, last_page: 1 });
    const [filters, setFilters] = useState({
        status: '',
        search: '',
        date_from: '',
        date_to: '',
        sort_by: 'created_at',
        sort_order: 'desc',
    });
    const [autoRefresh, setAutoRefresh] = useState(true);

    const loadDashboard = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const response = await api.get('/v4/monitoring/dashboard');
            setDashboard(response.data.data);
            setTechnicians(response.data.data.technicians || []);
        } catch (err) {
            setError(err.response?.data?.message || 'Failed to load dashboard');
        } finally {
            setLoading(false);
        }
    }, []);


    const loadRequests = useCallback(async (page = 1) => {
        setLoading(true);
        setError(null);
        try {
            const params = { ...filters, page, per_page: 20 };
            const response = await api.get('/v4/monitoring/requests', { params });
            setRequests(response.data.data.data || []);
            setPagination(response.data.data.pagination || { total: 0, per_page: 20, current_page: 1, last_page: 1 });
        } catch (err) {
            setError(err.response?.data?.message || 'Failed to load requests');
        } finally {
            setLoading(false);
        }
    }, [filters]);


    const updateRequestStatus = useCallback(async (id, status, notes) => {
        try {
            const response = await api.patch(`/v4/monitoring/requests/${id}/status`, { status, notes });
            await loadRequests();
            return response.data;
        } catch (err) {
            setError(err.response?.data?.message || 'Failed to update status');
            throw err;
        }
    }, [loadRequests]);


    const callTechnician = useCallback(async (technicianId, requestId) => {
        try {
            const response = await api.post(`/v4/monitoring/technicians/${technicianId}/call`, { request_id: requestId });
            return response.data.data;
        } catch (err) {
            setError(err.response?.data?.message || 'Failed to get call details');
            throw err;
        }
    }, []);


    const fetchNotifications = useCallback(async () => {
        try {
            const response = await api.get('/v4/monitoring/notifications');
            setNotifications(response.data.data.notifications || []);
            return response.data.data;
        } catch (err) {
            console.error('Failed to fetch notifications:', err);
            return { notifications: [] };
        }
    }, []);


    const value = {
        dashboard,
        requests,
        technicians,
        notifications,
        loading,
        error,
        pagination,
        filters,
        setFilters,
        autoRefresh,
        setAutoRefresh,
        loadDashboard,
        loadRequests,
        updateRequestStatus,
        callTechnician,
        fetchNotifications,
    };

    return (
        <MonitoringContext.Provider value={value}>
            {children}
        </MonitoringContext.Provider>
    );
};

export const useMonitoring = () => {
    const context = useContext(MonitoringContext);
    if (!context) {
        throw new Error('useMonitoring must be used within a MonitoringProvider');
    }
    return context;
};