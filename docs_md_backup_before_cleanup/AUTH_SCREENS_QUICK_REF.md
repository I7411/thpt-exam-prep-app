# 🚀 Auth Screens - Quick Reference

## Files Created

```
✅ lib/screens_new_splash.dart
✅ lib/screens_new_login.dart  
✅ lib/screens_new_register.dart
✅ lib/screens_new_forgot_password.dart
```

## Updated

```
✅ lib/app.dart (route imports + forgot password handler)
```

---

## Quick Test Commands

```bash
# Clean and prepare
flutter clean && flutter pub get

# Run app
flutter run

# Expected flow:
# Splash (3s) → LoginScreen
# Try: student@example.com / 123456
# Or click: 📚 Học sinh Demo button
```

---

## Demo Accounts

```
📚 student@example.com / 123456    → /student/home
👨‍🏫 teacher@example.com / 123456    → /teacher/dashboard
🔐 admin@example.com / 123456      → /admin/dashboard
```

---

## Features at a Glance

### SplashScreen
- 3-second animation
- Auto-session restore
- Role-based navigation

### LoginScreen
- Email/password validation
- 3 quick demo buttons
- Password visibility toggle
- Forgot password link
- Register link

### RegisterScreen
- Full name, email, role selection
- Password confirmation
- Auto-login after registration
- All validations

### ForgotPasswordScreen
- Email reset request
- Simulated 2-second processing
- Success state with SnackBar
- Auto-navigate after success

---

## Validation Rules

```
✓ Email: required + valid format
✓ Password: required + min 6 chars
✓ Name: required + min 3 chars
✓ Confirm: must match password
✓ Role: must select one
```

---

## Error Handling

```
✓ No crashes on invalid input
✓ Clear Vietnamese error messages
✓ Form validation on submit
✓ Server error simulation
✓ Dismissible error boxes
```

---

## Test Scenarios (20 total)

```
✅ 1. Fresh launch
✅ 2-4. Quick demo buttons (3 roles)
✅ 5-8. Manual login + validation
✅ 9-11. Registration + validation
✅ 12-13. Forgot password
✅ 14-15. Session + UI responsiveness
✅ 16-20. Edge cases + no crashes
```

---

## Buttons & Navigation

### LoginScreen
```
📚 Học sinh Demo    → Quick login as student
👨‍🏫 Giáo viên Demo   → Quick login as teacher
🔐 Admin Demo       → Quick login as admin
Quên mật khẩu?     → ForgotPasswordScreen
Đăng ký ngay      → RegisterScreen
Đăng nhập         → Login action
```

### RegisterScreen
```
Vai trò dropdown    → Student/Teacher/Admin
Đăng ký            → Register action
Đăng nhập          → Back to LoginScreen
```

### ForgotPasswordScreen
```
Gửi hướng dẫn      → Send reset email
Quay lại đăng nhập → Back to LoginScreen
```

---

## UI Components

```
✓ School icon (circular logo)
✓ Rounded input fields (12dp)
✓ Visibility toggle (eye icon)
✓ Loading spinners
✓ Error boxes (red)
✓ Success boxes (green)
✓ Info boxes (blue)
✓ Demo buttons (outlined)
✓ Primary buttons (elevated)
```

---

## States

```
Loading:   Disabled inputs, spinner in button
Success:   Navigate to dashboard
Error:     Red error box, retry possible
Session:   Auto-restore on app start
```

---

## Next Steps

1. ✅ Run and test all auth screens
2. ⏳ Build student dashboard
3. ⏳ Build teacher dashboard
4. ⏳ Build admin dashboard
5. ⏳ Integrate real API (if needed)

---

**Status**: 🎉 Complete and Ready!
**Test**: `flutter run` → Try demo accounts
