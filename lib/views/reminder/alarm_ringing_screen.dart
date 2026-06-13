import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/data/local/app_database.dart';
import 'package:thpt_exam_prep_app/services/alarm_audio_service.dart';
import 'package:thpt_exam_prep_app/services/notification_service.dart';
import 'package:thpt_exam_prep_app/services/ringtone_catalog_service.dart';
import 'package:intl/intl.dart';

class AlarmRingingScreen extends StatefulWidget {
  final int reminderId;

  const AlarmRingingScreen({super.key, required this.reminderId});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> with SingleTickerProviderStateMixin {
  StudyReminder? _reminder;
  bool _isLoading = true;
  bool _isConfirmed = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadReminderAndPlay();
  }

  Future<void> _loadReminderAndPlay() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final reminders = await AppLocalRepository.instance.getRemindersByUser(uid);
      final found = reminders.firstWhere((r) => r.id == widget.reminderId);
      
      setState(() {
        _reminder = found;
        _isLoading = false;
      });

      await AlarmAudioService.instance.playAlarm(found.ringtoneAsset);
    } catch (e) {
      debugPrint('AlarmRingingScreen: Lỗi tải lời nhắc hoặc tìm không thấy: $e');
      setState(() {
        _isLoading = false;
      });
      // Play default fallback ringtone
      await AlarmAudioService.instance.playAlarm('assets/audios/file.mp3');
    }
  }

  Future<void> _confirmAndStop() async {
    if (_isConfirmed) return;
    setState(() {
      _isConfirmed = true;
    });

    // Stop audio
    await AlarmAudioService.instance.stop();

    // Cancel notification display on status bar
    await NotificationService.instance.cancelReminder(widget.reminderId);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Safely stop playing sound when leaving screen
    AlarmAudioService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(DateTime.now());
    final ringtoneName = _reminder != null
        ? RingtoneCatalogService.getByAssetPath(_reminder!.ringtoneAsset).name
        : 'Nhạc chuông mặc định';

    return WillPopScope(
      onWillPop: () async {
        // Intercept back button to stop audio and confirm alarm
        await _confirmAndStop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Indicator
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'BÁO THỨC HỌC TẬP',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 2.0,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 72,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),

                // Center Ringing Animation
                Column(
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2 * _animationController.value),
                                blurRadius: 40 * _animationController.value,
                                spreadRadius: 20 * _animationController.value,
                              )
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: Icon(
                        Icons.alarm,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _reminder?.title ?? 'Đã đến giờ học!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (_reminder?.description != null && _reminder!.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _reminder!.description!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Chip(
                      avatar: const Icon(Icons.music_note, size: 16),
                      label: Text(
                        ringtoneName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),

                // Confirmation Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _confirmAndStop,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Xác nhận và tắt chuông',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
