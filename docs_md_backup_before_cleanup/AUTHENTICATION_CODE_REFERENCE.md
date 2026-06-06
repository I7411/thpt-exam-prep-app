# Code Reference - Authentication MVP

## File Locations & Contents Summary

### New Provider File

#### lib/providers_auth.dart (220 lines)
**Purpose**: Central authentication state management using ChangeNotifier

**Main Components**:
- `AuthProvider` class extending `ChangeNotifier`
- 4 state variables: currentUser, isLoading, errorMessage, isAuthenticated
- 6 public methods: login, register, logout, restoreSession, clearError, + helpers
- Integration with RepositoryService and SharedPreferences

**Key Methods**:
```dart
Future<bool> login(String email, String password)
Future<bool> register(String email, String password, String confirmPassword, 
                      String fullName, UserRole role)
Future<void> logout()
Future<void> restoreSession()
void clearError()
```

**Usage in Screens**:
```dart
// In LoginScreen
final authProvider = context.read<AuthProvider>();
await authProvider.login(email, password);

// In any screen watching auth
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    // Access: authProvider.isAuthenticated, authProvider.currentUser
  }
)
```

---

### New Screen Files

#### lib/screens_splash.dart (63 lines)
**Purpose**: App initialization and session restoration

**Flow**:
1. Show splash screen for 2 seconds
2. Call `authProvider.restoreSession()`
3. If authenticated → navigate to appropriate dashboard
4. If not authenticated → navigate to LoginScreen

**Key Code**:
```dart
Future<void> _initializeApp() async {
  await Future.delayed(const Duration(seconds: 2));
  final authProvider = context.read<AuthProvider>();
  await authProvider.restoreSession();
  
  if (authProvider.isAuthenticated) {
    // Navigate to dashboard
  } else {
    // Navigate to login
  }
}
```

---

#### lib/screens_login.dart (280 lines)
**Purpose**: User authentication interface

**Form Fields**:
- Email (with keyboard type: emailAddress)
- Password (with visibility toggle)

**Buttons**:
- "Đăng nhập" (Login) - main action
- "Quên mật khẩu?" (Forgot Password) - link
- "Đăng ký ngay" (Register) - link

**Display Elements**:
- Error message box (red background if error exists)
- Loading spinner during authentication
- Demo credentials info box (blue background)

**Key Code**:
```dart
void _handleLogin(BuildContext context) async {
  final authProvider = context.read<AuthProvider>();
  final success = await authProvider.login(
    _emailController.text.trim(),
    _passwordController.text,
  );
  
  if (success && mounted) {
    final user = authProvider.currentUser;
    String nextRoute;
    if (user.role == UserRole.student) {
      nextRoute = AppRoutes.studentHome;
    } else if (user.role == UserRole.teacher) {
      nextRoute = AppRoutes.teacherDashboard;
    } else {
      nextRoute = AppRoutes.adminDashboard;
    }
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }
}
```

---

#### lib/screens_register.dart (325 lines)
**Purpose**: New user registration interface

**Form Fields**:
- Họ tên (Full Name) - text input
- Email - email input
- Vai trò (Role) - dropdown (Student/Teacher/Admin)
- Mật khẩu (Password) - password input with visibility toggle
- Xác nhận mật khẩu (Confirm Password) - password input with visibility toggle

**Validation**:
- Email format check
- Password length (6+ chars)
- Password confirmation match
- Full name not empty
- Role selection required

**Key Code**:
```dart
Future<void> _handleRegister(BuildContext context) async {
  final authProvider = context.read<AuthProvider>();
  final success = await authProvider.register(
    _emailController.text.trim(),
    _passwordController.text,
    _confirmPasswordController.text,
    _nameController.text.trim(),
    _selectedRole,
  );
  
  if (success && mounted) {
    // Auto-login and navigate by role
  }
}
```

---

## Updated Files

### lib/main.dart
**Changes**:
- Added import: `import 'providers_auth.dart';`
- Wrapped app with MultiProvider:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const ThptSmartLearnApp(),
    ),
  );
}
```

---

### lib/app.dart
**Changes**:
- Added imports:
  ```dart
  import 'screens_splash.dart';
  import 'screens_login.dart';
  import 'screens_register.dart';
  ```

- Updated route handlers in `_generateRoute()`:
  ```dart
  case AppRoutes.splash:
    return MaterialPageRoute(
      builder: (_) => const SplashScreen(),  // Was SplashScreen inline
      settings: settings,
    );
  
  case AppRoutes.login:
    return MaterialPageRoute(
      builder: (_) => const LoginScreen(),   // Was PlaceholderScreen
      settings: settings,
    );
  
  case AppRoutes.register:
    return MaterialPageRoute(
      builder: (_) => const RegisterScreen(),  // Was PlaceholderScreen
      settings: settings,
    );
  ```

---

## Existing Files Used (Not Modified)

### lib/models.dart & Model Files
- `AppUser` - User data structure
- `UserRole` enum (student, teacher, admin)
- `NotificationItem`, `ProgressStat` - Other models used by screens

### lib/repository_service.dart
- `RepositoryService.getInstance()` - Service locator singleton
- `.auth` getter to access AuthRepository

### lib/repo_auth.dart
- `AuthRepository` - Abstract interface
- `MockAuthRepository` - Mock implementation with hardcoded test accounts

### lib/mock_progress.dart
- `MockUsersData.studentUser` - Student test account
- `MockUsersData.teacherUser` - Teacher test account
- `MockUsersData.adminUser` - Admin test account

### lib/app_routes.dart
- Route constants like `AppRoutes.splash`, `AppRoutes.login`, `AppRoutes.register`

### lib/app_theme.dart
- Theme definitions used by all screens

### lib/app_config.dart
- Configuration including API_BASE_URL

---

## Dependencies Used

### From pubspec.yaml (Already Added)
```yaml
provider: ^6.0.0           # State management
shared_preferences: ^2.0.0 # Session persistence
flutter:                   # Core
  material: true           # UI components
