import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SensitiveScreenProtectionService {
  static const MethodChannel _channel = MethodChannel(
    'thpt_exam_prep_app/window_security',
  );

  static final SensitiveScreenProtectionService instance =
      SensitiveScreenProtectionService._();

  SensitiveScreenProtectionService._();

  int _enableCount = 0;

  Future<void> enable() async {
    _enableCount += 1;
    if (_enableCount == 1) {
      await _setSecureFlag(true);
    }
  }

  Future<void> disable() async {
    if (_enableCount == 0) {
      return;
    }

    _enableCount -= 1;
    if (_enableCount == 0) {
      await _setSecureFlag(false);
    }
  }

  Future<void> _setSecureFlag(bool enabled) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('setSecureFlag', {
        'enabled': enabled,
      });
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Unable to update Android FLAG_SECURE: ${error.code}');
      debugPrint('message: ${error.message}');
      debugPrint('stackTrace: $stackTrace');
    }
  }
}
