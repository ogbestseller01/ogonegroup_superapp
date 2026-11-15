import { createFinanceContext } from './createFinanceContext';
import { financeRequestService } from 'services/financeRequest.service';

export const {
    Provider: FinanceRequestProvider,
    useFinance: useFinanceRequest,
} = createFinanceContext(financeRequestService, 'Requests');