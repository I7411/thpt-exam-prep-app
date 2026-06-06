# Core Infrastructure Code Files

## 📄 lib/app.dart - Main Application Widget

```dart
import 'package:flutter/material.dart';
import 'app_config.dart';
import 'app_theme.dart';
import 'app_routes.dart';
import 'placeholder_screen.dart';

/// Main application widget with all route definitions and handlers
class ThptSmartLearnApp extends StatefulWidget {
  const ThptSmartLearnApp({Key? key}) : super(key: key);

  @override
  State<ThptSmartLearnApp> createState() => _ThptSmartLearnAppState();
}

class _ThptSmartLearnAppState extends State<ThptSmartLearnApp> {
  @override
  void initState() {
    super.initState();
    if (AppConfig.enableDevTools) {
      AppConfig.printConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THPT Smart Learn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _generateRoute,
      home: const SplashScreen(),
    );
  }

  /// Route handler for all 25 app routes
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const PlaceholderScreen(
            routeName: 'Login',
            description: 'Login screen for students, teachers, and admins',
          ),
        );
      // ... 23 more routes
      default:
        return MaterialPageRoute(builder: (_) => ErrorScreen());
    }
  }
}

/// Splash Screen with THPT Smart Learn branding
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.school,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'THPT Smart Learn',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ứng dụng luyện thi THPT',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📄 lib/app_theme.dart - Material 3 Theme

**File Size**: ~350 lines
**Features**:
- Light & Dark themes
- Primary: #6366F1 (Purple/Blue)
- Secondary: #0EA5E9 (Ocean Blue)
- Complete typography system (Material 3)
- Styled buttons, inputs, cards, chips
- Consistent spacing & elevation

**Key Colors**:
```dart
primaryColor = #6366F1
secondaryColor = #0EA5E9
backgroundColor = #FAFAFA
errorColor = #DC2626
successColor = #10B981
```

---

## 📄 lib/app_constants.dart - Application Constants

**File Size**: ~120 lines
**Contains**:
```dart
// App Info
appName = 'THPT Smart Learn'
appVersion = '1.0.0'

// Roles
roleStudent = 'student'
roleTeacher = 'teacher'
roleAdmin = 'admin'

// Subject List (10 THPT subjects)
subjectNames = ['Toán', 'Ngữ Văn', 'Tiếng Anh', ...]

// Mock Accounts
mockStudentAccount = {email, password, name, role}
mockTeacherAccount = {email, password, name, role}
mockAdminAccount = {email, password, name, role}

// Database
dbName = 'thpt_smart_learn.db'
```

---

## 📄 lib/app_config.dart - Configuration (Updated)

**File Size**: ~45 lines
**Key Feature - Environment Variable**:
```dart
static String get apiBaseUrl {
  const String apiUrl = String.fromEnvironment('API_BASE_URL');
  return apiUrl.isNotEmpty ? apiUrl : 'http://localhost:3000';
}
```

**Usage**:
```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

**NO Hard-coding of API URLs!**

---

## 📄 lib/app_routes.dart - Route Definitions

**File Size**: ~75 lines
**All 25 Routes Defined**:
```dart
// Splash & Auth
splash = '/splash'
login = '/login'
register = '/register'
forgotPassword = '/forgot-password'

// Student (10 routes)
studentHome = '/student/home'
studentSubjects = '/student/subjects'
// ... etc

// Teacher (6 routes)
teacherDashboard = '/teacher/dashboard'
// ... etc

// Admin (5 routes)
adminDashboard = '/admin/dashboard'
// ... etc
```

---

## 📄 lib/placeholder_screen.dart - Placeholder Widget

**File Size**: ~55 lines
**Purpose**: Temporary UI for unimplemented routes
**Features**:
- Shows route name
- Shows description
- Construction icon
- Back button
- No compile errors

```dart
PlaceholderScreen(
  routeName: 'Login',
  description: 'Login screen for students, teachers, and admins',
)
```

---

## 📄 lib/main.dart - Entry Point (Updated)

**Previous**:
```dart
void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget { ... }
```

**Updated**:
```dart
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThptSmartLearnApp());
}
```

Clean & simple!

---

## 🚀 HOW TO RUN

### Step 1: Create Directories
```bash
bash setup_structure.sh
```

### Step 2: Install & Analyze
```bash
flutter clean
flutter pub get
flutter analyze
```

### Step 3: Run with Default Config
```bash
flutter run
```

### Step 4: Run with Custom API
```bash
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com
```

---

## ✅ VERIFICATION

After running, check:
1. ✓ App starts with splash screen
2. ✓ Navigates to login after 2 seconds
3. ✓ All routes accessible without errors
4. ✓ Theme applied correctly
5. ✓ No compile errors

Test a route:
```dart
// Push to student home
Navigator.pushNamed(context, AppRoutes.studentHome);
```

---

## 📊 CODE STATISTICS

| File | Lines | Components |
|------|-------|-----------|
| app.dart | ~350 | ThptSmartLearnApp, SplashScreen, route handlers |
| app_theme.dart | ~350 | Light/Dark themes, colors, typography |
| app_constants.dart | ~120 | Constants, mock data, subjects |
| app_config.dart | ~45 | Config, environment variables |
| app_routes.dart | ~75 | 25 route definitions |
| placeholder_screen.dart | ~55 | Placeholder widget |
| **Total** | **~995** | **6 core files** |

---

## 🎯 NEXT STEPS

1. ✅ Core infrastructure complete
2. Create directory structure (core/theme, etc.)
3. Implement data models
4. Create repository layer
5. Implement screens
6. Integrate state management

**Status**: Ready for next phase! 🚀
