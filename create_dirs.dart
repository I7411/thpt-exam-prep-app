import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  final baseDir = 'lib';
  
  final directories = [
    'core/config',
    'core/constants',
    'core/routes',
    'core/theme',
    'core/utils',
    'data/models',
    'data/mock',
    'data/local',
    'data/remote',
    'data/repositories',
    'providers',
    'screens/splash',
    'screens/auth',
    'screens/student',
    'screens/document',
    'screens/exam',
    'screens/progress',
    'screens/notification',
    'screens/profile',
    'screens/teacher',
    'screens/admin',
    'widgets',
  ];

  for (var dir in directories) {
    final dirPath = path.join(baseDir, dir);
    final directory = Directory(dirPath);
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('Created: $dir');
    }
  }
  
  print('All directories created successfully!');
}
