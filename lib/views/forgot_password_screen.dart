import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';
import 'package:thpt_exam_prep_app/services/sensitive_screen_protection_service.dart';
import 'package:thpt_exam_prep_app/widgets/app_text_field.dart';
import 'package:thpt_exam_prep_app/widgets/gradient_header.dart';
import 'package:thpt_exam_prep_app/widgets/primary_gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isGoogleOnly = false;

  @override
  void initState() {
    super.initState();
    SensitiveScreenProtectionService.instance.enable();
  }

  @override
  void dispose() {
    SensitiveScreenProtectionService.instance.disable();
    _emailController.dispose();
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

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _isGoogleOnly = false;
    });

    final authProvider = Provider.of<AuthController>(context, listen: false);
    final email = _emailController.text.trim();

    // 1. Verify email exists in system first
    final exists = await authProvider.verifyEmailExists(email);

    if (!exists) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage.isNotEmpty
                ? authProvider.errorMessage
                : 'Không tìm thấy tài khoản với email này.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 2. Check if Google-only account
    final isGoogleOnly = await authProvider.checkIsGoogleOnly(email);
    if (isGoogleOnly) {
      setState(() {
        _isLoading = false;
        _isGoogleOnly = true;
      });
      return;
    }

    // 3. Send Firebase Auth reset email
    final sent = await authProvider.sendPasswordReset(email);

    setState(() {
      _isLoading = false;
    });

    if (sent) {
      setState(() {
        _isSuccess = true;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage.isNotEmpty
                ? authProvider.errorMessage
                : 'Gửi email đặt lại mật khẩu thất bại.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthController>(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientHeader(
                    title: 'Quên mật khẩu',
                    subtitle: 'Nhập email để nhận liên kết đặt lại mật khẩu',
                    icon: Icons.lock_reset_rounded,
                    gradient: AppGradients.success,
                    trailing: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Đóng',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (authProvider.errorMessage.isNotEmpty && !_isGoogleOnly) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.redSoft,
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.22),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (_isGoogleOnly) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                'Tài khoản Google',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email này được đăng ký thông qua tài khoản Google. Bạn không cần mật khẩu riêng trên ứng dụng của chúng tôi.\n\nVui lòng quay lại màn hình đăng nhập và nhấn "Đăng nhập với Google" để truy cập.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[900],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ] else if (_isSuccess) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Đã gửi email thành công',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Một email đặt lại mật khẩu đã được gửi đến địa chỉ email của bạn.\n\nVui lòng nhấp vào liên kết trong email để đổi mật khẩu mới, sau đó quay lại ứng dụng để đăng nhập.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[900],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ] else ...[
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'Nhập email đã đăng ký',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryGradientButton(
                      label: _isLoading ? 'Đang gửi yêu cầu...' : 'Gửi liên kết đặt lại mật khẩu',
                      icon: Icons.send_rounded,
                      isLoading: _isLoading,
                      gradient: AppGradients.success,
                      onPressed: _isLoading ? null : _handleResetPassword,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Quay lại đăng nhập'),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
