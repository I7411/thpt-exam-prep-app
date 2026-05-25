import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Dùng để dùng kDebugMode

class AuthService {
  final String _baseUrl = 'http://192.168.1.166:5185/api/auth';

  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      // Ghi log để debug khi chạy ở chế độ Development
      if (kDebugMode) {
        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Thành công'};
      } else {
        // Cố gắng lấy thông báo lỗi từ server (nếu có)
        String errorMessage = 'Lỗi server (${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? errorMessage;
        } catch (_) {}
        
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      if (kDebugMode) print('Connection Error: $e');
      return {'success': false, 'message': 'Không thể kết nối tới server: $e'};
    }
  }
}