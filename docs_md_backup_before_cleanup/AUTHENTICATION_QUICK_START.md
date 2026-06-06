# 🚀 Authentication MVP - Quick Start Guide

## 1️⃣ Để Chạy Ứng Dụng

```bash
cd c:\LTDD_K6\thpt_exam_prep_app

# Chuẩn bị
flutter clean
flutter pub get

# Chạy ứng dụng
flutter run

# Kiểm tra lỗi (optional)
flutter analyze
```

## 2️⃣ Thử Đăng Nhập Ngay

### Demo Account 1: Học Sinh 📚
```
Email: student@example.com
Password: 123456

→ Sẽ vào trang: /student/home
```

### Demo Account 2: Giáo Viên 👨‍🏫
```
Email: teacher@example.com
Password: 123456

→ Sẽ vào trang: /teacher/dashboard
```

### Demo Account 3: Quản Trị 🔐
```
Email: admin@example.com
Password: 123456

→ Sẽ vào trang: /admin/dashboard
```

---

## 3️⃣ Quy Trình Làm Việc

### Khi Mở App Lần Đầu
```
Splash Screen (2 giây)
    ↓
Kiểm tra session đã lưu?
    ├─ CÓ → Vào dashboard
    └─ KHÔNG → Vào LoginScreen
```

### Đăng Nhập
```
Nhập email & password
    ↓
Kích nút "Đăng nhập"
    ↓
Kiểm tra thông tin (0.5 giây delay)
    ├─ Đúng → Lưu vào SharedPreferences → Vào dashboard
    └─ Sai → Hiện thông báo lỗi
```

### Lần Sau Mở App
```
Splash Screen sẽ tự động:
    ↓
Đọc SharedPreferences
    ↓
Tìm thấy session?
    ├─ CÓ → Vào dashboard (không cần đăng nhập)
    └─ KHÔNG → Vào LoginScreen
```

---

## 4️⃣ Kiểm Tra Nhanh (5 phút)

### Test 1: Student Login
1. Mở app → Splash screen
2. Đợi 2 giây
3. Nhập: `student@example.com` / `123456`
4. Kết quả: ✅ Vào `/student/home`

### Test 2: Teacher Login
1. Quay lại login screen
2. Nhập: `teacher@example.com` / `123456`
3. Kết quả: ✅ Vào `/teacher/dashboard`

### Test 3: Admin Login
1. Quay lại login screen
2. Nhập: `admin@example.com` / `123456`
3. Kết quả: ✅ Vào `/admin/dashboard`

### Test 4: Session Lưu
1. Đăng nhập thành công
2. Đóng app
3. Mở app lại
4. Kết quả: ✅ Nhảy vào dashboard (không cần đăng nhập)

---

## 5️⃣ Thử Các Tình Huống Lỗi

| Scenario | Nhập | Kết Quả |
|----------|------|---------|
| **Email sai** | `wrong@example.com` / `123456` | ❌ "Email hoặc mật khẩu không đúng" |
| **Password sai** | `student@example.com` / `wrong` | ❌ "Email hoặc mật khẩu không đúng" |
| **Email không hợp lệ** | `invalid-email` / `123456` | ❌ "Email không hợp lệ" |
| **Password quá ngắn** | `student@example.com` / `123` | ❌ (trong Register) "Mật khẩu phải có ít nhất 6 ký tự" |

---

## 6️⃣ Tính Năng Chính

✅ **Đăng Nhập 3 Vai Trò**
- Học sinh → Dashboard riêng
- Giáo viên → Dashboard riêng  
- Quản trị → Dashboard riêng

✅ **Lưu Phiên Làm Việc**
- Tự động lưu vào SharedPreferences
- Khi mở app lại, không cần đăng nhập

✅ **Kiểm Tra Input**
- Email format đúng
- Password ≥ 6 ký tự
- Xác nhận password khớp
- Tên đầy đủ

✅ **Giao Diện Thân Thiện**
- Thông báo lỗi rõ ràng (tiếng Việt)
- Loading spinner khi đăng nhập
- Hiện/ẩn password
- Gợi ý tài khoản demo

---

## 7️⃣ File Tạo Mới (4 File)

```
lib/
├── providers_auth.dart          ← State management
├── screens_splash.dart          ← Màn hình khởi động
├── screens_login.dart           ← Màn hình đăng nhập
└── screens_register.dart        ← Màn hình đăng ký
```

## 📝 File Sửa Đổi (2 File)

```
lib/
├── main.dart                    ← Thêm MultiProvider
└── app.dart                     ← Update routes
```

---

## 📚 Tài Liệu Tham Khảo

| File | Nội Dung |
|------|---------|
| **AUTHENTICATION_MVP_GUIDE.md** | Chi tiết kỹ thuật |
| **AUTHENTICATION_TEST_CHECKLIST.md** | 20 test cases |
| **AUTHENTICATION_MVP_SUMMARY.md** | Tổng hợp |
| **AUTHENTICATION_CODE_REFERENCE.md** | Tham khảo code |

---

## 🔧 Troubleshooting

### ❌ App crashes on startup
```
Kiểm tra:
- pubspec.yaml có provider?
- pubspec.yaml có shared_preferences?
- flutter pub get đã chạy?
```

### ❌ Login button không hoạt động
```
Kiểm tra:
- MultiProvider có trong main.dart?
- AuthProvider import đúng?
- RepositoryService khởi tạo?
```

### ❌ Session không lưu
```
Kiểm tra:
- shared_preferences có trong pubspec.yaml?
- App đóng gracefully (không crash)?
- Quyền storage (Android)?
```

### ❌ Navigation sai
```
Kiểm tra:
- Routes định nghĩa trong app_routes.dart?
- Route handler cập nhật trong app.dart?
- Screen class extends StatelessWidget/StatefulWidget?
```

---

## ⌨️ Hot Reload

Sau khi thay đổi code:

```bash
# Terminal đang chạy app
r                   # Hot reload
R                   # Full restart
q                   # Quit
```

---

## 🎯 Tiến Độ Phát Triển

```
✅ Phase 1: Project Standardization
✅ Phase 2: Core Infrastructure  
✅ Phase 3: Data Models
✅ Phase 4: Mock Repositories
✅ Phase 5: Authentication MVP ← YOU ARE HERE

⏳ Phase 6: Student Dashboard
⏳ Phase 7: Teacher Dashboard
⏳ Phase 8: Admin Dashboard
⏳ Phase 9: Database Integration
⏳ Phase 10: API Integration
```

---

## 💡 Tips

### Copy-paste demo credentials
```
📚 student@example.com / 123456
👨‍🏫 teacher@example.com / 123456
🔐 admin@example.com / 123456
```

### Tắt debug banner
```dart
// Đã tắt trong app.dart
debugShowCheckedModeBanner: false
```

### Check session data
```dart
// Trong terminal hoặc debugger
final prefs = await SharedPreferences.getInstance();
print(prefs.getString('userId'));      // Should print user ID
print(prefs.getString('userRole'));    // Should print role
```

---

## 📞 Support

### Nếu cần help
1. Đọc **AUTHENTICATION_MVP_GUIDE.md** - chi tiết kỹ thuật
2. Xem **AUTHENTICATION_TEST_CHECKLIST.md** - test scenarios
3. Check **AUTHENTICATION_CODE_REFERENCE.md** - code structure

---

## ✨ Ready to Go!

```
flutter run
→ 2 seconds splash
→ LoginScreen
→ Nhập: student@example.com / 123456
→ ✅ Dashboard!
```

**Chúc mừng! 🎉 Authentication MVP đã sẵn sàng!**
