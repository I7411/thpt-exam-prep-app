import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class AuthProvider extends ChangeNotifier {
  final RepositoryService _repositoryService = RepositoryService.getInstance();

  AppUser? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAuthenticated = false;

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  /// Attempt to restore session from shared preferences
  Future<void> restoreSession() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userRole = prefs.getString('userRole');
      final userEmail = prefs.getString('userEmail');
      final userName = prefs.getString('userName');

      if (userId != null && userRole != null) {
        // Reconstruct user from saved session
        _currentUser = AppUser(
          id: userId,
          email: userEmail ?? '',
          fullName: userName ?? '',
          role: _parseUserRole(userRole),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );
        _isAuthenticated = true;
      }
    } catch (e) {
      _errorMessage = 'Failed to restore session: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Validate input
      if (!_isValidEmail(email)) {
        _errorMessage = 'Email không hợp lệ';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Vui lòng nhập mật khẩu';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Call repository login
      final user = await _repositoryService.auth.login(email, password);

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;

        // Save session to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.id);
        await prefs.setString('userRole', user.role.toString());
        await prefs.setString('userEmail', user.email);
        await prefs.setString('userName', user.fullName);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email hoặc mật khẩu không đúng';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi đăng nhập: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a new user
  Future<bool> register(
    String email,
    String password,
    String confirmPassword,
    String fullName,
    UserRole role,
  ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Validate input
      if (!_isValidEmail(email)) {
        _errorMessage = 'Email không hợp lệ';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty || password.length < 6) {
        _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password != confirmPassword) {
        _errorMessage = 'Mật khẩu xác nhận không khớp';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (fullName.isEmpty) {
        _errorMessage = 'Vui lòng nhập họ tên';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Call repository register
      final user = await _repositoryService.auth.register(
        email,
        password,
        fullName,
        role,
      );

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;

        // Save session to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.id);
        await prefs.setString('userRole', user.role.toString());
        await prefs.setString('userEmail', user.email);
        await prefs.setString('userName', user.fullName);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Đăng ký thất bại, vui lòng thử lại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi đăng ký: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repositoryService.auth.logout();

      // Clear session from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userRole');
      await prefs.remove('userEmail');
      await prefs.remove('userName');

      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Lỗi đăng xuất: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Helper: Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Helper: Parse user role string to enum
  UserRole _parseUserRole(String roleString) {
    if (roleString.contains('student')) {
      return UserRole.student;
    } else if (roleString.contains('teacher')) {
      return UserRole.teacher;
    } else if (roleString.contains('admin')) {
      return UserRole.admin;
    }
    return UserRole.student; // Default
  }
}
