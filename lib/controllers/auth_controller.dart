import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';
import 'package:thpt_exam_prep_app/services/notification_service.dart';

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

  Future<bool> restoreSession() async {
    debugPrint('Đang kiểm tra phiên đăng nhập hiện tại...');
    _setLoading(true);
    _errorMessage = '';

    try {
      final user = await _repositoryService.auth.getCurrentUser().timeout(
        const Duration(seconds: 8),
      );
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        debugPrint('Đã xác định vai trò người dùng: ${user.role.toValue()}');
        NotificationService.instance.saveTokenToFirestore(user.id);
      } else {
        _currentUser = null;
        _isAuthenticated = false;
        debugPrint('Không có phiên đăng nhập. Chuyển về màn hình đăng nhập.');
      }
      return true;
    } on TimeoutException {
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = 'Kiểm tra phiên đăng nhập quá lâu. Vui lòng thử lại.';
      debugPrint('Kiểm tra phiên đăng nhập bị quá thời gian.');
      return false;
    } on FirebaseException catch (e, stackTrace) {
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = _getFirestoreErrorMessage(e);
      _logFirebaseException(
        'Lỗi khi đọc hồ sơ người dùng từ Firestore',
        e,
        stackTrace,
      );
      return false;
    } catch (e, stackTrace) {
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = 'Không thể khôi phục phiên đăng nhập. Vui lòng thử lại.';
      _logUnknownException(
        'Lỗi không xác định khi khôi phục phiên đăng nhập',
        e,
        stackTrace,
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final normalizedEmail = email.trim();
      if (!_isValidEmail(normalizedEmail)) {
        _errorMessage = 'Email không hợp lệ.';
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Vui lòng nhập mật khẩu.';
        return false;
      }

      debugPrint('Đang đăng nhập bằng Firebase Auth...');
      final user = await _repositoryService.auth.login(
        normalizedEmail,
        password,
      );

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        debugPrint('Đăng nhập thành công. Vai trò: ${user.role.toValue()}');
        NotificationService.instance.saveTokenToFirestore(user.id);
        return true;
      }

      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = 'Email hoặc mật khẩu không đúng.';
      return false;
    } on FirebaseAuthException catch (e, stackTrace) {
      _logFirebaseAuthException(
        'Lỗi khi đăng nhập bằng Firebase Auth',
        e,
        stackTrace,
      );

      final normalizedEmail = email.trim();
      if (_shouldAutoRegisterDemoAccount(normalizedEmail, e)) {
        return _tryAutoRegisterDemoAccount(normalizedEmail, password);
      }

      _errorMessage = _getLoginFirebaseAuthErrorMessage(e);
      return false;
    } on FirebaseException catch (e, stackTrace) {
      _errorMessage = _getFirestoreErrorMessage(e);
      _logFirebaseException(
        'Lỗi Firestore sau khi đăng nhập Firebase Auth thành công',
        e,
        stackTrace,
      );
      return false;
    } on TimeoutException {
      _errorMessage = 'Đăng nhập quá lâu. Vui lòng kiểm tra mạng và thử lại.';
      debugPrint('Đăng nhập bị quá thời gian.');
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại.';
      _logUnknownException('Lỗi không xác định khi đăng nhập', e, stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(
    String email,
    String password,
    String confirmPassword,
    String fullName,
    UserRole role,
  ) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final normalizedEmail = email.trim();
      final normalizedName = fullName.trim();
      if (normalizedName.isEmpty) {
        _errorMessage = 'Vui lòng nhập họ tên.';
        return false;
      }

      if (!_isValidEmail(normalizedEmail)) {
        _errorMessage = 'Email không hợp lệ.';
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.';
        return false;
      }

      if (password != confirmPassword) {
        _errorMessage = 'Mật khẩu xác nhận không khớp.';
        return false;
      }

      if (!UserRole.values.contains(role)) {
        _errorMessage = 'Vai trò không hợp lệ.';
        return false;
      }

      debugPrint('Đang tạo tài khoản bằng Firebase Auth...');
      final user = await _repositoryService.auth.register(
        normalizedEmail,
        password,
        normalizedName,
        role,
      );

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        debugPrint(
          'Tạo hồ sơ người dùng thành công. Vai trò: ${user.role.toValue()}',
        );
        NotificationService.instance.saveTokenToFirestore(user.id);
        return true;
      }

      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      return false;
    } on FirebaseAuthException catch (e, stackTrace) {
      _errorMessage = _getRegisterFirebaseAuthErrorMessage(e);
      _logFirebaseAuthException(
        'Lỗi khi đăng ký bằng Firebase Auth',
        e,
        stackTrace,
      );
      return false;
    } on FirebaseException catch (e, stackTrace) {
      _errorMessage = _getFirestoreErrorMessage(e);
      _logFirebaseException(
        'Lỗi khi tạo hồ sơ người dùng trên Firestore',
        e,
        stackTrace,
      );
      return false;
    } on TimeoutException {
      _errorMessage = 'Đăng ký quá lâu. Vui lòng kiểm tra mạng và thử lại.';
      debugPrint('Đăng ký bị quá thời gian.');
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      _logUnknownException('Lỗi không xác định khi đăng ký', e, stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final normalizedEmail = email.trim();
      if (!_isValidEmail(normalizedEmail)) {
        _errorMessage = 'Email không hợp lệ.';
        return false;
      }

      await _repositoryService.auth.sendPasswordResetEmail(normalizedEmail);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      _errorMessage = _getLoginFirebaseAuthErrorMessage(e);
      _logFirebaseAuthException(
        'Lỗi khi gửi email đặt lại mật khẩu',
        e,
        stackTrace,
      );
      return false;
    } on FirebaseException catch (e, stackTrace) {
      _errorMessage = _getFirestoreErrorMessage(e);
      _logFirebaseException(
        'Lỗi Firebase khi gửi email đặt lại mật khẩu',
        e,
        stackTrace,
      );
      return false;
    } on TimeoutException {
      _errorMessage = 'Gửi email đặt lại mật khẩu quá lâu. Vui lòng thử lại.';
      debugPrint('Gửi email đặt lại mật khẩu bị quá thời gian.');
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Không thể gửi email đặt lại mật khẩu. Vui lòng thử lại.';
      _logUnknownException(
        'Lỗi không xác định khi đặt lại mật khẩu',
        e,
        stackTrace,
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      debugPrint('Đang đăng nhập bằng Google...');
      final user = await _repositoryService.auth.signInWithGoogle();

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        debugPrint('Đăng nhập Google thành công. Vai trò: ${user.role.toValue()}');
        NotificationService.instance.saveTokenToFirestore(user.id);
        return true;
      }

      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = 'Đăng nhập bằng Google bị hủy hoặc thất bại.';
      return false;
    } on FirebaseAuthException catch (e, stackTrace) {
      _errorMessage = _getLoginFirebaseAuthErrorMessage(e);
      _logFirebaseAuthException('Lỗi khi đăng nhập bằng Google', e, stackTrace);
      return false;
    } on FirebaseException catch (e, stackTrace) {
      _errorMessage = _getFirestoreErrorMessage(e);
      _logFirebaseException('Lỗi Firestore sau khi đăng nhập Google', e, stackTrace);
      return false;
    } on TimeoutException {
      _errorMessage = 'Đăng nhập Google quá lâu. Vui lòng thử lại.';
      return false;
    } catch (e, stackTrace) {
      _errorMessage = 'Không thể đăng nhập bằng Google. Vui lòng thử lại.';
      _logUnknownException('Lỗi không xác định khi đăng nhập Google', e, stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmailExists(String email) async {
    _setLoading(true);
    _errorMessage = '';
    try {
      final exists = await _repositoryService.auth.verifyEmailExists(email);
      if (!exists) {
        _errorMessage = 'Không tìm thấy tài khoản với email này.';
      }
      return exists;
    } catch (e) {
      _errorMessage = 'Lỗi xác thực email: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    _setLoading(true);
    _errorMessage = '';
    try {
      if (newPassword.length < 6) {
        _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.';
        return false;
      }
      await _repositoryService.auth.confirmPasswordReset(code, newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'expired-action-code') {
        _errorMessage = 'Mã xác thực đã hết hạn.';
      } else if (e.code == 'invalid-action-code') {
        _errorMessage = 'Mã xác thực không hợp lệ.';
      } else if (e.code == 'user-not-found') {
        _errorMessage = 'Không tìm thấy người dùng.';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'Mật khẩu mới quá yếu.';
      } else {
        _errorMessage = 'Đặt lại mật khẩu thất bại: ${e.message}';
      }
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi khi đặt lại mật khẩu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _repositoryService.auth.logout();
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = '';
      debugPrint('Đã đăng xuất.');
    } catch (e) {
      _errorMessage = 'Không thể đăng xuất. Vui lòng thử lại.';
      debugPrint('Lỗi khi đăng xuất: $e');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  bool _shouldAutoRegisterDemoAccount(
    String email,
    FirebaseAuthException exception,
  ) {
    // Only auto-register on clear user-not-found, not on invalid-credential or wrong-password
    return exception.code == 'user-not-found' && _demoRoleForEmail(email) != null;
  }

  Future<bool> _tryAutoRegisterDemoAccount(
    String email,
    String password,
  ) async {
    final role = _demoRoleForEmail(email);
    if (role == null) {
      return false;
    }

    try {
      debugPrint(
        'Tài khoản demo chưa có trên Firebase Auth. Đang tự tạo tài khoản demo với vai trò: ${role.toValue()}',
      );
      final user = await _repositoryService.auth.register(
        email,
        password,
        _demoDisplayNameForRole(role),
        role,
      );

      if (user == null) {
        _currentUser = null;
        _isAuthenticated = false;
        _errorMessage = 'Không thể tự động đăng ký tài khoản demo.';
        return false;
      }

      _currentUser = user;
      _isAuthenticated = true;
      _errorMessage = '';
      debugPrint(
        'Tạo và đăng nhập tài khoản demo thành công. Vai trò: ${user.role.toValue()}',
      );
      NotificationService.instance.saveTokenToFirestore(user.id);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      _logFirebaseAuthException(
        'Lỗi khi tự tạo tài khoản demo bằng Firebase Auth',
        e,
        stackTrace,
      );
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = e.code == 'email-already-in-use'
          ? 'Email hoặc mật khẩu không chính xác.'
          : _getRegisterFirebaseAuthErrorMessage(e);
      return false;
    } on FirebaseException catch (e, stackTrace) {
      _logFirebaseException(
        'Lỗi Firestore khi tự tạo hồ sơ demo',
        e,
        stackTrace,
      );
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = _getFirestoreErrorMessage(e);
      return false;
    } on TimeoutException {
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = 'Không thể kết nối với Firestore. Vui lòng kiểm tra kết nối mạng của bạn.';
      debugPrint('Tự tạo tài khoản demo bị quá thời gian.');
      return false;
    } catch (e, stackTrace) {
      _logUnknownException(
        'Lỗi không xác định khi tự tạo tài khoản demo',
        e,
        stackTrace,
      );
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = 'Không thể tự động đăng ký tài khoản demo.';
      return false;
    }
  }

  UserRole? _demoRoleForEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == 'student.demo@thptsmartlearn.vn') {
      return UserRole.student;
    }
    if (normalizedEmail == 'teacher.demo@thptsmartlearn.vn') {
      return UserRole.teacher;
    }
    if (normalizedEmail == 'admin.demo@thptsmartlearn.vn') {
      return UserRole.admin;
    }
    return null;
  }

  String _demoDisplayNameForRole(UserRole role) {
    return switch (role) {
      UserRole.student => 'Học sinh Demo',
      UserRole.teacher => 'Giáo viên Demo',
      UserRole.admin => 'Admin Demo',
    };
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  String _getLoginFirebaseAuthErrorMessage(FirebaseAuthException e) {
    if (e.message != null && e.message!.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Authentication chưa được cấu hình đúng. Hãy kiểm tra google-services.json, firebase_options.dart và bật Email/Password trong Firebase Console.';
    }

    switch (e.code) {
      case 'CONFIGURATION_NOT_FOUND':
      case 'internal-error':
        return 'Firebase Authentication chưa được cấu hình đúng. Hãy kiểm tra google-services.json, firebase_options.dart và bật Email/Password trong Firebase Console.';
      case 'user-not-found':
        return 'Tài khoản này không tồn tại.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'network-request-failed':
        return 'Không thể kết nối với Firestore. Vui lòng kiểm tra kết nối mạng của bạn.';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';
      default:
        return 'Đăng nhập thất bại. Vui lòng thử lại.';
    }
  }

  String _getRegisterFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'network-request-failed':
        return 'Không thể kết nối với Firestore. Vui lòng kiểm tra kết nối mạng của bạn.';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';
      case 'operation-not-allowed':
      case 'CONFIGURATION_NOT_FOUND':
      case 'internal-error':
        return 'Firebase Authentication chưa được cấu hình đúng. Hãy bật Email/Password trong Firebase Console.';
      default:
        return 'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }

  String _getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Ứng dụng không có quyền đọc dữ liệu từ Firestore. Vui lòng kiểm tra Firestore Rules.';
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return 'Không thể kết nối với Firestore. Vui lòng kiểm tra kết nối mạng của bạn.';
      case 'missing-role':
        return 'Tài khoản này chưa được gán vai trò hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      default:
        return 'Không thể xử lý dữ liệu người dùng trên Firestore. Vui lòng thử lại.';
    }
  }

  Future<bool> updateProfile({required String fullName, String? className}) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    _errorMessage = '';
    try {
      final uid = _currentUser!.id;
      final updates = <String, dynamic>{
        'fullName': fullName.trim(),
        if (className != null) 'className': className.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updates)
          .timeout(const Duration(seconds: 10));
          
      // Update local state
      _currentUser = _currentUser!.copyWith(
        fullName: fullName.trim(),
        className: className?.trim(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật thông tin: $e';
      debugPrint('Lỗi cập nhật thông tin cá nhân: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _logFirebaseAuthException(
    String context,
    FirebaseAuthException exception,
    StackTrace stackTrace,
  ) {
    debugPrint('$context.');
    debugPrint('FirebaseAuthException.code: ${exception.code}');
    debugPrint('FirebaseAuthException.message: ${exception.message}');
    debugPrint('stackTrace: $stackTrace');
  }

  void _logFirebaseException(
    String context,
    FirebaseException exception,
    StackTrace stackTrace,
  ) {
    debugPrint('$context.');
    debugPrint('FirebaseException.code: ${exception.code}');
    debugPrint('FirebaseException.message: ${exception.message}');
    debugPrint('stackTrace: $stackTrace');
  }

  void _logUnknownException(
    String context,
    Object exception,
    StackTrace stackTrace,
  ) {
    debugPrint('$context: $exception');
    debugPrint('stackTrace: $stackTrace');
  }
}
