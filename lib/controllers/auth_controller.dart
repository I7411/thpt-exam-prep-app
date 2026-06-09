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
      _errorMessage = 'Lá»—i khÃ´i phá»¥c phiÃªn báº£n: $e';
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
        _errorMessage = 'Email khÃ´ng há»£p lá»‡';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Vui lÃ²ng nháº­p máº­t kháº©u';
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
        _errorMessage = 'Email hoáº·c máº­t kháº©u khÃ´ng Ä‘Ãºng';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if ((e.code == 'user-not-found' || e.code == 'invalid-credential') && email.contains('.demo@thptsmartlearn.vn')) {
        _errorMessage = 'TÃ i khoáº£n demo chÆ°a tá»“n táº¡i trÃªn Firebase Auth. HÃ£y táº¡o tÃ i khoáº£n demo trong Firebase Console hoáº·c cháº¡y chá»©c nÄƒng seed demo account.';
      } else {
        _errorMessage = _getFirebaseErrorMessage(e);
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _errorMessage = 'á»¨ng dá»¥ng chÆ°a cÃ³ quyá»n ghi dá»¯ liá»‡u Firestore. HÃ£y kiá»ƒm tra Firestore Rules.';
      } else {
        _errorMessage = 'Lá»—i Firebase: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lá»—i Ä‘Äƒng nháº­p: $e';
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
        _errorMessage = 'Email khÃ´ng há»£p lá»‡';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty || password.length < 6) {
        _errorMessage = 'Máº­t kháº©u pháº£i cÃ³ Ã­t nháº¥t 6 kÃ½ tá»±';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password != confirmPassword) {
        _errorMessage = 'Máº­t kháº©u xÃ¡c nháº­n khÃ´ng khá»›p';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (fullName.isEmpty) {
        _errorMessage = 'Vui lÃ²ng nháº­p há» tÃªn';
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
        _errorMessage = 'ÄÄƒng kÃ½ tháº¥t báº¡i';
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
        _errorMessage = 'á»¨ng dá»¥ng chÆ°a cÃ³ quyá»n ghi dá»¯ liá»‡u Firestore. HÃ£y kiá»ƒm tra Firestore Rules.';
      } else {
        _errorMessage = 'Lá»—i Firebase: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lá»—i Ä‘Äƒng kÃ½: $e';
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
        _errorMessage = 'Email khÃ´ng há»£p lá»‡';
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
        _errorMessage = 'á»¨ng dá»¥ng chÆ°a cÃ³ quyá»n ghi dá»¯ liá»‡u Firestore. HÃ£y kiá»ƒm tra Firestore Rules.';
      } else {
        _errorMessage = 'Lá»—i Firebase: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lá»—i Ä‘áº·t láº¡i máº­t kháº©u: $e';
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
      _errorMessage = 'Lá»—i Ä‘Äƒng xuáº¥t: $e';
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
      return 'Firebase Authentication chÆ°a Ä‘Æ°á»£c cáº¥u hÃ¬nh Ä‘Ãºng. HÃ£y kiá»ƒm tra google-services.json, firebase_options.dart vÃ  báº­t Email/Password trong Firebase Console.';
    }

    switch (e.code) {
      case 'CONFIGURATION_NOT_FOUND':
      case 'internal-error':
        return 'Firebase Authentication chÆ°a Ä‘Æ°á»£c cáº¥u hÃ¬nh Ä‘Ãºng. HÃ£y kiá»ƒm tra google-services.json, firebase_options.dart vÃ  báº­t Email/Password trong Firebase Console.';
      case 'user-not-found':
        return 'KhÃ´ng tÃ¬m tháº¥y tÃ i khoáº£n.';
      case 'wrong-password':
        return 'Máº­t kháº©u khÃ´ng Ä‘Ãºng.';
      case 'invalid-credential':
        return 'Email hoáº·c máº­t kháº©u khÃ´ng Ä‘Ãºng.';
      case 'invalid-email':
        return 'Email khÃ´ng há»£p lá»‡.';
      case 'user-disabled':
        return 'TÃ i khoáº£n Ä‘Ã£ bá»‹ vÃ´ hiá»‡u hÃ³a.';
      case 'email-already-in-use':
        return 'Email Ä‘Ã£ Ä‘Æ°á»£c sá»­ dá»¥ng.';
      case 'weak-password':
        return 'Máº­t kháº©u quÃ¡ yáº¿u.';
      case 'network-request-failed':
        return 'KhÃ´ng cÃ³ káº¿t ná»‘i máº¡ng.';
      default:
        return 'Lá»—i: ${e.message}';
    }
  }
}

