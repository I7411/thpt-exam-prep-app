import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/mock_exams.dart';

abstract class ExamRepository {
  Future<List<Exam>> getAllExams();
  Future<List<Exam>> getExamsBySubject(String subjectId);
  Future<Exam?> getExamById(String examId);
  Future<List<Question>> getQuestionsByExam(String examId);
  Future<Question?> getQuestionById(String id);

  Future<Exam> createExam(Exam exam);
  Future<void> updateExam(Exam exam);
  Future<void> deleteExam(String examId);

  Future<void> createQuestion(Question question);
  Future<void> deleteQuestion(String examId, String questionId);
}

class MockExamRepository implements ExamRepository {
  final List<Exam> _exams = List.from(MockExamsData.exams);
  final List<Question> _questions = List.from(MockExamsData.questions);

  void _handleFirebaseException(FirebaseException e) {
    debugPrint('FirebaseException: code=${e.code}, message=${e.message}');
    if (e.code == 'permission-denied') {
      throw Exception('Bạn không có quyền thực hiện thao tác này.');
    } else if (e.code == 'network-request-failed') {
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } else {
      throw Exception('Không thể thực hiện thao tác. Vui lòng thử lại.');
    }
  }

  Exam examFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final id = doc.id;
    final subjectId = data['subjectId'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final questionCount = data['questionCount'] as int? ?? 0;
    final durationMinutes = data['durationMinutes'] as int? ?? 60;
    final totalScore = (data['totalScore'] as num? ?? 10.0).toDouble();
    final passingScore = (data['passingScore'] as num? ?? 5.0).toDouble();
    final status = data['status'] as String? ?? (data['isPublished'] == true ? 'published' : 'draft');
    final creatorId = data['creatorId'] as String? ?? data['teacherId'] as String? ?? '';
    
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    
    DateTime? updatedAt;
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updatedAt = DateTime.tryParse(data['updatedAt'] as String);
    }

    return Exam(
      id: id,
      subjectId: subjectId,
      title: title,
      description: description,
      questionCount: questionCount,
      durationMinutes: durationMinutes,
      totalScore: totalScore,
      passingScore: passingScore,
      status: status,
      creatorId: creatorId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Question questionFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final id = doc.id;
    final examId = data['examId'] as String? ?? '';
    final content = data['content'] as String? ?? '';
    final explanation = data['explanation'] as String? ?? '';
    final orderNumber = data['orderNumber'] as int? ?? 0;
    final score = (data['score'] as num? ?? 1.0).toDouble();
    
    final List<AnswerOption> optionsList = [];
    final rawOptions = data['options'] as List<dynamic>? ?? [];
    if (rawOptions.isNotEmpty) {
      if (rawOptions.first is Map) {
        for (final opt in rawOptions) {
          optionsList.add(AnswerOption.fromJson(opt as Map<String, dynamic>));
        }
      } else {
        final int correctIdx = data['correctAnswerIndex'] as int? ?? 0;
        for (int i = 0; i < rawOptions.length; i++) {
          final label = i == 0 ? 'A' : i == 1 ? 'B' : i == 2 ? 'C' : 'D';
          final optionContent = rawOptions[i] as String? ?? '';
          optionsList.add(
            AnswerOption(
              id: 'opt_${doc.id}_$i',
              label: label,
              content: optionContent,
              isCorrect: i == correctIdx,
            ),
          );
        }
      }
    }
    
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return Question(
      id: id,
      examId: examId,
      content: content,
      explanation: explanation,
      orderNumber: orderNumber,
      score: score,
      options: optionsList,
      createdAt: createdAt,
    );
  }

  String _getSubjectName(String subjectId) {
    switch (subjectId) {
      case 'subj_001':
        return 'Toán';
      case 'subj_002':
        return 'Ngữ văn';
      case 'subj_003':
        return 'Tiếng Anh';
      case 'subj_004':
        return 'Vật lý';
      case 'subj_005':
        return 'Hóa học';
      case 'subj_006':
        return 'Sinh học';
      case 'subj_007':
        return 'Lịch sử';
      case 'subj_008':
        return 'Địa lý';
      case 'subj_009':
        return 'GDKTPL';
      default:
        return 'Môn học';
    }
  }

