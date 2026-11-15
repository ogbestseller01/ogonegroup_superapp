import { createFinanceContext } from './createFinanceContext';
import { financeCustomerService } from 'services/financeCustomer.service';

export const { Provider: FinanceCustomerProvider, useFinance: useFinanceCustomer } =
    createFinanceContext(financeCustomerService, 'Customers');