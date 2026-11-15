// src/hooks/usePortfolio.js
import { usePortfolios } from 'context/PortfolioContext';
import { useCallback } from 'react';

export const usePortfolioManagement = () => {
    const {
        items,
        item,
        loading,
        error,
        fetchAll,
        fetchOne,
        create,
        update,
        delete: remove,
        clearError,
    } = usePortfolios();

    const getPortfolios = useCallback(async (params) => {
        return await fetchAll(params);
    }, [fetchAll]);

    const getPortfolio = useCallback(async (id) => {
        return await fetchOne(id);
    }, [fetchOne]);

    const createPortfolio = useCallback(async (data) => {
        return await create(data);
    }, [create]);

    const updatePortfolio = useCallback(async (id, data) => {
        return await update(id, data);
    }, [update]);

    const deletePortfolio = useCallback(async (id) => {
        return await remove(id);
    }, [remove]);

    return {
        portfolios: items,
        portfolio: item,
        loading,
        error,
        getPortfolios,
        getPortfolio,
        createPortfolio,
        updatePortfolio,
        deletePortfolio,
        clearError,
    };
};