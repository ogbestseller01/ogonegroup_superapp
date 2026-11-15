// src/components/Sidebar/sidebarTranslations.js

/**
 * Fallback translation function.
 * If a key is missing from the dictionary, it returns the key itself.
 */
export const identityT = (key) => key;

export const sidebarTranslations = {
    en: {
        // ── Core Navigation ────────────────────────────────────────
        'sidebar.dashboard': 'Dashboard',

        // ── Static Pages ───────────────────────────────────────────
        'sidebar.staticPages': 'Static Pages',
        'sidebar.about': 'About',
        'sidebar.terms': 'Terms & Conditions',
        'sidebar.faqs': 'FAQs',
        'sidebar.privacy': 'Privacy Policy',

        // ── Services ───────────────────────────────────────────────
        'sidebar.services': 'Services',
        'sidebar.allServices': 'All Services',
        'sidebar.categories': 'Categories',

        // ── Technicians & Portfolios ───────────────────────────────
        'sidebar.technicians': 'Technicians',
        'sidebar.allTechnicians': 'All Technicians',
        'sidebar.portfolios': 'Portfolios',
        'sidebar.posts': 'Posts',
        'sidebar.allPosts': 'All Posts',

        // ── Requests ───────────────────────────────────────────────
        'sidebar.serviceRequests': 'Service Requests',
        'sidebar.allRequests': 'All Requests',

        // ── SMS ────────────────────────────────────────────────────
        'sidebar.smsLogs': 'SMS Logs',
        'sidebar.allSmsLogs': 'All SMS Logs',

        // ── Finance ────────────────────────────────────────────────
        'sidebar.finance': 'Finance',
        'sidebar.subscriptions': 'Subscriptions',
        'sidebar.customers': 'Customers',
        'sidebar.requests': 'Requests',
        'sidebar.jobs': 'Jobs', // ← ADDED
        'sidebar.allSubscriptions': 'All Subscriptions',
        'sidebar.rateCards': 'Rate Cards',
        'sidebar.paymentMethods': 'Payment Methods',

        // ── Monitoring ─────────────────────────────────────────────
        'sidebar.monitoring': 'Monitoring',
        'sidebar.monitoringDashboard': 'Monitoring Dashboard',


        'sidebar.reports': 'Reports',
        'sidebar.allReports': 'All Reports',

        // ── Banners ────────────────────────────────────────────────
        'sidebar.banners': 'Banners',

        // ── Settings ───────────────────────────────────────────────
        'sidebar.settings': 'Settings',
        'sidebar.users': 'Users',
        'sidebar.roles': 'Roles',
        'sidebar.permissions': 'Permissions',
        'sidebar.auditLogs': 'Audit Logs',
        'sidebar.otpManagement': 'OTP Management',
        'sidebar.profile': 'Profile',
        'sidebar.miniAppQr': 'Mini App QR',
        'sidebar.systemUpdates': 'System Updates',
    },

    sw: {
        // ── Core Navigation ────────────────────────────────────────
        'sidebar.dashboard': 'Dashibodi',

        // ── Static Pages ───────────────────────────────────────────
        'sidebar.staticPages': 'Kurasa Tuli',
        'sidebar.about': 'Kuhusu',
        'sidebar.terms': 'Vigezo na Masharti',
        'sidebar.faqs': 'Maswali Yanayoulizwa Mara kwa Mara',
        'sidebar.privacy': 'Sera ya Faragha',

        'sidebar.reports': 'Ripoti',
        'sidebar.allReports': 'Ripoti Zote',

        // ── Services ───────────────────────────────────────────────
        'sidebar.services': 'Huduma',
        'sidebar.allServices': 'Huduma Zote',
        'sidebar.categories': 'Makundi',

        // ── Technicians & Portfolios ───────────────────────────────
        'sidebar.technicians': 'Mafundi',
        'sidebar.allTechnicians': 'Mafundi Wote',
        'sidebar.portfolios': 'Kazi Zilizofanywa',
        'sidebar.posts': 'Machapisho',
        'sidebar.allPosts': 'Machapisho Yote',

        // ── Requests ───────────────────────────────────────────────
        'sidebar.serviceRequests': 'Maombi ya Huduma',
        'sidebar.allRequests': 'Maombi Yote',

        // ── SMS ────────────────────────────────────────────────────
        'sidebar.smsLogs': 'Kumbukumbu za SMS',
        'sidebar.allSmsLogs': 'Kumbukumbu Zote za SMS',

        // ── Finance ────────────────────────────────────────────────
        'sidebar.finance': 'Fedha',
        'sidebar.subscriptions': 'Usajili',
        'sidebar.customers': 'Wateja',
        'sidebar.requests': 'Maombi',
        'sidebar.jobs': 'Kazi', // ← ADDED
        'sidebar.allSubscriptions': 'Usajili Wote',
        'sidebar.rateCards': 'Kadi za Viwango',
        'sidebar.paymentMethods': 'Njia za Malipo',

        // ── Monitoring ─────────────────────────────────────────────
        'sidebar.monitoring': 'Ufuatiliaji',
        'sidebar.monitoringDashboard': 'Dashibodi ya Ufuatiliaji',

        // ── Banners ────────────────────────────────────────────────
        'sidebar.banners': 'Mabango',

        // ── Settings ───────────────────────────────────────────────
        'sidebar.settings': 'Mipangilio',
        'sidebar.users': 'Watumiaji',
        'sidebar.roles': 'Majukumu',
        'sidebar.permissions': 'Ruhusa',
        'sidebar.auditLogs': 'Kumbukumbu za Ukaguzi',
        'sidebar.otpManagement': 'Usimamizi wa OTP',
        'sidebar.profile': 'Wasifu',
        'sidebar.miniAppQr': 'QR ya App Ndogo', // ← ADDED
        'sidebar.systemUpdates': 'Masasisho ya Mfumo', // ← ADDED
    }
};

/**
 * Helper to get a translated string.
 * Usage: t('sidebar.dashboard') or t('sidebar.dashboard', 'en')
 */
export const getSidebarT = (lang = 'en') => {
    return (key) => sidebarTranslations[lang]?.[key] || sidebarTranslations['en']?.[key] || key;
};