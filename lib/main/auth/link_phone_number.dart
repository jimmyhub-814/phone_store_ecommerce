import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LinkPhonePage extends StatefulWidget {
  static const routeName = '/linkPhone';
  const LinkPhonePage({super.key});

  @override
  State<LinkPhonePage> createState() => _LinkPhonePageState();
}

class _LinkPhonePageState extends State<LinkPhonePage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;

  String verificationId = '';

  bool isLoading = false;
  bool otpSent = false;

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      showMessage('Nhập số điện thoại');
      return;
    }

    setState(() {
      isLoading = true;
    });

    await auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (
        PhoneAuthCredential credential,
      ) async {
        try {
          await auth.currentUser?.linkWithCredential(credential);

          showMessage('Liên kết số điện thoại thành công');

          if (mounted) {
            Navigator.pop(context);
          }
        } on FirebaseAuthException catch (e) {
          showMessage(e.message ?? 'Có lỗi xảy ra');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          isLoading = false;
        });

        showMessage(e.message ?? 'Xác minh thất bại');
      },
      codeSent: (
        String verificationId,
        int? resendToken,
      ) {
        setState(() {
          this.verificationId = verificationId;
          otpSent = true;
          isLoading = false;
        });

        showMessage('Đã gửi OTP');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        this.verificationId = verificationId;
      },
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      showMessage('Nhập mã OTP');
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await auth.currentUser?.linkWithCredential(credential);

      showMessage('Liên kết số điện thoại thành công');

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Có lỗi xảy ra');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liên kết số điện thoại'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                hintText: '+84901234567',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (otpSent)
              Column(
                children: [
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mã OTP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : otpSent
                        ? verifyOtp
                        : sendOtp,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        otpSent ? 'Xác minh OTP' : 'Gửi OTP',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
