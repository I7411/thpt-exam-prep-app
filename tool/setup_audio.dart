import 'dart:io';
import 'dart:math' as math;

void main() {
  final resRawDir = Directory('android/app/src/main/res/raw');
  if (!resRawDir.existsSync()) {
    resRawDir.createSync(recursive: true);
    print('Created raw resource directory: ${resRawDir.path}');
  }

  final audiosDir = Directory('assets/audios');
  if (!audiosDir.existsSync()) {
    audiosDir.createSync(recursive: true);
    print('Created assets/audios directory');
  }

  // Find the Doraemon theme song file
  final files = audiosDir.listSync();
  File? doraemonFile;
  for (final file in files) {
    if (file is File && file.path.contains('Doraemon')) {
      doraemonFile = file;
      break;
    }
  }

  if (doraemonFile != null) {
    // Copy as file.mp3 in assets
    final destAsset = File('assets/audios/file.mp3');
    doraemonFile.copySync(destAsset.path);
    print('Copied to asset: ${destAsset.path}');

    // Copy as file.mp3 in android raw
    final destRaw = File('android/app/src/main/res/raw/file.mp3');
    doraemonFile.copySync(destRaw.path);
    print('Copied to Android raw: ${destRaw.path}');
  } else {
    print('WARNING: Doraemon theme song file not found in assets/audios/');
  }

  // Let's also create a second sound file, e.g. alarm_gentle.wav, so we have exactly two or more options
  // Let's create a tiny beep WAV file for gentle alarm
  createGentleWav('assets/audios/alarm_gentle.wav');
  createGentleWav('android/app/src/main/res/raw/alarm_gentle.wav');
}

void createGentleWav(String path) {
  final file = File(path);
  file.parent.createSync(recursive: true);

  final sampleRate = 8000;
  final durationSeconds = 2.0;
  final numSamples = (sampleRate * durationSeconds).toInt();
  
  final headerSize = 44;
  final dataSize = numSamples;
  final fileSize = headerSize + dataSize;
  
  final bytes = List<int>.filled(fileSize, 0);
  
  // 'RIFF'
  bytes[0] = 0x52; bytes[1] = 0x49; bytes[2] = 0x46; bytes[3] = 0x46;
  // File size - 8
  final sz = fileSize - 8;
  bytes[4] = sz & 0xff;
  bytes[5] = (sz >> 8) & 0xff;
  bytes[6] = (sz >> 16) & 0xff;
  bytes[7] = (sz >> 24) & 0xff;
  
  // 'WAVE'
  bytes[8] = 0x57; bytes[9] = 0x41; bytes[10] = 0x56; bytes[11] = 0x45;
  // 'fmt '
  bytes[12] = 0x66; bytes[13] = 0x6d; bytes[14] = 0x74; bytes[15] = 0x20;
  
  // chunk size (16)
  bytes[16] = 16; bytes[17] = 0; bytes[18] = 0; bytes[19] = 0;
  // PCM = 1
  bytes[20] = 1; bytes[21] = 0;
  // Mono = 1
  bytes[22] = 1; bytes[23] = 0;
  // Sample rate (8000)
  bytes[24] = sampleRate & 0xff;
  bytes[25] = (sampleRate >> 8) & 0xff;
  bytes[26] = (sampleRate >> 16) & 0xff;
  bytes[27] = (sampleRate >> 24) & 0xff;
  // Byte rate (8000)
  bytes[28] = sampleRate & 0xff;
  bytes[29] = (sampleRate >> 8) & 0xff;
  bytes[30] = (sampleRate >> 16) & 0xff;
  bytes[31] = (sampleRate >> 24) & 0xff;
  // Block align (1)
  bytes[32] = 1; bytes[33] = 0;
  // Bits per sample (8)
  bytes[34] = 8; bytes[35] = 0;
  
  // 'data'
  bytes[36] = 0x64; bytes[37] = 0x61; bytes[38] = 0x74; bytes[39] = 0x61;
  // Data size
  bytes[40] = dataSize & 0xff;
  bytes[41] = (dataSize >> 8) & 0xff;
  bytes[42] = (dataSize >> 16) & 0xff;
  bytes[43] = (dataSize >> 24) & 0xff;
  
  // Sine wave: 440Hz gentle tone
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final amplitude = 0.5 * math.sin(2 * math.pi * 440.0 * t) * math.sin(math.pi * t / durationSeconds);
    final val = (128 + (amplitude * 120)).round().clamp(0, 255);
    bytes[44 + i] = val;
  }
  
  file.writeAsBytesSync(bytes);
  print('Generated gentle alarm sound at: $path');
}
