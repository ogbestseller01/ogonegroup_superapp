// src/context/PrintReportContext.js
import { createDataContext } from './createDataContext';
import { printReportService } from 'services/printReport.service';

const adapter = {
    getAll:  (params) => printReportService.getReport(params),
    getOne:  () => Promise.resolve({ data: null }),
    create:  () => Promise.resolve({ data: null }),
    update:  () => Promise.resolve({ data: null }),
    delete:  () => Promise.resolve({ data: null }),
};

export const { Provider: PrintReportProvider, useResource: usePrintReports } =
    createDataContext(adapter, 'PrintReport');