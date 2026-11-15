// src/pages/roles/rolelang.js

export const roleTranslations = {
    en: {
        'role.title': 'Roles',
        'role.subtitle': 'Manage system roles and their permissions',
        'role.add': 'Add Role',
        'role.refresh': 'Refresh',
        'role.searchPlaceholder': 'Search roles…',
        'role.accessDenied': 'Access Denied',
        'role.noPermission': 'You do not have permission to view roles.',
        'role.retry': 'Retry',
        'role.loadFailed': 'Failed to load roles',
        'role.noFound': 'No roles found',
        'role.edit': 'Edit',
        'role.assignPermissions': 'Assign Permissions',
        'role.delete': 'Delete',
        'role.cancel': 'Cancel',
        'role.confirm': 'Confirm',
        'role.actionFailed': 'Action failed',
        'role.deleted': 'Role deleted successfully',
        'role.deleteTitle': 'Delete Role',
        'role.deleteMessage': 'Are you sure you want to delete role "{name}"?',
        'role.guard': 'Guard',

        // Table
        'role.col.name': 'Role Name',
        'role.col.displayName': 'Display Name',
        'role.col.description': 'Description',
        'role.col.guard': 'Guard',
        'role.col.actions': 'Actions',

        // Form Modal
        'role.modal.editTitle': 'Edit Role',
        'role.modal.createTitle': 'Add New Role',
        'role.modal.editDesc': 'Update role details below',
        'role.modal.createDesc': 'Create a new role with a unique key',
        'role.modal.name': 'Role Name (key)',
        'role.modal.nameHelp': 'Unique identifier, uppercase e.g. ADMINISTRATOR',
        'role.modal.displayName': 'Display Name',
        'role.modal.description': 'Description',
        'role.modal.guard': 'Guard Name',
        'role.modal.guardHelp': "Usually 'web' or 'api'",
        'role.modal.update': 'Update Role',
        'role.modal.create': 'Create Role',
        'role.modal.updated': 'Role updated successfully',
        'role.modal.created': 'Role created successfully',
        'role.modal.failed': 'Operation failed',

        // Permissions Modal
        'role.perm.title': 'Manage Permissions',
        'role.perm.roleLabel': 'Role',
        'role.perm.search': 'Search permissions…',
        'role.perm.noFound': 'No permissions found',
        'role.perm.loadFailed': 'Failed to load permissions',
        'role.perm.updated': 'Permissions updated successfully',
        'role.perm.failed': 'Failed to sync permissions',
        'role.perm.save': 'Save Changes',
    },
    sw: {
        'role.title': 'Majukumu',
        'role.subtitle': 'Simamia majukumu ya mfumo na ruhusa zake',
        'role.add': 'Ongeza Jukumu',
        'role.refresh': 'Onyesha Upya',
        'role.searchPlaceholder': 'Tafuta majukumu…',
        'role.accessDenied': 'Ufikiaji Umekataliwa',
        'role.noPermission': 'Huna ruhusa ya kuona majukumu.',
        'role.retry': 'Jaribu Tena',
        'role.loadFailed': 'Imeshindwa kupakia majukumu',
        'role.noFound': 'Hakuna majukumu yaliyopatikana',
        'role.edit': 'Hariri',
        'role.assignPermissions': 'Weka Ruhusa',
        'role.delete': 'Futa',
        'role.cancel': 'Ghairi',
        'role.confirm': 'Thibitisha',
        'role.actionFailed': 'Kitendo kimeshindikana',
        'role.deleted': 'Jukumu limefutwa kwa mafanikio',
        'role.deleteTitle': 'Futa Jukumu',
        'role.deleteMessage': 'Una uhakika unataka kufuta jukumu "{name}"?',
        'role.guard': 'Guard',

        // Table
        'role.col.name': 'Jina la Jukumu',
        'role.col.displayName': 'Jina la Onyesho',
        'role.col.description': 'Maelezo',
        'role.col.guard': 'Guard',
        'role.col.actions': 'Vitendo',

        // Form Modal
        'role.modal.editTitle': 'Hariri Jukumu',
        'role.modal.createTitle': 'Ongeza Jukumu Jipya',
        'role.modal.editDesc': 'Sasisha maelezo ya jukumu hapa chini',
        'role.modal.createDesc': 'Unda jukumu jipya lenye ufunguo wa kipekee',
        'role.modal.name': 'Jina la Jukumu (ufunguo)',
        'role.modal.nameHelp': 'Kitambulisho cha kipekee, herufi kubwa mfano ADMINISTRATOR',
        'role.modal.displayName': 'Jina la Onyesho',
        'role.modal.description': 'Maelezo',
        'role.modal.guard': 'Jina la Guard',
        'role.modal.guardHelp': "Kawaida 'web' au 'api'",
        'role.modal.update': 'Sasisha Jukumu',
        'role.modal.create': 'Unda Jukumu',
        'role.modal.updated': 'Jukumu limesasishwa kwa mafanikio',
        'role.modal.created': 'Jukumu limeundwa kwa mafanikio',
        'role.modal.failed': 'Operesheni imeshindikana',

        // Permissions Modal
        'role.perm.title': 'Simamia Ruhusa',
        'role.perm.roleLabel': 'Jukumu',
        'role.perm.search': 'Tafuta ruhusa…',
        'role.perm.noFound': 'Hakuna ruhusa zilizopatikana',
        'role.perm.loadFailed': 'Imeshindwa kupakia ruhusa',
        'role.perm.updated': 'Ruhusa zimesasishwa kwa mafanikio',
        'role.perm.failed': 'Imeshindwa kusawazisha ruhusa',
        'role.perm.save': 'Hifadhi Mabadiliko',
    },
};

export function tRole(language, key) {
    return (
        roleTranslations[language]?.[key] ||
        roleTranslations.en?.[key] ||
        key
    );
}