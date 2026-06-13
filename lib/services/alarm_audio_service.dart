import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AlarmAudioService {
  AlarmAudioService._internal();

  static final AlarmAudioService instance = AlarmAudioService._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAlarm(String assetPath) async {
    try {
      await stop();

      _player = AudioPlayer();
      _player!.onPlayerStateChanged.listen((state) {
        _isPlaying = state == PlayerState.playing;
      });

      // Format asset path for audioplayers AssetSource (needs to omit "assets/")
      String cleanPath = assetPath;
      if (cleanPath.startsWith('assets/')) {
        cleanPath = cleanPath.substring(7);
      }

      debugPrint('AlarmAudioService: Playing looping alarm $cleanPath');
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.play(AssetSource(cleanPath));
      _isPlaying = true;
    } catch (e) {
      debugPrint('AlarmAudioService Error: Lỗi phát nhạc chuông: $e');
    }
  }

  Future<void> previewRingtone(String assetPath) async {
    try {
      await stop();

      _player = AudioPlayer();
      _player!.onPlayerStateChanged.listen((state) {
        _isPlaying = state == PlayerState.playing;
      });

      String cleanPath = assetPath;
      if (cleanPath.startsWith('assets/')) {
        cleanPath = cleanPath.substring(7);
      }

      debugPrint('AlarmAudioService: Playing preview $cleanPath');
      await _player!.setReleaseMode(ReleaseMode.release);
      await _player!.play(AssetSource(cleanPath));
      _isPlaying = true;
    } catch (e) {
      debugPrint('AlarmAudioService Error: Lỗi phát thử nhạc chuông: $e');
    }
  }

  Future<void> stop() async {
    try {
      if (_player != null) {
        debugPrint('AlarmAudioService: Stopping audio');
        await _player!.stop();
        await _player!.dispose();
        _player = null;
      }
      _isPlaying = false;
    } catch (e) {
      debugPrint('AlarmAudioService Error: Lỗi dừng nhạc chuông: $e');
    }
  }

  void dispose() {
    stop();
  }
}
