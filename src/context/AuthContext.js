// src/context/AuthContext.js
import React, { createContext, useContext, useState, useEffect } from 'react';
import api from '../services/api';
import { authService } from 'services/auth.service';

const AuthContext = createContext();

export const useAuth = () => {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error('useAuth must be used within AuthProvider');
    return ctx;
};

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [roles, setRoles] = useState([]);
    const [permissions, setPermissions] = useState([]);
    const [token, setToken] = useState(null);
    const [isLoading, setIsLoading] = useState(true);

    const fetchMyPermissions = async () => {
        try {
            const res = await authService.getMyPermissions();
            if (res.data?.status === 'success') {
                const perms = res.data.data.permissions || [];
                setPermissions(perms);
                return perms;
            }
            setPermissions([]);
            return [];
        } catch (err) {
            console.error('Error fetching permissions:', err);
            setPermissions([]);
            return [];
        }
    };

    useEffect(() => {
        const loadStoredUser = async () => {
            const storedToken = localStorage.getItem('auth_token');
            const storedUser = localStorage.getItem('user');

            if (storedToken && storedUser) {
                setToken(storedToken);
                try {
                    const parsedUser = JSON.parse(storedUser);
                    setUser(parsedUser);
                    if (parsedUser.roles) setRoles(parsedUser.roles);

                    await fetchMyPermissions();

                    try {
                        const response = await api.get('/v1/auth/me');
                        if (response.data?.status === 'success' && response.data.data) {
                            const freshUser = response.data.data.user;
                            const userRoles = response.data.data.roles || [];
                            setUser(freshUser);
                            setRoles(userRoles);
                            localStorage.setItem('user', JSON.stringify({ ...freshUser, roles: userRoles }));
                        }
                    } catch (err) {
                        console.error('Failed to fetch fresh user data:', err);
                    }
                } catch {
                    localStorage.removeItem('auth_token');
                    localStorage.removeItem('user');
                    setToken(null);
                    setUser(null);
                }
            }
            setIsLoading(false);
        };
        loadStoredUser();
    }, []);

    // Classic password login - supports both email and phone
    const login = async (identifier, password) => {
        const response = await authService.login(identifier, password);
        if (response.data?.status === 'success' && response.data.data) {
            const { user, roles, token } = response.data.data;
            const userWithRoles = { ...user, roles: roles || [] };

            setUser(userWithRoles);
            setRoles(roles || []);
            setToken(token);

            localStorage.setItem('auth_token', token);
            localStorage.setItem('user', JSON.stringify(userWithRoles));

            await fetchMyPermissions();
            return { user: userWithRoles, roles: roles || [], token };
        }
        throw new Error(response.data?.message || 'Login failed');
    };

    // ─── Web OTP Login helpers ───────────────────────────
    const requestWebOtp = async (identifier, password) => {
        const response = await authService.requestWebOtp(identifier, password);
        if (response.data?.status === 'success') {
            return response.data.data;
        }
        throw new Error(response.data?.message || 'Failed to send OTP');
    };

    const verifyWebOtp = async (email, otp) => {
        const response = await authService.verifyWebOtp(email, otp);
        if (response.data?.status === 'success' && response.data.data) {
            const { user, roles, token } = response.data.data;
            const userWithRoles = { ...user, roles: roles || [] };

            setUser(userWithRoles);
            setRoles(roles || []);
            setToken(token);

            localStorage.setItem('auth_token', token);
            localStorage.setItem('user', JSON.stringify(userWithRoles));

            await fetchMyPermissions();
            return { user: userWithRoles, roles: roles || [], token };
        }
        throw new Error(response.data?.message || 'OTP verification failed');
    };

    const resendWebOtp = async (email) => {
        const response = await authService.resendWebOtp(email);
        if (response.data?.status === 'success') {
            return response.data.data;
        }
        throw new Error(response.data?.message || 'Failed to resend OTP');
    };

    const logout = async () => {
        try {
            await authService.logout();
        } catch { /* ignore */ }

        setUser(null);
        setRoles([]);
        setPermissions([]);
        setToken(null);
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user');
    };

    const hasPermission = (permissionName) => permissions.includes(permissionName);
    const hasRole = (roleName) => roles.includes(roleName);

    const value = {
        user,
        roles,
        permissions,
        token,
        isLoading,
        login,
        requestWebOtp,
        verifyWebOtp,
        resendWebOtp,
        logout,
        isAuthenticated: !!token && !!user,
        hasPermission,
        hasRole,
    };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};