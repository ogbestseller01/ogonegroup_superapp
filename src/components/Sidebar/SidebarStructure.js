// src/components/Sidebar/SidebarStructure.js
import {
  Dashboard as DashboardIcon,
  Info as AboutIcon,
  Build as ServicesIcon,
  Engineering as TechniciansIcon,
  PhotoLibrary as PortfoliosIcon,
  Article as PostsIcon,
  RequestPage as RequestsIcon,
  Settings as SettingsIcon,
  MonitorHeart as MonitoringIcon,
  Subscriptions as SubscriptionsIcon,
  Category as CategoryIcon,
  AttachMoney as FinanceIcon,
  Sms as SmsIcon,
  QrCode2 as QrCodeIcon,
  Image as BannersIcon,
  Campaign as SystemUpdatesIcon,
  Work as WorkIcon,
  People as PeopleIcon,
  Security as RolesIcon,
  Lock as PermissionsIcon,
  History as AuditIcon,
  Pin as OtpIcon,
  Person as ProfileIcon,
  Article as ArticleIcon,
  Info as InfoIcon,
  PrivacyTip as PrivacyTipIcon,
  Build as BuildIcon,
  Payment as PaymentIcon,
  Receipt as ReceiptIcon,
  Assessment as ReportsIcon, // ← Imported for the Reports menu
  LocalOffer as RateCardIcon,
  CreditCard as PaymentMethodIcon,
  Chat as ChatIcon,
  Notifications as NotificationsIcon,
  Feedback as FeedbackIcon,
  Apps as AppsIcon,
} from '@mui/icons-material';

import { identityT, sidebarTranslations } from './sidebarTranslations';

const addIf = (condition, item) => (condition ? [item] : []);

const THEME_TOKENS = {
  activeColor: 'primary.main',
  hoverBg: 'action.hover',
  activeBg: 'action.selected',
  textColor: 'text.primary',
  subTextColor: 'text.secondary',
  borderColor: 'divider',
  iconColor: 'text.secondary',
  activeIconColor: 'primary.main',
};

const COMING_SOON_TOKENS = {
  ...THEME_TOKENS,
  disabled: true,
  comingSoon: true,
  textColor: 'text.disabled',
  iconColor: 'text.disabled',
};

