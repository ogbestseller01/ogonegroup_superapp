// lib/config/app_config.dart

class AppConfig {
  static const String baseUrl = 'http://192.168.100.144:8000/api';
  static const String appName = 'NearbyFundi';
  static const String appVersion = '0.0.1';

  // Pusher Channels Cloud – matches BROADCAST_DRIVER=pusher in Laravel .env
  static const String pusherAppKey = 'cf6d6176d4a97cf49517';
  static const String pusherCluster = 'mt1';

  // Authorization endpoint for private channels – Laravel registers this
  // via Broadcast::routes() under the /api prefix.
  static const String broadcastAuthUrl = '$baseUrl/broadcasting/auth';

  static const String storageBaseUrl = 'http://192.168.100.144:8000/storage';
}