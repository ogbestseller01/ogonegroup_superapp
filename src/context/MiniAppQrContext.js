import { createDataContext } from './createDataContext';
import { miniAppQrService } from 'services/miniAppQr.service';

const isOk = (res) => res?.data?.status === 'success' || res?.data?.success === true;

const adapter = {
    getAll: async (params) => {
        const response = await miniAppQrService.getQrs(params);
        if (isOk(response)) {
            const data = response.data.data;
            if (data && Array.isArray(data.data)) {
                return {
                    data: data.data,
                    pagination: {
                        total: data.total,
                        per_page: data.per_page,
                        current_page: data.current_page,
                        last_page: data.last_page,
                    },
                };
            }
            return { data: Array.isArray(data) ? data : [data] };
        }
        return { data: [] };
    },
    getOne: async (id) => {
        const response = await miniAppQrService.getQr(id);
        return isOk(response) ? response.data.data : null;
    },
    create: (data) => miniAppQrService.createQr(data),
    update: (id, data) => miniAppQrService.updateQr(id, data),
    delete: (id) => miniAppQrService.deleteQr(id),
};

export const { Provider: MiniAppQrProvider, useResource: useMiniAppQrs } =
    createDataContext(adapter, 'MiniAppQr');