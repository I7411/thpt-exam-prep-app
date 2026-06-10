import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isCheckingSession = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (mounted) {
      setState(() {
        _isCheckingSession = true;
        _errorMessage = null;
      });
    }

    try {
      final authProvider = context.read<AuthController>();
      final restored = await authProvider.restoreSession();

      if (!mounted) return;

      if (!restored) {
        setState(() {
          _isCheckingSession = false;
          _errorMessage = authProvider.errorMessage.isNotEmpty
              ? authProvider.errorMessage
              : 'Không thể kiểm tra phiên đăng nhập. Vui lòng thử lại.';
        });
        return;
      }

      if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      Navigator.of(
        context,
      ).pushReplacementNamed(_routeForRole(authProvider.currentUser!.role));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingSession = false;
        _errorMessage = 'Khởi động ứng dụng thất bại. Vui lòng thử lại.';
      });
      debugPrint('Lỗi khởi động splash: $e');
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
    final theme = Theme.of(context);
    final errorMessage = _errorMessage;

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 32),

            // App Name
            Text(
              'THPT Smart Learn',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'Ứng dụng ôn thi THPT',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 60),

            if (_isCheckingSession) ...[
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Đang khởi động...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage ?? 'Không thể khởi động ứng dụng.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _initializeApp,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                child: const Text(
                  'Về màn hình đăng nhập',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
