// src/hooks/useTableFilters.js
import { useState, useCallback } from 'react';

export const useTableFilters = (initialFilters = {}) => {
    const [filters, setFilters] = useState({
        page: 1,
        limit: 15,
        search: '',
        sort_by: 'created_at',
        sort_order: 'desc',
        ...initialFilters,
    });

    const updateFilter = useCallback((key, value) => {
        setFilters(prev => ({ ...prev, [key]: value }));
    }, []);

    const resetFilters = useCallback(() => {
        setFilters({
            page: 1,
            limit: 15,
            search: '',
            sort_by: 'created_at',
            sort_order: 'desc',
        });
    }, []);

    const setPage = useCallback((page) => {
        setFilters(prev => ({ ...prev, page }));
    }, []);

    const setSearch = useCallback((search) => {
        setFilters(prev => ({ ...prev, search, page: 1 }));
    }, []);

    const setSort = useCallback((sort_by, sort_order) => {
        setFilters(prev => ({ ...prev, sort_by, sort_order }));
    }, []);

    const getQueryParams = useCallback(() => {
        const params = {};
        Object.entries(filters).forEach(([key, value]) => {
            if (value !== '' && value !== undefined && value !== null) {
                params[key] = value;
            }
        });
        return params;
    }, [filters]);

    return {
        filters,
        updateFilter,
        resetFilters,
        setPage,
        setSearch,
        setSort,
        getQueryParams,
    };
};