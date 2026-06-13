import 'dart:io';

void main() {
  final dirs = [
    'lib',
    'test',
    'thpt-exam-prep-app/lib',
    'thpt-exam-prep-app/test',
  ];
  int totalFiles = 0;
  int totalMatches = 0;

  final regex = RegExp(r'\.withOpacity\(([^)]+)\)');

  for (final dirName in dirs) {
    final dir = Directory(dirName);
    if (!dir.existsSync()) continue;

    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final content = file.readAsStringSync();
      if (content.contains('.withOpacity(')) {
        int matchesInFile = 0;
        final newContent = content.replaceAllMapped(regex, (match) {
          matchesInFile++;
          return '.withValues(alpha: ${match.group(1)})';
        });

        if (newContent != content) {
          file.writeAsStringSync(newContent);
          totalFiles++;
          totalMatches += matchesInFile;
          print('Updated \${file.path} (\$matchesInFile matches)');
        }
      }
    }
  }

  print('\nFinished! Updated \$totalMatches instances in \$totalFiles files.');
}
