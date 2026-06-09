import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

/// Application user model
class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? bio;
  final UserRole role;
  final String? schoolName;
  final String? className;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.profileImageUrl,
    this.phoneNumber,
    this.bio,
    required this.role,
    this.schoolName,
    this.className,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Create AppUser from JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      bio: json['bio'] as String?,
      role: UserRole.fromValue(json['role'] as String? ?? 'student'),
      schoolName: json['schoolName'] as String?,
      className: json['className'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Create AppUser from Firestore DocumentSnapshot
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      id: data['uid'] as String? ?? doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      profileImageUrl: data['photoUrl'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      bio: data['bio'] as String?,
      role: UserRole.fromValue(data['role'] as String? ?? 'student'),
      schoolName: data['schoolName'] as String?,
      className: data['className'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convert AppUser to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'role': role.toValue(),
      'schoolName': schoolName,
      'className': className,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Convert AppUser to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'uid': id,
      'email': email,
      'fullName': fullName,
      'photoUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'role': role.toValue(),
      'schoolName': schoolName,
      'className': className,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  /// Create a copy with modified fields
  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? profileImageUrl,
    String? phoneNumber,
    String? bio,
    UserRole? role,
    String? schoolName,
    String? className,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'AppUser(id: $id, email: $email, fullName: $fullName, role: ${role.toValue()})';
}

