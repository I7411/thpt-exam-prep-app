import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class AuthController extends ChangeNotifier {
  final RepositoryService _repositoryService = RepositoryService.getInstance();

  AppUser? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAuthenticated = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> restoreSession() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _repositoryService.auth.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
      } else {
        // Fallback or clear local session if Firebase session is invalid
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi khôi phục phiên bản: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
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
        _errorMessage = 'Vui lòng nhập mật khẩu';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = await _repositoryService.auth.login(email, password);
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email hoặc mật khẩu không đúng';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if ((e.code == 'user-not-found' || e.code == 'invalid-credential') && email.contains('.demo@thptsmartlearn.vn')) {
        _errorMessage = 'Tài khoản demo chưa tồn tại trên Firebase Auth. Hãy tạo tài khoản demo trong Firebase Console hoặc chạy chức năng seed demo account.';
      } else {
        _errorMessage = _getFirebaseErrorMessage(e);
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _errorMessage = 'Ứng dụng chưa có quyền ghi dữ liệu Firestore. Hãy kiểm tra Firestore Rules.';
      } else {
        _errorMessage = 'Lỗi Firebase: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi đăng nhập: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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

      final user = await _repositoryService.auth.register(
        email,
        password,
        fullName,
        role,
      );

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Đăng ký thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _errorMessage = 'Ứng dụng chưa có quyền ghi dữ liệu Firestore. Hãy kiểm tra Firestore Rules.';
      } else {
        _errorMessage = 'Lỗi Firebase: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi đăng ký: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
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

      await _repositoryService.auth.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _errorMessage = 'Ứng dụng chưa có quyền ghi dữ liệu Firestore. Hãy kiểm tra Firestore Rules.';
      } else {
        _errorMessage = 'Lỗi Firebase: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi đặt lại mật khẩu: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repositoryService.auth.logout();
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Lỗi đăng xuất: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    if (e.message != null && e.message!.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Authentication chưa được cấu hình đúng. Hãy kiểm tra google-services.json, firebase_options.dart và bật Email/Password trong Firebase Console.';
    }

    switch (e.code) {
      case 'CONFIGURATION_NOT_FOUND':
      case 'internal-error':
        return 'Firebase Authentication chưa được cấu hình đúng. Hãy kiểm tra google-services.json, firebase_options.dart và bật Email/Password trong Firebase Console.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'network-request-failed':
        return 'Không có kết nối mạng.';
      default:
        return 'Lỗi: ${e.message}';
    }
  }
}

