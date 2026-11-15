// src/contexts/RequestContext.js
import { createDataContext } from './createDataContext';
import { requestService } from 'services/request.service';

const adapter = {
    getAll: (params) => requestService.getRequests(params), // Now uses /v4/admin/requests
    getOne: (id) => requestService.getRequest(id),
    create: (data) => requestService.createRequest(data),
    update: (id, data) => requestService.updateRequestStatus(id, data.status),
    delete: (id) => requestService.deleteRequest(id),
};

export const { Provider: RequestProvider, useResource: useRequests } = createDataContext(adapter, 'Request');