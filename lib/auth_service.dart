import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Đường dẫn URL Backend của bạn (nhìn trên thanh địa chỉ Swagger để lấy đúng số cổng)
  static const String baseUrl = 'https://localhost:7129/api/auth';

  // 1. Hàm gửi yêu cầu quên mật khẩu
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    return jsonDecode(response.body);
  }

  // 2. Hàm gửi mật khẩu mới kèm token để reset
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    return jsonDecode(response.body);
  }
}