import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
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
      child: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.textSecondary,
                  AppColors.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    "DM",
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.pink[400],
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Sniglet',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Mobile",
                  style: TextStyle(
                    fontSize: 28,
                    letterSpacing: 1.0,
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sniglet',
                  ),
                ),
              ],
            ),
          ),

          // MENU ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              children: [
                _menuItem(
                  context,
                  title: "Trang chủ",
                  icon: Icons.home_rounded,
                  color: Colors.teal,
                  onTap: () => Scaffold.of(context).closeDrawer(),
                ),
                _menuItem(
                  context,
                  title: "Thông tin đơn hàng",
                  icon: Icons.receipt_long_rounded,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pushNamed(context, OrderInfoPage.routeName);
                  },
                ),
                _menuItem(
                  context,
                  title: "Thông tin cá nhân",
                  icon: Icons.person_rounded,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pushNamed(context, AccountPage.routeName);
                  },
                ),
                // ⭐ THÊM TRUNG TÂM HỖ TRỢ
                _menuItem(
                  context,
                  title: "Trung tâm hỗ trợ",
                  icon: Icons.help_center_rounded,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pushNamed(context, "/supportCenter");
                  },
                ),

                // ⭐ THÊM CHÍNH SÁCH QUYỀN RIÊNG TƯ
                _menuItem(
                  context,
                  title: "Chính sách quyền riêng tư",
                  icon: Icons.privacy_tip_rounded,
                  color: Colors.green,
                  onTap: () {
                    Navigator.pushNamed(context, "/policy");
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // LOGOUT
                _logoutButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET MENU
  Widget _menuItem(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // WIDGET LOGOUT
  Widget _logoutButton(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.withValues(alpha: 0.12),
        child: const Icon(Icons.logout_rounded, color: Colors.red),
      ),
      title: const Text(
        "Đăng xuất",
        style: TextStyle(
          color: Colors.red,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
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
                    Navigator.of(dialogContext).pop(); // đóng dialog confirm

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
                      const Duration(seconds: 1),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
