// src/contexts/PortfolioContext.js
import { createDataContext } from './createDataContext';
import { portfolioService } from 'services/portfolio.service';

const DEFAULT_PAGINATION = { total: 0, per_page: 10, current_page: 1, last_page: 1 };

const adapter = {
    getAll: async (params) => {
        const response = await portfolioService.getPortfolios(params);
        const body = response?.data;

        if (body?.status !== 'success') {
            return { data: [], pagination: DEFAULT_PAGINATION };
        }

        const payload = body.data;

        if (payload && Array.isArray(payload.data)) {
            return {
                data: payload.data,
                pagination: payload.pagination || {
                    total: payload.data.length,
                    per_page: params?.per_page ?? 10,
                    current_page: params?.page ?? 1,
                    last_page: 1,
                },
            };
        }

        const arr = Array.isArray(payload) ? payload : [];
        return { data: arr, pagination: { ...DEFAULT_PAGINATION, total: arr.length } };
    },
    getOne: null,
    create: (data) => portfolioService.createPortfolio(data),
    update: (id, data) => portfolioService.updatePortfolio(id, data),
    delete: (id) => portfolioService.deletePortfolio(id),
};

export const {
    Provider: PortfolioProvider,
    useResource: usePortfolios,
} = createDataContext(adapter, 'Portfolio');