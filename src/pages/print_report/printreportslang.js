// src/pages/print_report/printreportslang.js

export const printReportTranslations = {
    en: {
        'report.title': 'Reports & Exports',
        'report.subtitle': 'Generate printable reports and data exports.',
        'report.apply': 'Apply',
        'report.print': 'Print / PDF',
        'report.exportCsv': 'Export CSV',
        'report.exportExcel': 'Export Excel',
        'report.exporting': 'Exporting...',
        'report.searchPlaceholder': 'Search...',
        'report.dateFrom': 'From',
        'report.dateTo': 'To',

        // Table / Print Data
        'report.generatedOn': 'Generated On',
        'report.period': 'Period',
        'report.totalRecords': 'Total Records',
        'report.confidential': 'Confidential - For Management Use Only',
        'report.noRecords': 'No records found for this period.',
        'report.companyName': 'Nearby Fundi',

        // Domains (Dropdown options)
        'report.domain.users': 'Users Directory',
        'report.domain.technicians': 'Technicians',
        'report.domain.requests': 'Service Requests',
        'report.domain.jobs': 'Jobs & Tickets',
        'report.domain.reviews': 'Customer Reviews',
        'report.domain.posts': 'Technician Posts',
    },
    sw: {
        'report.title': 'Ripoti na Mauzo',
        'report.subtitle': 'Tengeneza ripoti za kuchapisha na mauzo ya data.',
        'report.apply': 'Tumia',
        'report.print': 'Chapisha / PDF',
        'report.exportCsv': 'Hamisha CSV',
        'report.exportExcel': 'Hamisha Excel',
        'report.exporting': 'Inahamisha...',
        'report.searchPlaceholder': 'Tafuta...',
        'report.dateFrom': 'Kutoka',
        'report.dateTo': 'Hadi',

        // Table / Print Data
        'report.generatedOn': 'Imetengenezwa Tarehe',
        'report.period': 'Kipindi',
        'report.totalRecords': 'Jumla ya Kumbukumbu',
        'report.confidential': 'Siri - Kwa Matumizi ya Menejimenti Pekee',
        'report.noRecords': 'Hakuna kumbukumbu zilizopatikana kwa kipindi hiki.',
        'report.companyName': 'Nearby Fundi',

        // Domains (Dropdown options)
        'report.domain.users': 'Orodha ya Watumiaji',
        'report.domain.technicians': 'Mafundi',
        'report.domain.requests': 'Maombi ya Huduma',
        'report.domain.jobs': 'Kazi na Tiketi',
        'report.domain.reviews': 'Maoni ya Wateja',
        'report.domain.posts': 'Machapisho ya Mafundi',
    },
};

export function tReport(language, key) {
    return (
        printReportTranslations[language]?.[key] ||
        printReportTranslations.en?.[key] ||
        key
    );
}