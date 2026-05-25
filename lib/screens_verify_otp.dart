import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers_auth.dart';
import 'screens_new_reset_password.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyOtpScreen> createState() =>
      _VerifyOtpScreenState();
}

class _VerifyOtpScreenState
    extends State<VerifyOtpScreen> {

  final _otpController =
      TextEditingController();

  bool _isLoading = false;

  Future<void> _verifyOtp() async {

    final otp =
        _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập OTP',
          ),
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
        await authProvider.verifyOtp(
      widget.email,
      otp,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordScreen(
            email: widget.email,
          ),
        ),
      );

    } else {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _otpController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xác thực OTP',
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
                  'OTP đã gửi đến:',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

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
                      _otpController,

                  keyboardType:
                      TextInputType.number,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Nhập mã OTP',

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
                            : _verifyOtp,

                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Xác nhận OTP',
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