import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/storages.dart';
import 'package:phone_store/main/auth/login_page.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appbarIcon.dart';
import 'package:phone_store/models/user.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/changePassPage.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/verify_password_page.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:phone_store/main/pages/home/shared_widgets/safeImage.dart';
import 'package:provider/provider.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});
  static const routeName = '/userInfo';

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  bool isGoogle = false;
  final ImagePicker picker = ImagePicker();
  final ValueNotifier<bool> isEditMode = ValueNotifier<bool>(false);

  String? _pickedImage;
  String? userImg;

  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _genderController = TextEditingController();
  final _phoneController = TextEditingController();
  UserApp? user;
  User? currentUser;
  void _fillControllers(UserApp user) {
    _fullNameController.text = user.userName;
    _phoneController.text = user.userPhone;
    _emailController.text = user.userEmail;
    _dateController.text = user.userDate;
    _genderController.text = user.userGender;
  }

  @override
  void initState() {
    super.initState();

    currentUser = AuthHelper.currentUser;
    // Nếu chưa login → về trang login
    if (currentUser == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, LoginPage.routeName);
      });
      return;
    }

    isGoogle = currentUser!.providerData.any(
      (provider) => provider.providerId == "google.com",
    );
  }

  Future<String> uploadAvatar(String filePath) async {
    final ref = Storages.user(currentUser!.uid);
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

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
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 20,
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

  Future<void> updateInfo(UserApp oldInfo) async {
    if (_pickedImage != null) {
      userImg = await uploadAvatar(_pickedImage!);
    }

    final user = UserApp(
        id: currentUser!.uid,
        userName: _fullNameController.text.isEmpty
            ? oldInfo.userName
            : _fullNameController.text,
        userEmail: _emailController.text.isEmpty
            ? oldInfo.userEmail
            : _emailController.text,
        userDate: _dateController.text.isEmpty
            ? oldInfo.userDate
            : _dateController.text,
        userGender: _genderController.text.isEmpty
            ? oldInfo.userGender
            : _genderController.text,
        userAvatar: userImg ?? oldInfo.userAvatar,
        userPhone: _phoneController.text.isEmpty
            ? oldInfo.userPhone
            : _phoneController.text,
        userDeviceTokens: oldInfo.userDeviceTokens,
        isCompleted: oldInfo.isCompleted);

    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .set(user.toMap(), SetOptions(merge: true));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime(2007),
    );
    if (picked != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _dateController.text = formattedDate;
      });
    }
  }

  void changeType(BuildContext context, String type) {
    TextEditingController controller =
        type == 'name' ? _fullNameController : _phoneController;

    TextInputType keyboardType =
        type == 'phone' ? TextInputType.number : TextInputType.text;

    List<TextInputFormatter> inputFormatters = [];
    if (type == 'phone') {
      inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
      inputFormatters.add(LengthLimitingTextInputFormatter(11));
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'name' ? "Cập nhật tên" : "Cập nhật số điện thoại"),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: type == 'name'
                ? "Nhập tên mới..."
                : "Nhập số điện thoại mới...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              if (type == 'phone' &&
                  (controller.text.length < 10 ||
                      controller.text.length > 11)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Số điện thoại không hợp lệ!'),
                  ),
                );
                return;
              }
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void changeGender(BuildContext context) async {
    final gender = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Chọn giới tính',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            _genderOption(context, 'Nam'),
            _genderOption(context, 'Nữ'),
            _genderOption(context, 'Khác'),
          ],
        ),
      ),
    );

    if (gender != null) {
      setState(() {
        _genderController.text = gender;
      });
    }
  }

  Widget _genderOption(BuildContext context, String gender) {
    return InkWell(
      onTap: () => Navigator.pop(context, gender),
      splashColor: AppColors.primary.withValues(alpha: 0.2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        child: Text(
          gender,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    user = context.watch<UserProvider>().user;
    if (user != null && _fullNameController.text.isEmpty) {
      _fillControllers(user!);
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.scaffoldBg, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: AppbarIcon(
          onTap: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: isEditMode,
              builder: (context, edit, _) {
                return IconButton(
                  icon: edit
                      ? const Icon(Icons.done, color: AppColors.surface)
                      : const Icon(
                          Icons.edit,
                          color: AppColors.surface,
                        ),
                  onPressed: () {
                    if (isEditMode.value == true &&
                            _fullNameController.text != user!.userName ||
                        _phoneController.text != user!.userPhone ||
                        _emailController.text != user!.userEmail ||
                        _dateController.text != user!.userDate ||
                        _genderController.text != user!.userGender) {
                      if (edit == true) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: const Text('Lưu thay đổi thông tin?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('HỦY'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                onPressed: () async {
                                  isEditMode.value = !edit;
                                  try {
                                    await updateInfo(user!);
                                    _emailController.clear();
                                    _fullNameController.clear();
                                    _dateController.clear();
                                    _genderController.clear();
                                    _phoneController.clear();

                                    if (mounted)
                                      // ignore: curly_braces_in_flow_control_structures
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Lưu thông tin thành công!',
                                          ),
                                        ),
                                      );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Lưu thông tin thất bại. Vui lòng thử lại sau!',
                                        ),
                                      ),
                                    );
                                    print(e);
                                  }
                                },
                                child: const Text(
                                  'Lưu',
                                  style: TextStyle(color: AppColors.surface),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    } else {
                      isEditMode.value = !edit;
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: user == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: isEditMode,
                    builder: (context, edit, _) {
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              isEditMode.value = !edit;
                              _chooseImage();
                            },
                            child: ClipOval(
                              child: SafeImage(
                                url: _pickedImage ?? user?.userAvatar,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 1,
                            child: Container(
                              height: 25,
                              width: 25,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color: AppColors.surfaceLight,
                                ),
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                    'Họ và tên',
                    _fullNameController.text.isEmpty
                        ? user?.userName ?? ''
                        : _fullNameController.text,
                    Icons.person_outline,
                    onTap: () => changeType(context, 'name'),
                  ),
                  _buildInfoTile(
                    'Giới tính',
                    user!.userGender,
                    Icons.wc,
                    onTap: () => changeGender(context),
                  ),
                  _buildInfoTile(
                    'Ngày sinh',
                    _dateController.text.isEmpty
                        ? user!.userDate
                        : _dateController.text,
                    Icons.cake_outlined,
                    onTap: () => _selectDate(),
                  ),
                  _buildInfoTile(
                    'Số điện thoại',
                    _phoneController.text.isEmpty
                        ? user!.userPhone
                        : _phoneController.text,
                    Icons.phone_android,
                    onTap: () => changeType(context, 'phone'),
                  ),
                  Column(
                    children: [
                      if (!isGoogle) ...[
                        _buildInfoTile(
                          'Email',
                          user!.userEmail,
                          Icons.email_outlined,
                          onTap: () => Navigator.pushNamed(
                              context, VerifyPasswordPage.routeName,
                              arguments:
                                  VerifyPasswordPage(email: user!.userEmail)),
                        ),
                        _buildInfoTile(
                          'Mật khẩu',
                          '********',
                          Icons.lock_outline,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              ChangepassPage.routeName,
                              arguments: ChangepassPage(email: user!.userEmail),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon,
      {VoidCallback? onTap}) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEditMode,
      builder: (context, edit, _) {
        return GestureDetector(
          onTap: edit ? onTap : null,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),

                /// Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (edit) const Icon(Icons.chevron_right, color: Colors.grey)
              ],
            ),
          ),
        );
      },
    );
  }
}
