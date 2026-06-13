import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_controller.dart';

class TeacherExamCreateScreen extends StatefulWidget {
  const TeacherExamCreateScreen({super.key});

  @override
  State<TeacherExamCreateScreen> createState() => _TeacherExamCreateScreenState();
}

class _TeacherExamCreateScreenState extends State<TeacherExamCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  final _passingScoreController = TextEditingController(text: '5.0');
  String? _selectedSubjectId;
  bool _isSaving = false;

  final List<Map<String, String>> _fallbackSubjects = [
    {'id': 'subj_001', 'name': 'Toán'},
    {'id': 'subj_002', 'name': 'Ngữ văn'},
    {'id': 'subj_003', 'name': 'Tiếng Anh'},
    {'id': 'subj_004', 'name': 'Vật lý'},
    {'id': 'subj_005', 'name': 'Hóa học'},
    {'id': 'subj_006', 'name': 'Sinh học'},
    {'id': 'subj_007', 'name': 'Lịch sử'},
    {'id': 'subj_008', 'name': 'Địa lý'},
    {'id': 'subj_009', 'name': 'GDKTPL'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String errorMsg) {
    String message = 'Không thể thực hiện thao tác. Vui lòng thử lại.';
    if (errorMsg.contains('permission-denied') || errorMsg.contains('không có quyền')) {
      message = 'Bạn không có quyền thực hiện thao tác này.';
    } else if (errorMsg.contains('network-request-failed') || errorMsg.contains('kết nối mạng')) {
      message = 'Không có kết nối mạng. Vui lòng thử lại.';
    } else {
      message = errorMsg.replaceAll('Exception: ', '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitForm(bool navigateToQuestions) async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final duration = int.parse(_durationController.text.trim());
      final passingScore = double.parse(_passingScoreController.text.trim());
      final subjectId = _selectedSubjectId!;

      final teacherProvider = context.read<TeacherController>();
      final createdExam = await teacherProvider.createTeacherExam(
        title: title,
        subjectId: subjectId,
        durationMinutes: duration,
        description: description,
        passingScore: passingScore,
      );

      if (createdExam != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo đề kiểm tra thành công.'),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (navigateToQuestions) {
          if (mounted) {
            // Replace current route with question creation screen so popping from there returns to management
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.teacherQuestionCreate,
              arguments: {
                'examId': createdExam.id,
                'examTitle': createdExam.title,
              },
            );
          }
        } else {
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        throw Exception('Không tạo được đề thi. Vui lòng kiểm tra lại quyền truy cập.');
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = context.watch<TeacherController>();
    final subjectsList = teacherProvider.subjects.isNotEmpty
        ? teacherProvider.subjects.map((s) => {'id': s.id, 'name': s.name}).toList()
        : _fallbackSubjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đề kiểm tra'),
      ),
      body: SafeArea(
        child: _isSaving
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang lưu đề thi...', style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alert note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đề thi mới sẽ được lưu dưới dạng Bản nháp. Bạn có thể thêm câu hỏi trước khi Phát hành cho học sinh.',
                                style: TextStyle(color: Colors.amber.shade900, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tên bài kiểm tra',
                          hintText: 'Nhập tên bài kiểm tra...',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tên bài kiểm tra không được để trống.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subject dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Môn học',
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                        hint: const Text('Chọn môn học'),
                        items: subjectsList.map((subj) {
                          return DropdownMenuItem<String>(
                            value: subj['id'],
                            child: Text(subj['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSubjectId = val;
                          });
                        },
                        validator: (val) => val == null ? 'Vui lòng chọn môn học.' : null,
                      ),
                      const SizedBox(height: 16),

                      // Duration field
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thời gian làm bài (phút)',
                          hintText: 'Ví dụ: 45, 60, 90...',
                          prefixIcon: Icon(Icons.timer),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Thời gian làm bài không được để trống.';
                          }
                          final duration = int.tryParse(value);
                          if (duration == null || duration <= 0) {
                            return 'Thời gian làm bài phải lớn hơn 0.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Passing score field
                      TextFormField(
                        controller: _passingScoreController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Điểm đạt (từ 0 đến 10)',
                          hintText: 'Ví dụ: 5.0, 8.0...',
                          prefixIcon: Icon(Icons.grade),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Điểm đạt không được để trống.';
                          }
                          final score = double.tryParse(value);
                          if (score == null || score < 0 || score > 10) {
                            return 'Điểm đạt phải từ 0 đến 10.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả đề thi (Tùy chọn)',
                          hintText: 'Ví dụ: Đề thi thử chương 1 lớp 12...',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Actions Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _submitForm(false),
                              child: const Text('Lưu nháp'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade800,
                              ),
                              onPressed: () => _submitForm(true),
                              child: const Text('Lưu & Thêm câu hỏi'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