```

---

## Error Messages Map

```dart
// All error messages are in Vietnamese

"Email không hợp lệ"
  → Invalid email format (doesn't match regex)

"Vui lòng nhập mật khẩu"
  → Password field is empty

"Email hoặc mật khẩu không đúng"
  → Credentials don't match any mock account

"Mật khẩu phải có ít nhất 6 ký tự"
  → Password length < 6 characters

"Mật khẩu xác nhận không khớp"
  → Password and confirm password don't match

"Vui lòng nhập họ tên"
  → Full name field is empty

"Đăng ký thất bại, vui lòng thử lại"
  → Registration failed (rare, only if repo returns null)
```

---

## SharedPreferences Keys

```dart
// Session data keys
"userId"       → String: User's unique ID (e.g., "student_001")
"userRole"     → String: Role as enum string (e.g., "UserRole.student")
"userEmail"    → String: User's email address
"userName"     → String: User's full name
```

**Example After Login**:
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('userId', 'student_001');
await prefs.setString('userRole', 'UserRole.student');
await prefs.setString('userEmail', 'student@example.com');
await prefs.setString('userName', 'Nguyễn Văn A');
```

---

## Test Account Credentials

```
Student:
  Email: student@example.com
  Password: 123456
  ID: student_001
  Name: Nguyễn Văn A
  Role: UserRole.student
  Navigation: /student/home

Teacher:
  Email: teacher@example.com
  Password: 123456
  ID: teacher_001
  Name: Thầy Lê Văn B
  Role: UserRole.teacher
  Navigation: /teacher/dashboard

Admin:
  Email: admin@example.com
  Password: 123456
  ID: admin_001
  Name: Quản trị viên Hệ thống
  Role: UserRole.admin
  Navigation: /admin/dashboard
```

All credentials are in `MockUsersData` class in `lib/mock_progress.dart`.

---

## Data Flow Diagram

```
User Interface (Screens)
    ↓
AuthProvider (State Management)
    ├─ Holds: currentUser, isLoading, errorMessage, isAuthenticated
    ├─ Methods: login, register, logout, restoreSession
    ↓
RepositoryService (Service Locator)
    ├─ getInstance()
    ├─ .auth property
    ↓
AuthRepository (Abstraction)
    ├─ login(email, password)
    ├─ register(email, password, fullName, role)
    ├─ logout()
    ├─ getCurrentUser()
    ↓
MockAuthRepository (Implementation)
    ├─ Checks against MockUsersData
    ├─ Returns AppUser or null
    ├─ Simulates 500ms network delay
    ↓
SharedPreferences (Persistence)
    ├─ userId
    ├─ userRole
    ├─ userEmail
    ├─ userName
```

---

## Future Extension Points

### For API Integration
1. Create `ApiAuthRepository` implementing `AuthRepository`
2. Update `RepositoryService._initializeRepositories()`:
   ```dart
   _authRepo = ApiAuthRepository();  // Instead of MockAuthRepository
   ```
3. No screen changes needed - abstraction handles it!

### For Additional Providers
Following the same pattern:
```dart
// In main.dart MultiProvider:
ChangeNotifierProvider(create: (_) => SubjectProvider()),
ChangeNotifierProvider(create: (_) => ExamProvider()),
ChangeNotifierProvider(create: (_) => ProgressProvider()),
ChangeNotifierProvider(create: (_) => NotificationProvider()),
```

### For Database Integration
1. Create database layer (sqflite)
2. Modify MockAuthRepository to read/write to database
3. All dependent code continues to work unchanged

---

## Quick Reference Commands

```bash
# Run app
flutter run

# Run with analysis
flutter run && flutter analyze

# Test login flow
# 1. Open app
# 2. Wait for splash
# 3. Enter credentials from test accounts above
# 4. Verify navigation

# Check hot reload
# Press 'r' in terminal after code change

# Stop app
# Press 'q' in terminal

# Full rebuild if needed
flutter clean
flutter pub get
flutter run
```

---

## Documentation Files Location

1. **AUTHENTICATION_MVP_GUIDE.md**
   - Comprehensive technical guide
   - Architecture diagrams
   - Integration examples

2. **AUTHENTICATION_TEST_CHECKLIST.md**
   - 20 test scenarios
   - Step-by-step instructions
   - Debugging tips

3. **AUTHENTICATION_MVP_SUMMARY.md**
   - Executive summary
   - Feature overview
   - Next steps

4. **AUTHENTICATION_DELIVERY_OUTPUT.md**
   - Delivery checklist
   - Quick test guide
   - Project statistics

5. **This File** (CODE_REFERENCE.md)
   - Code structure reference
   - File locations
   - Key components

---

## Status: ✅ Ready for Testing

All files created and integrated. Ready for:
- Manual QA testing
- Integration with dashboard screens
- Future API migration
