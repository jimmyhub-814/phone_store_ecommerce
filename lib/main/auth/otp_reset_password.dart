// import 'dart:async';
// import 'dart:math';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:phone_store/app_constants/app_colors.dart';
// import 'package:mailer/mailer.dart' as mailer;
// import 'package:mailer/smtp_server.dart' as mailer_smtp;
// import 'package:loading_animation_widget/loading_animation_widget.dart';

// class OtpResetPassPage extends StatefulWidget {
//   final String email;
//   static const routeName = '/otpResetPass';
//   const OtpResetPassPage({super.key, required this.email});

//   @override
//   State<OtpResetPassPage> createState() => _OtpResetPassPageState();
// }

// enum OtpStatus { resetPassword, changeEmail }

// class _OtpResetPassPageState extends State<OtpResetPassPage> {
//   final List<TextEditingController> _otpController =
//       List.generate(4, (_) => TextEditingController());
//   final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

//   bool isCounting = true;
//   int remainingSeconds = 60;
//   Timer? countdownTimer;
//   String? currentOtp;
//   DateTime? otpExpireAt;

//   String get otpCode => _otpController.map((c) => c.text).join();

//   bool get isOTPComplete =>
//       _otpController.every((controller) => controller.text.isNotEmpty);

//   @override
//   void initState() {
//     super.initState();
//     // Bắt đầu countdown sẵn (nếu có OTP)
//     startCountdown(reset: true);

//     // Lấy args sau frame để an toàn
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (widget.email.isNotEmpty) {
//         await sendOtpEmail(widget.email);
//       }
//     });
//   }

//   /// Generate 6-digit OTP
//   String generateOTP() {
//     return (Random().nextInt(9000) + 1000).toString();
//   }

//   /// Send OTP via SMTP (mailer)
//   /// NOTE: replace smtpUsername and smtpPassword with secure values (App Password for Gmail)
//   Future<bool> sendOtpEmail(String email) async {
//     final otp = generateOTP();

//     // set these from secure storage / env; DO NOT hardcode in public repo
//     const smtpUsername = 'mynguyen.vo0974@gmail.com';
//     const smtpPassword = 'czsf uptl apbc yjni'; // << use App Password for Gmail

//     final smtpServer = mailer_smtp.SmtpServer(
//       'smtp.gmail.com',
//       port: 587,
//       username: smtpUsername,
//       password: smtpPassword,
//       // tls/ssl handled automatically by the package for port 587
//     );

//     final message = mailer.Message()
//       ..from = const mailer.Address(smtpUsername, 'Phone Store App')
//       ..recipients = [email]
//       ..subject = 'Mã xác thực (OTP) của bạn'
//       ..html = """
//   <div style="font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5;">
//     <div style="max-width: 420px; margin: auto; background: white; padding: 24px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
      
//       <h2 style="color: #333; text-align: center;">🔐 Xác thực Email</h2>
//       <p style="font-size: 15px; color: #555;">
//         Mã xác thực (OTP) của bạn là:
//       </p>

//       <div style="
//         background: #f0f8ff;
//         border-left: 5px solid #0066ff;
//         padding: 16px;
//         margin: 20px 0;
//         text-align: center;
//         border-radius: 8px;">
//         <span style="font-size: 32px; font-weight: bold; color: #0066ff; letter-spacing: 4px;">
//           $otp
//         </span>
//       </div>

//       <p style="font-size: 14px; color: #555;">
//         Mã này có hiệu lực trong <b>$remainingSeconds giây</b>.  
//         Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email này.
//       </p>

//       <p style="font-size: 13px; color: #999; margin-top: 30px; text-align: center;">
//         Phone Store App © 2025
//       </p>

//     </div>
//   </div>
//   """;

//     try {
//       final sendReport = await mailer.send(message, smtpServer);
//       // nếu gửi thành công set OTP và expiry
//       setState(() {
//         currentOtp = otp;
//         otpExpireAt = DateTime.now().add(Duration(seconds: remainingSeconds));
//         // reset countdown
//         startCountdown(reset: true);
//       });

//       debugPrint(
//           'OTP gửi thành công tới $email — otp=$otp — report: $sendReport');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('OTP đã được gửi. Kiểm tra email.')),
//         );
//       }
//       return true;
//     } catch (e) {
//       debugPrint('Lỗi gửi OTP: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Gửi OTP thất bại: $e')),
//         );
//       }
//       return false;
//     }
//   }

//   /// Start or restart countdown. If reset==true, set remainingSeconds to 60.
//   void startCountdown({bool reset = false}) {
//     countdownTimer?.cancel();
//     setState(() {
//       isCounting = true;
//       if (reset) remainingSeconds = 60;
//     });

//     countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//       if (remainingSeconds > 0) {
//         setState(() => remainingSeconds--);
//       } else {
//         timer.cancel();
//         setState(() {
//           isCounting = false;
//           // expire current OTP
//           currentOtp = null;
//           otpExpireAt = null;
//           remainingSeconds = 60; // chuẩn bị cho lần gửi lại
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     countdownTimer?.cancel();
//     for (var c in _otpController) {
//       c.dispose();
//     }
//     for (var f in _focusNodes) {
//       f.dispose();
//     }
//     super.dispose();
//   }

//   /// Verify OTP (compare with currentOtp and expiry)
//   bool verifyOtpLocally(String otp) {
//     if (currentOtp == null) return false;
//     if (otpExpireAt == null) return false;
//     if (DateTime.now().isAfter(otpExpireAt!)) {
//       // expired
//       currentOtp = null;
//       otpExpireAt = null;
//       return false;
//     }
//     return currentOtp == otp;
//   }

//   /// After successful verification do actions based on mode
//   Future<void> onVerified() async {
//     try {
//       final targetEmail = widget.email;
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: targetEmail);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Vui lòng kiểm tra email để đổi mật khẩu.',
//             ),
//           ),
//         );
//       }
//           // pop back to previous screen
//       if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
//       return;
//       // ignore: unrelated_type_equality_checks
//     } catch (e) {
//       debugPrint('Lỗi khi thực hiện action sau verify: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Lỗi khi thực hiện hành động: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _onVerifyPressed() async {
//     final code = otpCode;

