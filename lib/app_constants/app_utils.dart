import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phone_store/app_constants/app_colors.dart';

class AppUtils {
  const AppUtils._();
  static void showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  static String formatPhone(String input) {
    String digits = input.trim();

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '+84$digits';
  }

  static void hideLoading(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static Future<String> selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2002),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Select your birth date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      fieldLabelText: 'Birth date',
      fieldHintText: 'Choose your date of birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    return DateFormat('yyyy-MM-dd').format(picked!);
  }

  static Future<String?> selectGender(BuildContext context) async {
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
    return gender; 
  }

  static Widget _genderOption(BuildContext context, String gender) {
    final icon = gender == "Male"
        ? Icons.male
        : gender == "Female"
            ? Icons.female
            : Icons.transgender;

    return InkWell(
      onTap: () => Navigator.pop(context, gender),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              gender,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  static Future<String?> pickImage(
      ImageSource source, ImagePicker picker) async {
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

      return cropped!.path;
    }
    return null;
  }

  static String mapErrorMessage(String code) {
    return switch (code) {
      'invalid-verification-code' => 'Mã OTP không đúng',
      'session-expired' => 'Mã OTP đã hết hạn, vui lòng gửi lại',
      'too-many-requests' => 'Thử lại sau vài phút',
      _ => 'Đã có lỗi xảy ra',
    };
  }

  static Future<String?> chooseImage(
      BuildContext context, ImagePicker picker) async {
    return await showModalBottomSheet(
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
              onTap: () async {
                final image = await pickImage(ImageSource.camera, picker);

                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text("Choose from gallery"),
              onTap: () async {
                final image = await pickImage(ImageSource.gallery, picker);

                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
