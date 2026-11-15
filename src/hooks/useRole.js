// src/hooks/useRole.js
import { useRoles } from 'context/RoleContext';
import { useCallback, useState } from 'react';

export const useRoleManagement = () => {
    const {
        items = [],
        item = null,
        loading = false,
        error = null,
        fetchAll,
        fetchOne,
        create,
        update,
        delete: remove,
        getDropdown,
        clearError
    } = useRoles();

    // State for dropdown
    const [dropdownRoles, setDropdownRoles] = useState([]);
    const [dropdownLoading, setDropdownLoading] = useState(false);

    // Get dropdown roles
    const getDropdownRoles = useCallback(async () => {
        try {
            const roles = await getDropdown();
            const rolesArray = Array.isArray(roles) ? roles : [];
            return rolesArray;
        } catch (err) {
            console.error('getDropdownRoles error:', err);
            return [];
        }
    }, [getDropdown]);

    // Fetch dropdown roles with loading state
    const fetchDropdownRoles = useCallback(async () => {
        setDropdownLoading(true);
        try {
            const roles = await getDropdown();
            const rolesArray = Array.isArray(roles) ? roles : [];
            setDropdownRoles(rolesArray);
            return rolesArray;
        } catch (err) {
            console.error('fetchDropdownRoles error:', err);
            setDropdownRoles([]);
            return [];
        } finally {
            setDropdownLoading(false);
        }
    }, [getDropdown]);

    // Get all roles
    const getRoles = useCallback(async (params) => {
        try {
            console.log('useRole - getRoles called with params:', params);
            const result = await fetchAll(params);
            console.log('useRole - getRoles result:', result);
            return result;
        } catch (err) {
            console.error('useRole - getRoles error:', err);
            throw err;
        }
    }, [fetchAll]);

    // Get single role
    const getRole = useCallback(async (id) => {
        return await fetchOne(id);
    }, [fetchOne]);

    // Create role
    const createRole = useCallback(async (data) => {
        const result = await create(data);
        await fetchAll();
        return result;
    }, [create, fetchAll]);

    // Update role
    const updateRole = useCallback(async (id, data) => {
        const result = await update(id, data);
        await fetchAll();
        return result;
    }, [update, fetchAll]);

    // Delete role
    const deleteRole = useCallback(async (id) => {
        const result = await remove(id);
        await fetchAll();
        return result;
    }, [remove, fetchAll]);

    return {
        // State
        roles: items,
        role: item,
        loading,
        error,
        dropdownRoles,
        dropdownLoading,

        // Actions
        getRoles,
        getRole,
        createRole,
        updateRole,
        deleteRole,
        clearError,
        getDropdownRoles,
        fetchDropdownRoles,
    };
};