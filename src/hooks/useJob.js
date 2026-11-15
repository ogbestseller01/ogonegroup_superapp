// src/hooks/useJob.js
import { useCallback } from 'react';
import { useJobs } from 'context/JobContext';
import { jobService } from 'services/job.service';

export const useJobManagement = () => {
    const {
        items, item, loading, error,
        fetchAll, fetchOne, clearError,
    } = useJobs();

    const getJobs = useCallback((params) => fetchAll(params), [fetchAll]);
    const getJob  = useCallback((id)     => fetchOne(id),    [fetchOne]);

    const getStats = useCallback(async (params = {}) => {
        const res = await jobService.getJobStats(params);
        return res?.data?.data ?? res?.data ?? {};
    }, []);

    const requestCompletion = useCallback(async (id) => {
        const res = await jobService.requestCompletion(id);
        return res?.data;
    }, []);

    const verifyCompletion = useCallback(async (id, otp) => {
        const res = await jobService.verifyCompletion(id, otp);
        await fetchAll();
        return res?.data;
    }, [fetchAll]);

    const reviewJob = useCallback(async (id, payload) => {
        const res = await jobService.reviewJob(id, payload);
        await fetchAll();
        return res?.data;
    }, [fetchAll]);

    return {
        jobs: items,
        job: item,
        loading,
        error,
        getJobs,
        getJob,
        getStats,
        requestCompletion,
        verifyCompletion,
        reviewJob,
        clearError,
    };
};