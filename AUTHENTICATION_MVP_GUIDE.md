# Authentication MVP - Implementation Guide

## Overview
This document describes the complete authentication MVP implementation for THPT Smart Learn app with mock accounts, session persistence, and role-based navigation.

## New Files Created

### 1. **lib/providers_auth.dart** (220 lines)
- **Purpose**: Central authentication provider extending ChangeNotifier
- **States**: currentUser, isLoading, errorMessage, isAuthenticated
- **Methods**:
  - `login(email, password)` - Authenticate user and save session
  - `register(email, password, confirmPassword, fullName, role)` - Create new account
  - `logout()` - Clear session and remove from shared_preferences
  - `restoreSession()` - Load saved session on app start
  - `clearError()` - Clear error message
- **Features**:
  - Email validation using regex
  - Password length validation (min 6 characters)
  - Saves userId, userRole, userEmail, userName to shared_preferences
  - Does NOT save password (security best practice)
  - Integrates with RepositoryService for mock data

### 2. **lib/screens_splash.dart** (63 lines)
- **Purpose**: Splash screen shown on app startup
- **Features**:
  - 2-second delay for initialization
  - Calls `authProvider.restoreSession()`
  - Auto-navigates to login if no session, or home if authenticated
  - Prevents navigation errors with `mounted` check

### 3. **lib/screens_login.dart** (280 lines)
- **Purpose**: Login screen for all 3 user roles
- **Features**:
  - Email/password input fields
  - Password visibility toggle
  - Clear error messages in UI
  - Forgot password link
  - Register link
  - Demo credentials box with copy-friendly format
  - Auto-navigation to dashboard based on user role
  - Loading state while authenticating

### 4. **lib/screens_register.dart** (325 lines)
- **Purpose**: User registration screen
- **Features**:
  - Full name, email, password, confirm password fields
  - Role selection dropdown (Student/Teacher/Admin)
  - All input validation
  - Password confirmation matching
  - Error display in UI
  - Auto-login after successful registration
  - Role-based navigation to dashboard

## Updated Files

### 1. **lib/main.dart**
```dart
// OLD: Direct app instantiation
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThptSmartLearnApp());
}

// NEW: MultiProvider with AuthProvider
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

### 2. **lib/app.dart**
- Added imports for new screen files:
  - `screens_splash.dart`
  - `screens_login.dart`
  - `screens_register.dart`
- Updated route handlers to use real screens instead of PlaceholderScreen:
  - `/splash` → SplashScreen
  - `/login` → LoginScreen
  - `/register` → RegisterScreen

## Mock Accounts (from lib/mock_progress.dart)

### Test Credentials
All accounts use password: `123456`

```
📚 STUDENT ACCOUNT
Email: student@example.com
Password: 123456
Role: UserRole.student
Name: Nguyễn Văn A
School: THPT Phan Bội Châu
Class: 12A1
Navigation: /student/home

👨‍🏫 TEACHER ACCOUNT
Email: teacher@example.com
Password: 123456
Role: UserRole.teacher
Name: Thầy Lê Văn B
School: THPT Phan Bội Châu
Classes: 12A1, 12A2
Navigation: /teacher/dashboard

