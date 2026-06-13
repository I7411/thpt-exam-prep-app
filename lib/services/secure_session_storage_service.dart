import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thpt_exam_prep_app/models.dart';

abstract class SecureKeyValueStore {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  final FlutterSecureStorage _storage;

  const FlutterSecureKeyValueStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }
}

class SecureSessionStorageService {
  static const Duration rememberedSessionLifetime = Duration(days: 30);

  static const String _rememberMeEnabledKey = 'remember_me_enabled';
  static const String _rememberedEmailKey = 'remembered_email';
  static const String _loginAtKey = 'remembered_login_at';
  static const String _sessionVersionKey = 'remembered_session_version';
  static const String _installationIdKey = 'installation_id';
  static const String _installationPrefsKey =
      'secure_session_installation_id';

  static final SecureSessionStorageService instance =
      SecureSessionStorageService();

  final SecureKeyValueStore _store;

  SecureSessionStorageService({SecureKeyValueStore? store})
    : _store = store ?? const FlutterSecureKeyValueStore();

  Future<RememberedSession> loadRememberedSession() async {
    try {
      await _ensureCurrentInstallation();

      final email = await _store.read(key: _rememberedEmailKey);
      final enabled =
          (await _store.read(key: _rememberMeEnabledKey)) == 'true';
      if (!enabled) {
        return RememberedSession.disabled(email: email);
      }

      final loginAtRaw = await _store.read(key: _loginAtKey);
      final sessionVersionRaw = await _store.read(key: _sessionVersionKey);

      return RememberedSession(
        enabled: true,
        email: email,
        loginAt: loginAtRaw == null ? null : DateTime.tryParse(loginAtRaw),
        sessionVersion: sessionVersionRaw == null
            ? null
            : int.tryParse(sessionVersionRaw),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to read secure remembered session: $error');
      debugPrint('stackTrace: $stackTrace');
      return const RememberedSession.disabled();
    }
  }

  Future<void> saveRememberedSession({
    required String email,
    required int sessionVersion,
    DateTime? loginAt,
  }) async {
    try {
      await _ensureCurrentInstallation();
      await _store.write(key: _rememberMeEnabledKey, value: 'true');
      await _store.write(key: _rememberedEmailKey, value: email.trim());
      await _store.write(
        key: _loginAtKey,
        value: (loginAt ?? DateTime.now()).toIso8601String(),
      );
      await _store.write(
        key: _sessionVersionKey,
        value: sessionVersion.toString(),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to save secure remembered session: $error');
      debugPrint('stackTrace: $stackTrace');
    }
  }

  Future<void> clearRememberedSession({bool keepEmail = false}) async {
    try {
      await _ensureCurrentInstallation();
      await _deleteRememberedKeys(keepEmail: keepEmail);
    } catch (error, stackTrace) {
      debugPrint('Unable to clear secure remembered session: $error');
      debugPrint('stackTrace: $stackTrace');
    }
  }

  Future<void> _deleteRememberedKeys({required bool keepEmail}) async {
    await _store.delete(key: _rememberMeEnabledKey);
    await _store.delete(key: _loginAtKey);
    await _store.delete(key: _sessionVersionKey);
    if (!keepEmail) {
      await _store.delete(key: _rememberedEmailKey);
    }
  }

  Future<void> _ensureCurrentInstallation() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsInstallationId = prefs.getString(_installationPrefsKey);
    final secureInstallationId = await _store.read(key: _installationIdKey);

    if (prefsInstallationId == null || prefsInstallationId.isEmpty) {
      final newInstallationId = _generateInstallationId();
      if (secureInstallationId != null && secureInstallationId.isNotEmpty) {
        await _deleteRememberedKeys(keepEmail: false);
      }
      await prefs.setString(_installationPrefsKey, newInstallationId);
      await _store.write(
        key: _installationIdKey,
        value: newInstallationId,
      );
      return;
    }

    if (secureInstallationId != prefsInstallationId) {
      await _deleteRememberedKeys(keepEmail: false);
      await _store.write(
        key: _installationIdKey,
        value: prefsInstallationId,
      );
    }
  }

  String _generateInstallationId() {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return '$timestamp-$random';
  }
}
