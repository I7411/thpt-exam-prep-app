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
        title: const Text('CÃ¡c mÃ´n há»c'),
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
            return Center(child: Text('Lá»—i táº£i mÃ´n há»c: ${snapshot.error}'));
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
                    'KhÃ´ng cÃ³ mÃ´n há»c nÃ o',
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
                progress: '${subject.totalDocuments} tÃ i liá»‡u',
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
      case 'toÃ¡n':
        return const _SubjectConfig(Icons.calculate, Colors.blue);
      case 'ngá»¯ vÄƒn':
        return const _SubjectConfig(Icons.menu_book, Colors.red);
      case 'tiáº¿ng anh':
        return const _SubjectConfig(Icons.language, Colors.green);
      case 'váº­t lÃ½':
        return const _SubjectConfig(Icons.science, Colors.purple);
      case 'hÃ³a há»c':
        return const _SubjectConfig(Icons.science, Colors.orange);
      case 'sinh há»c':
        return const _SubjectConfig(Icons.favorite, Colors.pink);
      case 'lá»‹ch sá»­':
        return const _SubjectConfig(Icons.history_edu, Colors.brown);
      case 'Ä‘á»‹a lÃ½':
        return const _SubjectConfig(Icons.public, Colors.teal);
      case 'giÃ¡o dá»¥c kinh táº¿ vÃ  phÃ¡p luáº­t':
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

