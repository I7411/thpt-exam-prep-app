import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/data/mock/mock_exams.dart';
import 'package:thpt_exam_prep_app/controllers/admin_controller.dart';

class AdminExamQuestionManagementScreen extends StatefulWidget {
  const AdminExamQuestionManagementScreen({super.key});

  @override
  State<AdminExamQuestionManagementScreen> createState() =>
      _AdminExamQuestionManagementScreenState();
}

class _AdminExamQuestionManagementScreenState
    extends State<AdminExamQuestionManagementScreen> {
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<AdminController>().loadData();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminController>();
    final subjects = provider.subjects;
    final exams = provider.examSummaries
        .where(
          (item) =>
              _selectedSubjectId == null ||
              item.exam.subjectId == _selectedSubjectId,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đề thi & câu hỏi'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Lọc theo môn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tất cả môn'),
                      ),
                      ...subjects.map(
                        (subject) => DropdownMenuItem(
                          value: subject.id,
                          child: Text(subject.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedSubjectId = value),
                  ),
                  const SizedBox(height: 16),
                  if (exams.isEmpty)
                    const _EmptyState(
                      message: 'Chưa có đề thi nào phù hợp bộ lọc',
                    )
                  else
                    ...exams.map(
                      (exam) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ExamCard(item: exam, provider: provider),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo UI: thêm đề/câu hỏi')),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Thêm đề'),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final AdminExamSummary item;
  final AdminController provider;

  const _ExamCard({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    final questions = provider.exams
        .where((exam) => exam.id == item.exam.id)
        .length;
    final relatedQuestions = provider.examSummaries
        .firstWhere((exam) => exam.exam.id == item.exam.id)
        .questionCount;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      title: Text(
        item.exam.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${item.subject.name} • ${item.difficulty} • ${item.status}',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(
                    label: '${item.questionCount} câu hỏi',
                    color: Colors.blue,
                  ),
                  _Tag(
                    label: '${item.exam.durationMinutes} phút',
                    color: Colors.orange,
                  ),
                  _Tag(
                    label: item.status,
                    color: item.exam.isPublished ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Câu hỏi mẫu',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...MockExamQuestionPreview.fromExam(item.exam.id).map(
                (question) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${question.orderNumber}. ${question.content}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text('Đáp án đúng: ${question.correctAnswer}'),
                        Text('Độ khó: ${question.difficulty}'),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa'),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete),
                    label: const Text('Xóa'),
                  ),
                ],
              ),
              Text(
                'Tổng câu khớp: $relatedQuestions',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              Text(
                'Đếm đề trong repo: $questions',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MockExamQuestionPreview {
  final int orderNumber;
  final String content;
  final String correctAnswer;
  final String difficulty;

  const MockExamQuestionPreview({
    required this.orderNumber,
    required this.content,
    required this.correctAnswer,
    required this.difficulty,
  });

  static List<MockExamQuestionPreview> fromExam(String examId) {
    final preview = MockExamsData.questions
        .where((question) => question.examId == examId)
        .map((question) {
          final correct = question.options
              .firstWhere((option) => option.isCorrect)
              .content;
          final difficulty = question.orderNumber <= 2
              ? 'Dễ'
              : question.orderNumber <= 4
              ? 'Trung bình'
              : 'Khó';
          return MockExamQuestionPreview(
            orderNumber: question.orderNumber,
            content: question.content,
            correctAnswer: correct,
            difficulty: difficulty,
          );
        })
        .toList();
    return preview;
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.grey.shade700)),
    );
  }
}
