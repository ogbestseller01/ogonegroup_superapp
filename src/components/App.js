import React from 'react';
import { BrowserRouter, Navigate, Route, Routes, useNavigate } from 'react-router-dom';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import { setNavigator } from 'router/navigation';
import { AuthProvider, useAuth } from 'context/AuthContext';

// System Components
import Documentation from 'components/Documentation';
import Layout from 'components/Layout';
import Login from 'pages/login/Login';
import VerifyOTP from 'pages/verify_otp/VerifyOTP';
import ResetPassword from 'pages/reset_password/ResetPassword';
import ForgotPassword from 'pages/forgot_password/ForgotPassword';
import Error from 'pages/error/Error';

// Primary Pages
import Profile from 'pages/profile';
import Dashboard from 'pages/dashboard/Dashboard';
import UsersList from 'pages/user';
import PermissionsList from 'pages/permissions/PermissionList';
import RoleList from 'pages/roles/RoleList';
import AuditList from 'pages/audit/AuditList';
import OtpList from 'pages/otp/OtpList';
import AboutPage from 'pages/about/AboutPage';
import TermsPage from 'pages/terms/TermsPage';
import FaqList from 'pages/faqs/FaqList';
import TechniciansList from 'pages/technicians/TechniciansList';
import TechnicianDetails from 'pages/technicians/TechnicianDetails';
import PortfoliosList from 'pages/portfolios/PortfoliosList';
import PostsList from 'pages/posts/PostsList';
import RequestsList from 'pages/requests/RequestsList';
import ServicesList from 'pages/services/ServicesList';
import CategoriesList from 'pages/categories/CategoriesList';
import MonitoringMap from 'pages/monitoring/MonitoringMap';
import PrivacyPolicyPage from 'pages/privacy-policy/PrivacyPolicyPage';

// Subscription Pages
import SubscriptionList from 'pages/subscriptions/SubscriptionList';
import RateCardManagement from 'pages/subscriptions/RateCardManagement';
import PaymentMethodManagement from 'pages/subscriptions/PaymentMethodManagement';

// Finance Pages
import FinanceLayout from 'pages/finance/FinanceLayout';
import FinanceSubscriptions from 'pages/finance/FinanceSubscriptions';
import FinanceTechnicians from 'pages/finance/FinanceTechnicians';
import FinanceCustomers from 'pages/finance/FinanceCustomers';
import FinanceRequests from 'pages/finance/FinanceRequests';
import JobsList from 'pages/jobs/JobsList';

// Reports Page (NEW)
import PrintReport from 'pages/print_report/PrintReport';

// SMS Logs Pages
import SmsLogsList from 'pages/sms/SmsLogsList';

// Mini App QR Pages
import MiniAppQrList from 'pages/miniappqr/MiniAppQrList';

// Banners Page
import BannerList from 'pages/banners/BannerList';

// System Updates Page
import SystemUpdatesList from 'pages/system-updates/SystemUpdatesList';

// Context Providers
import { LanguageProvider } from 'context/LanguageContext';
import { UserProvider } from 'context/UserContext';
import { RoleProvider } from 'context/RoleContext';
import { PermissionProvider } from 'context/PermissionContext';
import { AuditProvider } from 'context/AuditContext';
import { OtpProvider } from 'context/OtpContext';
import { DashboardProvider } from 'context/DashboardContext';
import { AboutProvider } from 'context/AboutContext';
import { TermsProvider } from 'context/TermsContext';
import { FaqProvider } from 'context/FaqContext';
import { ServiceProvider } from 'context/ServiceContext';
import { TechnicianProvider } from 'context/TechnicianContext';
import { AdminTechnicianProvider } from 'context/AdminTechnicianContext';
import { PortfolioProvider } from 'context/PortfolioContext';
import { PostProvider } from 'context/PostContext';
import { CommentProvider } from 'context/CommentContext';
import { LikeProvider } from 'context/LikeContext';
import { RequestProvider } from 'context/RequestContext';
import { JobProvider } from 'context/JobContext';
import { PrintReportProvider } from 'context/PrintReportContext'; // NEW
import { ReportProvider } from 'context/ReportContext';
import {
    RateCardProvider,
    PaymentMethodProvider,
    SubscriptionProvider,
} from 'context/SubscriptionContext';
import { PrivacyPolicyProvider } from 'context/PrivacyPolicyContext';
import { SmsProvider } from 'context/SmsContext';
import { MiniAppQrProvider } from 'context/MiniAppQrContext';
import { BannerProvider } from 'context/BannerContext';
import { SystemUpdateProvider } from 'context/SystemUpdateContext';

// Route Guards
const PrivateRoute = ({ children, isAuthenticated }) => {
    if (!isAuthenticated) return <Navigate to="/login" replace />;
    return children;
};

const PublicRoute = ({ children, isAuthenticated }) => {
    if (isAuthenticated) return <Navigate to="/app/dashboard" replace />;
    return children;
};

function RouterNavigatorSync() {
    const navigate = useNavigate();
    React.useEffect(() => {
        setNavigator(navigate);
        return () => setNavigator(null);
    }, [navigate]);
    return null;
}

