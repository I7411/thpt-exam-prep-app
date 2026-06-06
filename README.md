# THPT Smart Learn

`thpt_exam_prep_app` là project Flutter phục vụ ôn thi tốt nghiệp THPT cho học sinh lớp 12. Ứng dụng hỗ trợ học theo môn, đọc tài liệu, luyện đề thi thử, theo dõi tiến độ học tập, nhận thông báo và cung cấp các luồng riêng cho học sinh, giáo viên, quản trị viên.

## 1. Giới thiệu

THPT Smart Learn là ứng dụng di động giúp học sinh lớp 12 hệ thống hóa kiến thức, luyện tập với đề thi thử và theo dõi quá trình ôn thi trước kỳ thi tốt nghiệp THPT.

Project hiện đang ở trạng thái MVP offline-first: dữ liệu nghiệp vụ chính được lấy từ mock repositories, trong khi codebase đã có sẵn nền tảng cấu hình, routing, state management, local persistence, thông báo nội bộ và lớp API service để chuẩn bị tích hợp backend thật.

Nhóm người dùng chính:

- Học sinh: xem môn học, đọc tài liệu, làm bài thi thử, xem tiến độ, nhận thông báo, quản lý hồ sơ.
- Giáo viên: xem dashboard, quản lý lớp, xem học sinh, xem ngân hàng câu hỏi, lịch giảng dạy.
- Quản trị viên: xem tổng quan hệ thống, quản lý người dùng, tài liệu, đề thi/câu hỏi và báo cáo.

## 2. Công nghệ sử dụng

- Flutter SDK với Material Design.
- Dart SDK `^3.10.7`.
- `provider`: quản lý state bằng `ChangeNotifier`.
- `shared_preferences`: lưu phiên đăng nhập.
- `sqflite`, `path`, `path_provider`: local database, lịch sử làm bài và tiến độ.
- `http`: nền tảng gọi REST API.
- `flutter_local_notifications`, `timezone`, `flutter_timezone`: thông báo cục bộ.
- `intl`: định dạng ngày, số và nội dung hiển thị.
- `flutter_lints`: lint rule cho Flutter/Dart.

Cấu hình quan trọng trong `pubspec.yaml`:

```yaml
name: thpt_exam_prep_app
description: THPT Exam Prep App - A Flutter mobile app for Grade 12 students to prepare for the Vietnamese THPT graduation exam.
version: 1.0.0+1
environment:
  sdk: ^3.10.7
```

## 3. Tính năng chính

- Splash screen, đăng nhập, đăng ký, quên mật khẩu, khôi phục session và đăng xuất.
- Điều hướng theo vai trò: học sinh, giáo viên, quản trị viên.
- Tài khoản demo cho cả 3 vai trò.
- Dashboard học sinh với thống kê học tập, môn học, đề thi gợi ý và tài liệu mới.
- Danh sách môn học THPT kèm tiến độ.
- Danh sách tài liệu có lọc theo môn, đánh dấu/bookmark và xem chi tiết.
- Luồng thi thử: danh sách đề, làm bài, chọn đáp án, nộp bài, xem kết quả và review đáp án.
- Màn hình tiến độ học tập, lịch sử làm bài, môn mạnh/yếu.
- Màn hình thông báo và notification service.
- Hồ sơ học sinh với cài đặt demo và logout.
- Màn hình giáo viên: dashboard, lớp học, chi tiết lớp, ngân hàng câu hỏi, lịch dạy, hồ sơ.
- Màn hình admin: dashboard, quản lý người dùng, tài liệu, đề thi/câu hỏi, báo cáo.
- Repository layer offline-first với mock data.
- API service scaffold để chuyển sang backend thật.
- SQLite local persistence cho exam attempts, answers và progress stats.

## 4. Cấu trúc thư mục

Code hiện tại có cả các file Flutter ở root-level `lib/` từ các phase trước và các thư mục module mới hơn.

