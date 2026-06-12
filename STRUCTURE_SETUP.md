# Flutter Project Structure Setup

## Directory Structure to Create

```
lib/
├── main.dart                          (already exists)
├── app.dart                           (to create)
├── core/
│   ├── config/
│   │   └── app_config.dart           (to create)
│   ├── constants/
│   │   └── app_constants.dart        (to create)
│   ├── routes/
│   │   └── app_routes.dart           (to create)
│   ├── theme/
│   │   ├── app_theme.dart            (to create)
│   │   └── colors.dart               (to create)
│   └── utils/
│       └── helpers.dart              (to create)
├── data/
│   ├── models/                        (directory for data models)
│   ├── mock/                          (directory for mock data)
│   ├── local/                         (directory for local database)
│   ├── remote/                        (directory for API services)
│   └── repositories/                  (directory for data repositories)
├── providers/                         (directory for state management)
├── screens/
│   ├── splash/                        (splash screen)
│   ├── auth/                          (login, register, password reset)
│   ├── student/                       (student features)
│   ├── document/                      (document management)
│   ├── exam/                          (exam screens)
│   ├── progress/                      (progress tracking)
│   ├── notification/                  (notifications)
│   ├── profile/                       (user profile)
│   ├── teacher/                       (teacher features)
│   └── admin/                         (admin features)
└── widgets/                           (reusable widgets)
```

## How to Create Directories

Use Git Bash or WSL:

```bash
# Navigate to project root
cd c:\LTDD_K6\thpt_exam_prep_app

# Run the setup script
bash setup_structure.sh

# Or manually run in Git Bash:
cd lib
mkdir -p core/config core/constants core/routes core/theme core/utils
mkdir -p data/models data/mock data/local data/remote data/repositories
mkdir -p providers
mkdir -p screens/{splash,auth,student,document,exam,progress,notification,profile,teacher,admin}
mkdir -p widgets
```

## Or use PowerShell (Windows 10+):

```powershell
cd c:\LTDD_K6\thpt_exam_prep_app\lib

@(
    "core/config", "core/constants", "core/routes", "core/theme", "core/utils",
    "data/models", "data/mock", "data/local", "data/remote", "data/repositories",
    "providers",
    "screens/splash", "screens/auth", "screens/student", "screens/document",
    "screens/exam", "screens/progress", "screens/notification", "screens/profile",
    "screens/teacher", "screens/admin",
    "widgets"
) | ForEach-Object { New-Item -ItemType Directory -Path $_ -Force }
```

## Recommended Starter Files

After creating directories, add these starter files to appropriate locations.
