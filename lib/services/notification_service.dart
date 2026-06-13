import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/services/ringtone_catalog_service.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> Function(String? payload)? _onNotificationTap;
  String? _pendingPayload;
  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  void Function(int id, String title, String body, String? payload)?
  onForegroundNotification;

  // Dialog duplicate protection cache
  final Set<String> _shownDialogIds = {};
  final List<MapEntry<DateTime, String>> _shownDialogLog = [];

  bool _isDialogDuplicate(String? id) {
    if (id == null || id.isEmpty) return false;
    final now = DateTime.now();

    // Clean up log entries older than 8 seconds
    _shownDialogLog.removeWhere((entry) {
      if (now.difference(entry.key).inSeconds > 8) {
        _shownDialogIds.remove(entry.value);
        return true;
      }
      return false;
    });

    if (_shownDialogIds.contains(id)) {
      debugPrint('Trùng lặp hội thoại thông báo phát hiện và ngăn chặn: $id');
      return true;
    }

    _shownDialogIds.add(id);
    _shownDialogLog.add(MapEntry(now, id));
    return false;
  }

  void _triggerForegroundNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? deduplicationId,
  }) {
    final dupId = deduplicationId ?? '${id}_${title}_$body';
    if (_isDialogDuplicate(dupId)) {
      return;
    }

    final handler = onForegroundNotification;
    if (handler != null) {
      handler(id, title, body, payload);
    }
  }

  // Notification Channel Constants
  static const String _channelId = 'thpt_exam_prep_channel';
  static const String _channelName = 'THPT Exam Prep Channel';
  static const String _channelDescription =
      'Channel for all THPT Exam Prep notifications';

  // Duplicate protection cache
  final Set<String> _processedNotificationIds = {};
  final List<MapEntry<DateTime, String>> _processedLog = [];

  bool _isDuplicate(String? id) {
    if (id == null || id.isEmpty) return false;
    final now = DateTime.now();

    // Clean up log entries older than 8 seconds
    _processedLog.removeWhere((entry) {
      if (now.difference(entry.key).inSeconds > 8) {
        _processedNotificationIds.remove(entry.value);
        return true;
      }
      return false;
    });

    if (_processedNotificationIds.contains(id)) {
      debugPrint('Trùng lặp thông báo phát hiện và ngăn chặn: $id');
      return true;
    }

    _processedNotificationIds.add(id);
    _processedLog.add(MapEntry(now, id));
    return false;
  }

  Future<void> initialize({
    required Future<void> Function(String? payload) onNotificationTap,
  }) async {
    if (_initialized) return;

    _onNotificationTap = onNotificationTap;

    await _configureLocalTimeZone();

    // 1. Initialize local notifications settings
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
        debugPrint('Nhấp vào thông báo local: payload=$payload');
        if (payload != null && payload.isNotEmpty) {
          await _handleTap(payload);
        }
      },
    );

    // Create consistent notification channel programmatically
    await _createNotificationChannel();

    // 2. Request runtime permissions
    await _requestPermissions();

    // 3. Initialize Firebase Messaging (FCM)
    await _initializeFcm();

    // 4. Load initial launch payload
    await _loadInitialLaunchPayload();

    _initialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const androidNotificationChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidNotificationChannel);
      debugPrint('Đã đăng ký kênh thông báo Android: $_channelId');
    }
  }

  Future<void> _initializeFcm() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request FCM permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Quyền FCM được cấp: ${settings.authorizationStatus}');

      // Get FCM Token
      _fcmToken = await messaging.getToken();
      debugPrint('FCM Registration Token: $_fcmToken');

      // Listen to Token refresh
      messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM Token làm mới: $token');
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          saveTokenToFirestore(currentUser.uid);
        }
      });

      // Handle FCM foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'Nhận được thông báo FCM ở chế độ hoạt động (foreground): ${message.messageId}',
        );

        final notificationId = message.messageId ?? '';
        final relatedId = message.data['relatedId'] ?? '';

        // Duplicate check
        if (_isDuplicate(notificationId) ||
            (relatedId.isNotEmpty && _isDuplicate(relatedId))) {
          return;
        }

        final notification = message.notification;
        if (notification != null) {
          final title =
              notification.title ?? message.data['title'] ?? 'Thông báo mới';
          final body = notification.body ?? message.data['body'] ?? '';
          final route =
              message.data['route'] ??
              message.data['actionUrl'] ??
              AppRoutes.studentNotifications;

          showLocalNotification(
            id: notification.hashCode,
            title: title,
            body: body,
            payload: route,
          );
        } else if (message.data.containsKey('title') ||
            message.data.containsKey('body')) {
          // Fallback for data-only payload
          final title = message.data['title'] ?? 'Thông báo';
          final body = message.data['body'] ?? '';
          final route =
              message.data['route'] ??
              message.data['actionUrl'] ??
              AppRoutes.studentNotifications;

          showLocalNotification(
            id: message.hashCode,
            title: title,
            body: body,
            payload: route,
          );
        }
      });

      // Handle FCM notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          'Đã nhấp vào thông báo FCM khi app chạy ngầm: ${message.messageId}',
        );
        final route =
            message.data['route'] ??
            message.data['actionUrl'] ??
            AppRoutes.studentNotifications;
        _handleTap(route);
      });

      // Handle FCM notification tap when app is terminated
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'Đã nhấp vào thông báo FCM khi app đã bị đóng hẳn: ${initialMessage.messageId}',
        );
        final route =
            initialMessage.data['route'] ??
            initialMessage.data['actionUrl'] ??
            AppRoutes.studentNotifications;
        _pendingPayload = route;
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo FCM: $e');
    }
  }

  Future<void> saveTokenToFirestore(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) {
        _fcmToken = token;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tokens')
            .doc(token)
            .set({
              'token': token,
              'platform': 'android',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        debugPrint('Đã lưu FCM token lên Firestore cho userId: $userId');
      }
    } catch (e) {
      debugPrint('Lỗi khi lưu FCM token lên Firestore: $e');
    }
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
    final id = _randomNotificationId();
    await _plugin.zonedSchedule(
      id,
      'Nhắc học',
      'Đến giờ ôn tập ngắn trong ngày.',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      _notificationDetails(),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Trigger in-app alert dialog after 10s if app is open
    Timer(const Duration(seconds: 10), () {
      _triggerForegroundNotification(
        id: id,
        title: 'Nhắc học',
        body: 'Đến giờ ôn tập ngắn trong ngày.',
        payload: payload,
      );
    });
  }

  Future<void> scheduleDailyStudyReminder({
    int hour = 19,
    int minute = 0,
    String payload = AppRoutes.studentProgress,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Cancel old reminder with ID 1900 first
    await _plugin.cancel(1900);

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

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? deduplicationId,
  }) async {
    if (deduplicationId != null && _isDuplicate(deduplicationId)) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, notificationDetails, payload: payload);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<void> scheduleReminder(StudyReminder reminder) async {
    if (!reminder.isEnabled) return;
    
    final ringtone = RingtoneCatalogService.getByAssetPath(reminder.ringtoneAsset);
    final channelId = 'study_reminders_${ringtone.androidRawName}';
    final channelName = 'Nhắc học - ${ringtone.name}';
    final soundName = ringtone.androidRawName;

    // Register a specific channel for this sound
    final androidNotificationChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Kênh thông báo nhắc học dùng nhạc chuông ${ringtone.name}',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      enableVibration: reminder.vibrationEnabled,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidNotificationChannel);
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Kênh nhắc học',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      enableVibration: reminder.vibrationEnabled,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    // Payload contains type and reminderId
    final payload = '{"type":"study_reminder","reminderId":${reminder.id}}';

    if (reminder.weekdays.isEmpty) {
      // Once
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      final notificationId = reminder.id * 10;
      await _plugin.cancel(notificationId);
      await _plugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description ?? 'Đến giờ học tập rồi!',
        scheduledTime,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Scheduled single reminder ${reminder.id} at $scheduledTime');
    } else if (reminder.weekdays.length == 7) {
      // Daily
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final notificationId = reminder.id * 10;
      await _plugin.cancel(notificationId);
      await _plugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description ?? 'Đến giờ học tập hằng ngày!',
        scheduledTime,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Scheduled daily reminder ${reminder.id} at $scheduledTime');
    } else {
      // Selected weekdays
      // Cancel any old ones first
      for (int w = 1; w <= 7; w++) {
        await _plugin.cancel(reminder.id * 10 + w);
      }

      for (final weekday in reminder.weekdays) {
        final notificationId = reminder.id * 10 + weekday;
        
        final now = tz.TZDateTime.now(tz.local);
        var scheduledTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          reminder.hour,
          reminder.minute,
        );
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }
        while (scheduledTime.weekday != weekday) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        await _plugin.zonedSchedule(
          notificationId,
          reminder.title,
          reminder.description ?? 'Đến giờ học tập theo lịch!',
          scheduledTime,
          notificationDetails,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        debugPrint('Scheduled weekly reminder ${reminder.id} weekday $weekday at $scheduledTime');
      }
    }
  }

  Future<void> cancelReminder(int reminderId) async {
    await _plugin.cancel(reminderId * 10);
    for (int w = 1; w <= 7; w++) {
      await _plugin.cancel(reminderId * 10 + w);
    }
    debugPrint('Cancelled reminder $reminderId');
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
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

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
