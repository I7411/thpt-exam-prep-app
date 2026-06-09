import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'app_navigation.dart';

import 'services/notification_service.dart';

import 'controllers/exam_controller.dart';
import 'controllers/admin_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/progress_controller.dart';
import 'controllers/teacher_controller.dart';
import 'controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        ChangeNotifierProvider(
          create: (_) => AuthController(),
        ),

        ChangeNotifierProvider(
          create: (_) => ExamController(),
        ),

        ChangeNotifierProvider(
          create: (_) => AdminController(),
        ),

        ChangeNotifierProvider(
          create: (_) => ProgressController(),
        ),

        ChangeNotifierProvider(
          create: (_) => NotificationController(),
        ),

        ChangeNotifierProvider(
          create: (_) => TeacherController(),
        ),
      ],

      child: const ThptSmartLearnApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance
        .handlePendingLaunchNotification();
  });
}
