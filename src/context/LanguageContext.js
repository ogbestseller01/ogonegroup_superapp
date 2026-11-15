// src/context/LanguageContext.js
import React, { createContext, useContext, useState, useEffect } from 'react';

const LanguageContext = createContext();

const translations = {
    en: {
        // Header
        'header.greeting': 'Hi,',
        'header.user': 'User',
        'header.profile': 'Profile',
        'header.signout': 'Sign Out',

        // Sidebar
        'sidebar.dashboard': 'Dashboard',
        'sidebar.staticPages': 'Static Pages',
        'sidebar.about': 'About',
        'sidebar.terms': 'Terms',
        'sidebar.faqs': 'FAQs',
        'sidebar.privacy': 'Privacy Policy',
        'sidebar.services': 'Services',
        'sidebar.allServices': 'All Services',
        'sidebar.categories': 'Categories',
        'sidebar.technicians': 'Technicians',
        'sidebar.allTechnicians': 'All Technicians',
        'sidebar.portfolios': 'Portfolios',
        'sidebar.posts': 'Posts',
        'sidebar.allPosts': 'All Posts',
        'sidebar.serviceRequests': 'Service Requests',
        'sidebar.allRequests': 'All Requests',
        'sidebar.smsLogs': 'SMS Logs',
        'sidebar.allSmsLogs': 'All SMS Logs',
        'sidebar.finance': 'Finance',
        'sidebar.subscriptions': 'Subscriptions',
        'sidebar.customers': 'Customers',
        'sidebar.requests': 'Requests',
        'sidebar.fund': 'Fund',
        'sidebar.fundManagement': 'Fund Management',
        'sidebar.fundTransactions': 'Fund Transactions',
        'sidebar.fundReports': 'Fund Reports',
        'sidebar.monitoring': 'Monitoring',
        'sidebar.monitoringDashboard': 'Monitoring Dashboard',
        'sidebar.allSubscriptions': 'All Subscriptions',
        'sidebar.rateCards': 'Rate Cards',
        'sidebar.paymentMethods': 'Payment Methods',
        'sidebar.settings': 'Settings',
        'sidebar.users': 'Users',
        'sidebar.roles': 'Roles',
        'sidebar.permissions': 'Permissions',
        'sidebar.auditLogs': 'Audit Logs',
        'sidebar.otpManagement': 'OTP Management',
        'sidebar.profile': 'Profile',

        // Common
        'common.search': 'Search...',
        'common.loading': 'Loading...',
        'common.save': 'Save',
        'common.cancel': 'Cancel',
        'common.delete': 'Delete',
        'common.edit': 'Edit',
        'common.view': 'View',
        'common.create': 'Create',
        'common.actions': 'Actions',
        'common.status': 'Status',
        'common.yes': 'Yes',
        'common.no': 'No',

        // Language
        'language.english': 'English',
        'language.swahili': 'Kiswahili',
        'language.select': 'Select Language',
    },
    sw: {
        // Header
        'header.greeting': 'Habari,',
        'header.user': 'Mtumiaji',
        'header.profile': 'Wasifu',
        'header.signout': 'Toka',

        // Sidebar
        'sidebar.dashboard': 'Dashibodi',
        'sidebar.staticPages': 'Kurasa za Kudumu',
        'sidebar.about': 'Kuhusu',
        'sidebar.terms': 'Masharti',
        'sidebar.faqs': 'Maswali Yanayoulizwa',
        'sidebar.privacy': 'Sera ya Faragha',
        'sidebar.services': 'Huduma',
        'sidebar.allServices': 'Huduma Zote',
        'sidebar.categories': 'Makundi',
        'sidebar.technicians': 'Mafundi',
        'sidebar.allTechnicians': 'Mafundi Wote',
        'sidebar.portfolios': 'Kazi Zilizofanywa',
        'sidebar.posts': 'Machapisho',
        'sidebar.allPosts': 'Machapisho Yote',
        'sidebar.serviceRequests': 'Maombi ya Huduma',
        'sidebar.allRequests': 'Maombi Yote',
        'sidebar.smsLogs': 'Kumbukumbu za SMS',
        'sidebar.allSmsLogs': 'Kumbukumbu Zote za SMS',
        'sidebar.finance': 'Fedha',
        'sidebar.subscriptions': 'Usajili',
        'sidebar.customers': 'Wateja',
        'sidebar.requests': 'Maombi',
        'sidebar.fund': 'Mfuko',
        'sidebar.fundManagement': 'Usimamizi wa Mfuko',
        'sidebar.fundTransactions': 'Miamala ya Mfuko',
        'sidebar.fundReports': 'Ripoti za Mfuko',
        'sidebar.monitoring': 'Ufuatiliaji',
        'sidebar.monitoringDashboard': 'Dashibodi ya Ufuatiliaji',
        'sidebar.allSubscriptions': 'Usajili Wote',
        'sidebar.rateCards': 'Kadi za Bei',
        'sidebar.paymentMethods': 'Njia za Malipo',
        'sidebar.settings': 'Mipangilio',
        'sidebar.users': 'Watumiaji',
        'sidebar.roles': 'Majukumu',
        'sidebar.permissions': 'Ruhusa',
        'sidebar.auditLogs': 'Kumbukumbu za Ukaguzi',
        'sidebar.otpManagement': 'Usimamizi wa OTP',
        'sidebar.profile': 'Wasifu',

        // Common
        'common.search': 'Tafuta...',
        'common.loading': 'Inapakia...',
        'common.save': 'Hifadhi',
        'common.cancel': 'Ghairi',
        'common.delete': 'Futa',
        'common.edit': 'Hariri',
        'common.view': 'Angalia',
        'common.create': 'Unda',
        'common.actions': 'Vitendo',
        'common.status': 'Hali',
        'common.yes': 'Ndiyo',
        'common.no': 'Hapana',

        // Language
        'language.english': 'English',
        'language.swahili': 'Kiswahili',
        'language.select': 'Chagua Lugha',
    },
};

export const LanguageProvider = ({ children }) => {
    const [language, setLanguageState] = useState(() => {
        return localStorage.getItem('app_language') || 'en';
    });

    useEffect(() => {
        localStorage.setItem('app_language', language);
        document.documentElement.lang = language;
    }, [language]);

    const t = (key, fallback = key) => {
        return translations[language]?.[key] || translations.en?.[key] || fallback;
    };

    const setLanguage = (lang) => {
        if (translations[lang]) {
            setLanguageState(lang);
        }
    };

    const value = {
        language,
        setLanguage,
        t,
        availableLanguages: ['en', 'sw'],
    };

    return (
        <LanguageContext.Provider value={value}>
            {children}
        </LanguageContext.Provider>
    );
};

export const useLanguage = () => {
    const context = useContext(LanguageContext);
    if (!context) {
        throw new Error('useLanguage must be used within a LanguageProvider');
    }
    return context;
};

export default LanguageContext;