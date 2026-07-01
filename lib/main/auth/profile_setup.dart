import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_utils.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/app_constants/storages.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/main/pages/shared_widgets/input_form.dart';
import 'package:phone_store/main/auth/login.dart';
import 'package:phone_store/models/user.dart';
import 'package:phone_store/services/notification_service.dart';

class ProfileSetup extends StatefulWidget {
  static const routeName = 'profile-setup';
  
  final String userId;
  final String? userAccount;

  const ProfileSetup({
    super.key,
    required this.userId,
    this.userAccount,
  });

  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _genderController = TextEditingController();
  User? currentUser;
  final ImagePicker picker = ImagePicker();
  String? _pickedImage;
  bool isGoogle = false;
  bool isPhone = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    currentUser = AuthHelper.currentUser;
    if (currentUser == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, LoginPage.routeName);
      });
      return;
    }

    isGoogle =
        currentUser!.providerData.any((p) => p.providerId == 'google.com');
    isPhone = currentUser!.providerData.any((p) => p.providerId == 'phone');
  }

  Future<void> submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your avatar'),
        ),
      );
      return;
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: LoadingAnimationWidget.waveDots(
            color: AppColors.primary,
            size: 60,
          ),
        ),
      ),
    );

    try {
      final userId = AuthHelper.userId;
      final file = File(_pickedImage!);

      final storageRef = Storages.user(userId!);

      await storageRef.putFile(file);
      final userImg = await storageRef.getDownloadURL();

      final token = await NotificationService().getDeviceToken();

      final userDoc = Collections.user.doc(userId);

      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        await userDoc.update({
          UserApp.idField: userId,
          UserApp.userNameField: _fullNameController.text.trim(),
          UserApp.userAccountField: widget.userAccount ?? '',
          UserApp.userDateField: _dateController.text.trim(),
          UserApp.userGenderField: _genderController.text.trim(),
          UserApp.userAvatarField: userImg,
          UserApp.userDeviceTokensField: [token],
          UserApp.isCompletedField: true,
        });
      } else {
        await userDoc.set({
          UserApp.idField: userId,
          UserApp.userAccountField: widget.userAccount ?? '',
          UserApp.userNameField: _fullNameController.text.trim(),
          UserApp.userDateField: _dateController.text.trim(),
          UserApp.userGenderField: _genderController.text.trim(),
          UserApp.userAvatarField: userImg,
          UserApp.userDeviceTokensField: [token],
          UserApp.isCompletedField: true,
        });
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile completed successfully!',
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('COMPLETE PROFILE ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: AppbarIcon(
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            await GoogleSignIn().signOut();
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 10,
            ),
            child: Column(
              children: [
                const Text(
                  "Complete Your Profile",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tell us a bit more about you so we can\npersonalize your experience.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () async {
                    final image = await AppUtils.chooseImage(context, picker);
                    if (image != null) {
                      setState(() => _pickedImage = image);
                    }
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.surface,
                      backgroundImage: _pickedImage != null
                          ? FileImage(
                              File(_pickedImage!),
                            )
                          : null,
                      child: _pickedImage == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      InputForm(
                        controller: _fullNameController,
                        hintText: "Full Name",
                        icon: Icons.person_outline,
                        validator: (v) =>
                            v!.isEmpty ? "Please enter your full name" : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InputForm(
                                controller: _dateController,
                                hintText: "Birth Date",
                                icon: Icons.calendar_month_outlined,
                                readOnly: true,
                                onTap: () async {
                                  String picked =
                                      await AppUtils.selectDate(context);

                                  setState(() {
                                    _dateController.text = picked;
                                  });
                                }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InputForm(
                              controller: _genderController,
                              hintText: "Gender",
                              icon: Icons.wc_outlined,
                              readOnly: true,
                              onTap: () async {
                                final gender =
                                    await AppUtils.selectGender(context);
                                if (gender != null) {
                                  setState(() {
                                    _genderController.text = gender;
                                  });
                                }
                              },
                              validator: (v) =>
                                  v!.isEmpty ? "Select gender" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: submitProfile,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ).copyWith(
                            backgroundColor:
                                WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.surfaceSecondary,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "Complete Profile",
                                style: TextStyle(
                                  color: AppColors.surface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
