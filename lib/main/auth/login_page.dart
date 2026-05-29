import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/home/shared_widgets/input.dart';
import 'package:phone_store/main/pages/home/shared_widgets/loadingService.dart';
import 'package:phone_store/main/auth/forgotPass_page.dart';
import 'package:phone_store/main/auth/register_page.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login_page';

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool password = true;
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  /// 🔹 Sign in with email/password
  void signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();

    try {
      LoadingService.show(context);

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = userCredential.user;
      if (user == null) throw "Không tìm thấy user";

      // 🔐 CHECK VERIFY EMAIL
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();

        LoadingService.hide(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vui lòng xác minh email trước khi đăng nhập"),
          ),
        );
        return;
      }

      LoadingService.hide(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) LoadingService.hide(context);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${e.message}")),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      LoadingService.show(context);

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        LoadingService.hide(context);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      LoadingService.hide(context);
    } catch (e) {
      if (mounted) LoadingService.hide(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng nhập Google: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                    'Welcome\nBack',
                    style: AppTextstyles.headingH3.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.85),
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
                        TextFormField(
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Please enter your password";
                            }
                            if (val.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                          controller: _passController,
                          style: AppTextstyles.headingH6
                              .copyWith(color: AppColors.surface),
                          obscureText: password,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              color: AppColors.surface.withValues(alpha: 0.7),
                              iconSize: 22,
                              icon: Icon(password
                                  ? Icons.visibility_off_outlined
                                  : Icons.remove_red_eye),
                              onPressed: () {
                                setState(
                                  () {
                                    password = !password;
                                  },
                                );
                              },
                            ),
                            hintText: "Password",
                            hintStyle: AppTextstyles.headingH6.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPassPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot password?',
                        style: AppTextstyles.smallTextBold.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.surfaceLight.withValues(alpha: 0.5),
                            blurRadius: 50,
                            offset: const Offset(0, 10),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      width: 120,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: signIn,
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
                          "Sign in",
                          style: AppTextstyles.headingH6
                              .copyWith(color: AppColors.surface),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 1,
                        color: AppColors.surface,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      const Text(
                        'or',
                        style: TextStyle(
                          color: AppColors.surface,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        height: 1,
                        color: AppColors.surface,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton(
                      onPressed: () async => await _signInWithGoogle(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(40, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        backgroundColor: AppColors.surface,
                      ),
                      child: Image.asset(
                        'assets/img/Google.png',
                        height: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don’t have an account? ',
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
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
