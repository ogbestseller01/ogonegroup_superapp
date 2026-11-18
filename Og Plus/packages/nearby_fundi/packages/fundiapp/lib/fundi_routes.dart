// packages/nearby_fundi/packages/fundiapp/lib/fundi_routes.dart
//
// Route generator used by FundiMiniApp (embedded mode).
// Must stay in sync with generateFundiAppRoute in main.dart

import 'package:flutter/material.dart';

import 'config/app_routes.dart';
import 'models/chat_conversation.dart';

// Auth screens
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/register_flow/register_location_screen.dart';
import 'screens/auth/register_flow/register_review_screen.dart';
import 'screens/auth/register_flow/register_services_screen.dart';
import 'screens/auth/register_flow/register_step1_screen.dart';
import 'screens/auth/register_flow/register_step2_screen.dart';
import 'screens/auth/register_flow/register_step3_screen.dart';
import 'screens/auth/register_flow/register_step4_screen.dart';
import 'screens/auth/register_flow/register_step5_screen.dart';
import 'screens/auth/reset_password_screen.dart';

// Main screens
import 'screens/chat/fundi_chat_screen.dart';
import 'screens/fundi/fundi_home_screen.dart';
import 'screens/fundi/fundi_portfolio_screen.dart';
import 'screens/fundi/fundi_posts_screen.dart';
import 'screens/fundi/fundi_requests_screen.dart';
import 'screens/fundi/profile/edit_profile_screen.dart';
import 'screens/fundi/profile/fundi_profile_screen.dart';
import 'screens/fundi/profile/fundi_settings_screen.dart';
import 'screens/jobs/jobs_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/static/about_screen.dart';
import 'screens/static/contact_us_screen.dart';
import 'screens/static/faq_screen.dart';
import 'screens/static/privacy_policy_screen.dart';
import 'screens/static/terms_screen.dart';
import 'screens/tickets/tickets_screen.dart';

// Payments (if used in mini-app)
import 'payments/screens/payment_screen.dart';

Route<dynamic> generateFundiRoute(RouteSettings settings) {
  final Object? args = settings.arguments;

  MaterialPageRoute<dynamic> route(Widget page) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  switch (settings.name) {
  // ── Entry screens ─────────────────────────────────────
    case AppRoutes.splash:
      return route(const SplashScreen());
    case AppRoutes.onboarding:
      return route(const OnboardingScreen());
    case AppRoutes.login:
      return route(const LoginScreen());

  // ── Registration flow ─────────────────────────────────
    case AppRoutes.registerStep1:
      return route(RegisterStep1Screen(
        initialData: args is Map<String, dynamic> && args.isNotEmpty ? args : null,
      ));

    case AppRoutes.registerServices:
      if (args is Map<String, dynamic> && args.isNotEmpty) {
        return route(RegisterServicesScreen(args: args));
      }
      return route(const RegisterStep1Screen());

    case AppRoutes.registerLocation:
      if (args is Map<String, dynamic> && args.isNotEmpty) {
        return route(RegisterLocationScreen(args: args));
      }
      return route(const RegisterStep1Screen());

    case AppRoutes.registerStep2:
      return route(RegisterStep2Screen(draftId: _getDraftArgument(args)));
    case AppRoutes.registerStep3:
      return route(RegisterStep3Screen(draftId: _getDraftArgument(args)));
    case AppRoutes.registerStep4:
      return route(RegisterStep4Screen(draftId: _getDraftArgument(args)));
    case AppRoutes.registerStep5:
      return route(RegisterStep5Screen(draftId: _getDraftArgument(args)));

    case AppRoutes.registerReview:
      if (args is Map<String, dynamic>) {
        final id = _getDraftArgument(args);
        if (id <= 0) return route(const RegisterStep1Screen());
        return route(RegisterReviewScreen(draftId: id, extra: args));
      }
      if (args is int && args > 0) {
        return route(RegisterReviewScreen(draftId: args));
      }
      return route(const RegisterStep1Screen());

  // ── OTP ───────────────────────────────────────────────
    case AppRoutes.otp:
      if (args is Map<String, dynamic>) {
        final identifier = (args['identifier'] ??
            args['phone'] ??
            args['email'] ??
            '')
            .toString();
        return route(OtpVerificationScreen(
          identifier: identifier,
          email: args['email']?.toString(),
          phone: args['phone']?.toString(),
          redirectToStep2: args['redirectToStep2'] == true,
          draftId: _nullableInt(args['draftId'] ?? args['technicianId']),
        ));
      }
      return route(OtpVerificationScreen(
        identifier: args?.toString() ?? '',
      ));

    case AppRoutes.forgot:
      return route(const ForgotPasswordScreen());
    case AppRoutes.reset:
      return route(ResetPasswordScreen(email: args?.toString() ?? ''));

  // ── Main fundi screens ────────────────────────────────
    case AppRoutes.home:
      return route(const FundiHomeScreen());
    case AppRoutes.posts:
    case AppRoutes.blog:
    case AppRoutes.createPost:
    case AppRoutes.editPost:
      return route(const FundiPostsScreen());
    case AppRoutes.portfolio:
    case AppRoutes.addPortfolio:
    case AppRoutes.editPortfolio:
      return route(const FundiPortfolioScreen());
    case AppRoutes.requests:
      return route(const FundiRequestsScreen());
    case AppRoutes.notifications:
      return route(const FundiHomeScreen());
    case AppRoutes.profile:
      return route(const FundiProfileScreen());
    case AppRoutes.editProfile:
      return route(const EditProfileScreen());
    case AppRoutes.settings:
      return route(const FundiSettingsScreen());

  // ── Tickets & Jobs ────────────────────────────────────
    case AppRoutes.tickets:
      return route(const TicketsScreen());
    case AppRoutes.jobs:
      return route(const JobsScreen());

  // ── Chat ──────────────────────────────────────────────
    case AppRoutes.chatList:
    // Adjust import if your chat list screen name is different
      return route(const FundiHomeScreen()); // temporary fallback
    case AppRoutes.chat:
      if (args is ChatConversation) {
        return route(FundiChatScreen(conversation: args));
      }
      return route(const FundiHomeScreen());

  // ── Payment ───────────────────────────────────────────
    case AppRoutes.payment:
      if (args is Map<String, dynamic>) {
        return route(PaymentScreen(
          reference: args['reference']?.toString() ?? 'UNKNOWN',
          requestsCount: args['requestsCount'] as int?,
          customerPhone: args['customerPhone']?.toString(),
        ));
      }
      return route(const SplashScreen());

  // ── Static pages ──────────────────────────────────────
    case AppRoutes.about:
      return route(const AboutScreen());
    case AppRoutes.terms:
      return route(const TermsScreen());
    case AppRoutes.faq:
      return route(const FaqScreen());
    case AppRoutes.contactUs:
      return route(const ContactUsScreen());
    case AppRoutes.privacy:
      return route(const PrivacyPolicyScreen());

    default:
      return route(const SplashScreen());
  }
}

// ── Helpers (same as main.dart) ─────────────────────────────

int _getDraftArgument(Object? args) {
  if (args is int) return args;
  if (args is String) return int.tryParse(args) ?? 0;
  if (args is Map<String, dynamic>) {
    final value = args['draftId'] ?? args['technicianId'] ?? args['id'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
  }
  return 0;
}

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}