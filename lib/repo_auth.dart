/// Abstract repository interface for authentication
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/mock_progress.dart';

abstract class AuthRepository {
  Future<AppUser?> login(String email, String password);
  Future<AppUser?> register(String email, String password, String fullName, UserRole role);
  Future<AppUser?> getCurrentUser();
  Future<void> logout();
  Future<bool> isLoggedIn();
}

/// Mock implementation of AuthRepository
class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;

  @override
  Future<AppUser?> login(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay

    // Hardcoded mock credentials
    if (email == 'student@example.com' && password == '123456') {
      _currentUser = MockUsersData.studentUser;
      return _currentUser;
    } else if ((email == 'teacher@example.com' || email == 'teacher@gmail.com') && password == '123456') {
      _currentUser = MockUsersData.teacherUser;
      return _currentUser;
    } else if ((email == 'admin@example.com' || email == 'admin@gmail.com') && password == '123456') {
      _currentUser = MockUsersData.adminUser;
      return _currentUser;
    }

    return null; // Login failed
  }

  @override
  Future<AppUser?> register(String email, String password, String fullName, UserRole role) async {
    await Future.delayed(Duration(milliseconds: 500));

    final newUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    _currentUser = newUser;
    return newUser;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(Duration(milliseconds: 300));
    _currentUser = null;
  }

  @override
  Future<bool> isLoggedIn() async {
    await Future.delayed(Duration(milliseconds: 100));
    return _currentUser != null;
  }
}
