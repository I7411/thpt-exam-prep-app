import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';
import 'package:thpt_exam_prep_app/widgets/app_text_field.dart';
import 'package:thpt_exam_prep_app/widgets/gradient_header.dart';
import 'package:thpt_exam_prep_app/widgets/primary_gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.student;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Xác nhận mật khẩu không được để trống';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Họ tên không được để trống';
    }
    if (value.length < 3) {
      return 'Họ tên phải có ít nhất 3 ký tự';
    }
    return null;
  }

  void _handleRegister(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthController>();
    final navigator = Navigator.of(context);

    final success = await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text,
      _confirmPasswordController.text,
      _nameController.text.trim(),
      _selectedRole,
    );

    if (success && mounted) {
      final user = authProvider.currentUser;
      if (user != null) {
        String nextRoute = AppRoutes.studentHome;
        if (user.role == UserRole.teacher) {
          nextRoute = AppRoutes.teacherDashboard;
        } else if (user.role == UserRole.admin) {
          nextRoute = AppRoutes.adminDashboard;
        }
        navigator.pushReplacementNamed(nextRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7ED), AppColors.background],
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
                            GradientHeader(
                              title: 'Tạo tài khoản mới',
                              subtitle: 'Bắt đầu hành trình ôn thi THPT của bạn',
                              icon: Icons.person_add_alt_1_rounded,
                              gradient: AppGradients.warm,
                              trailing: IconButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close, color: Colors.white),
                                tooltip: 'Đóng',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            if (authProvider.errorMessage.isNotEmpty) ...[
                              _ErrorBanner(message: authProvider.errorMessage),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            AppTextField(
                              controller: _nameController,
                              label: 'Họ tên',
                              hintText: 'Nhập họ tên đầy đủ',
                              icon: Icons.person_outline_rounded,
                              enabled: !authProvider.isLoading,
                              validator: _validateName,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              hintText: 'Nhập email',
                              icon: Icons.email_outlined,
                              enabled: !authProvider.isLoading,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Vai trò',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<UserRole>(
                              initialValue: _selectedRole,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: UserRole.student,
                                  child: Text('Học sinh'),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.teacher,
                                  child: Text('Giáo viên'),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.admin,
                                  child: Text('Quản trị viên'),
                                ),
                              ],
                              onChanged: authProvider.isLoading
                                  ? null
                                  : (role) {
                                      if (role != null) {
                                        setState(() {
                                          _selectedRole = role;
                                        });
                                      }
                                    },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Mật khẩu',
                              hintText: 'Tối thiểu 6 ký tự',
                              icon: Icons.lock_outline_rounded,
                              enabled: !authProvider.isLoading,
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _confirmPasswordController,
                              label: 'Xác nhận mật khẩu',
                              hintText: 'Nhập lại mật khẩu',
                              icon: Icons.verified_user_outlined,
                              enabled: !authProvider.isLoading,
                              obscureText: _obscureConfirmPassword,
                              validator: _validateConfirmPassword,
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmPassword
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            PrimaryGradientButton(
                              label: authProvider.isLoading
                                  ? 'Đang đăng ký...'
                                  : 'Đăng ký',
                              icon: Icons.person_add_rounded,
                              isLoading: authProvider.isLoading,
                              gradient: AppGradients.warm,
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _handleRegister(context),
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
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 28),
                                ),
                                label: const Text(
                                  'Đăng ký với Google',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () async {
                                        final success = await authProvider.loginWithGoogle();
                                        if (success && mounted) {
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
                                      },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Đã có tài khoản?'),
                                  TextButton(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () => Navigator.of(context)
                                            .pushReplacementNamed(AppRoutes.login),
                                    child: const Text('Đăng nhập'),
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

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        border: Border.all(color: AppColors.error.withOpacity(0.22)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
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
        ],
      ),
    );
  }
}
