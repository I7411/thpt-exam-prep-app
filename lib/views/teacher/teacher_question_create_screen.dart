import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/providers/teacher_provider.dart';
import 'package:thpt_exam_prep_app/models/exam_model.dart';

class TeacherQuestionCreateScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const TeacherQuestionCreateScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<TeacherQuestionCreateScreen> createState() => _TeacherQuestionCreateScreenState();
}

class _TeacherQuestionCreateScreenState extends State<TeacherQuestionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _contentController = TextEditingController();
  final _correctAnswerController = TextEditingController();
  final _wrong1Controller = TextEditingController();
  final _wrong2Controller = TextEditingController();
  final _wrong3Controller = TextEditingController();
  final _explanationController = TextEditingController();
  
  String _selectedDifficulty = 'easy'; // 'easy' | 'medium' | 'hard'
  bool _isSaving = false;
  int _addedInSessionCount = 0;

  @override
  void dispose() {
    _contentController.dispose();
    _correctAnswerController.dispose();
    _wrong1Controller.dispose();
    _wrong2Controller.dispose();
    _wrong3Controller.dispose();
    _explanationController.dispose();
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

  void _clearForm() {
    _contentController.clear();
    _correctAnswerController.clear();
    _wrong1Controller.clear();
    _wrong2Controller.clear();
    _wrong3Controller.clear();
    _explanationController.clear();
    setState(() {
      _selectedDifficulty = 'easy';
    });
  }

  Future<bool> _saveQuestion() async {
    if (_formKey.currentState?.validate() != true) return false;

    // Check unique answers validation
    final correct = _correctAnswerController.text.trim();
    final w1 = _wrong1Controller.text.trim();
    final w2 = _wrong2Controller.text.trim();
    final w3 = _wrong3Controller.text.trim();

    final answersSet = {correct, w1, w2, w3};
    if (answersSet.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Các đáp án không được trùng nhau. Vui lòng kiểm tra lại.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    setState(() => _isSaving = true);

    try {
      final teacherProvider = context.read<TeacherController>();
      await teacherProvider.addQuestionToExam(
        examId: widget.examId,
        content: _contentController.text.trim(),
        correctAnswer: correct,
        wrong1: w1,
        wrong2: w2,
        wrong3: w3,
        difficulty: _selectedDifficulty,
        explanation: _explanationController.text.trim(),
      );

      setState(() {
        _addedInSessionCount++;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu câu hỏi thành công.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      _showErrorSnackBar(e.toString());
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleSaveAndAddOther() async {
    final success = await _saveQuestion();
    if (success) {
      _clearForm();
    }
  }

  Future<void> _handleSaveAndFinish() async {
    final success = await _saveQuestion();
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = context.watch<TeacherController>();
    
    // Find active exam to display updated total questions count
    final activeExam = teacherProvider.createdExams.cast<Exam?>().firstWhere(
          (e) => e?.id == widget.examId,
          orElse: () => null,
        );

    final totalQuestions = activeExam?.questionCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm câu hỏi'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Tổng số: $totalQuestions câu',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: _isSaving
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang lưu câu hỏi...', style: TextStyle(color: AppColors.muted)),
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
                      // Header showing exam info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đề thi: ${widget.examTitle}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đã thêm trong phiên này: $_addedInSessionCount câu',
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Content field
                      TextFormField(
                        controller: _contentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung câu hỏi',
                          hintText: 'Nhập câu hỏi tại đây...',
                          prefixIcon: Icon(Icons.help_outline),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập nội dung câu hỏi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Correct Answer field
                      TextFormField(
                        controller: _correctAnswerController,
                        decoration: InputDecoration(
                          labelText: 'Đáp án đúng',
                          hintText: 'Nhập đáp án đúng...',
                          prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            borderSide: const BorderSide(color: AppColors.success, width: 1.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            borderSide: BorderSide(color: AppColors.success.withOpacity(0.5)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập đáp án đúng.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Wrong Answer 1 field
                      TextFormField(
                        controller: _wrong1Controller,
                        decoration: InputDecoration(
                          labelText: 'Đáp án sai 1',
                          hintText: 'Nhập đáp án sai thứ nhất...',
                          prefixIcon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            borderSide: const BorderSide(color: AppColors.error, width: 1.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            borderSide: BorderSide(color: AppColors.error.withOpacity(0.5)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập đủ 3 đáp án sai.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Wrong Answer 2 field
                      TextFormField(
                        controller: _wrong2Controller,
                        decoration: InputDecoration(
                          labelText: 'Đáp án sai 2',
                          hintText: 'Nhập đáp án sai thứ hai...',
                          prefixIcon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            borderSide: const BorderSide(color: AppColors.error, width: 1.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            borderSide: BorderSide(color: AppColors.error.withOpacity(0.5)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập đủ 3 đáp án sai.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Wrong Answer 3 field
                      TextFormField(
                        controller: _wrong3Controller,
                        decoration: InputDecoration(
                          labelText: 'Đáp án sai 3',
                          hintText: 'Nhập đáp án sai thứ ba...',
                          prefixIcon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            borderSide: const BorderSide(color: AppColors.error, width: 1.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            borderSide: BorderSide(color: AppColors.error.withOpacity(0.5)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập đủ 3 đáp án sai.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Difficulty select dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedDifficulty,
                        decoration: const InputDecoration(
                          labelText: 'Độ khó',
                          prefixIcon: Icon(Icons.trending_up),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'easy', child: Text('Dễ')),
                          DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                          DropdownMenuItem(value: 'hard', child: Text('Khó')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDifficulty = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Explanation field
                      TextFormField(
                        controller: _explanationController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Lời giải thích (Tùy chọn)',
                          hintText: 'Nhập giải thích đáp án...',
                          prefixIcon: Icon(Icons.lightbulb_outline),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Buttons layout
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _handleSaveAndAddOther,
                              child: const Text('Lưu & Thêm câu khác'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade800,
                              ),
                              onPressed: _handleSaveAndFinish,
                              child: const Text('Lưu câu hỏi'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Hoàn tất',
                            style: TextStyle(color: AppColors.muted, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
