// src/context/JobContext.js
import { createDataContext } from './createDataContext';
import { jobService } from 'services/job.service';

const adapter = {
    getAll: (params)       => jobService.getJobs(params),
    getOne: (id)           => jobService.getJob(id),
    create: (payload)      => jobService.requestCompletion(payload?.id),
    update: (id, payload)  => jobService.verifyCompletion(id, payload?.otp),
    delete: (_id)          => Promise.resolve({ data: null }),
};

export const { Provider: JobProvider, useResource: useJobs } =
    createDataContext(adapter, 'Job');