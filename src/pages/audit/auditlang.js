// src/pages/audit/auditlang.js

export const auditTranslations = {
    en: {
        'audit.title': 'Audit Trails',
        'audit.subtitle': 'Track every action performed in the system',
        'audit.accessDenied': 'Access Denied',
        'audit.noPermission': 'You do not have permission to view audit trails.',
        'audit.retry': 'Retry',
        'audit.loadFailed': 'Failed to load audit trails',
        'audit.noRecords': 'No audit records found',
        'audit.refresh': 'Refresh',
        'audit.viewDetails': 'View Details',
        'audit.noData': 'No data',
        'audit.unknown': 'Unknown',
        'audit.noEmail': 'No email',
        'audit.noDescription': 'No description',
        'audit.close': 'Close',

        // Stats
        'audit.stats.total': 'Total Records',
        'audit.stats.today': 'Today',
        'audit.stats.thisWeek': 'This Week',
        'audit.stats.topUsers': 'Top Users',

        // Filters
        'audit.filter.search': 'Search…',
        'audit.filter.module': 'Module',
        'audit.filter.action': 'Action',
        'audit.filter.from': 'From',
        'audit.filter.to': 'To',
        'audit.filter.allModules': 'All Modules',
        'audit.filter.allActions': 'All Actions',

        // Table
        'audit.col.dateTime': 'Date & Time',
        'audit.col.user': 'User',
        'audit.col.action': 'Action',
        'audit.col.module': 'Module',
        'audit.col.description': 'Description',
        'audit.col.ip': 'IP',
        'audit.col.method': 'Method',
        'audit.col.actions': 'Actions',

        // Modal
        'audit.modal.title': 'Audit Trail Details',
        'audit.modal.subtitle': 'Full record information',
        'audit.modal.dateTime': 'Date & Time',
        'audit.modal.user': 'User',
        'audit.modal.role': 'Role',
        'audit.modal.action': 'Action',
        'audit.modal.module': 'Module',
        'audit.modal.description': 'Description',
        'audit.modal.ip': 'IP Address',
        'audit.modal.method': 'Request Method',
        'audit.modal.url': 'Request URL',
        'audit.modal.userAgent': 'User Agent',
        'audit.modal.oldData': 'Old Data',
        'audit.modal.newData': 'New Data',
    },
    sw: {
        'audit.title': 'Rekodi za Ukaguzi',
        'audit.subtitle': 'Fuatilia kila kitendo kilichofanywa kwenye mfumo',
        'audit.accessDenied': 'Ufikiaji Umekataliwa',
        'audit.noPermission': 'Huna ruhusa ya kuona rekodi za ukaguzi.',
        'audit.retry': 'Jaribu Tena',
        'audit.loadFailed': 'Imeshindwa kupakia rekodi za ukaguzi',
        'audit.noRecords': 'Hakuna rekodi za ukaguzi zilizopatikana',
        'audit.refresh': 'Onyesha Upya',
        'audit.viewDetails': 'Tazama Maelezo',
        'audit.noData': 'Hakuna data',
        'audit.unknown': 'Haijulikani',
        'audit.noEmail': 'Hakuna barua pepe',
        'audit.noDescription': 'Hakuna maelezo',
        'audit.close': 'Funga',

        // Stats
        'audit.stats.total': 'Jumla ya Rekodi',
        'audit.stats.today': 'Leo',
        'audit.stats.thisWeek': 'Wiki Hii',
        'audit.stats.topUsers': 'Watumiaji Wakuu',

        // Filters
        'audit.filter.search': 'Tafuta…',
        'audit.filter.module': 'Moduli',
        'audit.filter.action': 'Kitendo',
        'audit.filter.from': 'Kuanzia',
        'audit.filter.to': 'Hadi',
        'audit.filter.allModules': 'Moduli Zote',
        'audit.filter.allActions': 'Vitendo Vyote',

        // Table
        'audit.col.dateTime': 'Tarehe na Saa',
        'audit.col.user': 'Mtumiaji',
        'audit.col.action': 'Kitendo',
        'audit.col.module': 'Moduli',
        'audit.col.description': 'Maelezo',
        'audit.col.ip': 'IP',
        'audit.col.method': 'Mbinu',
        'audit.col.actions': 'Vitendo',

        // Modal
        'audit.modal.title': 'Maelezo ya Rekodi ya Ukaguzi',
        'audit.modal.subtitle': 'Taarifa kamili za rekodi',
        'audit.modal.dateTime': 'Tarehe na Saa',
        'audit.modal.user': 'Mtumiaji',
        'audit.modal.role': 'Wajibu',
        'audit.modal.action': 'Kitendo',
        'audit.modal.module': 'Moduli',
        'audit.modal.description': 'Maelezo',
        'audit.modal.ip': 'Anwani ya IP',
        'audit.modal.method': 'Mbinu ya Ombi',
        'audit.modal.url': 'URL ya Ombi',
        'audit.modal.userAgent': 'User Agent',
        'audit.modal.oldData': 'Data ya Zamani',
        'audit.modal.newData': 'Data Mpya',
    },
};

export function tAudit(language, key) {
    return (
        auditTranslations[language]?.[key] ||
        auditTranslations.en?.[key] ||
        key
    );
}