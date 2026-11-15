// src/pages/services/serviceslang.js

export const servicesTranslations = {
    en: {
        // ── Common ────────────────────────────────────────────────
        'service.common.refresh': 'Refresh',
        'service.common.cancel': 'Cancel',
        'service.common.close': 'Close',
        'service.common.confirm': 'Confirm',
        'service.common.retry': 'Retry',
        'service.common.edit': 'Edit',
        'service.common.delete': 'Delete',
        'service.common.create': 'Create',
        'service.common.update': 'Update',
        'service.common.na': 'N/A',
        'service.common.unknown': 'Unknown',
        'service.common.unknownArea': 'Unknown area',
        'service.common.yes': 'Yes',
        'service.common.no': 'No',

        // ── Statuses ──────────────────────────────────────────────
        'service.status.verified': 'Verified',

        // ── Access ────────────────────────────────────────────────
        'service.accessDenied': 'You do not have permission to view services.',

        // ── ServicesList ──────────────────────────────────────────
        'service.list.title': 'Service Management',
        'service.list.subtitle': 'Manage service categories and technician assignments',
        'service.list.addService': 'Add Service',
        'service.list.searchPlaceholder': 'Search services...',
        'service.list.noMatch': 'No services match your search',
        'service.list.noFound': 'No categories or services found',
        'service.list.clearSearch': 'Clear Search',
        'service.list.loadFailed': 'Failed to load services',
        'service.list.loadDetailsFailed': 'Failed to load service details',
        'service.list.deleteSuccess': 'Service deleted successfully',
        'service.list.deleteFailed': 'Failed to delete service',
        'service.list.servicesCount': '{n} services',
        'service.list.techniciansCount': '{n} technician{s}',
        'service.list.viewTechnicians': 'View Technicians',

        // Stats
        'service.list.stat.totalServices': 'Total Services',
        'service.list.stat.categories': 'Categories',
        'service.list.stat.technicians': 'Technicians',

        // Delete confirm
        'service.delete.title': 'Delete Service',
        'service.delete.message': 'Are you sure you want to delete "{name}"? This action cannot be undone.',

        // ── ServiceFormModal ──────────────────────────────────────
        'service.form.editTitle': 'Edit Service',
        'service.form.createTitle': 'Add New Service',
        'service.form.nameEnLabel': 'Service Name (English)',
        'service.form.nameEnPlaceholder': 'e.g., TV Repair, Plumbing, AC Service',
        'service.form.nameEnHelper': 'Enter the service name (e.g., TV Repair, Plumbing)',
        'service.form.nameSwLabel': 'Service Name (Swahili)',
        'service.form.nameSwPlaceholder': 'e.g., Ukarabati wa TV, Mabomba',
        'service.form.categoriesLabel': 'Categories',
        'service.form.nameRequired': 'Service name is required',
        'service.form.nameTooShort': 'Service name must be at least 3 characters',
        'service.form.nameDuplicate': 'This service name already exists',
        'service.form.updated': 'Service updated successfully',
        'service.form.created': 'Service created successfully',
        'service.form.operationFailed': 'Operation failed',

        // ── TechniciansModal ──────────────────────────────────────
        'service.tech.title': 'Technicians for',
        'service.tech.fallbackService': 'Service',
        'service.tech.loadingFailed': 'Failed to load technicians. Please try again later.',
        'service.tech.none': 'No technicians assigned to this service.',
        'service.tech.yearsExperience': '{n} years experience',
    },

    sw: {
        // ── Common ────────────────────────────────────────────────
        'service.common.refresh': 'Onyesha Upya',
        'service.common.cancel': 'Ghairi',
        'service.common.close': 'Funga',
        'service.common.confirm': 'Thibitisha',
        'service.common.retry': 'Jaribu Tena',
        'service.common.edit': 'Hariri',
        'service.common.delete': 'Futa',
        'service.common.create': 'Unda',
        'service.common.update': 'Sasisha',
        'service.common.na': 'Hakuna',
        'service.common.unknown': 'Haijulikani',
        'service.common.unknownArea': 'Eneo lisilojulikana',
        'service.common.yes': 'Ndiyo',
        'service.common.no': 'Hapana',

        // ── Statuses ──────────────────────────────────────────────
        'service.status.verified': 'Imethibitishwa',

        // ── Access ────────────────────────────────────────────────
        'service.accessDenied': 'Huna ruhusa kuona huduma.',

        // ── ServicesList ──────────────────────────────────────────
        'service.list.title': 'Usimamizi wa Huduma',
        'service.list.subtitle': 'Simamia kategoria za huduma na ugawaji wa mafundi',
        'service.list.addService': 'Ongeza Huduma',
        'service.list.searchPlaceholder': 'Tafuta huduma...',
        'service.list.noMatch': 'Hakuna huduma zinazolingana na utafutaji wako',
        'service.list.noFound': 'Hakuna kategoria au huduma zilizopatikana',
        'service.list.clearSearch': 'Safisha Utafutaji',
        'service.list.loadFailed': 'Imeshindwa kupakia huduma',
        'service.list.loadDetailsFailed': 'Imeshindwa kupakia maelezo ya huduma',
        'service.list.deleteSuccess': 'Huduma imefutwa kwa mafanikio',
        'service.list.deleteFailed': 'Imeshindwa kufuta huduma',
        'service.list.servicesCount': 'huduma {n}',
        'service.list.techniciansCount': 'mafundi {n}',
        'service.list.viewTechnicians': 'Ona Mafundi',

        // Stats
        'service.list.stat.totalServices': 'Jumla ya Huduma',
        'service.list.stat.categories': 'Kategoria',
        'service.list.stat.technicians': 'Mafundi',

        // Delete confirm
        'service.delete.title': 'Futa Huduma',
        'service.delete.message': 'Una uhakika unataka kufuta "{name}"? Kitendo hiki hakiwezi kutenduliwa.',

        // ── ServiceFormModal ──────────────────────────────────────
        'service.form.editTitle': 'Hariri Huduma',
        'service.form.createTitle': 'Ongeza Huduma Mpya',
        'service.form.nameEnLabel': 'Jina la Huduma (Kiingereza)',
        'service.form.nameEnPlaceholder': 'k.m., Ukarabati wa TV, Mabomba, Huduma ya AC',
        'service.form.nameEnHelper': 'Weka jina la huduma (k.m., Ukarabati wa TV, Mabomba)',
        'service.form.nameSwLabel': 'Jina la Huduma (Kiswahili)',
        'service.form.nameSwPlaceholder': 'k.m., Ukarabati wa TV, Mabomba',
        'service.form.categoriesLabel': 'Kategoria',
        'service.form.nameRequired': 'Jina la huduma linahitajika',
        'service.form.nameTooShort': 'Jina la huduma lazima liwe na angalau herufi 3',
        'service.form.nameDuplicate': 'Jina hili la huduma tayari lipo',
        'service.form.updated': 'Huduma imesasishwa kwa mafanikio',
        'service.form.created': 'Huduma imeundwa kwa mafanikio',
        'service.form.operationFailed': 'Operesheni imeshindikana',

        // ── TechniciansModal ──────────────────────────────────────
        'service.tech.title': 'Mafundi wa',
        'service.tech.fallbackService': 'Huduma',
        'service.tech.loadingFailed': 'Imeshindwa kupakia mafundi. Tafadhali jaribu tena baadaye.',
        'service.tech.none': 'Hakuna mafundi waliopangiwa huduma hii.',
        'service.tech.yearsExperience': 'uzoefu wa miaka {n}',
    },
};

export function tService(language, key, replacements) {
    let str =
        servicesTranslations[language]?.[key] ||
        servicesTranslations.en?.[key] ||
        key;
    if (replacements) {
        Object.entries(replacements).forEach(([k, v]) => {
            str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
        });
    }
    return str;
}