import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/app_constants/app_utils.dart';
import 'package:phone_store/main/auth/login.dart';
import 'package:phone_store/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    await context
        .read<AuthUserProvider>()
        .sendOtpRegister(context, _phoneController);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthUserProvider>();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/img/authBackground.jpg',
                  fit: BoxFit.cover),
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
                padding: const EdgeInsets.only(left: 30, right: 30, top: 80),
                shrinkWrap: true,
                children: [
                  Text(
                    'Create\nAccount',
                    style: AppTextstyles.headingH3.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        IntlPhoneField(
                          controller: _phoneController,
                          initialCountryCode: 'VN',
                          disableLengthCheck: true,
                          style: AppTextstyles.headingH6.copyWith(
                            color: AppColors.surface,
                          ),
                          dropdownTextStyle: AppTextstyles.headingH6.copyWith(
                            color: AppColors.surface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Phone Number",
                            hintStyle: AppTextstyles.headingH6.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 15,
                            ),
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
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (phone) {
                            if (phone == null || phone.number.isEmpty) {
                              return 'Nhập số điện thoại';
                            }

                            if (phone.countryISOCode == 'VN' &&
                                ![9, 10].contains(phone.number.length)) {
                              return 'Số điện thoại không hợp lệ';
                            }

                            return null;
                          },
                          onChanged: (phone) {
                            print(phone.completeNumber);
                          },
                        ),
                        const SizedBox(height: 25),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.surfaceLight
                                      .withValues(alpha: 0.5),
                                  blurRadius: 50,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            width: 160,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      if (_phoneController.text.isEmpty) {
                                        AppUtils.showMessage(context,
                                            'Bạn chưa nhập số điện thoại!');
                                        return;
                                      }

                                      await sendOtp();
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: context.read<AuthUserProvider>().isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Gửi OTP',
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
                        style:
                            TextStyle(fontSize: 15, color: AppColors.surface),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
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
