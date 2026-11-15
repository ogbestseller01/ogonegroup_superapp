// src/contexts/UserContext.js
import { createDataContext } from './createDataContext';
import { userService } from 'services/user.service';

const adapter = {
  getAll: async (params) => {
    try {
      const response = await userService.getUsers(params);

      // Handle the API response structure
      if (response?.data?.status === 'success') {
        const data = response.data.data;

        // If data has a data property (paginated response), use it
        if (data && data.data) {
          return {
            data: data.data,
            pagination: data.pagination || {
              total: data.total || data.data.length,
              per_page: data.per_page || 20,
              current_page: data.current_page || 1,
              last_page: data.last_page || 1,
            }
          };
        }

        // If data is directly the array
        if (Array.isArray(data)) {
          return {
            data: data,
            pagination: {
              total: data.length,
              per_page: 20,
              current_page: 1,
              last_page: 1,
            }
          };
        }

        // If data is an object with items
        if (data && data.items) {
          return {
            data: data.items,
            pagination: {
              total: data.total || data.items.length,
              per_page: data.per_page || 20,
              current_page: data.current_page || 1,
              last_page: data.last_page || 1,
            }
          };
        }
      }

      // Fallback: return empty array
      return { data: [], pagination: { total: 0, per_page: 20, current_page: 1, last_page: 1 } };
    } catch (error) {
      console.error('Error fetching users:', error);
      throw error;
    }
  },
  getOne: (id) => userService.getUser(id),
  create: (data) => userService.createUser(data),
  update: (id, data) => userService.updateUser(id, data),
  delete: (id) => userService.deleteUser(id),
  getDropdown: (params) => userService.getUsersDropdown(params),
};

export const { Provider: UserProvider, useResource: useUsers } = createDataContext(adapter, 'User');