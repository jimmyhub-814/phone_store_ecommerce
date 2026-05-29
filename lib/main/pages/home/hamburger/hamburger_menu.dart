import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/home/hamburger/account.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/order_info.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:provider/provider.dart';

class HamburgerBar extends StatefulWidget {
  const HamburgerBar({super.key});

  @override
  State<HamburgerBar> createState() => _HamburgerBarState();
}

class _HamburgerBarState extends State<HamburgerBar> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.textSecondary,
        child: Column(
          children: [
            Image.asset(
              'assets/logo/fulllogo1.png',
              height: 180,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: [
                  _menuItem(
                    context,
                    title: "Thông tin đơn hàng",
                    icon: Icons.shopping_bag,
                    onTap: () {
                      Navigator.pushNamed(context, OrderInfoPage.routeName);
                    },
                  ),
                  _menuItem(
                    context,
                    title: "Thông tin cá nhân",
                    icon: Icons.person_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, AccountPage.routeName);
                    },
                  ),
                  _menuItem(
                    context,
                    title: "Trung tâm hỗ trợ",
                    icon: Icons.support_agent_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, "/supportCenter");
                    },
                  ),
                  _menuItem(
                    context,
                    title: "Chính sách quyền riêng tư",
                    icon: Icons.privacy_tip_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, "/policy");
                    },
                  ),
                  _menuItem(
                    context,
                    title: "AI Tư vấn",
                    icon: Icons.smart_toy,
                    onTap: () {
                      Navigator.pushNamed(context, "/chatAI");
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(
                    color: AppColors.surface,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _logoutButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // ICON BOX
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.surface,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // TEXT
                Expanded(
                  child: Text(
                    title,
                    style: AppTextstyles.headingH6.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.surface,
                    ),
                  ),
                ),

                // ARROW (tạo cảm giác chuyên nghiệp)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.surfaceLight,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET LOGOUT
  Widget _logoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Thông báo'),
              content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('HỦY'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Center(
                        child: LoadingAnimationWidget.waveDots(
                          color: AppColors.primary,
                          size: 60,
                        ),
                      ),
                    );

                    await Future.delayed(
                      const Duration(seconds: 2),
                    );

                    Navigator.of(context, rootNavigator: true).pop();
                    await context.read<UserProvider>().signOut();
                  },
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: AppColors.surface),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: const Row(
        children: [
          Icon(Icons.logout_rounded, color: AppColors.surface),
          SizedBox(
            width: 5,
          ),
          Text(
            "Đăng xuất",
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