```text
lib/
  main.dart                         Entry point, khởi tạo notification và MultiProvider
  app.dart                          App widget chính, theme, navigator, route dispatcher
  app_config.dart                   Export tới core/config/app_config.dart
  app_routes.dart                   Hằng số route
  app_theme.dart                    Material theme
  app_constants.dart                Hằng số app, role, mock account
  app_navigation.dart               Global navigator key
  models*.dart                      Data models và file export models.dart
  mock_*.dart                       Mock data offline
  repo_*.dart                       Repository interfaces và mock implementations
  repository_service.dart           Service locator cho repositories
  providers_auth.dart               AuthProvider
  screens_new_*.dart                Auth screens và student phase-1 screens
  widgets_*.dart                    Widget tái sử dụng cho màn hình học sinh

  core/
    config/app_config.dart          App config, API_BASE_URL qua dart-define

  data/
    local/app_database.dart         SQLite database và local repository
    local/notification_service.dart Local notification setup
    remote/api_service.dart         HTTP client wrapper

  providers/
    admin_provider.dart
    exam_provider.dart
    notification_provider.dart
    progress_provider.dart
    teacher_provider.dart

  screens/
    admin/                          Admin dashboard và management screens
    exam/                           Exam list, taking, result screens
    notification/                   Notification screen
    profile/                        Student profile
    progress/                       Learning progress
    teacher/                        Teacher dashboard, classes, question bank, schedule
```

Các thư mục `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` là platform target chuẩn của Flutter.

## 5. Kiến trúc hệ thống

Project đang đi theo kiến trúc phân lớp cho MVP:

```text
UI Screens
  -> Providers / ChangeNotifier
    -> RepositoryService
      -> Repository interfaces
        -> Mock repositories / API repositories trong tương lai
          -> Mock data, SQLite hoặc remote API
```

Các điểm chính:

- `main.dart` khởi tạo Flutter bindings, notification service và `MultiProvider`.
- `ThptSmartLearnApp` trong `app.dart` cấu hình theme, navigator key, initial route và `onGenerateRoute`.
- `AppRoutes` gom route cho auth, student, teacher và admin.
- Providers giữ state màn hình và gọi repositories.
- Repositories trả về dữ liệu typed async, hiện dùng mock implementations.
- `RepositoryService` là singleton service locator để UI không phụ thuộc trực tiếp vào implementation cụ thể.
- `ApiService` đã có wrapper cho `GET`, `POST`, `PUT`, `DELETE`, JSON parsing, timeout và API exception.
- `AppLocalRepository` lưu lịch sử làm bài và progress vào SQLite.

## 6. Data Models

Import trung tâm:

```dart
import 'package:thpt_exam_prep_app/models.dart';
```

Các model chính:

- `UserRole`: enum vai trò `student`, `teacher`, `admin`.
- `AppUser`: thông tin tài khoản và hồ sơ người dùng.
- `Subject`: môn học THPT.
- `Topic`: chủ đề trong môn học.
- `StudyDocument`: tài liệu học tập, mô tả, thời lượng đọc, tác giả, lượt xem/rating.
- `Exam`: đề thi hoặc đề thi thử, thời lượng, điểm, trạng thái publish.
- `Question`: câu hỏi, nội dung, giải thích, thứ tự, điểm và danh sách đáp án.
- `AnswerOption`: lựa chọn trắc nghiệm.
- `ExamAttempt`: phiên làm bài của học sinh.
- `ExamAnswer`: đáp án đã chọn và trạng thái đúng/sai.
- `ProgressStat`: thống kê tiến độ học theo học sinh và môn.
- `NotificationItem`: thông báo cho người dùng.
- `NotificationType`: loại thông báo.
- `TeacherClass`: lớp học do giáo viên phụ trách.
- `AdminReportStat`: số liệu tổng quan cho admin.

Các model được thiết kế theo hướng null-safe, có JSON serialization, `copyWith`, `toString` và một số helper method tính toán.

## 7. Repository Layer

Repository layer nằm trong các file `lib/repo_*.dart` và được truy cập qua `RepositoryService`.

Repositories hiện có:

