import { createDataContext } from './createDataContext';
import { bannerService } from 'services/banner.service';

const adapter = {
    getAll: async (params) => {
        const response = await bannerService.getBanners(params);
        const body = response?.data;

        if (body?.status === 'success' || body?.success === true) {
            const data = body.data;
            if (data?.data) {
                return {
                    data: data.data,
                    pagination: data.pagination || {
                        total: data.total || data.data.length,
                        per_page: data.per_page || 20,
                        current_page: data.current_page || 1,
                        last_page: data.last_page || 1,
                    },
                };
            }
            if (Array.isArray(data)) {
                return {
                    data,
                    pagination: { total: data.length, per_page: 20, current_page: 1, last_page: 1 },
                };
            }
        }
        return { data: [], pagination: { total: 0, per_page: 20, current_page: 1, last_page: 1 } };
    },
    getOne: (id) => bannerService.getBanner(id),
    create: (data) => bannerService.createBanner(data),
    update: (id, data) => bannerService.updateBanner(id, data),
    delete: (id) => bannerService.deleteBanner(id),
};

export const { Provider: BannerProvider, useResource: useBanners } =
    createDataContext(adapter, 'Banner');