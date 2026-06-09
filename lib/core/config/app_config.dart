import 'package:flutter/foundation.dart';

/// Application configuration
class AppConfig {
  static const String appName = 'THPT Smart Learn';
  static const String appVersion = '1.0.0';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5185/api',
  );

  static const int apiTimeout = 30;
  static const bool enableApiLogging = true;

  static const String dbName = 'thpt_smart_learn.db';
  static const int dbVersion = 1;

  static const bool enableMockData = true;
  static const bool enableDevTools = false;

  static void printConfig() {
    debugPrint('=== Cấu hình Ứng dụng ===');
    debugPrint('Tên ứng dụng: $appName');
    debugPrint('Phiên bản: $appVersion');
    debugPrint('Địa chỉ API: $apiBaseUrl');
    debugPrint('Thời gian chờ API: ${apiTimeout}s');
    debugPrint('Ghi log API: $enableApiLogging');
    debugPrint('Sử dụng dữ liệu giả lập: $enableMockData');
    debugPrint('========================');
  }
}