export function getSidebarStructure(hasPermission, globalT = identityT, lang = 'en') {
  const t = (key) => {
    const sidebarDict = sidebarTranslations[lang] || sidebarTranslations['en'];
    if (sidebarDict && sidebarDict[key]) {
      return sidebarDict[key];
    }
    const translated = globalT(key);
    return translated === key ? (sidebarDict?.[key] || key) : translated;
  };

  const structure = [];

  // ----- Dashboard -----
  if (hasPermission('dashboard.view')) {
    structure.push({
      id: 1,
      label: t('sidebar.dashboard'),
      link: '/app/dashboard',
      icon: <DashboardIcon />,
      ...THEME_TOKENS,
    });
  }

  // ----- Static Pages -----
  const staticChildren = [
    ...addIf(hasPermission('about.view'), {
      label: t('sidebar.about'),
      link: '/app/about',
      icon: <AboutIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('terms.view'), {
      label: t('sidebar.terms'),
      link: '/app/terms',
      icon: <ArticleIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('faqs.view'), {
      label: t('sidebar.faqs'),
      link: '/app/faqs',
      icon: <InfoIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('privacy.view'), {
      label: t('sidebar.privacy'),
      link: '/app/privacy-policy',
      icon: <PrivacyTipIcon />,
      ...THEME_TOKENS,
    }),
  ];

  if (staticChildren.length > 0) {
    structure.push({
      id: 2,
      label: t('sidebar.staticPages'),
      link: '#',
      icon: <AboutIcon />,
      children: staticChildren,
      ...THEME_TOKENS,
    });
  }

  // ----- Services -----
  if (hasPermission('services.view')) {
    const servicesChildren = [
      { label: t('sidebar.allServices'), link: '/app/services', icon: <BuildIcon />, ...THEME_TOKENS },
    ];

    if (hasPermission('service-categories.view')) {
      servicesChildren.push({
        label: t('sidebar.categories'),
        link: '/app/services/categories',
        icon: <CategoryIcon />,
        ...THEME_TOKENS,
      });
    }

    structure.push({
      id: 3,
      label: t('sidebar.services'),
      link: '/app/services',
      icon: <ServicesIcon />,
      children: servicesChildren,
      ...THEME_TOKENS,
    });
  }

  // ----- Technicians -----
  if (hasPermission('technicians.view')) {
    structure.push({
      id: 4,
      label: t('sidebar.technicians'),
      link: '/app/technicians',
      icon: <TechniciansIcon />,
      children: [
        { label: t('sidebar.allTechnicians'), link: '/app/technicians', icon: <TechniciansIcon />, ...THEME_TOKENS },
      ],
      ...THEME_TOKENS,
    });
  }

  // ----- Portfolios -----
  if (hasPermission('portfolios.view')) {
    structure.push({
      id: 5,
      label: t('sidebar.portfolios'),
      link: '/app/portfolios',
      icon: <PortfoliosIcon />,
      ...THEME_TOKENS,
    });
  }

  // ----- Posts -----
  if (hasPermission('posts.view')) {
    structure.push({
      id: 6,
      label: t('sidebar.posts'),
      link: '/app/posts',
      icon: <PostsIcon />,
      children: [{ label: t('sidebar.allPosts'), link: '/app/posts', icon: <PostsIcon />, ...THEME_TOKENS }],
      ...THEME_TOKENS,
    });
  }

  // ----- Service Requests -----
  if (hasPermission('requests.view')) {
    structure.push({
      id: 7,
      label: t('sidebar.serviceRequests'),
      link: '/app/requests',
      icon: <RequestsIcon />,
      children: [{ label: t('sidebar.allRequests'), link: '/app/requests', icon: <RequestsIcon />, ...THEME_TOKENS }],
      ...THEME_TOKENS,
    });
  }

  // ----- SMS Logs -----
  if (hasPermission('sms.view')) {
    structure.push({
      id: 14,
      label: t('sidebar.smsLogs'),
      link: '/app/sms-logs',
      icon: <SmsIcon />,
      children: [{ label: t('sidebar.allSmsLogs'), link: '/app/sms-logs', icon: <SmsIcon />, ...THEME_TOKENS }],
      ...THEME_TOKENS,
    });
  }

  // ----- Finance -----
  if (hasPermission('finance.view')) {
    const financeChildren = [
      { label: t('sidebar.subscriptions'), link: '/app/finance/subscriptions', icon: <SubscriptionsIcon />, ...COMING_SOON_TOKENS },
      { label: t('sidebar.technicians'),   link: '/app/finance/technicians',   icon: <TechniciansIcon />, ...THEME_TOKENS },
      { label: t('sidebar.customers'),     link: '/app/finance/customers',     icon: <PeopleIcon />, ...THEME_TOKENS },
      { label: t('sidebar.requests'),      link: '/app/finance/requests',      icon: <RequestsIcon />, ...THEME_TOKENS },
      ...addIf(
          hasPermission('jobs.view'),
          {
            label: t('sidebar.jobs'),
            link: '/app/finance/jobs',
            icon: <WorkIcon />,
            ...THEME_TOKENS,
          }
      ),
    ];

    structure.push({
      id: 13,
      label: t('sidebar.finance'),
      link: '/app/finance',
      icon: <FinanceIcon />,
      children: financeChildren,
      ...THEME_TOKENS,
    });
  }

  // ----- Monitoring -----
  if (hasPermission('monitoring.view')) {
    structure.push({
      id: 10,
      label: t('sidebar.monitoring'),
      link: '/app/monitoring',
      icon: <MonitoringIcon />,
      children: [
        { label: t('sidebar.monitoringDashboard'), link: '/app/monitoring', icon: <MonitoringIcon />, ...THEME_TOKENS },
      ],
      ...THEME_TOKENS,
    });
  }

  // ----- Subscriptions (Main Menu) -----
  const subscriptionChildren = [
    ...addIf(hasPermission('subscriptions.view'), {
      label: t('sidebar.allSubscriptions'),
      link: '/app/subscriptions',
      icon: <SubscriptionsIcon />,
      ...COMING_SOON_TOKENS,
    }),
    ...addIf(hasPermission('subscriptions.manage'), {
      label: t('sidebar.rateCards'),
      link: '/app/rate-cards',
      icon: <RateCardIcon />,
      ...COMING_SOON_TOKENS,
    }),
    ...addIf(hasPermission('subscriptions.manage'), {
      label: t('sidebar.paymentMethods'),
      link: '/app/payment-methods',
      icon: <PaymentMethodIcon />,
      ...COMING_SOON_TOKENS,
    }),
  ];

  if (subscriptionChildren.length > 0) {
    structure.push({
      id: 12,
      label: t('sidebar.subscriptions'),
      link: '#',
      icon: <SubscriptionsIcon />,
      children: subscriptionChildren,
      ...COMING_SOON_TOKENS,
    });
  }

  // ----- Banners -----
  if (hasPermission('banners.view') || hasPermission('dashboard.view')) {
    structure.push({
      id: 15,
      label: t('sidebar.banners'),
      link: '/app/banners',
      icon: <BannersIcon />,
      ...THEME_TOKENS,
    });
  }

  // ==========================================
  // ----- REPORTS (NEW - Added before Settings) -----
  // ==========================================
  if (hasPermission('reports.view') || hasPermission('dashboard.view')) {
    structure.push({
      id: 16,
      label: t('sidebar.reports') || 'Reports',
      link: '/app/reports',
      icon: <ReportsIcon />,
      ...THEME_TOKENS,
    });
  }

  // ----- Settings -----
  const settingsChildren = [
    ...addIf(hasPermission('users.view'), {
      label: t('sidebar.users'),
      link: '/app/users',
      icon: <PeopleIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('roles.view'), {
      label: t('sidebar.roles'),
      link: '/app/roles',
      icon: <RolesIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('permissions.view'), {
      label: t('sidebar.permissions'),
      link: '/app/permissions',
      icon: <PermissionsIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('audit.view'), {
      label: t('sidebar.auditLogs'),
      link: '/app/audit',
      icon: <AuditIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('otp.view'), {
      label: t('sidebar.otpManagement'),
      link: '/app/otp',
      icon: <OtpIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('profile.view'), {
      label: t('sidebar.profile'),
      link: '/app/profile',
      icon: <ProfileIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('miniapp-qrs.view'), {
      label: t('sidebar.miniAppQr'),
      link: '/app/miniappqr',
      icon: <QrCodeIcon />,
      ...THEME_TOKENS,
    }),
    ...addIf(hasPermission('system-updates.manage'), {
      label: t('sidebar.systemUpdates'),
      link: '/app/system-updates',
      icon: <SystemUpdatesIcon />,
      ...THEME_TOKENS,
    }),
  ];

  if (settingsChildren.length > 0) {
    structure.push({
      id: 9,
      label: t('sidebar.settings'),
      link: '#',
      icon: <SettingsIcon />,
      children: settingsChildren,
      ...THEME_TOKENS,
    });
  }

  return structure;
}

export default getSidebarStructure;