🔐 ADMIN ACCOUNT
Email: admin@example.com
Password: 123456
Role: UserRole.admin
Name: Quản trị viên Hệ thống
Navigation: /admin/dashboard
```

## How It Works

### Authentication Flow

1. **App Startup**
   ```
   main() 
   → MultiProvider(AuthProvider) 
   → SplashScreen
   → SplashScreen.initState() calls authProvider.restoreSession()
   → If session exists → navigate to dashboard
   → If no session → navigate to LoginScreen
   ```

2. **Login Process**
   ```
   LoginScreen.login()
   → AuthProvider.login(email, password)
   → RepositoryService.getInstance().auth.login()
   → MockAuthRepository checks hardcoded credentials
   → If match: create AppUser, save to shared_preferences, set _isAuthenticated = true
   → If no match: return error message
   → NavigateTo based on user.role
   ```

3. **Registration Process**
   ```
   RegisterScreen.register()
   → AuthProvider.register()
   → RepositoryService.getInstance().auth.register()
   → MockAuthRepository creates new AppUser with unique ID
   → Save to shared_preferences
   → Auto-login and navigate to dashboard
   ```

4. **Session Restoration**
   ```
   SplashScreen.initState()
   → AuthProvider.restoreSession()
   → Read from shared_preferences: userId, userRole, userEmail, userName
   → Reconstruct AppUser object
   → Set _isAuthenticated = true
   → Remaining data (schoolName, className, etc.) uses defaults
   ```

5. **Logout Process**
   ```
   [Any screen with logout button]
   → AuthProvider.logout()
   → Clear all data from shared_preferences
   → Set _currentUser = null, _isAuthenticated = false
   → Navigate to LoginScreen
   ```

### Session Storage (shared_preferences)

Session is persisted as follows:
```
{
  "userId": "student_001",
  "userRole": "UserRole.student",
  "userEmail": "student@example.com",
  "userName": "Nguyễn Văn A"
}
```

**Why these 4 fields?**
- Minimal data to reconstruct AppUser
- userId: unique identifier
- userRole: determines navigation destination
- userEmail: display in profile/settings
- userName: display in UI

**Why NOT password?**
- Security best practice: never store passwords
- Passwords should only exist at login time
- Session-based auth uses tokens/IDs, not passwords

### Role-Based Navigation

After successful login, the app navigates based on user role:

```dart
if (user.role == UserRole.student) {
  nextRoute = AppRoutes.studentHome;  // /student/home
} else if (user.role == UserRole.teacher) {
  nextRoute = AppRoutes.teacherDashboard;  // /teacher/dashboard
} else if (user.role == UserRole.admin) {
  nextRoute = AppRoutes.adminDashboard;  // /admin/dashboard
}
Navigator.of(context).pushReplacementNamed(nextRoute);
```

## Error Messages

All error messages are in Vietnamese:

| Error | Message |
|-------|---------|
| Invalid email format | "Email không hợp lệ" |
| Empty password | "Vui lòng nhập mật khẩu" |
| Wrong credentials | "Email hoặc mật khẩu không đúng" |
| Password too short | "Mật khẩu phải có ít nhất 6 ký tự" |
| Passwords don't match | "Mật khẩu xác nhận không khớp" |
| Empty full name | "Vui lòng nhập họ tên" |
| Registration failed | "Đăng ký thất bại, vui lòng thử lại" |

## State Management Architecture

```
┌─────────────────────────────────────────┐
│  main.dart                              │
│  MultiProvider with AuthProvider        │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  SplashScreen                           │
│  - Restores session on app start        │
│  - Routes to login or dashboard         │
└─────────────────────────────────────────┘
                    ↓
        ┌───────────┴───────────┐
        ↓                       ↓
┌──────────────────┐  ┌──────────────────┐
│ LoginScreen      │  │ Dashboard        │
│ (auth required)  │  │ (authenticated)  │
│                  │  │                  │
│ Input: email,    │  │ Displays user    │
│ password         │  │ data from        │
│                  │  │ AuthProvider     │
│ Uses:            │  │                  │
│ AuthProvider     │  │ Uses:            │
│ .login()         │  │ AuthProvider     │
│                  │  │ .currentUser     │
└──────────────────┘  └──────────────────┘
        ↓                       ↑
        └───────────┬───────────┘
                    ↓
         (Navigate on role)