- `AuthRepository`: login, register, current user, logout, trạng thái đăng nhập.
- `SubjectRepository`: danh sách môn học và CRUD.
- `DocumentRepository`: danh sách tài liệu, lọc theo môn/chủ đề và CRUD.
- `ExamRepository`: danh sách đề thi, câu hỏi và CRUD.
- `ProgressRepository`: tiến độ học sinh, điểm trung bình, số đề đã làm, số đề đạt.
- `NotificationRepository`: danh sách thông báo, unread count, mark read, create/delete.
- `TeacherRepository`: lớp học và attempt của học sinh theo giáo viên.
- `AdminRepository`: báo cáo hệ thống, người dùng, đề thi và tài liệu.

Ví dụ sử dụng:

```dart
final repos = RepositoryService.getInstance();

final user = await repos.auth.login('student@example.com', '123456');
final subjects = await repos.subject.getAllSubjects();
final exams = await repos.exam.getAllExams();
final notifications = await repos.notification.getNotificationsByUser('student_001');
```

Mock data hiện có: 9 môn học, 8 tài liệu, 5 đề thi, 25 câu hỏi, progress records, notifications, teacher classes và admin report stats.

## 8. Authentication Module

File chính:

- `lib/providers_auth.dart`
- `lib/screens_new_splash.dart`
- `lib/screens_new_login.dart`
- `lib/screens_new_register.dart`
- `lib/screens_new_forgot_password.dart`
- `lib/repo_auth.dart`

Chức năng đã triển khai:

- Splash screen khôi phục session từ `SharedPreferences`.
- Login validate email/password, gọi `AuthRepository`, lưu session và điều hướng theo role.
- Register validate họ tên, email, role, password, confirm password và auto-login sau khi đăng ký.
- Forgot password mô phỏng luồng gửi email reset.
- Logout xóa session đã lưu.
- Điều hướng theo role:
  - Student: `/student/home`
  - Teacher: `/teacher/dashboard`
  - Admin: `/admin/dashboard`

Tài khoản demo đang hoạt động theo `MockAuthRepository`:

| Vai trò | Email | Mật khẩu |
| --- | --- | --- |
| Student | `student@example.com` | `123456` |
| Teacher | `teacher@example.com` hoặc `teacher@gmail.com` | `123456` |
| Admin | `admin@example.com` hoặc `admin@gmail.com` | `123456` |

## 9. Student Screens / Main Screens

Màn hình học sinh:

- `StudentMainScreen`: shell điều hướng bằng BottomNavigationBar.
- `StudentHomeScreen`: lời chào, thống kê học tập, môn học, đề thi gợi ý, tài liệu mới.
- `SubjectListScreen`: grid môn học với icon, màu và progress.
- `DocumentListScreen`: danh sách tài liệu, filter chip theo môn, bookmark.
- `DocumentDetailScreen`: metadata, tóm tắt, mục tiêu học tập, topic liên quan, đánh dấu đã học.
- `ExamListScreen`: danh sách đề thi và lọc theo môn.
- `ExamTakingScreen`: làm bài, chọn đáp án, chuyển câu, nộp bài.
- `ExamResultScreen`: điểm, trạng thái đạt/chưa đạt, thống kê và review đáp án.
- `ProgressScreen`: tổng quan tiến độ, tiến độ theo môn, lịch sử làm bài.
- `NotificationScreen`: danh sách thông báo.
- `StudentProfileScreen`: hồ sơ, cài đặt demo và logout.

Màn hình giáo viên:

- Dashboard, danh sách lớp, chi tiết lớp, ngân hàng câu hỏi, lịch giảng dạy, hồ sơ.

Màn hình admin:

- Dashboard, quản lý người dùng, quản lý tài liệu, quản lý đề thi/câu hỏi, báo cáo.

## 10. Cài đặt project

1. Cài Flutter SDK.

   Kiểm tra Flutter đã sẵn sàng:

   ```bash
   flutter doctor
   ```

2. Clone hoặc mở project.

   ```bash
   cd c:\LTDD_K6\thpt_exam_prep_app
   ```

3. Cài dependency.

   ```bash
   flutter pub get
   ```

4. Kiểm tra thiết bị.

   ```bash
   flutter devices
   ```

5. Chạy project.

   ```bash
   flutter run
   ```

