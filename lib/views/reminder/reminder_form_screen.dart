import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/study_reminder_controller.dart';
import 'package:thpt_exam_prep_app/services/ringtone_catalog_service.dart';

class ReminderFormScreen extends StatefulWidget {
  final StudyReminder? reminder;

  const ReminderFormScreen({super.key, this.reminder});

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  ReminderRepeatType _repeatType = ReminderRepeatType.once;
  final Set<int> _selectedWeekdays = {};
  String _selectedRingtone = 'assets/audios/file.mp3';
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder?.title ?? '');
    _descController = TextEditingController(text: widget.reminder?.description ?? '');
    
    if (widget.reminder != null) {
      _selectedTime = TimeOfDay(hour: widget.reminder!.hour, minute: widget.reminder!.minute);
      _repeatType = widget.reminder!.repeatType;
      _selectedWeekdays.addAll(widget.reminder!.weekdays);
      _selectedRingtone = widget.reminder!.ringtoneAsset;
      _vibrationEnabled = widget.reminder!.vibrationEnabled;
    } else {
      _loadDefaultRingtone();
    }
  }

  Future<void> _loadDefaultRingtone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final saved = prefs.getString('study_reminder_ringtone_$uid');
      if (saved != null) {
        setState(() {
          _selectedRingtone = saved;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'CHỌN GIỜ NHẮC HỌC',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_repeatType == ReminderRepeatType.selectedWeekdays && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một thứ trong tuần.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final controller = Provider.of<StudyReminderController>(context, listen: false);

    // Prepare weekdays list based on repeat type
    List<int> weekdaysList = [];
    if (_repeatType == ReminderRepeatType.daily) {
      weekdaysList = [1, 2, 3, 4, 5, 6, 7];
    } else if (_repeatType == ReminderRepeatType.selectedWeekdays) {
      weekdaysList = _selectedWeekdays.toList()..sort();
    }

    final ringtone = RingtoneCatalogService.getByAssetPath(_selectedRingtone);

    final reminderToSave = StudyReminder(
      id: widget.reminder?.id ?? 0,
      userId: uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      weekdays: weekdaysList,
      ringtoneAsset: _selectedRingtone,
      androidSoundResource: ringtone.androidRawName,
      vibrationEnabled: _vibrationEnabled,
      isEnabled: widget.reminder?.isEnabled ?? true,
      createdAt: widget.reminder?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (widget.reminder != null) {
      success = await controller.updateReminder(reminderToSave);
    } else {
      success = await controller.createReminder(reminderToSave);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu lời nhắc thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Có lỗi xảy ra khi lưu lời nhắc.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWeekdaySelector() {
    final Map<int, String> labels = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn các ngày trong tuần:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.entries.map((entry) {
            final weekday = entry.key;
            final label = entry.value;
            final isSelected = _selectedWeekdays.contains(weekday);

            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWeekdays.add(weekday);
                  } else {
                    _selectedWeekdays.remove(weekday);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reminder != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Chỉnh sửa lời nhắc' : 'Tạo lời nhắc'),
      ),
      body: Consumer<StudyReminderController>(
        builder: (context, controller, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề lời nhắc *',
                    hintText: 'Ví dụ: Học Toán, Giải đề Sử...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tiêu đề.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú thêm',
                    hintText: 'Ví dụ: Làm từ câu 1 đến 30',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Time picker
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Thời gian nhắc nhở'),
                    subtitle: Text(
                      _selectedTime.format(context),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: _selectTime,
                      child: const Text('Thay đổi'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Repeat Type
                DropdownButtonFormField<ReminderRepeatType>(
                  value: _repeatType,
                  decoration: const InputDecoration(
                    labelText: 'Tần suất lặp lại',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ReminderRepeatType.once,
                      child: Text('Một lần'),
                    ),
                    DropdownMenuItem(
                      value: ReminderRepeatType.daily,
                      child: Text('Hằng ngày'),
                    ),
                    DropdownMenuItem(
                      value: ReminderRepeatType.selectedWeekdays,
                      child: Text('Chọn thứ trong tuần'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _repeatType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                if (_repeatType == ReminderRepeatType.selectedWeekdays) ...[
                  _buildWeekdaySelector(),
                  const SizedBox(height: 16),
                ],

                // Ringtone Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRingtone,
                  decoration: const InputDecoration(
                    labelText: 'Nhạc chuông báo thức',
                    border: OutlineInputBorder(),
                  ),
                  items: RingtoneCatalogService.ringtones.map((ringtone) {
                    return DropdownMenuItem<String>(
                      value: ringtone.assetPath,
                      child: Text(ringtone.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRingtone = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Vibration switch
                SwitchListTile(
                  title: const Text('Rung điện thoại'),
                  subtitle: const Text('Rung khi có thông báo nhắc học'),
                  value: _vibrationEnabled,
                  onChanged: (val) {
                    setState(() {
                      _vibrationEnabled = val;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: controller.isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Lưu lời nhắc học',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