function AppContent() {
    const { isAuthenticated, isLoading } = useAuth();

    if (isLoading) {
        return (
            <div
                style={{
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    height: '100vh',
                }}
            >
                Loading...
            </div>
        );
    }

    return (
        <Routes>
            {/* Public Routes */}
            <Route path="/login" element={<PublicRoute isAuthenticated={isAuthenticated}><Login /></PublicRoute>} />
            <Route path="/verify-otp" element={<PublicRoute isAuthenticated={isAuthenticated}><VerifyOTP /></PublicRoute>} />
            <Route path="/reset-password" element={<PublicRoute isAuthenticated={isAuthenticated}><ResetPassword /></PublicRoute>} />
            <Route path="/forgot-password" element={<PublicRoute isAuthenticated={isAuthenticated}><ForgotPassword /></PublicRoute>} />

            {/* Error Pages */}
            <Route path="/403" element={<Error code={403} />} />
            <Route path="/500" element={<Error code={500} />} />

            {/* Documentation */}
            <Route path="/documentation/*" element={<Documentation />} />

            {/* Protected Routes */}
            <Route path="/app/*" element={<PrivateRoute isAuthenticated={isAuthenticated}><Layout /></PrivateRoute>}>
                <Route path="profile" element={<Profile />} />
                <Route path="dashboard" element={<Dashboard />} />
                <Route path="users" element={<UsersList />} />
                <Route path="users/create" element={<UsersList />} />
                <Route path="users/:id/edit" element={<UsersList />} />
                <Route path="users/:id/view" element={<UsersList />} />
                <Route path="roles" element={<RoleList />} />
                <Route path="roles/create" element={<RoleList />} />
                <Route path="roles/:id/edit" element={<RoleList />} />
                <Route path="roles/:id/view" element={<RoleList />} />
                <Route path="permissions" element={<PermissionsList />} />
                <Route path="permissions/create" element={<PermissionsList />} />
                <Route path="permissions/:id/edit" element={<PermissionsList />} />
                <Route path="permissions/:id/view" element={<PermissionsList />} />
                <Route path="audit" element={<AuditList />} />
                <Route path="otp" element={<OtpList />} />
                <Route path="about" element={<AboutPage />} />
                <Route path="terms" element={<TermsPage />} />
                <Route path="faqs" element={<FaqList />} />
                <Route path="faqs/create" element={<FaqList />} />
                <Route path="faqs/:id/edit" element={<FaqList />} />
                <Route path="services" element={<ServicesList />} />
                <Route path="services/categories" element={<CategoriesList />} />
                <Route path="services/create" element={<ServicesList />} />
                <Route path="services/:id/edit" element={<ServicesList />} />
                <Route path="technicians" element={<TechniciansList />} />
                <Route path="technicians/:id" element={<TechnicianDetails />} />
                <Route path="portfolios" element={<PortfoliosList />} />
                <Route path="posts" element={<PostsList />} />
                <Route path="requests" element={<RequestsList />} />
                <Route path="monitoring" element={<MonitoringMap />} />

                {/* NEW Reports Route */}
                <Route path="reports" element={<PrintReport />} />

                <Route path="subscriptions" element={<SubscriptionList />} />
                <Route path="rate-cards" element={<RateCardManagement />} />
                <Route path="payment-methods" element={<PaymentMethodManagement />} />
                <Route path="privacy-policy" element={<PrivacyPolicyPage />} />
                <Route path="sms-logs" element={<SmsLogsList />} />

                <Route path="miniappqr" element={<MiniAppQrList />} />
                <Route path="banners" element={<BannerList />} />
                <Route path="system-updates" element={<SystemUpdatesList />} />

                <Route path="finance" element={<FinanceLayout />}>
                    <Route index element={<Navigate to="/app/finance/subscriptions" replace />} />
                    <Route path="subscriptions" element={<FinanceSubscriptions />} />
                    <Route path="technicians" element={<FinanceTechnicians />} />
                    <Route path="customers" element={<FinanceCustomers />} />
                    <Route path="requests" element={<FinanceRequests />} />
                    <Route path="jobs" element={<JobsList />} />
                    <Route path="*" element={<Navigate to="/app/finance/subscriptions" replace />} />
                </Route>

                <Route index element={<Navigate to="/app/dashboard" replace />} />
                <Route path="*" element={<Navigate to="/app/dashboard" replace />} />
            </Route>

            <Route path="/" element={<Navigate to="/app/dashboard" replace />} />
            <Route path="/app" element={<Navigate to="/app/dashboard" replace />} />
            <Route path="*" element={<Error />} />
        </Routes>
    );
}

// Context Provider Composer
const PROVIDERS = [
    LanguageProvider,
    AuthProvider,
    DashboardProvider,
    UserProvider,
    RoleProvider,
    PermissionProvider,
    AuditProvider,
    OtpProvider,
    AboutProvider,
    TermsProvider,
    FaqProvider,
    PrivacyPolicyProvider,
    ServiceProvider,
    TechnicianProvider,
    AdminTechnicianProvider,
    PortfolioProvider,
    PostProvider,
    CommentProvider,
    LikeProvider,
    RequestProvider,
    JobProvider,
    PrintReportProvider, // NEW
    ReportProvider,
    RateCardProvider,
    PaymentMethodProvider,
    SubscriptionProvider,
    SmsProvider,
    MiniAppQrProvider,
    BannerProvider,
    SystemUpdateProvider,
];

const AppProviders = ({ children }) =>
    PROVIDERS.reduceRight((acc, Provider) => <Provider>{acc}</Provider>, children);

export default function App() {
    return (
        <BrowserRouter>
            <AppProviders>
                <ToastContainer position="top-right" autoClose={3000} hideProgressBar={false} />
                <RouterNavigatorSync />
                <AppContent />
            </AppProviders>
        </BrowserRouter>
    );
}