```

## Testing Guide

### 1. Test Student Login

1. Start the app → Splash screen shows
2. After 2 seconds → Login screen
3. Enter:
   - Email: `student@example.com`
   - Password: `123456`
4. Click "Đăng nhập"
5. Should see loading spinner
6. Should navigate to `/student/home` (PlaceholderScreen currently)
7. Check shared_preferences has session data

**Verify in code:**
```dart
// Can check if session saved:
final prefs = await SharedPreferences.getInstance();
final userId = prefs.getString('userId');  // Should be 'student_001'
final role = prefs.getString('userRole');  // Should be 'UserRole.student'
```

### 2. Test Teacher Login

1. Go back to login (or log out)
2. Enter:
   - Email: `teacher@example.com`
   - Password: `123456`
3. Should navigate to `/teacher/dashboard` (PlaceholderScreen currently)

### 3. Test Admin Login

1. Go back to login
2. Enter:
   - Email: `admin@example.com`
   - Password: `123456`
3. Should navigate to `/admin/dashboard` (PlaceholderScreen currently)

### 4. Test Error Handling

**Wrong password:**
- Email: `student@example.com`
- Password: `wrong`
- Result: "Email hoặc mật khẩu không đúng"

**Invalid email:**
- Email: `invalid-email`
- Password: `123456`
- Result: "Email không hợp lệ"

**Empty fields:**
- Email: `` (empty)
- Password: `123456`
- Result: "Email không hợp lệ"

### 5. Test Session Restoration

1. Login with student account
2. Close and reopen the app
3. Should skip splash and login, go directly to `/student/home`
4. User data should be available in AuthProvider.currentUser

### 6. Test Logout

1. [When logout button is implemented in dashboard]
2. Click logout
3. Should return to login screen
4. Session data should be cleared from shared_preferences

### 7. Test Registration

1. Click "Đăng ký ngay" on login screen
2. Fill in:
   - Họ tên: `Trần Thị B`
   - Email: `trainb@example.com`
   - Vai trò: `Học sinh`
   - Mật khẩu: `123456`
   - Xác nhận mật khẩu: `123456`
3. Click "Đăng ký"
4. Should auto-login and navigate to `/student/home`
5. New account should be stored in MockAuthRepository

## Integration with Existing Systems

### RepositoryService Integration
```dart
// AuthProvider uses this internally
final user = await RepositoryService.getInstance().auth.login(email, password);
```

### Existing Repositories Accessed
- `RepositoryService.getInstance().auth` - for login/register/logout
- All other repositories available for screens to use

### Later API Integration
To switch from mock to real API:

1. Create `ApiAuthRepository` implementing `AuthRepository`
2. In `RepositoryService._initializeRepositories()`:
   ```dart
   // Change this:
   _authRepo = MockAuthRepository();
   // To this:
   _authRepo = ApiAuthRepository();
   ```
3. No changes needed in AuthProvider, LoginScreen, or any other screens!

## File Structure Summary

```
lib/
├── main.dart                    (Updated with MultiProvider)
├── app.dart                     (Updated with screen imports)
├── app_routes.dart              (No changes)
├── app_theme.dart               (No changes)
├── app_config.dart              (No changes)
├── providers_auth.dart          (NEW)
├── screens_splash.dart          (NEW)
├── screens_login.dart           (NEW)
├── screens_register.dart        (NEW)
├── repository_service.dart      (No changes)
├── repo_auth.dart               (No changes, used by provider)
├── mock_progress.dart           (No changes, contains test accounts)
└── [other files...]
```

## Next Steps

1. ✅ Authentication MVP with 3 test accounts
2. ✅ Session persistence with shared_preferences
3. ✅ Error handling and validation
4. ⏳ Implement student dashboard (lib/screens_student_home.dart)
5. ⏳ Implement teacher dashboard (lib/screens_teacher_dashboard.dart)
6. ⏳ Implement admin dashboard (lib/screens_admin_dashboard.dart)
7. ⏳ Add forgot password screen
8. ⏳ Create other providers (SubjectProvider, ExamProvider, etc.)

## Troubleshooting

### Login button doesn't respond
- Check if AuthProvider is properly initialized in main.dart
- Verify RepositoryService is initialized

### Session not persisting
- Check if shared_preferences is in pubspec.yaml
- Make sure `flutter pub get` is run
- Check if app permissions include storage (Android)

### Navigation not working
- Verify routes are defined in app_routes.dart
- Check if route handlers in app.dart match route names
- Ensure screens extend StatefulWidget or StatelessWidget

### Error messages not showing
- Verify errorMessage getter in AuthProvider is correct
- Check if Consumer<AuthProvider> is wrapping UI
- Confirm notifyListeners() is called after setting errorMessage

## Code Quality

- ✅ All input validation (email, password, length checks)
- ✅ Error messages in Vietnamese for Vietnamese users
- ✅ Loading states while authenticating
- ✅ Session persistence for offline support
- ✅ No hardcoded URLs or API endpoints
- ✅ Null-safety compliance
- ✅ Clear separation of concerns (Provider → Repository → MockData)
- ✅ Security: passwords never stored locally
