// src/pages/otp/otplang.js

export const otpTranslations = {
    en: {
        'otp.title': 'OTP Management',
        'otp.subtitle': 'View and manage one-time passwords',
        'otp.accessDenied': 'Access Denied',
        'otp.noPermission': 'You do not have permission to view OTP records.',
        'otp.retry': 'Retry',
        'otp.loadFailed': 'Failed to load OTP records',
        'otp.noRecords': 'No OTP records found',
        'otp.refresh': 'Refresh',
        'otp.cleanup': 'Cleanup Expired',
        'otp.cleanupTooltip': 'Delete expired & unused OTPs',
        'otp.cleanupTitle': 'Cleanup Expired OTPs',
        'otp.cleanupMessage': 'This will permanently delete all expired and unused OTP records. Are you sure?',
        'otp.cleanupSuccess': 'Cleanup completed',
        'otp.cleanupFailed': 'Cleanup failed',
        'otp.actionFailed': 'Action failed',
        'otp.cancel': 'Cancel',
        'otp.confirm': 'Confirm',

        // Stats
        'otp.stats.total': 'Total OTPs',
        'otp.stats.used': 'Used',
        'otp.stats.unused': 'Unused',
        'otp.stats.expired': 'Expired',
        'otp.stats.byType': 'By Type',

        // Filters
        'otp.filter.email': 'Search email…',
        'otp.filter.type': 'Type',
        'otp.filter.usedStatus': 'Used Status',
        'otp.filter.expired': 'Expired',
        'otp.filter.start': 'Start',
        'otp.filter.end': 'End',
        'otp.filter.allTypes': 'All Types',
        'otp.filter.registration': 'Registration',
        'otp.filter.passwordReset': 'Password Reset',
        'otp.filter.emailVerification': 'Email Verification',
        'otp.filter.login': 'Login',
        'otp.filter.all': 'All',
        'otp.filter.used': 'Used',
        'otp.filter.unused': 'Unused',
        'otp.filter.expiredOnly': 'Expired Only',

        // Table
        'otp.col.email': 'Email',
        'otp.col.type': 'Type',
        'otp.col.otp': 'OTP',
        'otp.col.used': 'Used',
        'otp.col.expiresAt': 'Expires At',
        'otp.col.createdAt': 'Created At',
        'otp.col.ip': 'IP',
        'otp.used': 'Used',
        'otp.unused': 'Unused',
        'otp.expired': 'Expired',
        'otp.expires': 'Expires',
        'otp.created': 'Created',
    },
    sw: {
        'otp.title': 'Usimamizi wa OTP',
        'otp.subtitle': 'Tazama na simamia nywila za mara moja',
        'otp.accessDenied': 'Ufikiaji Umekataliwa',
        'otp.noPermission': 'Huna ruhusa ya kuona rekodi za OTP.',
        'otp.retry': 'Jaribu Tena',
        'otp.loadFailed': 'Imeshindwa kupakia rekodi za OTP',
        'otp.noRecords': 'Hakuna rekodi za OTP zilizopatikana',
        'otp.refresh': 'Onyesha Upya',
        'otp.cleanup': 'Safisha Zilizokwisha',
        'otp.cleanupTooltip': 'Futa OTP zilizokwisha na zisizotumika',
        'otp.cleanupTitle': 'Safisha OTP Zilizokwisha',
        'otp.cleanupMessage': 'Hii itafuta kabisa rekodi zote za OTP zilizokwisha na zisizotumika. Una uhakika?',
        'otp.cleanupSuccess': 'Usafishaji umekamilika',
        'otp.cleanupFailed': 'Usafishaji umeshindikana',
        'otp.actionFailed': 'Kitendo kimeshindikana',
        'otp.cancel': 'Ghairi',
        'otp.confirm': 'Thibitisha',

        // Stats
        'otp.stats.total': 'Jumla ya OTP',
        'otp.stats.used': 'Zimetumika',
        'otp.stats.unused': 'Hazijatumika',
        'otp.stats.expired': 'Zimekwisha',
        'otp.stats.byType': 'Kwa Aina',

        // Filters
        'otp.filter.email': 'Tafuta barua pepe…',
        'otp.filter.type': 'Aina',
        'otp.filter.usedStatus': 'Hali ya Matumizi',
        'otp.filter.expired': 'Zimekwisha',
        'otp.filter.start': 'Kuanzia',
        'otp.filter.end': 'Hadi',
        'otp.filter.allTypes': 'Aina Zote',
        'otp.filter.registration': 'Usajili',
        'otp.filter.passwordReset': 'Kuweka Upya Nenosiri',
        'otp.filter.emailVerification': 'Uthibitishaji wa Barua Pepe',
        'otp.filter.login': 'Kuingia',
        'otp.filter.all': 'Zote',
        'otp.filter.used': 'Zimetumika',
        'otp.filter.unused': 'Hazijatumika',
        'otp.filter.expiredOnly': 'Zilizokwisha Pekee',

        // Table
        'otp.col.email': 'Barua Pepe',
        'otp.col.type': 'Aina',
        'otp.col.otp': 'OTP',
        'otp.col.used': 'Imetumika',
        'otp.col.expiresAt': 'Inaisha',
        'otp.col.createdAt': 'Imeundwa',
        'otp.col.ip': 'IP',
        'otp.used': 'Imetumika',
        'otp.unused': 'Haijatumika',
        'otp.expired': 'Imekwisha',
        'otp.expires': 'Inaisha',
        'otp.created': 'Imeundwa',
    },
};

export function tOtp(language, key) {
    return (
        otpTranslations[language]?.[key] ||
        otpTranslations.en?.[key] ||
        key
    );
}