// src/hooks/usePermissions.js
import { useAuth } from 'context/AuthContext';
import { useMemo } from 'react';

export const usePermissions = () => {
    const { permissions, hasPermission, roles, user } = useAuth();

    const can = (permission) => {
        return hasPermission(permission);
    };

    const hasRole = (role) => {
        return roles?.includes(role) || false;
    };

    const isAdmin = () => {
        return roles?.includes('ADMINISTRATOR') || false;
    };

    const isManager = () => {
        return roles?.includes('MANAGER') || false;
    };

    const isAdminOrManager = () => {
        return isAdmin() || isManager();
    };

    // Debug log to check what's happening
    console.log('usePermissions Debug:', {
        roles,
        isAdmin: isAdmin(),
        isManager: isManager(),
        isAdminOrManager: isAdminOrManager(),
        permissionsCount: permissions?.length || 0,
        user
    });

    return {
        permissions,
        roles,
        can,
        hasRole,
        isAdmin,
        isManager,
        isAdminOrManager,
    };
};