# Authentication MVP - Quick Test Checklist

## Demo Accounts
Copy-paste these credentials for quick testing:

### Student
```
Email: student@example.com
Password: 123456
Expected Navigation: /student/home
```

### Teacher
```
Email: teacher@example.com
Password: 123456
Expected Navigation: /teacher/dashboard
```

### Admin
```
Email: admin@example.com
Password: 123456
Expected Navigation: /admin/dashboard
```

---

## Test Scenarios

### ✅ Scenario 1: Fresh Start (First Time User)
- [ ] Open app
- [ ] Splash screen shows for ~2 seconds
- [ ] Redirects to LoginScreen
- [ ] No error messages visible
- [ ] Demo accounts displayed in info box

### ✅ Scenario 2: Student Login
- [ ] Enter: `student@example.com` / `123456`
- [ ] Click "Đăng nhập"
- [ ] Loading spinner appears
- [ ] After ~0.5s delay, navigates to `/student/home`
- [ ] Can verify session saved in SharedPreferences

### ✅ Scenario 3: Teacher Login
- [ ] Enter: `teacher@example.com` / `123456`
- [ ] Click "Đăng nhập"
- [ ] Navigates to `/teacher/dashboard`
- [ ] Different dashboard than student (role-based)

### ✅ Scenario 4: Admin Login
- [ ] Enter: `admin@example.com` / `123456`
- [ ] Click "Đăng nhập"
- [ ] Navigates to `/admin/dashboard`
- [ ] Admin-specific UI elements

### ✅ Scenario 5: Wrong Password
- [ ] Enter: `student@example.com` / `wrongpass`
- [ ] Click "Đăng nhập"
- [ ] Error message: "Email hoặc mật khẩu không đúng"
- [ ] No navigation occurs
- [ ] User can retry

### ✅ Scenario 6: Wrong Email
- [ ] Enter: `wrongemail@example.com` / `123456`
- [ ] Click "Đăng nhập"
- [ ] Error message: "Email hoặc mật khẩu không đúng"
- [ ] No navigation occurs

### ✅ Scenario 7: Invalid Email Format
- [ ] Enter: `invalid-email` / `123456`
- [ ] Click "Đăng nhập"
- [ ] Error message: "Email không hợp lệ"
- [ ] No network delay (immediate validation)

### ✅ Scenario 8: Empty Password
- [ ] Enter: `student@example.com` / `` (empty)
- [ ] Click "Đăng nhập"
- [ ] Error message: "Vui lòng nhập mật khẩu"
- [ ] No network delay

### ✅ Scenario 9: Password Visibility Toggle
- [ ] Enter password in field
- [ ] Initial state: dots/asterisks (hidden)
- [ ] Click eye icon → password shows as text
- [ ] Click eye icon → password hides again

### ✅ Scenario 10: Session Restoration
- [ ] Login as student
- [ ] Close app (properly, not crash)
- [ ] Reopen app
- [ ] Should SKIP splash and login, go directly to `/student/home`
- [ ] User info should be available

### ✅ Scenario 11: Forgot Password Link
- [ ] Click "Quên mật khẩu?" link
- [ ] Should navigate to `/forgot-password` (PlaceholderScreen for now)
- [ ] Should be able to go back to login

### ✅ Scenario 12: Register Link
- [ ] Click "Đăng ký ngay" link
- [ ] Should navigate to RegisterScreen
- [ ] Should show registration form

### ✅ Scenario 13: Register New Student
- [ ] Fill in:
  - [ ] Họ tên: `Trần Thị B`
  - [ ] Email: `trainb@example.com`
  - [ ] Vai trò: Select "Học sinh"
  - [ ] Mật khẩu: `password123`
  - [ ] Xác nhận: `password123`
- [ ] Click "Đăng ký"
- [ ] Should auto-login and navigate to `/student/home`

### ✅ Scenario 14: Register with Non-Matching Passwords
- [ ] Fill passwords:
  - [ ] Mật khẩu: `password123`
  - [ ] Xác nhận: `different456`
- [ ] Click "Đăng ký"
- [ ] Error: "Mật khẩu xác nhận không khớp"

### ✅ Scenario 15: Register with Short Password
- [ ] Mật khẩu: `123`
- [ ] Click "Đăng ký"
- [ ] Error: "Mật khẩu phải có ít nhất 6 ký tự"

### ✅ Scenario 16: Multiple Login Attempts
- [ ] Wrong password 3 times
- [ ] Each attempt shows error message
- [ ] Can still type new credentials and retry
- [ ] After successful login, error clears

### ✅ Scenario 17: Clear Error Messages
- [ ] Login with wrong password
- [ ] Error message shows
- [ ] Start typing in email field
- [ ] Error should persist (no auto-clear during input)
- [ ] After successful next attempt or manual clear, error disappears

### ✅ Scenario 18: Logout (when implemented)
- [ ] [After dashboard screens are built]
- [ ] Click logout button
- [ ] Should return to LoginScreen
- [ ] SharedPreferences should be cleared
- [ ] Next fresh launch should show splash→login again

### ✅ Scenario 19: Network Simulation
- [ ] Login as student
- [ ] Loading indicator appears (circles for ~0.5s)
- [ ] Simulates network delay (production-like behavior)
- [ ] Should NOT be instant navigation

### ✅ Scenario 20: UI Responsiveness
- [ ] Input fields are enabled during login
- [ ] After clicking login, button/fields become disabled
- [ ] Can't double-click to trigger multiple requests
- [ ] After response, fields re-enable

---

## Environment Setup Commands

```bash
# Run with API URL defined (for later API integration testing)
flutter run --dart-define=API_BASE_URL=https://api.example.com

# Or without define (uses default from AppConfig)
flutter run

# For testing on device
flutter run -d device_id

# Clean rebuild if needed
flutter clean
flutter pub get
flutter run
```

---

## Debugging Tips

### Check SharedPreferences content
```dart
// In a test screen:
final prefs = await SharedPreferences.getInstance();
print('User ID: ${prefs.getString('userId')}');
print('User Role: ${prefs.getString('userRole')}');
print('User Email: ${prefs.getString('userEmail')}');
print('User Name: ${prefs.getString('userName')}');
```

### Check AuthProvider state
```dart
final auth = context.watch<AuthProvider>();
print('Is Authenticated: ${auth.isAuthenticated}');
print('Current User: ${auth.currentUser?.email}');
print('Is Loading: ${auth.isLoading}');
print('Error: ${auth.errorMessage}');
```

### Check Repository
```dart
final user = await RepositoryService.getInstance().auth.login(
  'student@example.com',
  '123456',
);
print('User returned: ${user?.fullName}');
```

---

## Expected Test Duration
- Full test suite: ~5-10 minutes
- Quick smoke test: ~2 minutes
- Each scenario: ~30 seconds

---

## Sign-off Checklist

- [ ] All 20 scenarios pass
- [ ] No console errors or warnings
- [ ] No UI rendering issues
- [ ] Navigation works correctly for all roles
- [ ] Session persistence works
- [ ] Error messages display correctly
- [ ] Loading states appear and disappear
- [ ] Password field obscuring works
- [ ] Can navigate between login/register
- [ ] Ready for student dashboard implementation

---

## Notes
- Accounts persist across sessions via SharedPreferences
- New registrations are stored in MockAuthRepository (memory-based)
- Mock data includes realistic Vietnamese names and schools
- All error messages are in Vietnamese
- Email validation uses simple regex (not RFC-compliant, but sufficient for MVP)
