// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:phone_store/app_constants/app_colors.dart';
// import 'package:phone_store/app_constants/auth_helper.dart';
// import 'package:phone_store/main/pages/home/shared_widgets/inputForm.dart';

// class EnterNewEmail extends StatefulWidget {
//   final String email;
//   final String pass;
//   static const routeName = '/enterNewEmail';
//   const EnterNewEmail({super.key, required this.email, required this.pass});

//   @override
//   State<EnterNewEmail> createState() => _EnterNewEmailState();
// }

// class _EnterNewEmailState extends State<EnterNewEmail> {
//   TextEditingController emailController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     final user = AuthHelper.userId;

//     Future<String?> updateEmailFirebase(String newEmail) async {
//       try {
//         final user = AuthHelper.currentUser!;
//         final cred = EmailAuthProvider.credential(
//           email: user.email!,
//           password: widget.pass,
//         );
//         await user.reauthenticateWithCredential(cred);
//         await user.updateEmail(newEmail);

//         await user.reload();
//         return null; // thành công
//       } catch (e) {
//         print("Update Email Error: $e");
//         return e.toString(); // trả lỗi về cho UI
//       }
//     }

//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: AppColors.surface,
//         centerTitle: true,
//         title: const Text(
//           "Change Email",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: AppColors.primary,
//           ),
//         ),
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(
//             Icons.keyboard_backspace_rounded,
//             color: AppColors.primary,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Enter your new email address",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               InputForm(
//                 icon: Icons.email_outlined,
//                 controller: emailController,
//                 obscureText: false,
//                 hintText: 'New Email',
//               ),
//               const SizedBox(height: 30),
//               SizedBox(
//                 width: double.infinity,
//                 height: 55,
//                 child: ElevatedButton(
//                   onPressed: () async {
//                     FocusScope.of(context).unfocus();
//                     if (emailController.text == widget.email) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Email trùng khớp với email hiện tại!'),
//                         ),
//                       );
//                       return;
//                     }

//                     final error =
//                         await updateEmailFirebase(emailController.text.trim());

//                     if (error != null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('Lỗi cập nhật email: $error'),
//                         ),
//                       );
//                       return;
//                     }

//                     await FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(user)
//                         .update({'userEmail': emailController.text.trim()});

//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Đổi email thành công!')),
//                       );
//                     }

//                     Navigator.pop(context);
//                     return;
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(18),
//                     ),
//                   ),
//                   child: const Text(
//                     "Continue",
//                     style: TextStyle(
//                       color: AppColors.surface,
//                       fontSize: 19,
//                       fontWeight: FontWeight.bold,
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
