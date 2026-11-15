import { createFinanceContext } from './createFinanceContext';
import { financeTechnicianService } from 'services/financeTechnician.service';

export const { Provider: FinanceTechnicianProvider, useFinance: useFinanceTechnician } =
    createFinanceContext(financeTechnicianService, 'Technicians');