import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phone_store/app_constants/app_utils.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/main/pages/shared_widgets/otp_dialog.dart';
import 'dart:async';
import 'package:phone_store/models/user.dart';

class AuthUserProvider extends ChangeNotifier {
  String? _verificationId;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  VoidCallback? onCodeSent;
  Function(String)? onSuccess;
  Function(String)? onError;

  Future<bool> isPhoneAlreadyRegistered(String phone) async {
    try {
      final doc = await Collections.registeredPhones.doc(phone).get();
      print('📄 Phone exists: ${doc.exists}');
      return doc.exists;
    } catch (e) {
      print('❌ Error: $e');
      return false;
    }
  }

  Future<void> sendOtpRegister(
      BuildContext context, TextEditingController phoneController) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final phone = AppUtils.formatPhone(phoneController.text);
    bool exists = await isPhoneAlreadyRegistered(phone);
    
    if (exists) {
      _isLoading = false;
      notifyListeners();
      AppUtils.showMessage(context, 'Số điện thoại này đã được đăng ký.');
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);

          _isLoading = false;
          notifyListeners();
          onSuccess?.call('Đăng ký thành công!');
        } on FirebaseAuthException catch (e) {
          _isLoading = false;
          notifyListeners();
          onError?.call(e.message ?? 'Có lỗi xảy ra');
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        AppUtils.hideLoading(context);
        _isLoading = false;
        _errorMessage = e.message ?? 'Xác minh thất bại';
        onError?.call(_errorMessage!);
        notifyListeners();
      },
      codeSent: (String verificationId, int? resendToken) async {
        _verificationId = verificationId;
        _isLoading = false;
        notifyListeners();
        onCodeSent?.call();
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.6),
          builder: (_) => const OtpDialog(
            status: 'register',
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> sendOtpLogin(BuildContext context, String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final phone = AppUtils.formatPhone(phoneNumber);
    bool exists = await isPhoneAlreadyRegistered(phone);
    if (!exists) {
      _isLoading = false;
      notifyListeners();
      AppUtils.showMessage(context, 'Số điện thoại chưa được đăng ký.');
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _isLoading = false;
          notifyListeners();
        } on FirebaseAuthException catch (e) {
          _isLoading = false;
          notifyListeners();
          onError?.call(e.message ?? 'Có lỗi xảy ra');
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        _isLoading = false;
        _errorMessage = e.message ?? 'Xác minh thất bại';
        onError?.call(_errorMessage!);
        notifyListeners();
      },
      codeSent: (String verificationId, int? resendToken) async {
        _verificationId = verificationId;
        _isLoading = false;
        notifyListeners();
        onCodeSent?.call();
        await showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.6),
          builder: (_) => const OtpDialog(
            status: 'login',
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  String _mapErrorMessage(String code) {
    return switch (code) {
      'invalid-verification-code' => 'Mã OTP không đúng',
      'session-expired' => 'Mã OTP đã hết hạn, vui lòng gửi lại',
      'too-many-requests' => 'Thử lại sau vài phút',
      _ => 'Đã có lỗi xảy ra',
    };
  }

  Future<bool> verifyOtpRegistered(String otp) async {
    if (_verificationId == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = AuthHelper.currentUser;
      final userRef = Collections.registeredPhones.doc(user!.phoneNumber);

      await userRef.set({
        UserApp.idField: user.uid,
        'creatAt': Timestamp.now(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      print('❌ verifyOtpRegistered error: $e');
      print(st);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtpLogin(String otp) async {
    if (_verificationId == null) return false;

    try {
      _isLoading = true;
      notifyListeners();
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      _errorMessage = _mapErrorMessage(e.code);
      onError?.call(_errorMessage!);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (!context.mounted) return;
      final user = userCredential.user!;
      final doc = await Collections.user.doc(user.uid).get();

      if (!doc.exists) {
        await Collections.user.doc(user.uid).set({
          UserApp.userAccountField: user.email ?? '',
          UserApp.isCompletedField: false,
        });
      }
    } catch (e) {
      if (context.mounted) AppUtils.hideLoading(context);
      ;
      if (!context.mounted) return;
      _errorMessage = e.toString().isEmpty ? 'Lỗi đăng nhập' : e.toString();

      onError?.call(_errorMessage!);
    }
  }
}
