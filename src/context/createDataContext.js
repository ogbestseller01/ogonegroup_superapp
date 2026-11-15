// src/contexts/createDataContext.js
import React, { createContext, useContext, useReducer, useCallback } from 'react';

// Initial state
const createInitialState = () => ({
    items: [],
    item: null,
    loading: false,
    error: null,
    pagination: {
        total: 0,
        per_page: 10,
        current_page: 1,
        last_page: 1,
    },
});

// Action types
const ACTION_TYPES = {
    SET_LOADING: 'SET_LOADING',
    SET_ERROR: 'SET_ERROR',
    SET_ITEMS: 'SET_ITEMS',
    SET_ITEM: 'SET_ITEM',
    ADD_ITEM: 'ADD_ITEM',
    UPDATE_ITEM: 'UPDATE_ITEM',
    REMOVE_ITEM: 'REMOVE_ITEM',
    CLEAR_ERROR: 'CLEAR_ERROR',
    RESET: 'RESET',
};

// Reducer
const dataReducer = (state, action) => {
    switch (action.type) {
        case ACTION_TYPES.SET_LOADING:
            return { ...state, loading: action.payload };

        case ACTION_TYPES.SET_ERROR:
            return { ...state, error: action.payload, loading: false };

        case ACTION_TYPES.CLEAR_ERROR:
            return { ...state, error: null };

        case ACTION_TYPES.SET_ITEMS:
            return {
                ...state,
                items: action.payload.data || [],
                pagination: action.payload.pagination || state.pagination,
                loading: false,
                error: null,
            };

        case ACTION_TYPES.SET_ITEM:
            return {
                ...state,
                item: action.payload,
                loading: false,
                error: null,
            };

        case ACTION_TYPES.ADD_ITEM:
            return {
                ...state,
                items: [action.payload, ...state.items],
                loading: false,
                error: null,
            };

        case ACTION_TYPES.UPDATE_ITEM:
            return {
                ...state,
                items: state.items.map(item =>
                    item.id === action.payload.id ? action.payload : item
                ),
                item: state.item?.id === action.payload.id ? action.payload : state.item,
                loading: false,
                error: null,
            };

        case ACTION_TYPES.REMOVE_ITEM:
            return {
                ...state,
                items: state.items.filter(item => item.id !== action.payload),
                item: state.item?.id === action.payload ? null : state.item,
                loading: false,
                error: null,
            };

        case ACTION_TYPES.RESET:
            return createInitialState();

        default:
            return state;
    }
};

// Helper to extract data
const extractData = (response, defaultValue = null) => {
    if (!response) return defaultValue;

    if (Array.isArray(response)) return response;

    if (response.data !== undefined) {
        if (Array.isArray(response.data)) return response.data;
        if (response.data.data !== undefined) {
            return Array.isArray(response.data.data) ? response.data.data : response.data.data;
        }
        if (typeof response.data === 'object' && response.data !== null) {
            return response.data;
        }
    }

    if (typeof response === 'object' && response !== null) {
        return response;
    }

    return defaultValue;
};

