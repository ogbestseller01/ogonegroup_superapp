// src/hooks/useBreadcrumbs.js
import { useMemo } from 'react';
import { useLocation } from 'react-router-dom';

const routeMap = {
    'dashboard': 'Dashboard',
    'users': 'Users',
    'users-create': 'Create User',
    'users-edit': 'Edit User',
    'users-view': 'View User',
    'roles': 'Roles',
    'roles-create': 'Create Role',
    'roles-edit': 'Edit Role',
    'permissions': 'Permissions',
    'permissions-create': 'Create Permission',
    'permissions-edit': 'Edit Permission',
    'audit': 'Audit Logs',
    'otp': 'OTP Management',
    'about': 'About',
    'about-edit': 'Edit About',
    'terms': 'Terms',
    'terms-edit': 'Edit Terms',
    'faqs': 'FAQs',
    'faqs-create': 'Create FAQ',
    'faqs-edit': 'Edit FAQ',
    'services': 'Services',
    'services-create': 'Create Service',
    'services-edit': 'Edit Service',
    'technicians': 'Technicians',
    'technicians-create': 'Create Technician',
    'technicians-edit': 'Edit Technician',
    'technicians-view': 'View Technician',
    'portfolios': 'Portfolios',
    'portfolios-create': 'Create Portfolio',
    'portfolios-edit': 'Edit Portfolio',
    'posts': 'Posts',
    'posts-create': 'Create Post',
    'posts-edit': 'Edit Post',
    'requests': 'Service Requests',
    'requests-view': 'View Request',
    'reports': 'Reports',
    'reports-users': 'Users Report',
    'reports-technicians': 'Technicians Report',
    'reports-requests': 'Requests Report',
    'reports-services': 'Services Report',
    'reports-blog': 'Blog Report',
    'reports-portfolio': 'Portfolio Report',
    'reports-revenue': 'Revenue Report',
    'settings': 'Settings',
    'profile': 'Profile',
    'analytics': 'Analytics',
};

export const useBreadcrumbs = () => {
    const location = useLocation();

    const breadcrumbs = useMemo(() => {
        const paths = location.pathname.split('/').filter(Boolean);
        const items = [];

        let currentPath = '';
        paths.forEach((path, index) => {
            currentPath += `/${path}`;

            let label = routeMap[path];
            if (!label) {
                label = path
                    .split('-')
                    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
                    .join(' ');
            }

            items.push({
                label,
                path: currentPath,
                isCurrent: index === paths.length - 1,
            });
        });

        return items;
    }, [location.pathname]);

    return breadcrumbs;
};