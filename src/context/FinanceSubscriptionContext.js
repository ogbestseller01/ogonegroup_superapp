import { createFinanceContext } from './createFinanceContext';
import { financeSubscriptionService } from 'services/financeSubscription.service';

export const { Provider: FinanceSubscriptionProvider, useFinance: useFinanceSubscription } =
    createFinanceContext(financeSubscriptionService, 'Subscriptions');