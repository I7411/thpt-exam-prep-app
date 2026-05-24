import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Splash screen duration
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Try to restore session
    final authProvider = context.read<AuthProvider>();
    await authProvider.restoreSession();

    if (!mounted) return;

    // Navigate based on auth state
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      // User is logged in, navigate to appropriate dashboard
      final role = authProvider.currentUser!.role.toString();
      String route;
      
      if (role.contains('student')) {
        route = AppRoutes.studentHome;
      } else if (role.contains('teacher')) {
        route = AppRoutes.teacherDashboard;
      } else if (role.contains('admin')) {
        route = AppRoutes.adminDashboard;
      } else {
        route = AppRoutes.login;
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } else {
      // No session, go to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
              child: const Icon(
                Icons.school,
                size: 60,
                color: Colors.white,
              ),
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
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 60),

            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),

            // Loading text
            Text(
              'Đang khởi động...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
