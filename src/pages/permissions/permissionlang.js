// src/pages/permissions/permissionlang.js

export const permissionTranslations = {
    en: {
        'perm.title': 'Permissions',
        'perm.subtitle': 'Manage system permissions and access keys',
        'perm.add': 'Add Permission',
        'perm.refresh': 'Refresh',
        'perm.searchPlaceholder': 'Search permissions…',
        'perm.accessDenied': 'Access Denied',
        'perm.noPermission': 'You do not have permission to view permissions.',
        'perm.retry': 'Retry',
        'perm.loadFailed': 'Failed to load permissions',
        'perm.noFound': 'No permissions found',
        'perm.edit': 'Edit',
        'perm.cancel': 'Cancel',
        'perm.confirm': 'Confirm',
        'perm.actionFailed': 'Action failed',

        // Table
        'perm.col.key': 'Permission Key',
        'perm.col.displayName': 'Display Name',
        'perm.col.description': 'Description',
        'perm.col.guard': 'Guard',
        'perm.col.actions': 'Actions',
        'perm.guard': 'Guard',

        // Modal
        'perm.modal.editTitle': 'Edit Permission',
        'perm.modal.createTitle': 'Add New Permission',
        'perm.modal.editDesc': 'Update permission details below',
        'perm.modal.createDesc': 'Create a new permission with a unique key',
        'perm.modal.name': 'Permission Name (key)',
        'perm.modal.nameHelp': 'Unique identifier, e.g. users.view',
        'perm.modal.displayName': 'Display Name',
        'perm.modal.description': 'Description',
        'perm.modal.guard': 'Guard Name',
        'perm.modal.guardHelp': "Usually 'web' or 'api'",
        'perm.modal.update': 'Update Permission',
        'perm.modal.create': 'Create Permission',
        'perm.modal.updated': 'Permission updated successfully',
        'perm.modal.created': 'Permission created successfully',
        'perm.modal.failed': 'Operation failed',
    },
    sw: {
        'perm.title': 'Ruhusa',
        'perm.subtitle': 'Simamia ruhusa za mfumo na funguo za ufikiaji',
        'perm.add': 'Ongeza Ruhusa',
        'perm.refresh': 'Onyesha Upya',
        'perm.searchPlaceholder': 'Tafuta ruhusa…',
        'perm.accessDenied': 'Ufikiaji Umekataliwa',
        'perm.noPermission': 'Huna ruhusa ya kuona ruhusa.',
        'perm.retry': 'Jaribu Tena',
        'perm.loadFailed': 'Imeshindwa kupakia ruhusa',
        'perm.noFound': 'Hakuna ruhusa zilizopatikana',
        'perm.edit': 'Hariri',
        'perm.cancel': 'Ghairi',
        'perm.confirm': 'Thibitisha',
        'perm.actionFailed': 'Kitendo kimeshindikana',

        // Table
        'perm.col.key': 'Ufunguo wa Ruhusa',
        'perm.col.displayName': 'Jina la Onyesho',
        'perm.col.description': 'Maelezo',
        'perm.col.guard': 'Guard',
        'perm.col.actions': 'Vitendo',
        'perm.guard': 'Guard',

        // Modal
        'perm.modal.editTitle': 'Hariri Ruhusa',
        'perm.modal.createTitle': 'Ongeza Ruhusa Mpya',
        'perm.modal.editDesc': 'Sasisha maelezo ya ruhusa hapa chini',
        'perm.modal.createDesc': 'Unda ruhusa mpya yenye ufunguo wa kipekee',
        'perm.modal.name': 'Jina la Ruhusa (ufunguo)',
        'perm.modal.nameHelp': 'Kitambulisho cha kipekee, mfano users.view',
        'perm.modal.displayName': 'Jina la Onyesho',
        'perm.modal.description': 'Maelezo',
        'perm.modal.guard': 'Jina la Guard',
        'perm.modal.guardHelp': "Kawaida 'web' au 'api'",
        'perm.modal.update': 'Sasisha Ruhusa',
        'perm.modal.create': 'Unda Ruhusa',
        'perm.modal.updated': 'Ruhusa imesasishwa kwa mafanikio',
        'perm.modal.created': 'Ruhusa imeundwa kwa mafanikio',
        'perm.modal.failed': 'Operesheni imeshindikana',
    },
};

export function tPerm(language, key) {
    return (
        permissionTranslations[language]?.[key] ||
        permissionTranslations.en?.[key] ||
        key
    );
}