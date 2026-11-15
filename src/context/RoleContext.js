// src/contexts/RoleContext.js
import { createDataContext } from './createDataContext';
import { roleService } from 'services/role.service';

const adapter = {
    getAll: async (params) => {
        try {
            console.log('Fetching roles with params:', params);
            const response = await roleService.getRoles(params);
            console.log('Roles API response:', response);

            // The API returns { status: "success", message: "Success", data: { current_page: 1, data: [...], ... } }
            if (response?.data?.status === 'success') {
                const data = response.data.data;
                // If it's paginated, data.data contains the array
                if (data && data.data) {
                    return {
                        data: data.data,
                        pagination: {
                            total: data.total,
                            per_page: data.per_page,
                            current_page: data.current_page,
                            last_page: data.last_page,
                        }
                    };
                }
                // If it's a direct array
                if (Array.isArray(data)) {
                    return { data: data };
                }
                return { data: [] };
            }
            // If response is not in expected format
            if (response?.data?.data && Array.isArray(response.data.data)) {
                return { data: response.data.data };
            }
            return { data: [] };
        } catch (error) {
            console.error('Roles API error:', error);
            // Return empty data instead of throwing to avoid breaking UI
            return { data: [] };
        }
    },
    getOne: async (id) => {
        try {
            const response = await roleService.getRole(id);
            if (response?.data?.status === 'success') {
                return { data: response.data.data };
            }
            return { data: null };
        } catch (error) {
            console.error('Role API error:', error);
            return { data: null };
        }
    },
    create: (data) => roleService.createRole(data),
    update: (id, data) => roleService.updateRole(id, data),
    delete: (id) => roleService.deleteRole(id),
    getDropdown: () => roleService.getRolesDropdown(),
};

export const { Provider: RoleProvider, useResource: useRoles } = createDataContext(adapter, 'Role');