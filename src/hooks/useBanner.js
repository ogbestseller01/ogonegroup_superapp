import { useCallback } from 'react';
import { useBanners } from 'context/BannerContext';
import { bannerService } from 'services/banner.service';

export const useBannerManagement = () => {
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
    } = useBanners();

    const getBanners = useCallback(async (params) => {
        return await fetchAll(params);
    }, [fetchAll]);

    const getBanner = useCallback(async (id) => {
        return await fetchOne(id);
    }, [fetchOne]);

    const createBanner = useCallback(async (formData) => {
        const result = await create(formData);
        await fetchAll();
        return result;
    }, [create, fetchAll]);

    const updateBanner = useCallback(async (id, formData) => {
        const result = await update(id, formData);
        await fetchAll();
        return result;
    }, [update, fetchAll]);

    const deleteBanner = useCallback(async (id) => {
        const result = await remove(id);
        await fetchAll();
        return result;
    }, [remove, fetchAll]);

    const updateStatus = useCallback(async (id, status) => {
        const result = await bannerService.updateStatus(id, status);
        await fetchAll();
        return result;
    }, [fetchAll]);

    return {
        banners: items,
        banner: item,
        loading,
        error,
        getBanners,
        getBanner,
        createBanner,
        updateBanner,
        deleteBanner,
        updateStatus,
        clearError,
    };
};