//     if (!verifyOtpLocally(code)) {
//       debugPrint("OTP nhập: $code — FAIL (invalid or expired)");

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('OTP không hợp lệ hoặc đã hết hạn.')),
//         );
//       }
//       return;
//     }

//     debugPrint("OTP nhập: $code — OK (verified)");

//     await onVerified(); // <<< QUAN TRỌNG, PHẢI GỌI
//   }

//   Future<void> _onResendPressed() async {
   
//     final ok = await sendOtpEmail(widget.email);
//     if (!ok && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Gửi lại OTP thất bại — thử lại sau.')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
  

//     return Scaffold(
//       backgroundColor: AppColors.surface,
//       appBar: AppBar(
//         title: const Text('Xác minh OTP'),
//         leading: AppbarIcon(),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: AppColors.surface,
//         foregroundColor: Colors.black87,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 12),
//               const Text(
//                 "Nhập mã xác nhận đã gửi tới:",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                     fontSize: 18, fontWeight: FontWeight.w500, height: 1.4),
//               ),
//               Text(
//                 widget.email,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   color: AppColors.primary,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   height: 1.4,
//                 ),
//               ),
//               const SizedBox(height: 28),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: List.generate(
//                   4,
//                   (index) {
//                     return SizedBox(
//                       width: 65,
//                       child: TextField(
//                         controller: _otpController[index],
//                         focusNode: _focusNodes[index],
//                         keyboardType: TextInputType.number,
//                         inputFormatters: [
//                           LengthLimitingTextInputFormatter(1),
//                           FilteringTextInputFormatter.digitsOnly,
//                         ],
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor: AppColors.surface,
//                           contentPadding:
//                               const EdgeInsets.symmetric(vertical: 16),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: const BorderSide(
//                                 color: AppColors.iconPrimary, width: 2),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: const BorderSide(
//                               color: AppColors.primary,
//                               width: 2,
//                             ),
//                           ),
//                         ),
//                         onChanged: (val) {
//                           if (val.isNotEmpty) {
//                             if (index < 3) {
//                               _focusNodes[index + 1].requestFocus();
//                             } else {
//                               _focusNodes[index].unfocus();
//                             }
//                           } else {
//                             if (index > 0) {
//                               _focusNodes[index - 1].requestFocus();
//                             }
//                           }
//                           setState(() {});
//                         },
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 22),
//               isCounting
//                   ? Text(
//                       "Mã OTP sẽ hết hạn sau: $remainingSeconds giây",
//                       style: const TextStyle(
//                         fontSize: 15,
//                       ),
//                     )
//                   : TextButton(
//                       onPressed: _onResendPressed,
//                       child: const Text(
//                         "Gửi lại mã OTP",
//                         style: TextStyle(
//                           fontSize: 15,
//                           color: AppColors.primary,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//               const SizedBox(height: 28),
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                   onPressed: isOTPComplete ? _onVerifyPressed : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     disabledBackgroundColor: Colors.grey.shade300,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   child: const Text(
//                     "Xác minh",
//                     style: TextStyle(
//                       fontSize: 17,
//                       color: AppColors.surface,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
