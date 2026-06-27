import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';

class LoadingService {
  static bool _isShowing = false;

  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Center(
          child: LoadingAnimationWidget.waveDots(
            color: AppColors.primary,
            size: 60,
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (!_isShowing) return;

    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    _isShowing = false;
  }
}
