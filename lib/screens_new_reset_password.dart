import 'package:flutter/material.dart';

class ResetPasswordScreen
    extends StatefulWidget {

  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
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

  Future<void> _changePassword() async {

    final password =
        _passwordController.text.trim();

    final confirm =
        _confirmController.text.trim();

    if (password.isEmpty ||
        confirm.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập đầy đủ',
          ),
        ),
      );

      return;
    }

    if (password != confirm) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mật khẩu không khớp',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    // GIẢ LẬP ĐỔI MẬT KHẨU

    await Future.delayed(
      const Duration(seconds: 1),
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đổi mật khẩu thành công',
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushReplacementNamed(
      context,
      '/login',
    );
  }

  @override
  void dispose() {

    _passwordController.dispose();

    _confirmController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đổi mật khẩu',
        ),
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

                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

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
                    onPressed:
                        _isLoading
                            ? null
                            : _changePassword,

                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
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