// lib/providers/auth_issue_text.dart

import '../l10n/app_localizations.dart';
import 'auth_provider.dart';

extension AuthIssueText on AuthIssue {
  String text(AppLocalizations l) => switch (this) {
    AuthIssue.loginFailed => l.loginFailed,
    AuthIssue.network => l.loginNetworkError,
    AuthIssue.notFundiAccount => l.loginNotFundiAccount,
    AuthIssue.savedLoginInvalid => l.loginSavedLoginInvalid,
    AuthIssue.sessionExpired => l.loginSessionExpired,
    AuthIssue.registrationExpired => l.loginRegistrationExpired,
    AuthIssue.phoneTaken => l.loginPhoneTaken,
    AuthIssue.phoneDeleted => l.loginPhoneDeleted,
    AuthIssue.emailTaken => l.loginEmailTaken,
    AuthIssue.idTaken => l.loginIdTaken,
    AuthIssue.stepsIncomplete => l.loginStepsIncomplete,
    AuthIssue.submitFailed => l.loginSubmitFailed,
  };
}

extension AuthProviderErrorText on AuthProvider {
  /// Localized message for the current error. Falls back to the server text.
  /// Use this in the register / OTP screens too: `auth.errorText(l10n)`.
  String errorText(AppLocalizations l) {
    final i = issue;
    if (i != null) return i.text(l);
    final m = errorMessage;
    return (m != null && m.isNotEmpty) ? m : l.loginFailed;
  }
}