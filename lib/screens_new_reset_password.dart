import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final _passwordController =
      TextEditingController();

  final _confirmController =
      TextEditingController();

  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final password =
        _passwordController.text.trim();

    final confirm =
        _confirmController.text.trim();

    if (password.isEmpty ||
        confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
             Text(
            'Vui lòng nhập đầy đủ mật khẩu',
          ),
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Mật khẩu không khớp'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider =
        Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final success =
        await authProvider.resetPassword(
      widget.token,
      password,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đổi mật khẩu thành công',
          ),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        '/login',
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Đặt lại mật khẩu'),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                TextField(
                  controller:
                      _passwordController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Mật khẩu mới',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller:
                      _confirmController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Nhập lại mật khẩu',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _resetPassword,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Đổi mật khẩu',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}