import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thpt_exam_prep_app/services/secure_session_storage_service.dart';

class FakeSecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves only remembered-session metadata', () async {
    final store = FakeSecureKeyValueStore();
    final service = SecureSessionStorageService(store: store);
    final loginAt = DateTime.utc(2026, 6, 13, 8);

    await service.saveRememberedSession(
      email: 'student@example.com',
      sessionVersion: 3,
      loginAt: loginAt,
    );

    final session = await service.loadRememberedSession();

    expect(session.enabled, isTrue);
    expect(session.email, 'student@example.com');
    expect(session.sessionVersion, 3);
    expect(session.loginAt, loginAt);
    expect(store.values.values, isNot(contains('123456')));
    expect(store.values.keys, isNot(contains('password')));
    expect(store.values.keys, isNot(contains('access_token')));
    expect(store.values.keys, isNot(contains('refresh_token')));
  });

  test('clears remembered session when installation marker changes', () async {
    final store = FakeSecureKeyValueStore()
      ..values['installation_id'] = 'old-install'
      ..values['remember_me_enabled'] = 'true'
      ..values['remembered_email'] = 'student@example.com'
      ..values['remembered_login_at'] =
          DateTime.utc(2026, 6, 13).toIso8601String()
      ..values['remembered_session_version'] = '1';
    final service = SecureSessionStorageService(store: store);

    final session = await service.loadRememberedSession();

    expect(session.enabled, isFalse);
    expect(store.values.containsKey('remember_me_enabled'), isFalse);
    expect(store.values.containsKey('remembered_email'), isFalse);
    expect(store.values['installation_id'], isNot('old-install'));
  });
}
