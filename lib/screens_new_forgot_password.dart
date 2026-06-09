import 'package:flutter/material.dart';
import 'package:thpt_exam_prep_app/app_routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen>
      createState() =>
          _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final _formKey =
      GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {

    _emailController.dispose();

    super.dispose();
  }

  // ================= VALIDATE EMAIL =================

  String? _validateEmail(
      String? value) {

    if (value == null ||
        value.isEmpty) {

      return 'Email không được để trống';
    }

    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailRegex.hasMatch(value)) {

      return 'Email không hợp lệ';
    }

    return null;
  }

  // ================= SEND OTP =================

  Future<void> _handleSendOtp() async {

    if (!_formKey.currentState!
        .validate()) {

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
        await authProvider
            .sendPasswordReset(
      _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'OTP đã được gửi',
          ),
          backgroundColor:
              Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VerifyOtpScreen(
            email:
                _emailController.text
                    .trim(),
          ),
        ),
      );

    } else {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            authProvider
                    .errorMessage
                    .isNotEmpty
                ? authProvider
                    .errorMessage
                : 'Gửi OTP thất bại',
          ),

          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quên mật khẩu',
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              children: [

                const SizedBox(
                    height: 40),

                const Icon(
                  Icons.lock_reset,
                  size: 90,
                  color: Colors.blue,
                ),

                const SizedBox(
                    height: 30),

                const Text(
                  'Nhập email để nhận mã OTP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),

                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(
                    height: 30),

                // ================= EMAIL =================

                TextFormField(
                  controller:
                      _emailController,

                  keyboardType:
                      TextInputType
                          .emailAddress,

                  validator:
                      _validateEmail,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Email',

                    border:
                        OutlineInputBorder(),

                    prefixIcon:
                        Icon(Icons.email),
                  ),
                ),

                const SizedBox(
                    height: 30),

                // ================= BUTTON =================

                SizedBox(
                  width:
                      double.infinity,

                  height: 50,

                  child:
                      ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _handleSendOtp,

                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                                color:
                                    Colors
                                        .white,
                              )
                            : const Text(
                                'Gửi OTP',
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