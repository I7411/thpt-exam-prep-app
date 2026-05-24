import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz; // <-- THÊM DÒNG NÀY ĐỂ IMPORT MÚI GIỜ
import 'app.dart';
import 'app_navigation.dart';
import 'data/local/notification_service.dart';
import 'providers/exam_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/teacher_provider.dart';
import 'providers_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // KHỞI TẠO MÚI GIỜ TRƯỚC KHI INIT NOTIFICATION SERVICE
  tz.initializeTimeZones(); // <-- THÊM DÒNG NÀY ĐỂ SỬA LỖI ASIA/SAIGON

  await NotificationService.instance.initialize(
    onNotificationTap: (payload) async {
      if (payload == null || payload.isEmpty) return;

      final navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        NotificationService.instance.queuePendingPayload(payload);
        return;
      }

      navigator.pushNamed(payload);
    },
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
      ],
      child: const ThptSmartLearnApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.handlePendingLaunchNotification();
  });
}