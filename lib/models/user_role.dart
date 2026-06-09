/// User role enumeration
enum UserRole {
  student,
  teacher,
  admin;

  /// Convert enum to string
  String toValue() => name;

  /// Parse string to enum
  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.student,
    );
  }

  /// Get Vietnamese display name
  String getDisplayName() {
    return switch (this) {
      UserRole.student => 'Há»c sinh',
      UserRole.teacher => 'GiÃ¡o viÃªn',
      UserRole.admin => 'Quáº£n trá»‹ viÃªn',
    };
  }
}

