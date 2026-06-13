import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';
import 'package:thpt_exam_prep_app/services/sensitive_screen_protection_service.dart';
import 'package:thpt_exam_prep_app/widgets/app_password_field.dart';
import 'package:thpt_exam_prep_app/widgets/app_text_field.dart';
import 'package:thpt_exam_prep_app/widgets/gradient_header.dart';
import 'package:thpt_exam_prep_app/widgets/primary_gradient_button.dart';
import 'package:thpt_exam_prep_app/widgets/role_demo_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    SensitiveScreenProtectionService.instance.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRememberMePreference();
    });
  }

  Future<void> _loadRememberMePreference() async {
    final authProvider = context.read<AuthController>();
    await authProvider.loadRememberMePreference();
    if (!mounted) return;

    setState(() {
      _rememberMe = authProvider.rememberMeEnabled;
      final rememberedEmail = authProvider.rememberedEmail;
      if (rememberedEmail != null &&
          rememberedEmail.isNotEmpty &&
          _emailController.text.isEmpty) {
        _emailController.text = rememberedEmail;
      }
    });
  }

  @override
  void dispose() {
    SensitiveScreenProtectionService.instance.disable();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  void _handleLogin(BuildContext context, String email, String password) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthController>();
      final success = await authProvider.login(
        email,
        password,
        rememberMe: _rememberMe,
      );

      if (success && mounted) {
        _passwordController.clear();
        final firebaseUser = FirebaseAuth.instance.currentUser;
        final isDemo = email.trim().toLowerCase().endsWith('.demo@thptsmartlearn.vn') ||
                       email.trim().toLowerCase() == 'student.demo@thptsmartlearn.vn' ||
                       email.trim().toLowerCase() == 'teacher.demo@thptsmartlearn.vn' ||
                       email.trim().toLowerCase() == 'admin.demo@thptsmartlearn.vn';
        if (firebaseUser != null && !firebaseUser.emailVerified && !isDemo) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.verifyEmail);
          return;
        }

        final user = authProvider.currentUser;
        if (user != null) {
          String nextRoute = AppRoutes.studentHome;
          if (user.role == UserRole.teacher) {
            nextRoute = AppRoutes.teacherDashboard;
          } else if (user.role == UserRole.admin) {
            nextRoute = AppRoutes.adminDashboard;
          }
          Navigator.of(context).pushReplacementNamed(nextRoute);
        }
      }
    }
  }

  void _quickLogin(String email, String password) async {
    _emailController.text = email;
    _passwordController.text = password;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _handleLogin(context, email, password);
    }
  }

  void _showLinkAccountDialog(BuildContext context, AuthController authProvider) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isLoading = context.select<AuthController, bool>((ap) => ap.isLoading);
            final errorMessage = context.select<AuthController, String>((ap) => ap.errorMessage);

            return AlertDialog(
              title: const Text('Liên kết tài khoản'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email này đã được đăng ký bằng mật khẩu. Vui lòng nhập mật khẩu của bạn để liên kết với tài khoản Google.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    AppPasswordField(
                      controller: passwordController,
                      enabled: !isLoading,
                      label: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu của bạn',
                      icon: Icons.lock_outline,
                      showLabel: false,
                      outlineBorder: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mật khẩu không được để trống';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    if (errorMessage.isNotEmpty && errorMessage != 'account-exists-with-different-credential') ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage,
                        style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          authProvider.clearPendingCredentials();
                          Navigator.of(context).pop();
                        },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final success = await authProvider.linkGoogleAccount(
                              passwordController.text,
                            );
                            if (success && context.mounted) {
                              Navigator.of(context).pop(); // close dialog
                              final user = authProvider.currentUser;
                              if (user != null) {
                                String nextRoute = AppRoutes.studentHome;
                                if (user.role == UserRole.teacher) {
                                  nextRoute = AppRoutes.teacherDashboard;
                                } else if (user.role == UserRole.admin) {
                                  nextRoute = AppRoutes.adminDashboard;
                                }
                                Navigator.of(context).pushReplacementNamed(nextRoute);
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Liên kết'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      passwordController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2FE), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Consumer<AuthController>(
            builder: (context, authProvider, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - AppSpacing.lg * 2,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const GradientHeader(
                              title: 'THPT Smart Learn',
                              subtitle: 'Ôn thi THPT hiệu quả mỗi ngày',
                              icon: Icons.school_rounded,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _ErrorBanner(
                              message: authProvider.errorMessage,
                              onClose: authProvider.clearError,
                            ),
                            if (authProvider.errorMessage.isNotEmpty)
                              const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              hintText: 'Nhập email của bạn',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !authProvider.isLoading,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppPasswordField(
                              controller: _passwordController,
                              label: 'Mật khẩu',
                              hintText: 'Nhập mật khẩu',
                              icon: Icons.lock_outline_rounded,
                              enabled: !authProvider.isLoading,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            CheckboxListTile(
                              value: _rememberMe,
                              onChanged: authProvider.isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Remember me'),
                              subtitle: const Text(
                                'Keep me signed in for up to 30 days on this device.',
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.forgotPassword),
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            PrimaryGradientButton(
                              label: authProvider.isLoading
                                  ? 'Đang đăng nhập...'
                                  : 'Đăng nhập',
                              icon: Icons.login_rounded,
                              isLoading: authProvider.isLoading,
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _handleLogin(
                                      context,
                                      _emailController.text,
                                      _passwordController.text,
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                icon: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                                  height: 24,
                                  width: 24,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.g_mobiledata, size: 28),
                                ),
                                label: const Text(
                                  'Đăng nhập với Google',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () async {
                                        final success = await authProvider
                                            .loginWithGoogle(
                                          rememberMe: _rememberMe,
                                        );
                                        if (success) {
                                          if (mounted) {
                                            final user = authProvider.currentUser;
                                            if (user != null) {
                                              String nextRoute = AppRoutes.studentHome;
                                              if (user.role == UserRole.teacher) {
                                                nextRoute = AppRoutes.teacherDashboard;
                                              } else if (user.role == UserRole.admin) {
                                                nextRoute = AppRoutes.adminDashboard;
                                              }
                                              Navigator.of(context).pushReplacementNamed(nextRoute);
                                            }
                                          }
                                        } else {
                                          if (mounted && authProvider.errorMessage == 'account-exists-with-different-credential') {
                                            _showLinkAccountDialog(context, authProvider);
                                          }
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _DividerLabel(label: 'Tài khoản demo'),
                            const SizedBox(height: AppSpacing.md),
                            RoleDemoButton(
                              label: 'Học sinh Demo',
                              subtitle: 'Vào trang ôn thi và tiến độ học tập',
                              icon: Icons.menu_book_rounded,
                              color: AppColors.primary,
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _quickLogin(
                                      'student.demo@thptsmartlearn.vn',
                                      '123456',
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            RoleDemoButton(
                              label: 'Giáo viên Demo',
                              subtitle: 'Quản lý lớp, câu hỏi và đề thi',
                              icon: Icons.assignment_ind_rounded,
                              color: AppColors.secondary,
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _quickLogin(
                                      'teacher.demo@thptsmartlearn.vn',
                                      '123456',
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            RoleDemoButton(
                              label: 'Admin Demo',
                              subtitle:
                                  'Theo dõi người dùng và dữ liệu hệ thống',
                              icon: Icons.admin_panel_settings_rounded,
                              color: AppColors.error,
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _quickLogin(
                                      'admin.demo@thptsmartlearn.vn',
                                      '123456',
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Chưa có tài khoản?'),
                                  TextButton(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () => Navigator.of(
                                            context,
                                          ).pushNamed(AppRoutes.register),
                                    child: const Text('Đăng ký ngay'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, color: AppColors.error, size: 20),
          ),
        ],
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
