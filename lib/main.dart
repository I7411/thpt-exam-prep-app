import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'app_navigation.dart';

import 'services/notification_service.dart';

import 'controllers/exam_controller.dart';
import 'controllers/admin_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/progress_controller.dart';
import 'controllers/teacher_controller.dart';
import 'controllers/teacher_student_connection_controller.dart';
import 'controllers/auth_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('Nhận thông báo FCM ở chế độ nền: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Đang khởi tạo Firebase...');
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('Firebase đã khởi tạo thành công.');

  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Không thể đăng ký FCM background handler: $e');
  }

  try {
    await NotificationService.instance
        .initialize(
          onNotificationTap: (payload) async {
            if (payload == null || payload.isEmpty) return;

            final navigator = appNavigatorKey.currentState;
            if (navigator == null) {
              NotificationService.instance.queuePendingPayload(payload);
              return;
            }

            navigator.pushNamed(payload);
          },
        )
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Không thể khởi tạo thông báo local lúc mở app: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),

        ChangeNotifierProvider(create: (_) => ExamController()),

        ChangeNotifierProvider(create: (_) => AdminController()),

        ChangeNotifierProvider(create: (_) => ProgressController()),

        ChangeNotifierProvider(create: (_) => NotificationController()),

        ChangeNotifierProvider(create: (_) => TeacherController()),

        ChangeNotifierProvider(
          create: (_) => TeacherStudentConnectionController(),
        ),
      ],

      child: const ThptSmartLearnApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.handlePendingLaunchNotification();
  });
}
