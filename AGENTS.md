# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

**THPT Smart Learn** is a multi-role exam prep app for Vietnamese high school students (THPT = Tú tài Phổ Thông), built with Flutter. It supports three roles: student, teacher, and admin.

## Common Commands

```bash
flutter pub get          # Install/update dependencies
flutter run              # Run in debug mode
flutter analyze          # Static analysis (uses analysis_options.yaml)
flutter test             # Run all tests (only test/widget_test.dart currently)
flutter build apk        # Android release APK
flutter build web        # Web build
```

## Architecture

The app follows a **layered architecture**:

```
Screens (lib/screens/)
    ↓
Providers (lib/providers/) — ChangeNotifier + Provider 6.0
    ↓
Repositories (lib/repo_*.dart) — abstract interfaces with mock implementations
    ↓
Data Layer — ApiService (HTTP) + AppDatabase (SQLite) + SharedPreferences
```

### State Management

Uses `provider` package with `MultiProvider` + `ChangeNotifier`. All providers are initialized at app startup in [lib/main.dart](lib/main.dart):

- **AuthProvider** ([lib/providers_auth.dart](lib/providers_auth.dart)) — login/logout/session restore via SharedPreferences
- **ExamProvider** ([lib/providers/exam_provider.dart](lib/providers/exam_provider.dart)) — active exam session, timer, answer selection, history
- **ProgressProvider** ([lib/providers/progress_provider.dart](lib/providers/progress_provider.dart)) — per-subject learning stats
- **AdminProvider** / **TeacherProvider** / **NotificationProvider** — role-specific data

### Repository Pattern

All data access goes through abstract repository interfaces (e.g., `AuthRepository`, `ExamRepository`) defined in `lib/repo_*.dart`. Currently **all implementations are mocks** (prefixed `Mock*`). The `RepositoryService` singleton in [lib/data/remote/repository_service.dart](lib/data/remote/repository_service.dart) wires them up.

**Mock credentials:**
- Student: `student@example.com` / `123456`
- Teacher: `teacher@example.com` / `123456`
- Admin: `admin@example.com` / `123456`

**To switch to real API:** Replace `Mock*` implementations with real ones in `RepositoryService._initializeRepositories()` and set the API base URL in `AppConfig`.

### Navigation

Named routes defined in [lib/app_routes.dart](lib/app_routes.dart), generated in [lib/app.dart](lib/app.dart) via `onGenerateRoute`. A global `appNavigatorKey` ([lib/app_navigation.dart](lib/app_navigation.dart)) enables navigation from outside the widget tree (e.g., notification taps).

Route namespaces: `/splash`, `/login`, `/register`, `/student/*`, `/teacher/*`, `/admin/*`

### Data Layer

- **Remote:** `ApiService` ([lib/data/remote/api_service.dart](lib/data/remote/api_service.dart)) — HTTP client with 30s timeout, base URL from `AppConfig`
- **Local DB:** `AppDatabase` + `AppLocalRepository` ([lib/data/local/](lib/data/local/)) — SQLite via `sqflite`; tables: `exam_attempts`, `exam_answers`, `progress_stats`
- **Session:** SharedPreferences for auth token/user persistence
- **Notifications:** `NotificationService` ([lib/data/local/notification_service.dart](lib/data/local/notification_service.dart)) — `flutter_local_notifications`, channel `study_reminders`, daily 7 PM reminder

### Models

Central export: [lib/models.dart](lib/models.dart). All models have `fromJson()`/`toJson()`. Key types: `AppUser`, `UserRole` (enum), `Exam`, `Question`, `ExamAttempt`, `ProgressStat`, `TeacherClass`.

### Theme & Config

- **Theme:** Material 3, primary indigo `#6366F1` — [lib/app_theme.dart](lib/app_theme.dart)
- **Config:** [lib/core/config/app_config.dart](lib/core/config/app_config.dart) — `enableMockData: true` (default), API base URL `http://192.168.1.10:5130/api`

## File Naming Conventions

The codebase uses two patterns:
- Flat files in `lib/` root use prefix-based naming: `screens_login.dart`, `models_user_role.dart`, `repo_auth.dart`, `providers_auth.dart`
- Feature subdirectories use standard `snake_case_screen.dart` naming: `lib/screens/exam/exam_list_screen.dart`
