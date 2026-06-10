import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../core/routes/app_routes.dart';

import 'package:provider/provider.dart';
import '../controllers/learning_controller.dart';
import 'package:thpt_exam_prep_app/widgets/subject_card.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningController>().loadSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Các môn học'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<LearningController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(child: Text(controller.errorMessage!));
          }

          final subjects = controller.subjects;
          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.subject, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có môn học nào',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(AppRadius.panel),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Chọn môn học để xem tài liệu và đề thi thử phù hợp.',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subject = subjects[index];
                      final config = _subjectConfig(subject.name);

                      return SubjectCard(
                        name: subject.name,
                        icon: config.icon,
                        color: config.color,
                        progress: '${subject.totalDocuments} tài liệu',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.studentDocuments,
                            arguments: subject.id,
                          );
                        },
                      );
                    },
                    childCount: subjects.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  _SubjectConfig _subjectConfig(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'toán':
        return const _SubjectConfig(Icons.calculate, Color(0xFF3B82F6));
      case 'ngữ văn':
        return const _SubjectConfig(Icons.menu_book, Color(0xFFFB7185));
      case 'tiếng anh':
        return const _SubjectConfig(Icons.language, AppColors.success);
      case 'vật lý':
        return const _SubjectConfig(Icons.science, Color(0xFF8B5CF6));
      case 'hóa học':
        return const _SubjectConfig(Icons.science, AppColors.accent);
      case 'sinh học':
        return const _SubjectConfig(Icons.favorite, Color(0xFF22C55E));
      case 'lịch sử':
        return const _SubjectConfig(Icons.history_edu, Color(0xFFB45309));
      case 'địa lý':
        return const _SubjectConfig(Icons.public, Color(0xFF0891B2));
      case 'giáo dục kinh tế và pháp luật':
        return const _SubjectConfig(Icons.gavel, AppColors.primary);
      default:
        return const _SubjectConfig(Icons.subject, AppColors.muted);
    }
  }
}

class _SubjectConfig {
  final IconData icon;
  final Color color;

  const _SubjectConfig(this.icon, this.color);
}
