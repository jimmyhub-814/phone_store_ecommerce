// import 'package:flutter/material.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:phone_store/app_constants/app_colors.dart';
// import 'package:phone_store/main/auth/otp_reset_password.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:phone_store/main/pages/home/shared_widgets/inputForm.dart';

// class ForgotPassPage extends StatefulWidget {
//   const ForgotPassPage({super.key});

//   @override
//   State<ForgotPassPage> createState() => _ForgotPassPageState();
// }

// class _ForgotPassPageState extends State<ForgotPassPage> {
//   final _emailController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.surface,
//       appBar: AppBar(
//         title: const Text("Quên mật khẩu"),
//         leading: AppbarIcon(),
//         elevation: 0,
//         backgroundColor: AppColors.surface,
//         foregroundColor: Colors.black87,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(height: 50),
//             const Text(
//               "Đặt lại mật khẩu",
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Nhập email và chúng tôi sẽ gửi mã xác nhận để đặt lại mật khẩu.',
//               style: TextStyle(fontSize: 15, color: Colors.black54),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             Form(
//               key: _formKey,
//               child: InputForm(
//                 controller: _emailController,
//                 hintText: 'Email',
//                 icon: Icons.email_outlined,
//               ),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _isLoading
//                     ? null
//                     : () async {
//                         if (_formKey.currentState!.validate()) {
//                           final email = _emailController.text.trim();

//                           // Kiểm tra đuôi gmail
//                           if (!email.endsWith('@gmail.com')) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Vui lòng nhập email hợp lệ!'),
//                               ),
//                             );
//                             return;
//                           }

//                           // setState(() => _isLoading = true);
//                           // final exists = await checkEmailExists(email);

//                           // if (!exists) {
//                           //   setState(() => _isLoading = false);
//                           //   ScaffoldMessenger.of(context).showSnackBar(
//                           //     const SnackBar(
//                           //       content: Text(
//                           //         'Tài khoản email này không tồn tại!',
//                           //       ),
//                           //     ),
//                           //   );
//                           //   return;
//                           // }

//                           // setState(() => _isLoading = false);

//                           Navigator.pushNamed(
//                             context,
//                             OtpResetPassPage.routeName,
//                             arguments: OtpResetPassPage(
//                               email: _emailController.text.trim(),
//                             ),
//                           );
//                         }
//                       },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.textSecondary,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                 ),
//                 child: _isLoading
//                     ? SizedBox(
//                         height: 22,
//                         width: 22,
//                         child: Center(
//                           child: LoadingAnimationWidget.waveDots(
//                             color: AppColors.primary,
//                             size: 60,
//                           ),
//                         ),
//                       )
//                     : const Text(
//                         "Gửi email đặt lại mật khẩu",
//                         style: TextStyle(
//                           color: AppColors.surface,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//               ),
//             ),
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }
// }