  @override
  Future<List<Exam>> getAllExams() async {
    final List<Exam> examsList = [];
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      Query query = FirebaseFirestore.instance.collection('exams');
      
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final role = userDoc.data()?['role'] as String? ?? 'student';
          if (role == 'teacher') {
            query = query.where('teacherId', isEqualTo: uid);
          } else if (role == 'student') {
            query = query.where('status', isEqualTo: 'published');
          }
        } else {
          query = query.where('status', isEqualTo: 'published');
        }
      } else {
        query = query.where('status', isEqualTo: 'published');
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 10));
      for (final doc in snapshot.docs) {
        try {
          examsList.add(examFromFirestore(doc));
        } catch (e) {
          debugPrint('Lỗi parse đề thi từ document ${doc.id}: $e');
        }
      }
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      debugPrint('Lỗi tải đề thi: $e');
    }

    // Append mock exams if their ID is not already in the Firestore exams list
    final existingIds = examsList.map((e) => e.id).toSet();
    for (final mockExam in _exams) {
      if (!existingIds.contains(mockExam.id)) {
        examsList.add(mockExam);
      }
    }

    return examsList;
  }

  @override
  Future<List<Exam>> getExamsBySubject(String subjectId) async {
    final List<Exam> examsList = [];
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      Query query = FirebaseFirestore.instance.collection('exams').where('subjectId', isEqualTo: subjectId);
      
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final role = userDoc.data()?['role'] as String? ?? 'student';
          if (role == 'teacher') {
            query = query.where('teacherId', isEqualTo: uid);
          } else if (role == 'student') {
            query = query.where('status', isEqualTo: 'published');
          }
        } else {
          query = query.where('status', isEqualTo: 'published');
        }
      } else {
        query = query.where('status', isEqualTo: 'published');
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 10));
      for (final doc in snapshot.docs) {
        try {
          examsList.add(examFromFirestore(doc));
        } catch (e) {
          debugPrint('Lỗi parse đề thi: $e');
        }
      }
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      debugPrint('Lỗi tải đề thi theo môn: $e');
    }

    final existingIds = examsList.map((e) => e.id).toSet();
    for (final mockExam in _exams) {
      if (mockExam.subjectId == subjectId && !existingIds.contains(mockExam.id)) {
        examsList.add(mockExam);
      }
    }

    return examsList;
  }

  @override
  Future<Exam?> getExamById(String examId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('exams')
          .doc(examId)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return examFromFirestore(doc);
      }
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      debugPrint('Lỗi lấy đề thi: $e');
    }

    try {
      return _exams.firstWhere((e) => e.id == examId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Question>> getQuestionsByExam(String examId) async {
    final List<Question> questionsList = [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exams')
          .doc(examId)
          .collection('questions')
          .get()
          .timeout(const Duration(seconds: 10));
      for (final doc in snapshot.docs) {
        try {
          questionsList.add(questionFromFirestore(doc));
        } catch (e) {
          debugPrint('Lỗi parse câu hỏi: $e');
        }
      }
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      debugPrint('Lỗi tải câu hỏi: $e');
    }

    if (questionsList.isNotEmpty) {
      questionsList.sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
      return questionsList;
    }

    final mockQuestions = _questions.where((q) => q.examId == examId).toList();
    mockQuestions.sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
    return mockQuestions;
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    try {
      return _questions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Exam> createExam(Exam exam) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String teacherName = 'Giáo viên';
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          teacherName = userDoc.data()?['fullName'] as String? ?? 'Giáo viên';
        }
      }

      final examData = {
        'id': exam.id,
        'title': exam.title,
        'subjectId': exam.subjectId,
        'subjectName': _getSubjectName(exam.subjectId),
        'description': exam.description,
        'durationMinutes': exam.durationMinutes,
        'teacherId': exam.creatorId,
        'teacherName': teacherName,
        'status': exam.status,
        'questionCount': exam.questionCount,
        'passingScore': exam.passingScore,
        'totalScore': exam.totalScore,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'publishedAt': exam.status == 'published' ? FieldValue.serverTimestamp() : null,
      };

      await FirebaseFirestore.instance
          .collection('exams')
          .doc(exam.id)
          .set(examData)
          .timeout(const Duration(seconds: 10));
          
      return exam;
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
      rethrow;
    } catch (e) {
      throw Exception('Không thể thực hiện thao tác. Vui lòng thử lại.');
    }
  }

  @override
  Future<void> updateExam(Exam exam) async {
    try {
      final examData = {
        'title': exam.title,
        'subjectId': exam.subjectId,
        'subjectName': _getSubjectName(exam.subjectId),
        'description': exam.description,
        'durationMinutes': exam.durationMinutes,
        'status': exam.status,
        'questionCount': exam.questionCount,
        'passingScore': exam.passingScore,
        'totalScore': exam.totalScore,
        'updatedAt': FieldValue.serverTimestamp(),
        'publishedAt': exam.status == 'published' ? FieldValue.serverTimestamp() : null,
      };

      await FirebaseFirestore.instance
          .collection('exams')
          .doc(exam.id)
          .update(examData)
          .timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      throw Exception('Không thể thực hiện thao tác. Vui lòng thử lại.');
    }
  }

  @override
  Future<void> deleteExam(String examId) async {
    try {
      await FirebaseFirestore.instance
          .collection('exams')
          .doc(examId)
          .delete()
          .timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      throw Exception('Không thể thực hiện thao tác. Vui lòng thử lại.');
    }
  }

  @override
  Future<void> createQuestion(Question question) async {
    try {
      int correctAnswerIndex = 0;
      final optionsList = <String>[];
      for (int i = 0; i < question.options.length; i++) {
        optionsList.add(question.options[i].content);
        if (question.options[i].isCorrect) {
          correctAnswerIndex = i;
        }
      }

      final examRef = FirebaseFirestore.instance.collection('exams').doc(question.examId);
      final questionRef = examRef.collection('questions').doc(question.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final examDoc = await transaction.get(examRef);
        if (!examDoc.exists) {
          throw Exception('Đề thi không tồn tại.');
        }

        final currentCount = examDoc.data()?['questionCount'] as int? ?? 0;

        transaction.set(questionRef, {
          'id': question.id,
          'examId': question.examId,
          'content': question.content,
          'options': optionsList,
          'correctAnswerIndex': correctAnswerIndex,
          'difficulty': question.orderNumber <= 2 ? 'easy' : question.orderNumber <= 4 ? 'medium' : 'hard',
          'explanation': question.explanation,
          'orderNumber': question.orderNumber,
          'score': question.score,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(examRef, {
          'questionCount': currentCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }).timeout(const Duration(seconds: 12));
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      throw Exception('Không thể thực hiện thao tác. Vui lòng thử lại.');
    }
  }

  @override
  Future<void> deleteQuestion(String examId, String questionId) async {
    try {
      final examRef = FirebaseFirestore.instance.collection('exams').doc(examId);
      final questionRef = examRef.collection('questions').doc(questionId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final examDoc = await transaction.get(examRef);
        if (!examDoc.exists) {
          throw Exception('Đề thi không tồn tại.');
        }

        final currentCount = examDoc.data()?['questionCount'] as int? ?? 0;

        transaction.delete(questionRef);
        transaction.update(examRef, {
          'questionCount': currentCount > 0 ? currentCount - 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }).timeout(const Duration(seconds: 12));
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      throw Exception('Không thể thực hiện thao tác. Vui lòng thử lại.');
    }
  }
}
