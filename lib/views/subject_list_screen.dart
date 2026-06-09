import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';
import '../models.dart';
import '../repository_service.dart';
import '../widgets_subject_card.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  late final RepositoryService _repositoryService;
  late Future<List<Subject>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _repositoryService = RepositoryService.instance;
    _subjectsFuture = _repositoryService.subject.getAllSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Các môn học'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Subject>>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải môn học: ${snapshot.error}'));
          }

          final subjects = snapshot.data ?? const <Subject>[];
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

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
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
          );
        },
      ),
    );
  }

  _SubjectConfig _subjectConfig(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'toán':
        return const _SubjectConfig(Icons.calculate, Colors.blue);
      case 'ngữ văn':
        return const _SubjectConfig(Icons.menu_book, Colors.red);
      case 'tiếng anh':
        return const _SubjectConfig(Icons.language, Colors.green);
      case 'vật lý':
        return const _SubjectConfig(Icons.science, Colors.purple);
      case 'hóa học':
        return const _SubjectConfig(Icons.science, Colors.orange);
      case 'sinh học':
        return const _SubjectConfig(Icons.favorite, Colors.pink);
      case 'lịch sử':
        return const _SubjectConfig(Icons.history_edu, Colors.brown);
      case 'địa lý':
        return const _SubjectConfig(Icons.public, Colors.teal);
      case 'giáo dục kinh tế và pháp luật':
        return const _SubjectConfig(Icons.gavel, Colors.indigo);
      default:
        return const _SubjectConfig(Icons.subject, Colors.grey);
    }
  }
}

class _SubjectConfig {
  final IconData icon;
  final Color color;

  const _SubjectConfig(this.icon, this.color);
}

