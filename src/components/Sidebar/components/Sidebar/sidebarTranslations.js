// src/components/Sidebar/sidebarTranslations.js

/**
 * Fallback English translations for the sidebar.
 * Used only when the real `t` function from LanguageContext is not provided.
 */
export const sidebarFallback = {
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
};

export const identityT = (key) => sidebarFallback[key] || key;