6. Chạy với API URL tùy chỉnh nếu cần.

   ```bash
   flutter run --dart-define=API_BASE_URL=https://api.example.com
   ```

## 11. Lệnh chạy nhanh

```bash
flutter clean
flutter pub get
flutter analyze
flutter run
```

Chạy trên thiết bị cụ thể:

```bash
flutter devices
flutter run -d <device-id>
```

Chạy với backend URL:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

## 12. Build Android / iOS

Build Android APK:

```bash
flutter build apk --release
```

Build Android App Bundle:

```bash
flutter build appbundle --release
```

Build Android với API URL:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

Build iOS:

```bash
flutter build ios --release
```

Lưu ý: build iOS cần macOS, Xcode và cấu hình signing hợp lệ.

## 13. Cấu hình pubspec.yaml và AppConfig quan trọng

Cấu hình runtime nằm ở `lib/core/config/app_config.dart`:

```dart
static const String appName = 'THPT Smart Learn';
static const String appVersion = '1.0.0';
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.10:5130/api',
);
static const int apiTimeout = 30;
static const bool enableMockData = true;
```

Ghi nhớ:

- Không hard-code backend URL trong widget hoặc repository.
- Dùng `AppConfig.apiBaseUrl`.
- Truyền backend URL qua `--dart-define=API_BASE_URL=...`.
- MVP hiện đang dùng mock data.
- `ApiService` đã sẵn sàng cho remote repository trong tương lai.
- SQLite hiện lưu exam attempts, exam answers và progress stats.

## 14. Checklist trạng thái hoàn thành

Trạng thái tổng hợp hiện tại:

- Project setup và chuẩn hóa dependency: hoàn thành.
- Core infrastructure: hoàn thành.
- Theme, routes, app config, navigation shell: hoàn thành.
- Data models: hoàn thành.
- Mock data và repository layer: hoàn thành.
- Authentication MVP: hoàn thành.
- Authentication screens: hoàn thành.
- Student screens phase 1: hoàn thành.
- Exam, progress, notification, teacher và admin screens: đã có trong source.
- Backend API integration: đã có scaffold, chưa thay thế toàn bộ mock repositories.
- Automated tests và production deployment: cần bổ sung thêm.

Checklist kiểm tra nhanh:

- Chạy `flutter pub get`.
- Chạy `flutter analyze`.
- Chạy app bằng `flutter run`.
- Test login student/teacher/admin demo.
- Test lọc tài liệu và xem chi tiết tài liệu.
- Test danh sách đề thi, làm bài và kết quả.
- Test progress và notification screens.

## 15. Ghi chú kỹ thuật quan trọng và hướng phát triển tiếp theo

Ghi chú kỹ thuật:

- Credential đang hoạt động nằm trong `MockAuthRepository` ở `lib/repo_auth.dart`.
- `AppConstants.mockStudentAccount` vẫn có mật khẩu cũ `student123`, trong khi login thực tế dùng `123456`. Nên đồng bộ trước khi dùng lại constant này.
- `AppConfig.dbName` là `thpt_smart_learn.db`, còn `AppDatabase` đang mở `thpt_exam_prep_app.db`. Nên chọn một tên database thống nhất trước production.
- Một số file cũ vẫn nằm trực tiếp trong `lib/` song song với thư mục module mới. Nên chuẩn hóa lại cấu trúc sau khi ổn định feature.
- Các file Markdown cũ trong thư mục gốc chủ yếu là delivery report, guide, summary và checklist theo từng phase. README này là bản tổng hợp để dùng làm tài liệu onboarding chính.

Hướng phát triển tiếp theo:

- Thay mock repositories bằng API repositories.
- Bổ sung auth token, refresh token và xử lý session bảo mật hơn.
- Đồng bộ constants, database name và cấu trúc thư mục.
- Thêm unit test cho models, repositories, providers và auth flow.
- Thêm widget test cho auth, student document, exam và progress screens.
- Thêm integration test cho điều hướng theo role.
- Hoàn thiện empty/loading/error states cho teacher và admin workflows.
- Chuẩn bị signing, release config và tài liệu triển khai production.
