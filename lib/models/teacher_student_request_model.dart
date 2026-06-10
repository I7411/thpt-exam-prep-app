import 'package:cloud_firestore/cloud_firestore.dart';

enum TeacherStudentRequestStatus {
  pending,
  accepted,
  rejected;

  String toValue() => name;

  static TeacherStudentRequestStatus fromValue(String value) {
    return TeacherStudentRequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TeacherStudentRequestStatus.pending,
    );
  }
}

class TeacherStudentRequest {
  final String id;
  final String teacherId;
  final String teacherEmail;
  final String teacherName;
  final String studentId;
  final String studentEmail;
  final String studentName;
  final TeacherStudentRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeacherStudentRequest({
    required this.id,
    required this.teacherId,
    required this.teacherEmail,
    required this.teacherName,
    required this.studentId,
    required this.studentEmail,
    required this.studentName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeacherStudentRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TeacherStudentRequest(
      id: data['id'] as String? ?? doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      teacherEmail: data['teacherEmail'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      studentEmail: data['studentEmail'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      status: TeacherStudentRequestStatus.fromValue(
        data['status'] as String? ?? 'pending',
      ),
      createdAt: _dateFromFirestore(data['createdAt']),
      updatedAt: _dateFromFirestore(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherEmail': teacherEmail,
      'teacherName': teacherName,
      'studentId': studentId,
      'studentEmail': studentEmail,
      'studentName': studentName,
      'status': status.toValue(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _dateFromFirestore(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
