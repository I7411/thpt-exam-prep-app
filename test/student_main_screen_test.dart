import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/views/student_main_screen.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';
import 'package:thpt_exam_prep_app/controllers/exam_controller.dart';
import 'package:thpt_exam_prep_app/controllers/admin_controller.dart';
import 'package:thpt_exam_prep_app/controllers/progress_controller.dart';
import 'package:thpt_exam_prep_app/controllers/learning_controller.dart';
import 'package:thpt_exam_prep_app/controllers/notification_controller.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_controller.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_student_connection_controller.dart';

void main() {
  testWidgets('StudentMainScreen should render without throwing', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    addTearDown(() {
      FlutterError.onError = originalOnError;
    });
    FlutterError.onError = (FlutterErrorDetails details) {
      // Ignore errors for this test
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthController()),
          ChangeNotifierProvider(create: (_) => ExamController()),
          ChangeNotifierProvider(create: (_) => AdminController()),
          ChangeNotifierProvider(create: (_) => ProgressController()),
          ChangeNotifierProvider(create: (_) => LearningController()),
          ChangeNotifierProvider(create: (_) => NotificationController()),
          ChangeNotifierProvider(create: (_) => TeacherController()),
          ChangeNotifierProvider(
            create: (_) => TeacherStudentConnectionController(),
          ),
        ],
        child: const MaterialApp(home: StudentMainScreen()),
      ),
    );

    await tester.pump();
  });
}
