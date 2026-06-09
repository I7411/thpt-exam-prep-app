# Hướng dẫn Sửa lỗi Firebase CONFIGURATION_NOT_FOUND

Lỗi `An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]` hoặc các lỗi liên quan đến Firebase Authentication thường xảy ra khi dự án chưa được cấu hình đúng trên Firebase Console hoặc bị sai lệch thông tin kết nối giữa app và Firebase.

Dưới đây là các bước bắt buộc phải thực hiện trên **Firebase Console** để sửa triệt để lỗi này.

## Bước 1: Kiểm tra Package Name (Application ID)
1. Mở file `android/app/build.gradle.kts`.
2. Tìm dòng `applicationId = "com.example.thpt_exam_prep_app"`.
3. Đảm bảo tên package này **trùng khớp hoàn toàn** với package name bạn đã đăng ký cho ứng dụng Android trên Firebase Console.

## Bước 2: Tải và cập nhật google-services.json
1. Vào [Firebase Console](https://console.firebase.google.com/).
2. Chọn dự án "THPT Smart Learn" của bạn.
3. Nhấp vào biểu tượng ⚙️ (Project settings).
4. Kéo xuống phần **Your apps**, chọn ứng dụng Android.
5. Tải file `google-services.json`.
6. Đặt file này vào đúng đường dẫn: `android/app/google-services.json` trong project của bạn. (Thay thế file cũ nếu có).

## Bước 3: Cập nhật cấu hình FlutterFire
Để đảm bảo code Dart nhận đúng thông tin cấu hình từ Firebase:
1. Mở terminal tại thư mục gốc của project (cùng cấp với `pubspec.yaml`).
2. Chạy lệnh:
   ```bash
   flutterfire configure
   ```
3. Chọn project Firebase tương ứng và các nền tảng bạn muốn hỗ trợ (bắt buộc chọn Android).
4. Lệnh này sẽ tự động sinh/cập nhật file `lib/firebase_options.dart`.

## Bước 4: Bật Email/Password Authentication (QUAN TRỌNG NHẤT)
Lỗi `CONFIGURATION_NOT_FOUND` thường xuyên do nguyên nhân này:
1. Vào Firebase Console, chọn mục **Authentication** (ở menu bên trái).
2. Chuyển sang tab **Sign-in method**.
3. Nhấn **Add new provider** và chọn **Email/Password**.
4. Bật công tắc **Enable** cho "Email/Password" (không cần bật Email link/Passwordless).
5. Nhấn **Save**.

## Bước 5: Bật Cloud Firestore
1. Vào Firebase Console, chọn mục **Firestore Database**.
2. Nhấn **Create database**.
3. Chọn vị trí (Location) gần bạn nhất (ví dụ: `asia-southeast1`).
4. Khởi tạo ở **Test mode** (để dễ test ban đầu, sau này cấu hình rules sau).

## Bước 6: Tạo Demo Accounts
Ứng dụng có các nút đăng nhập nhanh với tài khoản Demo. Bạn phải tự tạo các tài khoản này trên Firebase Auth để chúng hoạt động:
1. Trong màn hình **Authentication**, chuyển sang tab **Users**.
2. Nhấn **Add user** và tạo lần lượt 3 tài khoản với mật khẩu là `123456`:
   - `student.demo@thptsmartlearn.vn`
   - `teacher.demo@thptsmartlearn.vn`
   - `admin.demo@thptsmartlearn.vn`
*(Lưu ý: Nếu không tạo, khi bấm nút Demo trên app, bạn sẽ nhận được thông báo "Tài khoản demo chưa tồn tại...").*

## Bước 7: Làm sạch và chạy lại ứng dụng
Sau khi thực hiện xong tất cả các bước trên, hãy chạy các lệnh sau để đảm bảo ứng dụng được build lại với cấu hình mới nhất:
```bash
flutter clean
flutter pub get
flutter analyze
flutter run
```

Chúc bạn thành công!
