// src/pages/sms/smslang.js

export const smsTranslations = {
    en: {
        // ── Common ────────────────────────────────────────────────
        'sms.common.refresh': 'Refresh',
        'sms.common.cancel': 'Cancel',
        'sms.common.clear': 'Clear',
        'sms.common.confirm': 'Confirm',
        'sms.common.close': 'Close',
        'sms.common.retry': 'Retry',
        'sms.common.loading': 'Loading...',
        'sms.common.none': 'None',
        'sms.common.system': 'System',
        'sms.common.unknownUser': 'Unknown User',
        'sms.common.unknown': 'Unknown',
        'sms.common.active': 'Active',

        // ── Statuses ──────────────────────────────────────────────
        'sms.status.sent': 'Sent',
        'sms.status.failed': 'Failed',
        'sms.status.pending': 'Pending',
        'sms.status.queued': 'Queued',
        'sms.status.all': 'All statuses',
        'sms.status.error': 'Error',

        // ── Send SMS Dialog ───────────────────────────────────────
        'sms.send.title': 'Send SMS',
        'sms.send.selectUserOptional': 'Select User (Optional)',
        'sms.send.selectedPrefix': 'Selected:',
        'sms.send.recipientLabel': 'Recipient Phone Number',
        'sms.send.recipientPlaceholder': 'e.g., 255XXXXXXXXX',
        'sms.send.messageLabel': 'Message',
        'sms.send.messagePlaceholder': 'Type your message here...',
        'sms.send.charCount': '{n} chars ({parts} part{s})',
        'sms.send.sending': 'Sending...',
        'sms.send.sendButton': 'Send SMS',
        'sms.send.errorRecipient': 'Please select a recipient',
        'sms.send.errorMessage': 'Please enter a message',
        'sms.send.errorSendFailed': 'Failed to send SMS',

        // ── User Selector ─────────────────────────────────────────
        'sms.userSelector.title': 'Select User',
        'sms.userSelector.searchPlaceholder': 'Search users by name, email, or phone...',
        'sms.userSelector.noUsers': 'No users found',
        'sms.userSelector.selectButton': 'Select User',

        // ── SMS Logs List ─────────────────────────────────────────
        'sms.logs.accessDenied': 'You do not have permission to view SMS logs.',
        'sms.logs.title': 'SMS Logs',
        'sms.logs.subtitle': 'Track every message sent from the system',
        'sms.logs.sendSms': 'Send SMS',
        'sms.logs.refresh': 'Refresh',
        'sms.logs.searchPlaceholder': 'Search recipient, message…',
        'sms.logs.filterByUser': 'Filter by user',
        'sms.logs.userFiltered': 'User filtered',
        'sms.logs.noFound': 'No SMS logs found',
        'sms.logs.noFoundForUser': 'No SMS logs found for this user',

        // Stats
        'sms.logs.stats.total': 'Total Messages',
        'sms.logs.stats.totalCaption': 'All time',
        'sms.logs.stats.sent': 'Sent Successfully',
        'sms.logs.stats.sentCaption': '{n}% success rate',
        'sms.logs.stats.failed': 'Failed',
        'sms.logs.stats.failedCaption': '{n}% of total',
        'sms.logs.stats.successRate': 'Success Rate',

        // Table columns
        'sms.logs.col.user': 'User',
        'sms.logs.col.recipient': 'Recipient',
        'sms.logs.col.message': 'Message',
        'sms.logs.col.status': 'Status',
        'sms.logs.col.sentAt': 'Sent At',
        'sms.logs.col.actions': 'Actions',

        // Row actions
        'sms.logs.action.showMessage': 'Show full message',
        'sms.logs.action.hideMessage': 'Hide message',
        'sms.logs.action.show': 'Show message',
        'sms.logs.action.hide': 'Hide message',
        'sms.logs.action.resend': 'Resend SMS',
        'sms.logs.action.delete': 'Delete Log',

        // Confirm dialogs
        'sms.logs.confirm.resendTitle': 'Resend SMS',
        'sms.logs.confirm.resendMsg': 'Are you sure you want to resend this SMS to {recipient}?',
        'sms.logs.confirm.deleteTitle': 'Delete SMS Log',
        'sms.logs.confirm.deleteMsg': 'Are you sure you want to delete this SMS log?',

        // Toasts
        'sms.logs.toast.resendSuccess': 'SMS resent successfully',
        'sms.logs.toast.resendFailed': 'Failed to resend SMS',
        'sms.logs.toast.deleteSuccess': 'SMS log deleted successfully',
        'sms.logs.toast.deleteFailed': 'Failed to delete SMS log',
        'sms.logs.toast.sendSuccess': 'SMS sent successfully',
        'sms.logs.toast.sendFailed': 'Failed to send SMS',
        'sms.logs.toast.loadFailed': 'Failed to load SMS logs',
    },

    sw: {
        // ── Common ────────────────────────────────────────────────
        'sms.common.refresh': 'Onyesha Upya',
        'sms.common.cancel': 'Ghairi',
        'sms.common.clear': 'Safisha',
        'sms.common.confirm': 'Thibitisha',
        'sms.common.close': 'Funga',
        'sms.common.retry': 'Jaribu Tena',
        'sms.common.loading': 'Inapakia...',
        'sms.common.none': 'Hakuna',
        'sms.common.system': 'Mfumo',
        'sms.common.unknownUser': 'Mtumiaji Asiyefahamika',
        'sms.common.unknown': 'Haijulikani',
        'sms.common.active': 'Hai',

        // ── Statuses ──────────────────────────────────────────────
        'sms.status.sent': 'Imetumwa',
        'sms.status.failed': 'Imeshindikana',
        'sms.status.pending': 'Inasubiri',
        'sms.status.queued': 'Imehifadhiwa',
        'sms.status.all': 'Hali zote',
        'sms.status.error': 'Hitilafu',

        // ── Send SMS Dialog ───────────────────────────────────────
        'sms.send.title': 'Tuma SMS',
        'sms.send.selectUserOptional': 'Chagua Mtumiaji (Si lazima)',
        'sms.send.selectedPrefix': 'Imechaguliwa:',
        'sms.send.recipientLabel': 'Namba ya Simu ya Mpokeaji',
        'sms.send.recipientPlaceholder': 'k.m., 255XXXXXXXXX',
        'sms.send.messageLabel': 'Ujumbe',
        'sms.send.messagePlaceholder': 'Andika ujumbe wako hapa...',
        'sms.send.charCount': 'herufi {n} (sehemu {parts})',
        'sms.send.sending': 'Inatuma...',
        'sms.send.sendButton': 'Tuma SMS',
        'sms.send.errorRecipient': 'Tafadhali chagua mpokeaji',
        'sms.send.errorMessage': 'Tafadhali andika ujumbe',
        'sms.send.errorSendFailed': 'Imeshindwa kutuma SMS',

        // ── User Selector ─────────────────────────────────────────
        'sms.userSelector.title': 'Chagua Mtumiaji',
        'sms.userSelector.searchPlaceholder': 'Tafuta watumiaji kwa jina, barua pepe, au simu...',
        'sms.userSelector.noUsers': 'Hakuna watumiaji walipatikana',
        'sms.userSelector.selectButton': 'Chagua Mtumiaji',

        // ── SMS Logs List ─────────────────────────────────────────
        'sms.logs.accessDenied': 'Huna ruhusa kuona kumbukumbu za SMS.',
        'sms.logs.title': 'Kumbukumbu za SMS',
        'sms.logs.subtitle': 'Fuatilia kila ujumbe uliotumwa kutoka mfumo',
        'sms.logs.sendSms': 'Tuma SMS',
        'sms.logs.refresh': 'Onyesha Upya',
        'sms.logs.searchPlaceholder': 'Tafuta mpokeaji, ujumbe…',
        'sms.logs.filterByUser': 'Chuja kwa mtumiaji',
        'sms.logs.userFiltered': 'Mtumiaji amechujwa',
        'sms.logs.noFound': 'Hakuna kumbukumbu za SMS zilizopatikana',
        'sms.logs.noFoundForUser': 'Hakuna kumbukumbu za SMS kwa mtumiaji huyu',

        // Stats
        'sms.logs.stats.total': 'Jumla ya Ujumbe',
        'sms.logs.stats.totalCaption': 'Muda wote',
        'sms.logs.stats.sent': 'Imetumwa kwa Mafanikio',
        'sms.logs.stats.sentCaption': 'kiwango cha mafanikio {n}%',
        'sms.logs.stats.failed': 'Imeshindikana',
        'sms.logs.stats.failedCaption': '{n}% ya jumla',
        'sms.logs.stats.successRate': 'Kiwango cha Mafanikio',

        // Table columns
        'sms.logs.col.user': 'Mtumiaji',
        'sms.logs.col.recipient': 'Mpokeaji',
        'sms.logs.col.message': 'Ujumbe',
        'sms.logs.col.status': 'Hali',
        'sms.logs.col.sentAt': 'Imetumwa',
        'sms.logs.col.actions': 'Vitendo',

        // Row actions
        'sms.logs.action.showMessage': 'Onyesha ujumbe kamili',
        'sms.logs.action.hideMessage': 'Ficha ujumbe',
        'sms.logs.action.show': 'Onyesha ujumbe',
        'sms.logs.action.hide': 'Ficha ujumbe',
        'sms.logs.action.resend': 'Tuma SMS Tena',
        'sms.logs.action.delete': 'Futa Kumbukumbu',

        // Confirm dialogs
        'sms.logs.confirm.resendTitle': 'Tuma SMS Tena',
        'sms.logs.confirm.resendMsg': 'Una uhakika unataka kutuma SMS hii tena kwa {recipient}?',
        'sms.logs.confirm.deleteTitle': 'Futa Kumbukumbu ya SMS',
        'sms.logs.confirm.deleteMsg': 'Una uhakika unataka kufuta kumbukumbu hii ya SMS?',

        // Toasts
        'sms.logs.toast.resendSuccess': 'SMS imetumwa tena kwa mafanikio',
        'sms.logs.toast.resendFailed': 'Imeshindwa kutuma SMS tena',
        'sms.logs.toast.deleteSuccess': 'Kumbukumbu ya SMS imefutwa',
        'sms.logs.toast.deleteFailed': 'Imeshindwa kufuta kumbukumbu',
        'sms.logs.toast.sendSuccess': 'SMS imetumwa kwa mafanikio',
        'sms.logs.toast.sendFailed': 'Imeshindwa kutuma SMS',
        'sms.logs.toast.loadFailed': 'Imeshindwa kupakia kumbukumbu za SMS',
    },
};

export function tSms(language, key, replacements) {
    let str =
        smsTranslations[language]?.[key] ||
        smsTranslations.en?.[key] ||
        key;
    if (replacements) {
        Object.entries(replacements).forEach(([k, v]) => {
            str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
        });
    }
    return str;
}