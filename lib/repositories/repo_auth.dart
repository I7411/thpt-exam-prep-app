import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:thpt_exam_prep_app/models.dart';

const Duration _authTimeout = Duration(seconds: 15);
const Duration _firestoreTimeout = Duration(seconds: 15);

/// The Web/Server OAuth 2.0 client_id from google-services.json
/// (the entry with client_type = 3). Required on Android so that
/// GoogleSignIn returns an idToken that Firebase Auth can verify.
const String _googleServerClientId =
    '529775655888-l8mcjhpu4i4veijhqev9cj60gsjom86n.apps.googleusercontent.com';

abstract class AuthRepository {
  Future<AppUser?> login(String email, String password);
  Future<AppUser?> register(
    String email,
    String password,
    String fullName,
    UserRole role,
  );
  Future<AppUser?> getCurrentUser();
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<bool> sendPasswordResetEmail(String email);
  Future<AppUser?> signInWithGoogle();
  Future<bool> verifyEmailExists(String email);
  Future<void> confirmPasswordReset(String code, String newPassword);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final userCredential = await _firebaseAuth
        .signInWithEmailAndPassword(email: normalizedEmail, password: password)
        .timeout(_authTimeout);

    final user = userCredential.user;
    if (user == null) {
      return null;
    }

    return _readOrCreateUserProfile(
      user,
      fallbackEmail: normalizedEmail,
      fallbackFullName: _displayNameOrEmail(user, normalizedEmail),
    );
  }

  @override
  Future<AppUser?> register(
    String email,
    String password,
    String fullName,
    UserRole role,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = fullName.trim();
    final userCredential = await _firebaseAuth
        .createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        )
        .timeout(_authTimeout);

    final user = userCredential.user;
    if (user == null) {
      return null;
    }

    await user.updateDisplayName(normalizedName).timeout(_authTimeout);
    await user.sendEmailVerification().timeout(_authTimeout);

    final now = DateTime.now();
    final newAppUser = AppUser(
      id: user.uid,
      email: normalizedEmail,
      fullName: normalizedName,
      role: role,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    await _setUserDocument(
      uid: user.uid,
      email: normalizedEmail,
      fullName: normalizedName,
      role: role,
      isCreate: true,
      signInProvider: 'email',
    );

    return newAppUser;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    return _readOrCreateUserProfile(
      user,
      fallbackEmail: user.email ?? '',
      fallbackFullName: _displayNameOrEmail(user, user.email ?? 'Học sinh'),
    ).timeout(_firestoreTimeout);
  }

  @override
  Future<void> logout() async {
    // Sign out of Google as well so the account picker shows next time.
    // Use GoogleSignIn.instance for version 7.2.0 API
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    await _firebaseAuth
        .sendPasswordResetEmail(email: email.trim().toLowerCase())
        .timeout(_authTimeout);
    return true;
  }

  static const Map<String, Map<String, dynamic>> _demoAccounts = {
    'student.demo@thptsmartlearn.vn': {
      'role': UserRole.student,
      'fullName': 'Học sinh Demo',
    },
    'teacher.demo@thptsmartlearn.vn': {
      'role': UserRole.teacher,
      'fullName': 'Giáo viên Demo',
    },
    'admin.demo@thptsmartlearn.vn': {
      'role': UserRole.admin,
      'fullName': 'Admin Demo',
    },
  };

  Future<AppUser> _readOrCreateUserProfile(
    User firebaseUser, {
    required String fallbackEmail,
    required String fallbackFullName,
  }) async {
    final normalizedEmail = (firebaseUser.email ?? fallbackEmail)
        .trim()
        .toLowerCase();
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await userDoc.get().timeout(_firestoreTimeout);

    if (doc.exists) {
      final data = doc.data();
      if (data == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'missing-role',
          message: 'This account has not been assigned a role.',
        );
      }

      final roleValue = data['role'] as String?;
      if (roleValue == null ||
          (roleValue != 'student' &&
              roleValue != 'teacher' &&
              roleValue != 'admin')) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'missing-role',
          message: 'This account has not been assigned a role.',
        );
      }

      final isActive = data['isActive'] as bool? ?? true;
      if (!isActive) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'user-disabled',
          message: 'This account has been disabled.',
        );
      }

      return AppUser.fromFirestore(doc);
    }

    if (!_demoAccounts.containsKey(normalizedEmail)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'profile-missing',
        message: 'This account does not have a user profile in Firestore.',
      );
    }

    final demoInfo = _demoAccounts[normalizedEmail]!;
    final assignedRole = demoInfo['role'] as UserRole;
    final assignedFullName = demoInfo['fullName'] as String;

    await _setUserDocument(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? fallbackEmail,
      fullName: assignedFullName,
      role: assignedRole,
      isCreate: true,
      signInProvider: 'email',
    );

    final now = DateTime.now();
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? fallbackEmail,
      fullName: assignedFullName,
      role: assignedRole,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  Future<void> _setUserDocument({
    required String uid,
    required String email,
    required String fullName,
    required UserRole role,
    required bool isCreate,
    String? photoUrl,
    String? signInProvider,
  }) async {
    final data = <String, dynamic>{
      'uid': uid,
      'email': email.trim(),
      'fullName': fullName.trim().isEmpty ? email.trim() : fullName.trim(),
      'role': role.toValue(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      // ignore: use_null_aware_elements
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (signInProvider != null) 'signInProvider': signInProvider,
    };

    if (isCreate) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['sessionVersion'] = 0;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true))
        .timeout(_firestoreTimeout);
  }

  String _displayNameOrEmail(User user, String fallbackEmail) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return fallbackEmail.trim().isEmpty ? 'Học sinh' : fallbackEmail.trim();
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    // serverClientId is the Web OAuth 2.0 client_id (client_type=3) from
    // google-services.json. Without it, Android GoogleSignIn does NOT return
    // an idToken, causing Firebase Auth signInWithCredential to fail.
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on PlatformException catch (e) {
      // Log the exact platform error code for diagnosis
      throw FirebaseAuthException(
        code: 'google-sign-in-platform-error',
        message:
            'PlatformException during Google Sign-In. '
            'code=${e.code}, message=${e.message}. '
            'Make sure SHA-1 is registered in Firebase Console and '
            'google-services.json is up to date.',
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-error',
        message: 'Error during Google Sign-In: $e',
      );
    }

    if (googleUser == null) {
      // User dismissed the picker — not an error.
      return null;
    }

    // In 7.2.0, authentication is synchronous and only provides idToken
    final googleAuth = googleUser.authentication;
    final authz = await googleUser.authorizationClient.authorizationForScopes(
      [],
    );

    // If idToken is null the Web/Android OAuth client is missing or the
    // SHA-1 fingerprint has not been registered yet.
    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message:
            'Google Sign-In succeeded but idToken is null. '
            'Register SHA-1 (${const String.fromEnvironment('DEBUG_SHA1', defaultValue: 'CD:55:FB:A9:37:FB:0E:D6:39:6E:57:97:3A:9B:6F:EE:79:EC:F4:15')}) '
            'in Firebase Console → Project Settings → Your Android App → SHA certificate fingerprints, '
            'then download and replace google-services.json.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: authz?.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth
        .signInWithCredential(credential)
        .timeout(_authTimeout);

    final user = userCredential.user;
    if (user == null) {
      return null;
    }

    // Prepare profile image url if available from Google
    final photoUrl = user.photoURL;

    // Check if the user document exists.
    final userDoc = _firestore.collection('users').doc(user.uid);
    final doc = await userDoc.get().timeout(_firestoreTimeout);

    if (doc.exists) {
      // Document exists: update safe fields only.
      // Do NOT overwrite role or isActive set by admin.
      final existingData = doc.data()!;
      final updates = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        // Only fill fullName if it is missing in Firestore.
        if ((existingData['fullName'] as String?)?.trim().isEmpty ?? true)
          'fullName': user.displayName ?? 'Học sinh',
        'updatedAt': FieldValue.serverTimestamp(),
        // ignore: use_null_aware_elements
        if (photoUrl != null) 'photoUrl': photoUrl,
        'signInProvider': existingData['signInProvider'] ?? 'google',
      };
      await userDoc
          .set(updates, SetOptions(merge: true))
          .timeout(_firestoreTimeout);
      return AppUser.fromFirestore(
        await userDoc.get().timeout(_firestoreTimeout),
      );
    }

    // Document does not exist: create a new student profile.
    final now = DateTime.now();
    await _setUserDocument(
      uid: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? 'Học sinh',
      role: UserRole.student,
      isCreate: true,
      photoUrl: photoUrl,
      signInProvider: 'google',
    );

    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? 'Học sinh',
      role: UserRole.student,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      profileImageUrl: photoUrl,
    );
  }

  @override
  Future<bool> verifyEmailExists(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get()
        .timeout(_firestoreTimeout);
    return query.docs.isNotEmpty;
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    await _firebaseAuth
        .confirmPasswordReset(code: code.trim(), newPassword: newPassword)
        .timeout(_authTimeout);
  }
}
