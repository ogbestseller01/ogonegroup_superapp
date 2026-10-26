// lib/config/app_config.dart

class AppConfig {
  static const String baseUrl = 'http://172.18.5.97:8000/api';
  static const String appName = 'NearbyFundi';
  static const String appVersion = '0.0.1';

  // 👇 Use Pusher Cloud (works on any network)
  static const String webSocketUrl = 'https://mt1.pusher.com';

  static const String storageBaseUrl = 'http://172.18.5.97:8000/storage';
}