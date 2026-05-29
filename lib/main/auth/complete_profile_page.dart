import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/app_constants/storages.dart';
import 'package:phone_store/main/pages/home/mainPage/home_page.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/main/pages/home/shared_widgets/inputForm.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:phone_store/main/auth/login_page.dart' show LoginPage;
import 'package:phone_store/models/user.dart';
import 'package:phone_store/services/notification_service.dart';

class CompleteProfilePage extends StatefulWidget {
  final String userId;
  final String userEmail;
  const CompleteProfilePage(
      {super.key, required this.userId, required this.userEmail});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _genderController = TextEditingController();
  final _phoneController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  String? _pickedImage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ================= DATE PICKER =================
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2002),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ================= SELECT GENDER =================
  Future<void> selectGender(BuildContext context) async {
    final gender = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 15),
            _genderOption(context, "Male"),
            _genderOption(context, "Female"),
            _genderOption(context, "Other"),
          ],
        ),
      ),
    );

    if (gender != null) _genderController.text = gender;
  }

  Widget _genderOption(BuildContext context, String gender) {
    return ListTile(
      title: Text(gender, style: const TextStyle(fontSize: 16)),
      leading: Icon(
        gender == "Male"
            ? Icons.male
            : gender == "Female"
                ? Icons.female
                : Icons.transgender,
        color: Colors.pinkAccent,
      ),
      onTap: () => Navigator.pop(context, gender),
    );
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: AppColors.surface,
          ),
        ],
      );
      if (cropped != null) setState(() => _pickedImage = cropped.path);
    }
  }

  void _chooseImage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            20,
          ),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Take a photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text("Choose from gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= SUBMIT =================
  Future<void> submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your avatar')),
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

      // ================== UPLOAD ẢNH LÊN STORAGE ==================
      final storageRef = Storages.user(userId!);

      await storageRef.putFile(file);
      final userImg = await storageRef.getDownloadURL();

      // ================== LẤY FCM TOKEN ==================
      final token = await NotificationService().getDeviceToken();

      // ================== CHECK USER ĐÃ TỒN TẠI CHƯA ==================
      final userDoc = Collections.user.doc(userId);

      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        // UPDATE
        await userDoc.update({
          UserApp.userNameField: _fullNameController.text.trim(),
          UserApp.userEmailField: widget.userEmail,
          UserApp.userPhoneField: _phoneController.text.trim(),
          UserApp.userDateField: _dateController.text.trim(),
          UserApp.userGenderField: _genderController.text.trim(),
          UserApp.userAvatarField: userImg,
          UserApp.userDeviceTokensField: [token],
          UserApp.isCompletedField: true,
        });
      } else {
        // INSERT
        await userDoc.set({
          UserApp.idField: userId,
          UserApp.userEmailField: widget.userEmail,
          UserApp.userNameField: _fullNameController.text.trim(),
          UserApp.userPhoneField: _phoneController.text.trim(),
          UserApp.userDateField: _dateController.text.trim(),
          UserApp.userGenderField: _genderController.text.trim(),
          UserApp.userAvatarField: userImg,
          UserApp.userDeviceTokensField: [token],
          UserApp.isCompletedField: true,
        });
      }

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile completed successfully!',
            ),
          ),
        );

        Navigator.pushReplacementNamed(context, HomePage.routeName);
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint('COMPLETE PROFILE ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ================= UI =================
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
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

                // AVATAR
                GestureDetector(
                  onTap: _chooseImage,
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

                      IntlPhoneField(
                        controller: _phoneController,
                        decoration: inputDecoration("Phone Number"),
                        initialCountryCode: "VN",
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
                              onTap: _selectDate,
                              validator: (v) =>
                                  v!.isEmpty ? "Select your birthday" : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InputForm(
                              controller: _genderController,
                              hintText: "Gender",
                              icon: Icons.wc_outlined,
                              readOnly: true,
                              onTap: () => selectGender(context),
                              validator: (v) =>
                                  v!.isEmpty ? "Select gender" : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // BEAUTIFUL BUTTON
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
