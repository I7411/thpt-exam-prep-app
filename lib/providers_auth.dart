import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final RepositoryService _repositoryService =
      RepositoryService.getInstance();

  AppUser? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAuthenticated = false;

  // ================= GETTERS =================

  AppUser? get currentUser => _currentUser;

  bool get isLoading => _isLoading;

  String get errorMessage => _errorMessage;

  bool get isAuthenticated => _isAuthenticated;

  // ================= RESTORE SESSION =================

  Future<void> restoreSession() async {
    _isLoading = true;
    _errorMessage = '';

    notifyListeners();

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final userId = prefs.getString('userId');

      final userRole =
          prefs.getString('userRole');

      final userEmail =
          prefs.getString('userEmail');

      final userName =
          prefs.getString('userName');

      if (userId != null &&
          userRole != null) {
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
      _errorMessage =
          'Failed to restore session: $e';
    }

    _isLoading = false;

    notifyListeners();
  }

  // ================= LOGIN =================

  Future<bool> login(
    String email,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = '';

    notifyListeners();

    try {
      if (!_isValidEmail(email)) {
        _errorMessage = 'Email không hợp lệ';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      if (password.isEmpty) {
        _errorMessage =
            'Vui lòng nhập mật khẩu';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      final user =
          await _repositoryService.auth
              .login(email, password);

      if (user != null) {
        _currentUser = user;

        _isAuthenticated = true;

        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
            'userId', user.id);

        await prefs.setString(
            'userRole',
            user.role.toString());

        await prefs.setString(
            'userEmail', user.email);

        await prefs.setString(
            'userName', user.fullName);

        _isLoading = false;

        notifyListeners();

        return true;
      } else {
        _errorMessage =
            'Email hoặc mật khẩu không đúng';

        _isLoading = false;

        notifyListeners();

        return false;
      }
    } catch (e) {
      _errorMessage =
          'Lỗi đăng nhập: $e';

      _isLoading = false;

      notifyListeners();

      return false;
    }
  }

  // ================= REGISTER =================

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
      if (!_isValidEmail(email)) {
        _errorMessage = 'Email không hợp lệ';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      if (password.isEmpty ||
          password.length < 6) {
        _errorMessage =
            'Mật khẩu phải có ít nhất 6 ký tự';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      if (password != confirmPassword) {
        _errorMessage =
            'Mật khẩu xác nhận không khớp';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      if (fullName.isEmpty) {
        _errorMessage =
            'Vui lòng nhập họ tên';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      final user =
          await _repositoryService.auth
              .register(
        email,
        password,
        fullName,
        role,
      );

      if (user != null) {
        _currentUser = user;

        _isAuthenticated = true;

        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
            'userId', user.id);

        await prefs.setString(
            'userRole',
            user.role.toString());

        await prefs.setString(
            'userEmail', user.email);

        await prefs.setString(
            'userName', user.fullName);

        _isLoading = false;

        notifyListeners();

        return true;
      } else {
        _errorMessage =
            'Đăng ký thất bại';

        _isLoading = false;

        notifyListeners();

        return false;
      }
    } catch (e) {
      _errorMessage =
          'Lỗi đăng ký: $e';

      _isLoading = false;

      notifyListeners();

      return false;
    }
  }

  // ================= SEND OTP =================

  Future<bool> sendPasswordReset(
      String email) async {
    _isLoading = true;

    _errorMessage = '';

    notifyListeners();

    try {
      if (!_isValidEmail(email)) {
        _errorMessage =
            'Email không hợp lệ';

        _isLoading = false;

        notifyListeners();

        return false;
      }

      final response = await http.post(
        Uri.parse(
          'http://localhost:5185/api/auth/send-otp',
        ),

        headers: {
          'Content-Type':
              'application/json',
        },

        body: jsonEncode({
          'email': email,
        }),
      );

      print(
          'SEND OTP STATUS: ${response.statusCode}');

      print(
          'SEND OTP BODY: ${response.body}');

      _isLoading = false;

      if (response.statusCode == 200) {
        notifyListeners();

        return true;
      } else {
        final data =
            jsonDecode(response.body);

        _errorMessage =
            data['message'] ??
            'Gửi email thất bại';

        notifyListeners();

        return false;
      }
    } catch (e) {
      _isLoading = false;

      _errorMessage =
          'Lỗi API: $e';

      notifyListeners();

      return false;
    }
  }

  // ================= VERIFY OTP =================

  Future<bool> verifyOtp(
    String email,
    String otp,
  ) async {
    _isLoading = true;

    _errorMessage = '';

    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(
          'http://localhost:5185/api/auth/verify-otp',
        ),

        headers: {
          'Content-Type':
              'application/json',
        },

        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      print(
          'VERIFY OTP STATUS: ${response.statusCode}');

      print(
          'VERIFY OTP BODY: ${response.body}');

      _isLoading = false;

      if (response.statusCode == 200) {
        notifyListeners();

        return true;
      } else {
        final data =
            jsonDecode(response.body);

        _errorMessage =
            data['message'] ??
            'OTP không hợp lệ';

        notifyListeners();

        return false;
      }
    } catch (e) {
      _isLoading = false;

      _errorMessage =
          'Lỗi xác thực OTP: $e';

      notifyListeners();

      return false;
    }
  }
// ================= RESET PASSWORD =================

Future<bool> resetPassword(
  String token,
  String newPassword,
) async {
  _isLoading = true;

  _errorMessage = '';

  notifyListeners();

  try {
    final response = await http.post(
      Uri.parse(
        'http://localhost:5185/api/auth/reset-password',
      ),

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    print(
        'RESET PASSWORD STATUS: ${response.statusCode}');

    print(
        'RESET PASSWORD BODY: ${response.body}');

    _isLoading = false;

    if (response.statusCode == 200) {
      notifyListeners();

      return true;
    } else {
      final data =
          jsonDecode(response.body);

      _errorMessage =
          data['message'] ??
          'Đổi mật khẩu thất bại';

      notifyListeners();

      return false;
    }
  } catch (e) {
    _isLoading = false;

    _errorMessage =
        'Lỗi reset password: $e';

    notifyListeners();

    return false;
  }
}
  // ================= LOGOUT =================

  Future<void> logout() async {
    _isLoading = true;

    notifyListeners();

    try {
      await _repositoryService.auth
          .logout();

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.remove('userId');

      await prefs.remove('userRole');

      await prefs.remove('userEmail');

      await prefs.remove('userName');

      _currentUser = null;

      _isAuthenticated = false;

      _errorMessage = '';
    } catch (e) {
      _errorMessage =
          'Lỗi đăng xuất: $e';
    }

    _isLoading = false;

    notifyListeners();
  }

  // ================= CLEAR ERROR =================

  void clearError() {
    _errorMessage = '';

    notifyListeners();
  }

  // ================= VALIDATE EMAIL =================

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // ================= PARSE ROLE =================

  UserRole _parseUserRole(
      String roleString) {
    if (roleString.contains('student')) {
      return UserRole.student;
    } else if (roleString
        .contains('teacher')) {
      return UserRole.teacher;
    } else if (roleString
        .contains('admin')) {
      return UserRole.admin;
    }

    return UserRole.student;
  }
}