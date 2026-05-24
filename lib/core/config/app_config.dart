/// Application configuration
class AppConfig {
  static const String appName = 'THPT Smart Learn';
  static const String appVersion = '1.0.0';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.10:5130/api',
  );

  static const int apiTimeout = 30;
  static const bool enableApiLogging = true;

  static const String dbName = 'thpt_smart_learn.db';
  static const int dbVersion = 1;

  static const bool enableMockData = true;
  static const bool enableDevTools = false;

  static void printConfig() {
    // ignore: avoid_print
    print('=== App Configuration ===');
    // ignore: avoid_print
    print('App Name: $appName');
    // ignore: avoid_print
    print('App Version: $appVersion');
    // ignore: avoid_print
    print('API Base URL: $apiBaseUrl');
    // ignore: avoid_print
    print('API Timeout: ${apiTimeout}s');
    // ignore: avoid_print
    print('Enable API Logging: $enableApiLogging');
    // ignore: avoid_print
    print('Enable Mock Data: $enableMockData');
    // ignore: avoid_print
    print('========================');
  }
}