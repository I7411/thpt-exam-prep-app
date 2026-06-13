import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isReloading = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _startAutoReloadTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Reload user state periodically every 5 seconds to automatically detect verification
  void _startAutoReloadTimer() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        timer.cancel();
        return;
      }
      if (user.emailVerified) {
        timer.cancel();
        _checkVerificationStatus(autoRedirect: true);
      } else {
        try {
          await user.reload();
        } catch (_) {}
      }
    });
  }

  Future<void> _checkVerificationStatus({bool autoRedirect = false}) async {
    if (_isReloading) return;
    setState(() {
      _isReloading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      final isVerified = refreshedUser?.emailVerified ?? false;

      if (isVerified) {
        final authProvider = context.read<AuthController>();
        final restored = await authProvider.restoreSession();

        if (!mounted) return;

        if (restored && authProvider.currentUser != null) {
          final nextRoute = _routeForRole(authProvider.currentUser!.role);
          Navigator.of(context).pushReplacementNamed(nextRoute);
        } else {
          setState(() {
            _errorMessage = 'Đã xác thực email, nhưng không thể tải thông tin hồ sơ.';
          });
        }
      } else {
        if (!autoRedirect) {
          setState(() {
            _errorMessage = 'Tài khoản chưa được xác thực. Vui lòng nhấn vào liên kết trong email gửi đến bạn.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kiểm tra trạng thái xác thực: $e';
      });
    } finally {
      setState(() {
        _isReloading = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending || _cooldownSeconds > 0) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _startCooldown();
        setState(() {
          _successMessage = 'Đã gửi lại email xác thực thành công. Vui lòng kiểm tra cả thư mục Spam.';
        });
      } else {
        setState(() {
          _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'too-many-requests') {
          _errorMessage = 'Bạn đã yêu cầu gửi quá nhiều lần. Vui lòng thử lại sau.';
        } else {
          _errorMessage = 'Không thể gửi lại email xác thực: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể gửi lại email xác thực: $e';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthController>();
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  String _routeForRole(UserRole role) {
    return switch (role) {
      UserRole.student => AppRoutes.studentHome,
      UserRole.teacher => AppRoutes.teacherDashboard,
      UserRole.admin => AppRoutes.adminDashboard,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Xác thực tài khoản'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Main Icon Header
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 50,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Kiểm tra email của bạn',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description Text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Một liên kết xác thực tài khoản đã được gửi đến địa chỉ email:\n'),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const TextSpan(text: '.\n\nVui lòng nhấn vào liên kết trong email để kích hoạt tài khoản của bạn trước khi tiếp tục.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Error or Success Banner
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.redSoft,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null || _successMessage != null)
                const SizedBox(height: 24),

              // Check Status Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isReloading ? null : () => _checkVerificationStatus(),
                  icon: _isReloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Xác nhận đã xác thực',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Resend Email Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: (_isResending || _cooldownSeconds > 0)
                      ? null
                      : _resendVerificationEmail,
                  icon: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _cooldownSeconds > 0
                        ? 'Gửi lại sau (${_cooldownSeconds}s)'
                        : 'Gửi lại email xác thực',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Sign Out Text Button
              TextButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
