import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thpt_exam_prep_app/models.dart';

abstract class AuthRepository {
  Future<AppUser?> login(String email, String password);
  Future<AppUser?> register(String email, String password, String fullName, UserRole role);
  Future<AppUser?> getCurrentUser();
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<bool> sendPasswordResetEmail(String email);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Fetch user details from Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return AppUser.fromFirestore(doc);
        } else {
          // Document does not exist. Create a fallback user.
          final fallbackUser = AppUser(
            id: user.uid,
            email: email,
            fullName: 'NgÆ°á»i dÃ¹ng chÆ°a cáº¥u hÃ¬nh',
            role: UserRole.student,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          );
          // Auto create in Firestore to avoid errors
          await _firestore.collection('users').doc(user.uid).set(fallbackUser.toFirestore());
          return fallbackUser;
        }
      }
      return null;
    } on FirebaseAuthException {
      rethrow; // Let Provider handle specific Firebase exceptions
    } catch (e) {
      throw Exception('Lá»—i Ä‘Äƒng nháº­p: $e');
    }
  }

  @override
  Future<AppUser?> register(String email, String password, String fullName, UserRole role) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final newAppUser = AppUser(
          id: user.uid,
          email: email,
          fullName: fullName,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );

        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(newAppUser.toFirestore());
        return newAppUser;
      }
      return null;
    } on FirebaseAuthException {
      rethrow; 
    } catch (e) {
      throw Exception('Lá»—i Ä‘Äƒng kÃ½: $e');
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return AppUser.fromFirestore(doc);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Lá»—i Ä‘áº·t láº¡i máº­t kháº©u: $e');
    }
  }
}
