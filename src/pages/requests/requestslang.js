// src/pages/requests/requestslang.js

export const requestsTranslations = {
    en: {
        // ── Common ────────────────────────────────────────────────
        'req.common.refresh': 'Refresh',
        'req.common.cancel': 'Cancel',
        'req.common.confirm': 'Confirm',
        'req.common.close': 'Close',
        'req.common.view': 'View',
        'req.common.delete': 'Delete',
        'req.common.none': 'N/A',
        'req.common.unknown': 'Unknown',
        'req.common.notAssigned': 'Not Assigned',
        'req.common.system': 'System',
        'req.common.all': 'All',

        // ── Statuses ──────────────────────────────────────────────
        'req.status.pending': 'Pending',
        'req.status.accepted': 'Accepted',
        'req.status.rejected': 'Rejected',
        'req.status.cancelled': 'Cancelled',
        'req.status.in_progress': 'In Progress',
        'req.status.completed': 'Completed',

        // ── Access ────────────────────────────────────────────────
        'req.accessDenied': 'You do not have permission to view requests.',

        // ── Filters ───────────────────────────────────────────────
        'req.filter.status': 'Status',
        'req.filter.searchPlaceholder': 'Search requests...',

        // ── Stats ─────────────────────────────────────────────────
        'req.stats.total': 'Total Requests',
        'req.stats.pending': 'Pending',
        'req.stats.inProgress': 'In Progress',
        'req.stats.completed': 'Completed',

        // ── Table ─────────────────────────────────────────────────
        'req.table.title': 'Service Requests',
        'req.table.col.customer': 'Customer',
        'req.table.col.technician': 'Technician',
        'req.table.col.service': 'Service',
        'req.table.col.status': 'Status',
        'req.table.col.created': 'Created',
        'req.table.col.actions': 'Actions',
        'req.table.viewTooltip': 'View Request',
        'req.table.deleteTooltip': 'Delete Request',
        'req.table.noFound': 'No requests found',

        // ── Detail Dialog ─────────────────────────────────────────
        'req.dialog.title': 'Request Details',
        'req.dialog.description': 'Description',
        'req.dialog.noDescription': 'No description provided',
        'req.dialog.customerInfo': 'Customer Information',
        'req.dialog.technicianInfo': 'Technician Information',
        'req.dialog.customerId': 'Customer ID: {id}',
        'req.dialog.technicianId': 'Technician ID: {id}',
        'req.dialog.activityLog': 'Activity Log',
        'req.dialog.byUser': 'by {name}',
        'req.dialog.scheduleInfo': 'Schedule Information',
        'req.dialog.scheduleDate': 'Date:',
        'req.dialog.scheduleTime': 'Time:',
        'req.dialog.close': 'Close',

        // ── Delete Confirm ────────────────────────────────────────
        'req.delete.title': 'Delete Request',
        'req.delete.message': 'Are you sure you want to delete this request?',

        // ── Toasts ────────────────────────────────────────────────
        'req.toast.loadFailed': 'Failed to load requests',
        'req.toast.deleteSuccess': 'Request deleted successfully',
        'req.toast.deleteFailed': 'Failed to delete request',
    },

    sw: {
        // ── Common ────────────────────────────────────────────────
        'req.common.refresh': 'Onyesha Upya',
        'req.common.cancel': 'Ghairi',
        'req.common.confirm': 'Thibitisha',
        'req.common.close': 'Funga',
        'req.common.view': 'Ona',
        'req.common.delete': 'Futa',
        'req.common.none': 'Hakuna',
        'req.common.unknown': 'Haijulikani',
        'req.common.notAssigned': 'Hajapangiwa',
        'req.common.system': 'Mfumo',
        'req.common.all': 'Zote',

        // ── Statuses ──────────────────────────────────────────────
        'req.status.pending': 'Inasubiri',
        'req.status.accepted': 'Imekubaliwa',
        'req.status.rejected': 'Imekataliwa',
        'req.status.cancelled': 'Imefutwa',
        'req.status.in_progress': 'Inaendelea',
        'req.status.completed': 'Imekamilika',

        // ── Access ────────────────────────────────────────────────
        'req.accessDenied': 'Huna ruhusa kuona maombi.',

        // ── Filters ───────────────────────────────────────────────
        'req.filter.status': 'Hali',
        'req.filter.searchPlaceholder': 'Tafuta maombi...',

        // ── Stats ─────────────────────────────────────────────────
        'req.stats.total': 'Jumla ya Maombi',
        'req.stats.pending': 'Inasubiri',
        'req.stats.inProgress': 'Inaendelea',
        'req.stats.completed': 'Imekamilika',

        // ── Table ─────────────────────────────────────────────────
        'req.table.title': 'Maombi ya Huduma',
        'req.table.col.customer': 'Mteja',
        'req.table.col.technician': 'Fundi',
        'req.table.col.service': 'Huduma',
        'req.table.col.status': 'Hali',
        'req.table.col.created': 'Imeundwa',
        'req.table.col.actions': 'Vitendo',
        'req.table.viewTooltip': 'Ona Ombi',
        'req.table.deleteTooltip': 'Futa Ombi',
        'req.table.noFound': 'Hakuna maombi yaliyopatikana',

        // ── Detail Dialog ─────────────────────────────────────────
        'req.dialog.title': 'Maelezo ya Ombi',
        'req.dialog.description': 'Maelezo',
        'req.dialog.noDescription': 'Hakuna maelezo yaliyotolewa',
        'req.dialog.customerInfo': 'Taarifa za Mteja',
        'req.dialog.technicianInfo': 'Taarifa za Fundi',
        'req.dialog.customerId': 'Kitambulisho cha Mteja: {id}',
        'req.dialog.technicianId': 'Kitambulisho cha Fundi: {id}',
        'req.dialog.activityLog': 'Kumbukumbu ya Shughuli',
        'req.dialog.byUser': 'na {name}',
        'req.dialog.scheduleInfo': 'Taarifa za Ratiba',
        'req.dialog.scheduleDate': 'Tarehe:',
        'req.dialog.scheduleTime': 'Muda:',
        'req.dialog.close': 'Funga',

        // ── Delete Confirm ────────────────────────────────────────
        'req.delete.title': 'Futa Ombi',
        'req.delete.message': 'Una uhakika unataka kufuta ombi hili?',

        // ── Toasts ────────────────────────────────────────────────
        'req.toast.loadFailed': 'Imeshindwa kupakia maombi',
        'req.toast.deleteSuccess': 'Ombi limefutwa kwa mafanikio',
        'req.toast.deleteFailed': 'Imeshindwa kufuta ombi',
    },
};

export function tReq(language, key, replacements) {
    let str =
        requestsTranslations[language]?.[key] ||
        requestsTranslations.en?.[key] ||
        key;
    if (replacements) {
        Object.entries(replacements).forEach(([k, v]) => {
            str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
        });
    }
    return str;
}