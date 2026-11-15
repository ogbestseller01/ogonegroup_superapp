// src/pages/system-updates/systemUpdateLang.js

export const systemUpdateTranslations = {
    en: {
        'su.title': 'System Updates',
        'su.subtitle': 'Publish announcements to all users via in-app card and push',
        'su.add': 'New Update',
        'su.refresh': 'Refresh',
        'su.searchPlaceholder': 'Search title or description…',
        'su.accessDenied': 'You do not have permission to manage system updates.',
        'su.retry': 'Retry',
        'su.noFound': 'No system updates yet',
        'su.cancel': 'Cancel',
        'su.confirm': 'Confirm',
        'su.actionSuccess': 'Action completed successfully',
        'su.actionFailed': 'Action failed',

        'su.filter.status': 'Status',
        'su.filter.allStatuses': 'All statuses',
        'su.status.draft': 'Draft',
        'su.status.published': 'Published',
        'su.status.closed': 'Closed',

        'su.col.title': 'Title',
        'su.col.status': 'Status',
        'su.col.channels': 'Channels',
        'su.col.reach': 'Reach',
        'su.col.published': 'Published',
        'su.col.created': 'Created',
        'su.col.actions': 'Actions',
        'su.reach.received': 'received',
        'su.reach.viewed': 'viewed',
        'su.reach.dismissed': 'dismissed',
        'su.reach.pushSent': 'push sent',
        'su.reach.pushFailed': 'push failed',

        'su.action.edit': 'Edit',
        'su.action.publish': 'Publish',
        'su.action.close': 'Close',
        'su.action.delete': 'Delete',
        'su.action.viewStats': 'View Stats',

        'su.confirm.publishTitle': 'Publish Update',
        'su.confirm.publishMsg':
            'Publishing sends an in-app card and push notification to every active user. This cannot be undone. Continue?',
        'su.confirm.closeTitle': 'Close Update',
        'su.confirm.closeMsg':
            'Closing removes the update from the home screen for everyone. Continue?',
        'su.confirm.deleteTitle': 'Delete Update',
        'su.confirm.deleteMsg':
            'This update will be permanently hidden from the admin panel and all users. Continue?',

        'su.msg.published': 'Update published. Notifications are being sent.',
        'su.msg.closed': 'Update closed.',
        'su.msg.deleted': 'Update deleted.',
        'su.msg.publishFailed': 'Failed to publish update.',
        'su.msg.closeFailed': 'Failed to close update.',
        'su.msg.deleteFailed': 'Failed to delete update.',

        'su.form.createTitle': 'New System Update',
        'su.form.editTitle': 'Edit System Update',
        'su.form.createDesc': 'Write the announcement and choose delivery channels',
        'su.form.editDesc': 'Content edits do not re-send notifications',
        'su.form.title': 'Title',
        'su.form.titleHint': 'Shown as the card and push headline (max 255)',
        'su.form.description': 'Description',
        'su.form.descriptionHint': 'Full text shown when the user opens the update (max 5000)',
        'su.form.channels': 'Delivery channels',
        'su.form.sendPush': 'Send push notification (FCM)',
        'su.form.sendPushHint': 'Reaches users with the app installed. Free.',
        'su.form.saveDraft': 'Save as Draft',
        'su.form.saveChanges': 'Save Changes',
        'su.form.publishNow': 'Publish Now',
        'su.form.titleRequired': 'Title is required',
        'su.form.descriptionRequired': 'Description is required',
        'su.form.titleMin': 'Title must be at least 3 characters',
        'su.form.descriptionMin': 'Description must be at least 3 characters',
        'su.form.checkErrors': 'Please check the form for errors.',
        'su.form.failed': 'Operation failed',
        'su.form.created': 'Draft created.',
        'su.form.updated': 'Update saved.',
        'su.form.published': 'Update published.',

        'su.stats.title': 'Delivery stats — {title}',
        'su.stats.received': 'Received (in-app)',
        'su.stats.viewed': 'Viewed',
        'su.stats.dismissed': 'Dismissed',
        'su.stats.pushSent': 'Push sent',
        'su.stats.pushFailed': 'Push failed',
        'su.stats.close': 'Close',
    },

    sw: {
        'su.title': 'Taarifa za Mfumo',
        'su.subtitle': 'Tangaza kwa watumiaji wote kupitia kadi na push',
        'su.add': 'Taarifa Mpya',
        'su.refresh': 'Onyesha Upya',
        'su.searchPlaceholder': 'Tafuta kichwa au maelezo…',
        'su.accessDenied': 'Huna ruhusa ya kusimamia taarifa za mfumo.',
        'su.retry': 'Jaribu Tena',
        'su.noFound': 'Hakuna taarifa za mfumo bado',
        'su.cancel': 'Ghairi',
        'su.confirm': 'Thibitisha',
        'su.actionSuccess': 'Kitendo kimekamilika kwa mafanikio',
        'su.actionFailed': 'Kitendo kimeshindikana',

        'su.filter.status': 'Hali',
        'su.filter.allStatuses': 'Hali zote',
        'su.status.draft': 'Rasimu',
        'su.status.published': 'Imetangazwa',
        'su.status.closed': 'Imefungwa',

        'su.col.title': 'Kichwa',
        'su.col.status': 'Hali',
        'su.col.channels': 'Njia',
        'su.col.reach': 'Ufikiaji',
        'su.col.published': 'Ilitangazwa',
        'su.col.created': 'Imeundwa',
        'su.col.actions': 'Vitendo',
        'su.reach.received': 'imepokelewa',
        'su.reach.viewed': 'imeonwa',
        'su.reach.dismissed': 'imekataliwa',
        'su.reach.pushSent': 'push imetumwa',
        'su.reach.pushFailed': 'push imeshindikana',

        'su.action.edit': 'Hariri',
        'su.action.publish': 'Tangaza',
        'su.action.close': 'Funga',
        'su.action.delete': 'Futa',
        'su.action.viewStats': 'Ona Takwimu',

        'su.confirm.publishTitle': 'Tangaza Taarifa',
        'su.confirm.publishMsg':
            'Kutangaza kutuma kadi na push kwa kila mtumiaji hai. Hii haiwezi kutenduliwa. Endelea?',
        'su.confirm.closeTitle': 'Funga Taarifa',
        'su.confirm.closeMsg':
            'Kufunga kutaondoa taarifa kwenye skrini ya nyumbani kwa kila mtu. Endelea?',
        'su.confirm.deleteTitle': 'Futa Taarifa',
        'su.confirm.deleteMsg':
            'Taarifa hii itafichwa kabisa kutoka paneli ya msimamizi na watumiaji wote. Endelea?',

        'su.msg.published': 'Taarifa imetangazwa. Arifa zinatumwa.',
        'su.msg.closed': 'Taarifa imefungwa.',
        'su.msg.deleted': 'Taarifa imefutwa.',
        'su.msg.publishFailed': 'Imeshindwa kutangaza taarifa.',
        'su.msg.closeFailed': 'Imeshindwa kufunga taarifa.',
        'su.msg.deleteFailed': 'Imeshindwa kufuta taarifa.',

        'su.form.createTitle': 'Taarifa Mpya ya Mfumo',
        'su.form.editTitle': 'Hariri Taarifa ya Mfumo',
        'su.form.createDesc': 'Andika tangazo na chagua njia za uwasilishaji',
        'su.form.editDesc': 'Mabadiliko ya maudhui hayatuma arifa tena',
        'su.form.title': 'Kichwa',
        'su.form.titleHint': 'Inaonekana kama kichwa cha kadi na push (kiwango cha juu 255)',
        'su.form.description': 'Maelezo',
        'su.form.descriptionHint': 'Maandishi kamili yanapoonekana mtumiaji anapofungua taarifa (kiwango cha juu 5000)',
        'su.form.channels': 'Njia za uwasilishaji',
        'su.form.sendPush': 'Tuma arifa ya push (FCM)',
        'su.form.sendPushHint': 'Inawafikia watumiaji walio na app. Bure.',
        'su.form.saveDraft': 'Hifadhi kama Rasimu',
        'su.form.saveChanges': 'Hifadhi Mabadiliko',
        'su.form.publishNow': 'Tangaza Sasa',
        'su.form.titleRequired': 'Kichwa kinahitajika',
        'su.form.descriptionRequired': 'Maelezo yanahitajika',
        'su.form.titleMin': 'Kichwa lazima kiwe na angalau herufi 3',
        'su.form.descriptionMin': 'Maelezo lazima yawe na angalau herufi 3',
        'su.form.checkErrors': 'Tafadhali angalia fomu kwa makosa.',
        'su.form.failed': 'Operesheni imeshindikana',
        'su.form.created': 'Rasimu imeundwa.',
        'su.form.updated': 'Taarifa imehifadhiwa.',
        'su.form.published': 'Taarifa imetangazwa.',

        'su.stats.title': 'Takwimu za uwasilishaji — {title}',
        'su.stats.received': 'Imepokelewa (ndani ya app)',
        'su.stats.viewed': 'Imeonwa',
        'su.stats.dismissed': 'Imekataliwa',
        'su.stats.pushSent': 'Push imetumwa',
        'su.stats.pushFailed': 'Push imeshindikana',
        'su.stats.close': 'Funga',
    },
};

export function tSystemUpdate(language, key, replacements) {
    let str =
        systemUpdateTranslations[language]?.[key] ||
        systemUpdateTranslations.en?.[key] ||
        key;
    if (replacements) {
        Object.entries(replacements).forEach(([k, v]) => {
            str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
        });
    }
    return str;
}