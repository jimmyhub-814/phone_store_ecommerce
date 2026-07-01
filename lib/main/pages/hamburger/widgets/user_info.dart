import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/app_constants/app_utils.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/app_constants/storages.dart';
import 'package:phone_store/main/auth/login.dart';
import 'package:phone_store/models/user.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:phone_store/main/pages/shared_widgets/safe_image.dart';
import 'package:provider/provider.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});
  static const routeName = '/user-info';

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final ImagePicker picker = ImagePicker();
  final ValueNotifier<bool> isEditMode = ValueNotifier<bool>(false);

  String? _pickedImage;
  String? userImg;

  final _userAccountController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _genderController = TextEditingController();

  bool isGoogle = false;
  bool isPhone = false;

  @override
  void initState() {
    super.initState();

    if (AuthHelper.currentUser == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, LoginPage.routeName);
      });
      return;
    }

    isGoogle = AuthHelper.currentUser!.providerData
        .any((p) => p.providerId == 'google.com');
    isPhone = AuthHelper.currentUser!.providerData
        .any((p) => p.providerId == 'phone');
  }

  void _fillControllers(UserApp user) {
    _fullNameController.text = user.userName;
    _userAccountController.text = user.userAccount;
    _dateController.text = user.userDate;
    _genderController.text = user.userGender;
  }

  Future<String> uploadAvatar(String filePath) async {
    final ref = Storages.user(AuthHelper.userId!);
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<void> updateInfo(UserApp oldInfo) async {
    if (_pickedImage != null) {
      userImg = await uploadAvatar(_pickedImage!);
    }

    final user = UserApp(
      id: AuthHelper.userId!,
      userName: _fullNameController.text.isEmpty
          ? oldInfo.userName
          : _fullNameController.text,
      userAccount: _userAccountController.text.isEmpty
          ? oldInfo.userAccount
          : _userAccountController.text,
      userDate: _dateController.text.isEmpty
          ? oldInfo.userDate
          : _dateController.text,
      userGender: _genderController.text.isEmpty
          ? oldInfo.userGender
          : _genderController.text,
      userAvatar: userImg ?? oldInfo.userAvatar,
      userDeviceTokens: oldInfo.userDeviceTokens,
      isCompleted: oldInfo.isCompleted,
      shippingInfo: oldInfo.shippingInfo,
    );

    await Collections.user
        .doc(AuthHelper.userId!)
        .set(user.toMap(), SetOptions(merge: true));

    context.read<UserProvider>().updateLocalUser(user);
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

  void _handleEditToggle(bool edit, UserApp user) {
    final hasChanges = _fullNameController.text != user.userName ||
        _userAccountController.text != user.userAccount ||
        _dateController.text != user.userDate ||
        _genderController.text != user.userGender ||
        _pickedImage != null;

    if (edit && hasChanges) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Lưu thay đổi?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Thông tin của bạn sẽ được cập nhật.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                isEditMode.value = false;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(
                    child: Center(
                      child: LoadingAnimationWidget.waveDots(
                        color: AppColors.primary,
                        size: 60,
                      ),
                    ),
                  ),
                );

                try {
                  await updateInfo(user);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.surface),
                          SizedBox(width: 8),
                          Text('Lưu thông tin thành công!'),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$e'),
                    ),
                  );
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
    } else {
      isEditMode.value = !edit;
    }
  }

  void changeType(BuildContext context, String type) {
    TextEditingController controller;
    String title;
    String hintText;
    if (type == 'name') {
      controller = _fullNameController;
      title = "Cập nhật tên";
      hintText = "Nhập tên mới...";
    } else {
      controller = _userAccountController;
      title = "Cập nhật số điện thoại";
      hintText = "Nhập số điện thoại mới...";
    }

    List<TextInputFormatter> inputFormatters = [];
    if (type == 'phone') {
      inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
      inputFormatters.add(LengthLimitingTextInputFormatter(11));
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      type == 'phone'
                          ? Icons.phone_outlined
                          : Icons.badge_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Vui lòng nhập thông tin";
                      }
                      Navigator.pop(context);
                      return null;
                    },
                    controller: controller,
                    style: AppTextstyles.headingH6
                        .copyWith(color: AppColors.surface),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: AppTextstyles.headingH6.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.8),
                      ),
                      filled: true,
                      fillColor: AppColors.surface.withValues(alpha: 0.08),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.text.isEmpty) {
                          AppUtils.showMessage(
                            context,
                            'Vui lòng nhập thông tin!',
                          );
                          return;
                        }
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Huỷ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
            const Divider(height: 1, color: AppColors.lightBorder),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Consumer<UserProvider>(builder: (context, provider, child) {
        final user = provider.user;
        if (user != null && _fullNameController.text.isEmpty) {
          _fillControllers(user);
        }

        return CustomScrollView(
          slivers: [
            _buildSliverAppBar(user!),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildInfoSection(user),
                  _buildAccountSection(user),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      }),
    );
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

  Widget _buildSliverAppBar(UserApp user) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -30,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 40,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Center(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isEditMode,
                    builder: (context, edit, _) {
                      return GestureDetector(
                        onTap: edit
                            ? () async {
                                final image =
                                    await AppUtils.chooseImage(context, picker);
                                if (image != null) {
                                  setState(() => _pickedImage = image);
                                }
                              }
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 45,
                            ),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surface
                                          .withValues(alpha: 0.9),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.5),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: SafeImage(
                                      url: _pickedImage ?? user.userAvatar,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (edit)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.surface,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: AppColors.surface,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      AppColors.surface.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fingerprint_rounded,
                                    size: 12,
                                    color: AppColors.surface
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${AuthHelper.userId?.substring(0, 8) ?? '—'}...',
                                    style: TextStyle(
                                      color: AppColors.surface
                                          .withValues(alpha: 0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1A1A2E),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.surface,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Thông tin cá nhân',
        style: TextStyle(
          color: AppColors.surface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: isEditMode,
          builder: (context, edit, _) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _handleEditToggle(edit, user),
                icon: Icon(
                  edit ? Icons.check_rounded : Icons.edit_outlined,
                  color: AppColors.surface,
                  size: 16,
                ),
                label: Text(
                  edit ? 'Lưu' : 'Sửa',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surface.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoSection(UserApp user) {
    return _buildCard(
      title: 'Thông tin cá nhân',
      icon: Icons.person_outline,
      children: [
        _buildInfoTile(
          'Họ và tên',
          _fullNameController.text.isNotEmpty
              ? _fullNameController.text
              : user.userName,
          Icons.badge_outlined,
          onTap: () => changeType(context, 'name'),
        ),
        _buildDivider(),
        _buildInfoTile(
            'Giới tính',
            _genderController.text.isNotEmpty
                ? _genderController.text
                : user.userGender,
            Icons.wc_outlined,
            onTap: () => changeGender(context)),
        _buildDivider(),
        _buildInfoTile(
            'Ngày sinh',
            _dateController.text.isNotEmpty
                ? _dateController.text
                : user.userDate,
            Icons.cake_outlined,
            onTap: () => _selectDate()),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, indent: 56, endIndent: 0, thickness: 0.5);

  Widget _buildInfoTile(String title, String value, IconData icon,
      {VoidCallback? onTap}) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEditMode,
      builder: (context, edit, _) {
        return InkWell(
          onTap: edit ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value.isEmpty ? '—' : value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: value.isEmpty
                              ? Colors.grey.shade400
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
                if (edit)
                  if (onTap != null)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountSection(UserApp user) {
    return _buildCard(
      title: 'Tài khoản & Bảo mật',
      icon: Icons.shield_outlined,
      children: [
        _buildInfoTile(
          isPhone ? 'Số điện thoại' : 'Email',
          user.userAccount,
          isPhone ? Icons.phone : Icons.email_outlined,
          onTap: null,
        ),
      ],
    );
  }
}
