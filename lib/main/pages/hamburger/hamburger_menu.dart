import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/auth/logout.dart';
import 'package:phone_store/main/pages/hamburger/account.dart';
import 'package:phone_store/main/pages/hamburger/support.dart';
import 'package:phone_store/main/pages/hamburger/widgets/chat_with_AI.dart';
import 'package:phone_store/main/pages/notification/notification.dart';

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
                    title: "Thông tin cá nhân",
                    icon: Icons.person_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, AccountPage.routeName);
                    },
                  ),
                  _menuItem(
                    context,
                    title: "Thông báo",
                    icon: Icons.message_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, NotificationPage.routeName);
                    },
                  ),
                  _menuItem(
                    context,
                    title: "AI Tư vấn",
                    icon: Icons.smart_toy,
                    onTap: () {
                      Navigator.pushNamed(context, ChatAI.routeName);
                    },
                  ),
                  _menuItem(
                    context,
                    title: "Trung tâm hỗ trợ",
                    icon: Icons.support_agent_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, SupportCenterPage.routeName);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(
                    color: AppColors.surface,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.black.withValues(alpha: 0.6),
                        builder: (_) => const LogOutDialog(),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
}
