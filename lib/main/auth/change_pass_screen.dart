// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:phone_store/app_constants/app_colors.dart';
// import 'package:phone_store/app_constants/auth_helper.dart';
// import 'package:phone_store/main/auth/otp_reset_password.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:phone_store/main/pages/home/shared_widgets/inputForm.dart';

// class ChangepassPage extends StatefulWidget {
//   final String email;
//   static const routeName = '/changePassPage';
//   const ChangepassPage({super.key, required this.email});

//   @override
//   State<ChangepassPage> createState() => _ChangepassPageState();
// }

// class _ChangepassPageState extends State<ChangepassPage> {
//   bool isObscureCurrentPassword = true;
//   bool isObscureNewPassword = true;
//   bool isObscureConfirmNewPassword = true;

//   final _passController = TextEditingController();
//   final _newPassController = TextEditingController();
//   final _confirmPassController = TextEditingController();

//   bool isLoading = false;

//   @override
//   void dispose() {
//     _passController.dispose();
//     _newPassController.dispose();
//     _confirmPassController.dispose();
//     super.dispose();
//   }

//   void _show(String text) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         content: Text(text),
//       ),
//     );
//   }

//   Future<void> changePassword(String email) async {
//     FocusScope.of(context).unfocus();

//     final oldPass = _passController.text.trim();
//     final newPass = _newPassController.text.trim();
//     final confirmPass = _confirmPassController.text.trim();

//     if (newPass.length < 6) {
//       _show("Mật khẩu mới phải từ 6 ký tự trở lên!");
//       return;
//     }
//     if (newPass != confirmPass) {
//       _show("Vui lòng nhập đúng mật khẩu xác nhận!");
//       return;
//     }
//     if (newPass == oldPass) {
//       _show("Mật khẩu mới không được trùng mật khẩu cũ!");
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       final user = AuthHelper.currentUser;
//       if (user == null) return;

//       final credential =
//           EmailAuthProvider.credential(email: email, password: oldPass);

//       await user.reauthenticateWithCredential(credential);
//       await user.updatePassword(newPass);

//       _show("Đổi mật khẩu thành công!");

//       // 🧹 XÓA Ô NHẬP MẬT KHẨU

//       Future.delayed(const Duration(seconds: 2), () {
//         if (mounted) {
//           Navigator.pop(context);
//           Navigator.pop(context);
//         }
//       });
//     } catch (e) {
//       _show("Sai mật khẩu. Vui lòng thử lại!");
//     }

//     setState(() => isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => FocusScope.of(context).unfocus(),
//       child: Scaffold(
//         backgroundColor: AppColors.surface,
//         appBar: AppBar(
//           leading: AppbarIcon(),
//           backgroundColor: AppColors.surface,
//           elevation: 0,
//           centerTitle: true,
//           title: const Text(
//             "Đổi mật khẩu",
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//           ),
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Bảo mật tài khoản của bạn",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 "Vui lòng nhập mật khẩu hiện tại và mật khẩu mới.",
//                 style: TextStyle(color: Colors.black54),
//               ),
//               const SizedBox(height: 15),

//               // OLD PASSWORD
//               InputForm(
//                 controller: _passController,
//                 hintText: 'Mật khẩu hiện tại',
//                 icon: Icons.lock_outline,
//                 obscureText: isObscureCurrentPassword,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     isObscureCurrentPassword
//                         ? Icons.visibility_off
//                         : Icons.visibility,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       isObscureCurrentPassword = !isObscureCurrentPassword;
//                     });
//                   },
//                 ),
//               ),

//               // NEW PASSWORD
//               InputForm(
//                 controller: _newPassController,
//                 hintText: 'Mật khẩu mới',
//                 icon: Icons.lock_person_outlined,
//                 obscureText: isObscureNewPassword,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     isObscureNewPassword
//                         ? Icons.visibility_off
//                         : Icons.visibility,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       isObscureNewPassword = !isObscureNewPassword;
//                     });
//                   },
//                 ),
//               ),

//               // CONFIRM PASSWORD
//               InputForm(
//                 controller: _confirmPassController,
//                 hintText: 'Xác nhận mật khẩu mới',
//                 icon: Icons.verified_user_outlined,
//                 obscureText: isObscureConfirmNewPassword,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     isObscureConfirmNewPassword
//                         ? Icons.visibility_off
//                         : Icons.visibility,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       isObscureConfirmNewPassword =
//                           !isObscureConfirmNewPassword;
//                     });
//                   },
//                 ),
//               ),

//               // FORGOT PASSWORD
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: GestureDetector(
//                   onTap: () {
//                     Navigator.pushNamed(
//                       context,
//                       OtpResetPassPage.routeName,
//                       arguments: (email: widget.email),
//                     );
//                   },
//                   child: Text(
//                     "Quên mật khẩu?",
//                     style: TextStyle(
//                       color: Colors.blue[600],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               /// BUTTON WITH GRADIENT
//               GestureDetector(
//                 onTap: isLoading ? null : () => changePassword(widget.email),
//                 child: Container(
//                   height: 55,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(18),
//                     gradient: const LinearGradient(
//                       colors: [
//                         AppColors.textSecondary,
//                         AppColors.primary,
//                       ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 8,
//                         offset: Offset(0, 3),
//                       )
//                     ],
//                   ),
//                   child: Center(
//                     child: isLoading
//                         ? Center(
//                             child: LoadingAnimationWidget.waveDots(
//                               color: AppColors.primary,
//                               size: 60,
//                             ),
//                           )
//                         : const Text(
//                             "Đổi mật khẩu",
//                             style: TextStyle(
//                               color: AppColors.surface,
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
