import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';
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
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isStepTwo = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mã oobCode từ liên kết email';
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

  Future<void> _handleStepOne() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthController>(context, listen: false);
    final email = _emailController.text.trim();

    // 1. Verify email exists in system
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

    // 2. Send Firebase Auth reset email
    final sent = await authProvider.sendPasswordReset(email);

    setState(() {
      _isLoading = false;
    });

    if (sent) {
      setState(() {
        _isStepTwo = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi mã xác nhận đến email của bạn.'),
          backgroundColor: AppColors.success,
        ),
      );
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

  Future<void> _handleStepTwo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthController>(context, listen: false);
    final code = _codeController.text.trim();
    final newPassword = _passwordController.text;

    final success = await authProvider.confirmPasswordReset(code, newPassword);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage.isNotEmpty
                ? authProvider.errorMessage
                : 'Đặt lại mật khẩu thất bại. Vui lòng kiểm tra lại mã xác nhận.',
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
                    title: _isStepTwo ? 'Đặt lại mật khẩu' : 'Quên mật khẩu',
                    subtitle: _isStepTwo
                        ? 'Nhập mã oobCode từ email và mật khẩu mới'
                        : 'Nhập email để nhận liên kết đặt lại mật khẩu',
                    icon: _isStepTwo ? Icons.lock_open_rounded : Icons.lock_reset_rounded,
                    gradient: AppGradients.success,
                    trailing: IconButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Đóng',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  if (authProvider.errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.redSoft,
                        border: Border.all(color: AppColors.error.withOpacity(0.22)),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage,
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (!_isStepTwo) ...[
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
                      label: _isLoading ? 'Đang kiểm tra...' : 'Tiếp tục',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: _isLoading,
                      gradient: AppGradients.success,
                      onPressed: _isLoading ? null : _handleSendResetEmailHelper,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Một email đặt lại mật khẩu đã được gửi đến ${_emailController.text}.\n'
                        'Vui lòng nhấp vào liên kết trong email, sao chép tham số "oobCode" từ URL của trang mở ra (hoặc từ email) và điền vào ô bên dưới để đặt lại mật khẩu trực tiếp.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _codeController,
                      label: 'Mã xác nhận (oobCode)',
                      hintText: 'Nhập mã oobCode',
                      icon: Icons.vpn_key_outlined,
                      validator: _validateCode,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu mới',
                      hintText: 'Nhập mật khẩu mới (tối thiểu 6 ký tự)',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      enabled: !_isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                      label: 'Xác nhận mật khẩu mới',
                      hintText: 'Nhập lại mật khẩu mới',
                      icon: Icons.verified_user_outlined,
                      obscureText: _obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                      enabled: !_isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryGradientButton(
                      label: _isLoading ? 'Đang xử lý...' : 'Xác nhận đổi mật khẩu',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isLoading,
                      gradient: AppGradients.success,
                      onPressed: _isLoading ? null : _handleStepTwo,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Quay lại nhập Email'),
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isStepTwo = false;
                                });
                              },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSendResetEmailHelper() {
    _handleStepOne();
  }
}