export function createDataContext(adapter, resourceName) {
    const Context = createContext();

    const Provider = ({ children }) => {
        const [state, dispatch] = useReducer(dataReducer, null, createInitialState);

        // Reset state
        const reset = useCallback(() => {
            dispatch({ type: ACTION_TYPES.RESET });
        }, []);

        // Fetch all items
        const fetchAll = useCallback(async (params = {}) => {
            if (!adapter.getAll) {
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: `${resourceName} getAll not supported`
                });
                return null;
            }

            dispatch({ type: ACTION_TYPES.SET_LOADING, payload: true });

            try {
                const response = await adapter.getAll(params);
                const data = extractData(response, []);

                dispatch({
                    type: ACTION_TYPES.SET_ITEMS,
                    payload: {
                        data: Array.isArray(data) ? data : [data],
                        pagination: state.pagination,
                    }
                });

                return data;
            } catch (error) {
                console.error(`fetchAll error (${resourceName}):`, error);
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: error.message || 'Failed to fetch data'
                });
                return null;
            }
        }, [adapter, resourceName, state.pagination]);

        // Fetch single item
        const fetchOne = useCallback(async (id) => {
            if (!adapter.getOne) {
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: `${resourceName} getOne not supported`
                });
                return null;
            }

            dispatch({ type: ACTION_TYPES.SET_LOADING, payload: true });

            try {
                const response = await adapter.getOne(id);
                const data = extractData(response);

                dispatch({
                    type: ACTION_TYPES.SET_ITEM,
                    payload: data
                });

                return data;
            } catch (error) {
                console.error(`fetchOne error (${resourceName}):`, error);
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: error.message || 'Failed to fetch item'
                });
                return null;
            }
        }, [adapter, resourceName]);

        // Create item
        const create = useCallback(async (data) => {
            if (!adapter.create) {
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: `${resourceName} create not supported`
                });
                return null;
            }

            dispatch({ type: ACTION_TYPES.SET_LOADING, payload: true });

            try {
                const response = await adapter.create(data);
                const newItem = extractData(response);

                dispatch({
                    type: ACTION_TYPES.ADD_ITEM,
                    payload: newItem
                });

                return newItem;
            } catch (error) {
                console.error(`create error (${resourceName}):`, error);
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: error.response?.data?.message || error.message || 'Failed to create'
                });
                throw error;
            }
        }, [adapter, resourceName]);

        // Update item
        const update = useCallback(async (id, data) => {
            if (!adapter.update) {
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: `${resourceName} update not supported`
                });
                return null;
            }

            dispatch({ type: ACTION_TYPES.SET_LOADING, payload: true });

            try {
                const response = await adapter.update(id, data);
                const updatedItem = extractData(response);

                dispatch({
                    type: ACTION_TYPES.UPDATE_ITEM,
                    payload: { id, ...updatedItem }
                });

                return updatedItem;
            } catch (error) {
                console.error(`update error (${resourceName}):`, error);
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: error.response?.data?.message || error.message || 'Failed to update'
                });
                throw error;
            }
        }, [adapter, resourceName]);

        // Delete item
        const deleteItem = useCallback(async (id) => {
            if (!adapter.delete) {
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: `${resourceName} delete not supported`
                });
                return false;
            }

            dispatch({ type: ACTION_TYPES.SET_LOADING, payload: true });

            try {
                const response = await adapter.delete(id);

                const isSuccess = response?.status === 200 ||
                    response?.status === 204 ||
                    response?.data?.status === 'success' ||
                    response?.data?.success === true;

                if (isSuccess) {
                    dispatch({
                        type: ACTION_TYPES.REMOVE_ITEM,
                        payload: id
                    });
                    return true;
                }

                throw new Error(response?.data?.message || 'Failed to delete');
            } catch (error) {
                console.error(`delete error (${resourceName}):`, error);
                dispatch({
                    type: ACTION_TYPES.SET_ERROR,
                    payload: error.response?.data?.message || error.message || 'Failed to delete'
                });
                return false;
            }
        }, [adapter, resourceName]);

        // Get dropdown
        const getDropdown = useCallback(async (params = {}) => {
            if (!adapter.getDropdown) {
                console.warn(`${resourceName} getDropdown not supported`);
                return [];
            }

            try {
                const response = await adapter.getDropdown(params);
                const data = extractData(response, []);
                return Array.isArray(data) ? data : [data];
            } catch (error) {
                console.error(`getDropdown error (${resourceName}):`, error);
                return [];
            }
        }, [adapter, resourceName]);

        // Clear error
        const clearError = useCallback(() => {
            dispatch({ type: ACTION_TYPES.CLEAR_ERROR });
        }, []);

        // Context value
        const value = {
            // State
            items: state.items,
            item: state.item,
            loading: state.loading,
            error: state.error,
            pagination: state.pagination,

            // Actions
            fetchAll,
            fetchOne,
            create,
            update,
            delete: deleteItem,
            getDropdown,
            clearError,
            reset,
        };

        return <Context.Provider value={value}>{children}</Context.Provider>;
    };

    // Custom hook
    const useResource = () => {
        const context = useContext(Context);
        if (!context) {
            throw new Error(`use${resourceName} must be used within a ${resourceName}Provider`);
        }
        return context;
    };

    return { Provider, useResource };
}