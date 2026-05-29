import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/home/shared_widgets/input.dart';
import 'package:phone_store/main/pages/home/shared_widgets/loadingService.dart';
import 'package:phone_store/main/auth/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool password = true;
  bool confirmPassword = true;

  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void hideLoading() {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    LoadingService.show(context);

    try {
      final res = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      // Gửi mail xác minh
      await res.user!.sendEmailVerification();

      hideLoading();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check your email to confirm your account'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      hideLoading();
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tài khoản đã tồn tại")),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Đăng ký thất bại")),
      );
    } catch (e) {
      hideLoading();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/img/a.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                shrinkWrap: true,
                children: [
                  Text(
                    'Create\nAccount',
                    style: AppTextstyles.headingH3.copyWith(
                      color: AppColors.surface.withValues(
                       alpha: 0.85,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        InputFormS(
                          controller: _emailController,
                          hintText: 'Email',
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Please enter your email";
                            } else if (!val.contains('@') ||
                                !val.contains('.')) {
                              return "Please enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        InputFormS(
                          controller: _passController,
                          hintText: 'Password',
                          obscureText: password,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Please enter your password";
                            } else if (val.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              password
                                  ? Icons.visibility_off
                                  : Icons.remove_red_eye,
                              color: AppColors.surface.withValues(alpha:0.7),
                            ),
                            onPressed: () =>
                                setState(() => password = !password),
                          ),
                        ),
                        const SizedBox(height: 18),
                        InputFormS(
                          controller: _confirmController,
                          hintText: 'Confirm Password',
                          obscureText: confirmPassword,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Confirm password';
                            }
                            if (val != _passController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              confirmPassword
                                  ? Icons.visibility_off
                                  : Icons.remove_red_eye,
                              color: AppColors.surface.withValues(alpha: 0.7),
                            ),
                            onPressed: () => setState(
                                () => confirmPassword = !confirmPassword),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.surfaceLight.withValues(alpha:0.5),
                                  blurRadius: 50,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            width: 120,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: signUp,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                "Sign up",
                                style: AppTextstyles.headingH6
                                    .copyWith(color: AppColors.surface),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.surface,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
