import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  void _handleRegister(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
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
        // Navigate to appropriate dashboard
        String nextRoute;
        if (user.role == UserRole.student) {
          nextRoute = AppRoutes.studentHome;
        } else if (user.role == UserRole.teacher) {
          nextRoute = AppRoutes.teacherDashboard;
        } else if (user.role == UserRole.admin) {
          nextRoute = AppRoutes.adminDashboard;
        } else {
          nextRoute = AppRoutes.studentHome;
        }

        Navigator.of(context).pushReplacementNamed(nextRoute);
      }
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Học sinh';
      case UserRole.teacher:
        return 'Giáo viên';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Tạo tài khoản mới',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (authProvider.errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (authProvider.errorMessage.isNotEmpty)
                    const SizedBox(height: 24),

                  // Full Name
                  Text(
                    'Họ tên',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    enabled: !authProvider.isLoading,
                    decoration: InputDecoration(
                      hintText: 'Nhập họ tên đầy đủ',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    enabled: !authProvider.isLoading,
                    decoration: InputDecoration(
                      hintText: 'Nhập email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Role selection
                  Text(
                    'Vai trò',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.security),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                  const SizedBox(height: 20),

                  // Password field
                  Text(
                    'Mật khẩu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    enabled: !authProvider.isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password field
                  Text(
                    'Xác nhận mật khẩu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    enabled: !authProvider.isLoading,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Nhập lại mật khẩu',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : () => _handleRegister(context),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Đăng ký'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Đã có tài khoản? '),
                        TextButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                          child: const Text('Đăng nhập'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}