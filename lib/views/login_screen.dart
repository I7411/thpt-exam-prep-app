import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email khÃ´ng Ä‘Æ°á»£c Ä‘á»ƒ trá»‘ng';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email khÃ´ng há»£p lá»‡';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Máº­t kháº©u khÃ´ng Ä‘Æ°á»£c Ä‘á»ƒ trá»‘ng';
    }
    if (value.length < 6) {
      return 'Máº­t kháº©u pháº£i cÃ³ Ã­t nháº¥t 6 kÃ½ tá»±';
    }
    return null;
  }

  void _handleLogin(BuildContext context, String email, String password) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthController>();
      final success = await authProvider.login(email, password);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthController>(
          builder: (context, authProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          // School Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.school,
                              size: 40,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'THPT Smart Learn',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'á»¨ng dá»¥ng Ã´n thi THPT',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

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
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => authProvider.clearError(),
                              child: const Icon(Icons.close, color: Colors.red, size: 20),
                            ),
                          ],
                        ),
                      ),
                    if (authProvider.errorMessage.isNotEmpty)
                      const SizedBox(height: 20),

                    // Email field
                    Text(
                      'Email',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      enabled: !authProvider.isLoading,
                      decoration: InputDecoration(
                        hintText: 'Nháº­p email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    Text(
                      'Máº­t kháº©u',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !authProvider.isLoading,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Nháº­p máº­t kháº©u',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                        child: const Text('QuÃªn máº­t kháº©u?'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _handleLogin(context, _emailController.text, _passwordController.text),
                        icon: authProvider.isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.login),
                        label: Text(
                          authProvider.isLoading ? 'Äang Ä‘Äƒng nháº­p...' : 'ÄÄƒng nháº­p',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Hoáº·c thá»­ demo',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Demo buttons
                    _buildDemoButton(
                      context,
                      authProvider,
                      'ðŸ“š Há»c sinh Demo',
                      'student.demo@thptsmartlearn.vn',
                      '123456',
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildDemoButton(
                      context,
                      authProvider,
                      'ðŸ‘¨â€ðŸ« GiÃ¡o viÃªn Demo',
                      'teacher.demo@thptsmartlearn.vn',
                      '123456',
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildDemoButton(
                      context,
                      authProvider,
                      'ðŸ” Admin Demo',
                      'admin.demo@thptsmartlearn.vn',
                      '123456',
                      Colors.red,
                    ),
                    const SizedBox(height: 24),

                    // Register link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('ChÆ°a cÃ³ tÃ i khoáº£n? '),
                          TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () => Navigator.of(context).pushNamed(AppRoutes.register),
                            child: const Text('ÄÄƒng kÃ½ ngay'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDemoButton(
    BuildContext context,
    AuthController authProvider,
    String label,
    String email,
    String password,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: authProvider.isLoading ? null : () => _quickLogin(email, password),
        icon: const Icon(Icons.flash_on),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

