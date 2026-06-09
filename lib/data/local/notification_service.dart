import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:thpt_exam_prep_app/app_routes.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> Function(String? payload)? _onNotificationTap;
  String? _pendingPayload;
  bool _initialized = false;

  static const String _channelId = 'study_reminders';
  static const String _channelName = 'Study reminders';
  static const String _channelDescription =
      'Local reminders for study planning';

  Future<void> initialize({
    required Future<void> Function(String? payload) onNotificationTap,
  }) async {
    if (_initialized) return;

    _onNotificationTap = onNotificationTap;

    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;

        if (payload != null && payload.isNotEmpty) {
          await _handleTap(payload);
        }
      },
    );

    await _requestPermissions();
    await _loadInitialLaunchPayload();

    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();

    try {
      final dynamic localTimezone = await FlutterTimezone.getLocalTimezone();

      String timeZoneName;

      if (localTimezone is String) {
        timeZoneName = localTimezone;
      } else {
        final dynamic identifier = localTimezone.identifier;
        timeZoneName = identifier is String && identifier.isNotEmpty
            ? identifier
            : 'Asia/Ho_Chi_Minh';
      }

      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }
  }

  Future<void> handlePendingLaunchNotification() async {
    final payload = _pendingPayload;
    _pendingPayload = null;

    if (payload == null || payload.isEmpty) return;

    await _handleTap(payload);
  }

  void queuePendingPayload(String payload) {
    if (payload.isEmpty) return;

    _pendingPayload = payload;
  }

  Future<void> showStudyReminderDemo({
    String payload = AppRoutes.studentNotifications,
  }) async {
    await _plugin.zonedSchedule(
      _randomNotificationId(),
      'Nhắc học',
      'Đến giờ ôn tập ngắn trong ngày.',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      _notificationDetails(),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleDailyStudyReminder({
    String payload = AppRoutes.studentProgress,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      19,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1900,
      'Nhắc học hằng ngày',
      'Đến giờ học tập theo kế hoạch.',
      scheduledTime,
      _notificationDetails(),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) return;

    final dynamic androidPlugin = androidImplementation;

    try {
      await androidPlugin.requestNotificationsPermission();
      return;
    } catch (_) {
      // Fallback for older flutter_local_notifications versions.
    }

    try {
      await androidPlugin.requestPermission();
    } catch (_) {
      // Some versions/platforms do not expose a notification permission API.
    }
  }

  Future<void> _loadInitialLaunchPayload() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _pendingPayload = launchDetails?.notificationResponse?.payload;
    }
  }

  Future<void> _handleTap(String payload) async {
    final handler = _onNotificationTap;

    if (handler != null) {
      await handler(payload);
      return;
    }

    _pendingPayload = payload;
  }

  int _randomNotificationId() {
    return 1000 + Random().nextInt(800000);
  }
}