// lib/config/google_config.dart

class GoogleConfig {
  GoogleConfig._();

  /// WEB client ID. The ID token is issued for this client and the Laravel
  /// server verifies it. It MUST also be listed in the backend .env:
  ///   GOOGLE_CLIENT_IDS=911035937686-0060npubekah8kl8d3qldq2539tr3u2m.apps.googleusercontent.com
  static const String webClientId =
      '911035937686-0060npubekah8kl8d3qldq2539tr3u2m.apps.googleusercontent.com';

  /// iOS client ID (type "iOS" in Google Cloud Console). Leave null on
  /// Android-only builds, or if GIDClientID is already in Info.plist.
  static const String? iosClientId = null;
}