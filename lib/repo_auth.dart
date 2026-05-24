import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/mock_progress.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class AuthRepository {
  Future<AppUser?> login(String email, String password);
  Future<AppUser?> register(String email, String password, String fullName, UserRole role);
  Future<AppUser?> getCurrentUser();
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<bool> sendPasswordResetEmail(String email); // Thêm hàm này vào mẫu thiết kế
}

/// Mock implementation of AuthRepository
class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;

  // GIẢI PHÁP: Tạo danh sách lưu trữ tạm thời trên RAM để lưu user mẫu và user mới đăng ký
  final List<Map<String, dynamic>> _registeredUsers = [
    {'email': 'student@example.com', 'password': '123456', 'user': MockUsersData.studentUser},
    {'email': 'teacher@example.com', 'password': '123456', 'user': MockUsersData.teacherUser},
    {'email': 'teacher@gmail.com', 'password': '123456', 'user': MockUsersData.teacherUser},
    {'email': 'admin@example.com', 'password': '123456', 'user': MockUsersData.adminUser},
    {'email': 'admin@gmail.com', 'password': '123456', 'user': MockUsersData.adminUser},
  ];

  @override
  Future<AppUser?> login(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 500)); // Giả lập độ trễ mạng

    // Tìm kiếm tài khoản trong danh sách bộ nhớ tạm
    try {
      final match = _registeredUsers.firstWhere(
        (account) => account['email'] == email && account['password'] == password,
      );
      _currentUser = match['user'] as AppUser;
      return _currentUser;
    } catch (_) {
      return null; // Không tìm thấy email hoặc sai mật khẩu
    }
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

    // FIX CỦA BẠN: Thêm tài khoản mới này vào danh sách để có thể đăng nhập lại sau đó
    _registeredUsers.add({
      'email': email,
      'password': password,
      'user': newUser,
    });

    _currentUser = newUser;
    return newUser;
  }

  @override
@override
Future<bool> sendPasswordResetEmail(String email) async {
  try {
    final response = await http.post(
      Uri.parse('https://localhost:7129/api/auth/forgot-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    return response.statusCode == 200;
  } catch (e) {
    print("Lỗi API: $e");
    return false;
  }
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