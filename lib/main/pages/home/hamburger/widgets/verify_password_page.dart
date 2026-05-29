import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/main/auth/otp_reset_password.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/enterNewEmail.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/main/pages/home/shared_widgets/inputForm.dart';

class VerifyPasswordPage extends StatefulWidget {
  final String email;
  static const routeName = '/verify_password_page';
  const VerifyPasswordPage({super.key, required this.email});

  @override
  State<VerifyPasswordPage> createState() => _VerifyPasswordPageState();
}

class _VerifyPasswordPageState extends State<VerifyPasswordPage> {
  bool isObscureCurrentPassword = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    passWord.text = ""; // reset khi quay lại
  }

  Future<bool> verifyPassword(String email, String password) async {
    try {
      // Lấy user hiện tại
      User? user = AuthHelper.currentUser;

      if (user == null) {
        print("User chưa đăng nhập");
        return false;
      }

      // Xác thực lại user với mật khẩu nhập vào
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      print("Mật khẩu đúng!");

      return true;
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('Wrong password. Please try again!'),
          );
        },
      );
      print("Mật khẩu sai hoặc có lỗi: $e");
      return false;
    }
  }

  TextEditingController passWord = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: AppbarIcon(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              "Xác nhận mật khẩu",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Vui lòng nhập mật khẩu hiện tại để tiếp tục thay đổi email.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            InputForm(
              icon: Icons.lock_person_outlined,
              controller: passWord,
              obscureText: isObscureCurrentPassword,
              hintText: 'Nhập mật khẩu',
              suffixIcon: IconButton(
                icon: isObscureCurrentPassword
                    ? const Icon(Icons.visibility_off)
                    : const Icon(Icons.remove_red_eye),
                onPressed: () {
                  setState(() {
                    isObscureCurrentPassword = !isObscureCurrentPassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.pushNamed(
                    context,
                    OtpResetPassPage.routeName,
                    arguments: OtpResetPassPage(
                      email: widget.email,
                    ),
                  );
                },
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final b = await verifyPassword(
                    widget.email,
                    passWord.text.trim(),
                  );
                  if (b == true) {
                    Navigator.pushNamed(
                      context,
                      EnterNewEmail.routeName,
                      arguments: EnterNewEmail(
                        pass: passWord.text,
                        email: widget.email,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Tiếp tục",
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
