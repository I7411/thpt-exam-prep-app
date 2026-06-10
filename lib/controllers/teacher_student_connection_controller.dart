import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:thpt_exam_prep_app/models.dart';

const Duration _connectionTimeout = Duration(seconds: 12);
const String _requestCollection = 'teacher_student_requests';
const String _usersCollection = 'users';
const String _progressCollection = 'progress_stats';

class StudentProgressPreview {
  final double averageScore;
  final double completionPercentage;
  final int totalExamsTaken;
  final int examsPassed;
  final int streakDays;

  const StudentProgressPreview({
    required this.averageScore,
    required this.completionPercentage,
    required this.totalExamsTaken,
    required this.examsPassed,
    required this.streakDays,
  });
}

class TeacherStudentConnectionController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentTeacher;
  AppUser? _currentStudent;
  AppUser? _searchedStudent;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isSending = false;
  String _errorMessage = '';
  String _successMessage = '';
  List<TeacherStudentRequest> _teacherPendingRequests = [];
  List<TeacherStudentRequest> _myStudents = [];
  List<TeacherStudentRequest> _studentPendingRequests = [];
  final Map<String, StudentProgressPreview> _progressByStudentId = {};

  AppUser? get searchedStudent => _searchedStudent;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isSending => _isSending;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;
  List<TeacherStudentRequest> get teacherPendingRequests =>
      List.unmodifiable(_teacherPendingRequests);
  List<TeacherStudentRequest> get myStudents => List.unmodifiable(_myStudents);
  List<TeacherStudentRequest> get studentPendingRequests =>
      List.unmodifiable(_studentPendingRequests);

  StudentProgressPreview? progressForStudent(String studentId) {
    return _progressByStudentId[studentId];
  }

  Future<void> loadForTeacher(AppUser teacher, {bool force = false}) async {
    if (teacher.role != UserRole.teacher) {
      _errorMessage = 'Tài khoản hiện tại không phải giáo viên.';
      notifyListeners();
      return;
    }

    if (!force &&
        _currentTeacher?.id == teacher.id &&
        (_teacherPendingRequests.isNotEmpty || _myStudents.isNotEmpty)) {
      return;
    }

    _currentTeacher = teacher;
    _errorMessage = '';
    _setLoading(true);

    try {
      final results = await Future.wait<List<TeacherStudentRequest>>([
        _safeRequestList(
          _getRequestsForTeacher(
            teacher.id,
            TeacherStudentRequestStatus.pending,
          ),
          'lời mời đang chờ của giáo viên',
        ),
        _safeRequestList(
          getMyStudents(teacher.id),
          'danh sách học sinh đã kết nối',
        ),
      ]);

      _teacherPendingRequests = results[0];
      _myStudents = results[1];
      await _loadProgressForStudents(_myStudents);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadForStudent(AppUser student, {bool force = false}) async {
    if (student.role != UserRole.student) {
      _errorMessage = 'Tài khoản hiện tại không phải học sinh.';
      notifyListeners();
      return;
    }

    if (!force &&
        _currentStudent?.id == student.id &&
        _studentPendingRequests.isNotEmpty) {
      return;
    }

    _currentStudent = student;
    _errorMessage = '';
    _setLoading(true);

    try {
      _studentPendingRequests = await _safeRequestList(
        getPendingRequestsForStudent(student.id),
        'lời mời giáo viên của học sinh',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<AppUser?> searchStudentByEmail(String email) async {
    final normalizedEmail = email.trim();
    _isSearching = true;
    _errorMessage = '';
    _successMessage = '';
    _searchedStudent = null;
    notifyListeners();

    try {
      if (!_isValidEmail(normalizedEmail)) {
        _errorMessage = 'Email học sinh không hợp lệ.';
        return null;
      }

      final student = await _findStudentByEmail(normalizedEmail);
      if (student == null) {
        _errorMessage = 'Không tìm thấy học sinh với email này.';
        return null;
      }

      if (student.role != UserRole.student) {
        _errorMessage = 'Email này không thuộc tài khoản học sinh.';
        return null;
      }

      _searchedStudent = student;
      return student;
    } on FirebaseException catch (e) {
      _errorMessage = _friendlyError(e);
      debugPrint('Lỗi khi tìm học sinh theo email: ${e.code}');
      return null;
    } on TimeoutException {
      _errorMessage = 'Tìm học sinh quá lâu. Vui lòng kiểm tra mạng.';
      debugPrint('Tìm học sinh bị quá thời gian.');
      return null;
    } catch (e) {
      _errorMessage = 'Không thể tìm học sinh. Vui lòng thử lại.';
      debugPrint('Lỗi không xác định khi tìm học sinh: $e');
      return null;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<bool> sendConnectionRequest(
    String studentEmail, {
    AppUser? teacher,
  }) async {
    final currentTeacher = teacher ?? _currentTeacher;
    if (currentTeacher == null || currentTeacher.role != UserRole.teacher) {
      _errorMessage = 'Không xác định được tài khoản giáo viên.';
      notifyListeners();
      return false;
    }

    final normalizedEmail = studentEmail.trim();
    _isSending = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      if (!_isValidEmail(normalizedEmail)) {
        _errorMessage = 'Email học sinh không hợp lệ.';
        return false;
      }

      final student = await _findStudentByEmail(normalizedEmail);
      if (student == null || student.role != UserRole.student) {
        _errorMessage = 'Không tìm thấy tài khoản học sinh phù hợp.';
        return false;
      }

      if (student.id == currentTeacher.id) {
        _errorMessage = 'Giáo viên không thể gửi lời mời cho chính mình.';
        return false;
      }

      final requestId = _requestId(currentTeacher.id, student.id);
      final requestRef = _firestore
          .collection(_requestCollection)
          .doc(requestId);
      final existingDoc = await requestRef.get().timeout(_connectionTimeout);

      if (existingDoc.exists) {
        final existing = TeacherStudentRequest.fromFirestore(existingDoc);
        if (existing.status == TeacherStudentRequestStatus.pending) {
          _errorMessage = 'Lời mời đã được gửi và đang chờ học sinh phản hồi.';
          return false;
        }
        if (existing.status == TeacherStudentRequestStatus.accepted) {
          _errorMessage = 'Học sinh này đã kết nối với giáo viên.';
          return false;
        }
      }

      debugPrint('Đang gửi lời mời kết nối học sinh...');
      await requestRef
          .set({
            'id': requestId,
            'teacherId': currentTeacher.id,
            'teacherEmail': currentTeacher.email,
            'teacherName': currentTeacher.fullName,
            'studentId': student.id,
            'studentEmail': student.email,
            'studentName': student.fullName,
            'status': TeacherStudentRequestStatus.pending.toValue(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(_connectionTimeout);

      _searchedStudent = student;
      await loadForTeacher(currentTeacher, force: true);
      _successMessage = 'Đã gửi lời mời kết nối đến ${student.fullName}.';
      debugPrint('Gửi lời mời kết nối thành công.');
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = _friendlyError(e);
      debugPrint('Lỗi Firestore khi gửi lời mời kết nối: ${e.code}');
      return false;
    } on TimeoutException {
      _errorMessage = 'Gửi lời mời quá lâu. Vui lòng kiểm tra mạng.';
      debugPrint('Gửi lời mời kết nối bị quá thời gian.');
      return false;
    } catch (e) {
      _errorMessage = 'Không thể gửi lời mời kết nối. Vui lòng thử lại.';
      debugPrint('Lỗi không xác định khi gửi lời mời kết nối: $e');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<List<TeacherStudentRequest>> getMyStudents(String teacherId) async {
    return _getRequestsForTeacher(
      teacherId,
      TeacherStudentRequestStatus.accepted,
    );
  }

  Future<List<TeacherStudentRequest>> getPendingRequestsForStudent(
    String studentId,
  ) async {
    final snapshot = await _firestore
        .collection(_requestCollection)
        .where('studentId', isEqualTo: studentId)
        .limit(50)
        .get()
        .timeout(_connectionTimeout);

    return _requestsFromSnapshot(snapshot)
        .where(
          (request) => request.status == TeacherStudentRequestStatus.pending,
        )
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  Future<bool> acceptRequest(String requestId) {
    return _updateRequestStatus(
      requestId,
      TeacherStudentRequestStatus.accepted,
      'Đã chấp nhận lời mời của giáo viên.',
    );
  }

  Future<bool> rejectRequest(String requestId) {
    return _updateRequestStatus(
      requestId,
      TeacherStudentRequestStatus.rejected,
      'Đã từ chối lời mời của giáo viên.',
    );
  }

  Future<bool> removeStudentConnection(
    String teacherId,
    String studentId,
  ) async {
    _setLoading(true);
    _errorMessage = '';
    _successMessage = '';

    try {
      await _firestore
          .collection(_requestCollection)
          .doc(_requestId(teacherId, studentId))
          .delete()
          .timeout(_connectionTimeout);

      _myStudents.removeWhere((request) => request.studentId == studentId);
      _progressByStudentId.remove(studentId);
      _successMessage = 'Đã xóa kết nối học sinh.';
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = _friendlyError(e);
      debugPrint('Lỗi Firestore khi xóa kết nối học sinh: ${e.code}');
      return false;
    } on TimeoutException {
      _errorMessage = 'Xóa kết nối quá lâu. Vui lòng thử lại.';
      return false;
    } catch (e) {
      _errorMessage = 'Không thể xóa kết nối học sinh. Vui lòng thử lại.';
      debugPrint('Lỗi không xác định khi xóa kết nối học sinh: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearMessages() {
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();
  }

  Future<bool> _updateRequestStatus(
    String requestId,
    TeacherStudentRequestStatus status,
    String successMessage,
  ) async {
    _setLoading(true);
    _errorMessage = '';
    _successMessage = '';

    try {
      await _firestore
          .collection(_requestCollection)
          .doc(requestId)
          .update({
            'status': status.toValue(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_connectionTimeout);

      _successMessage = successMessage;
      if (_currentStudent != null) {
        await loadForStudent(_currentStudent!, force: true);
      }
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = _friendlyError(e);
      debugPrint('Lỗi Firestore khi cập nhật lời mời: ${e.code}');
      return false;
    } on TimeoutException {
      _errorMessage = 'Cập nhật lời mời quá lâu. Vui lòng thử lại.';
      return false;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật lời mời. Vui lòng thử lại.';
      debugPrint('Lỗi không xác định khi cập nhật lời mời: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<TeacherStudentRequest>> _getRequestsForTeacher(
    String teacherId,
    TeacherStudentRequestStatus status,
  ) async {
    final snapshot = await _firestore
        .collection(_requestCollection)
        .where('teacherId', isEqualTo: teacherId)
        .limit(50)
        .get()
        .timeout(_connectionTimeout);

    return _requestsFromSnapshot(
        snapshot,
      ).where((request) => request.status == status).toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  Future<List<TeacherStudentRequest>> _safeRequestList(
    Future<List<TeacherStudentRequest>> future,
    String label,
  ) async {
    try {
      return await future;
    } on FirebaseException catch (e) {
      _errorMessage = _friendlyError(e);
      debugPrint('Không tải được $label: ${e.code}');
      return <TeacherStudentRequest>[];
    } on TimeoutException {
      _errorMessage = 'Tải $label quá lâu. Vui lòng thử lại.';
      debugPrint('Tải $label bị quá thời gian.');
      return <TeacherStudentRequest>[];
    } catch (e) {
      _errorMessage = 'Không thể tải $label. Vui lòng thử lại.';
      debugPrint('Lỗi không xác định khi tải $label: $e');
      return <TeacherStudentRequest>[];
    }
  }

  List<TeacherStudentRequest> _requestsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(TeacherStudentRequest.fromFirestore)
        .where(
          (request) =>
              request.teacherId.isNotEmpty && request.studentId.isNotEmpty,
        )
        .toList();
  }

  Future<AppUser?> _findStudentByEmail(String email) async {
    final snapshot = await _firestore
        .collection(_usersCollection)
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get()
        .timeout(_connectionTimeout);

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final user = AppUser.fromFirestore(snapshot.docs.first);
    return user.role == UserRole.student ? user : null;
  }

  Future<void> _loadProgressForStudents(
    List<TeacherStudentRequest> requests,
  ) async {
    _progressByStudentId.clear();

    for (final request in requests.take(20)) {
      try {
        final snapshot = await _firestore
            .collection(_progressCollection)
            .where('studentId', isEqualTo: request.studentId)
            .limit(20)
            .get()
            .timeout(_connectionTimeout);

        if (snapshot.docs.isEmpty) {
          continue;
        }

        _progressByStudentId[request.studentId] = _buildProgressPreview(
          snapshot.docs,
        );
      } catch (e) {
        debugPrint(
          'Không tải được tiến độ của học sinh ${request.studentId}: $e',
        );
      }
    }
  }

  StudentProgressPreview _buildProgressPreview(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var totalExams = 0;
    var examsPassed = 0;
    var totalScore = 0.0;
    var scoreCount = 0;
    var totalCompletion = 0.0;
    var maxStreak = 0;

    for (final doc in docs) {
      final data = doc.data();
      totalExams += data['totalExamsTaken'] as int? ?? 0;
      examsPassed += data['examsPassed'] as int? ?? 0;
      totalScore += (data['averageScore'] as num? ?? 0).toDouble();
      totalCompletion += (data['completionPercentage'] as num? ?? 0).toDouble();
      maxStreak = [
        maxStreak,
        data['streakDays'] as int? ?? 0,
      ].reduce((left, right) => left > right ? left : right);
      scoreCount++;
    }

    return StudentProgressPreview(
      averageScore: scoreCount == 0 ? 0 : totalScore / scoreCount,
      completionPercentage: scoreCount == 0 ? 0 : totalCompletion / scoreCount,
      totalExamsTaken: totalExams,
      examsPassed: examsPassed,
      streakDays: maxStreak,
    );
  }

  String _requestId(String teacherId, String studentId) {
    return '${teacherId}_$studentId';
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  String _friendlyError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bạn chưa có quyền thực hiện thao tác này. Vui lòng kiểm tra Firestore Rules.';
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return 'Không thể kết nối Firestore. Vui lòng kiểm tra mạng và thử lại.';
      default:
        return 'Không thể xử lý dữ liệu kết nối. Vui lòng thử lại.';
    }
  }
}
