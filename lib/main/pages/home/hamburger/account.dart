import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/main/auth/link_phone.dart';
import 'package:phone_store/main/auth/login_page.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/models/user.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/order_status.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/user_info.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:phone_store/main/pages/home/shared_widgets/safeImage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  static const routeName = '/account';
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final currentUser = AuthHelper.currentUser;
  late Future<UserApp?> userFuture;
  @override
  void initState() {
    super.initState();
    userFuture = context.read<UserProvider>().getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Tài khoản",
          style: TextStyle(color: AppColors.surface),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: AppbarIcon(),
      ),
      body: FutureBuilder<UserApp?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 60,
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(
              child: Text('Không có dữ liệu người dùng'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.userName,
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              user.userEmail,
                              style: TextStyle(
                                color:
                                    AppColors.surface.withValues(alpha: 0.75),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ClipOval(
                        child: SafeImage(
                          url: user.userAvatar,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildItem(
                        icon: Icons.account_circle,
                        title: 'Quản lý tài khoản',
                        onTap: () => Navigator.pushNamed(
                            context, UserInfoPage.routeName),
                      ),
                      _divider(),
                      _buildItem(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Đơn hàng đã mua',
                        onTap: () => Navigator.pushNamed(
                          context,
                          OrderStatusPage.routeName,
                          arguments: const OrderStatusPage(index: 3),
                        ),
                      ),
                      _divider(),
                      _buildItem(
                        icon: Icons.star_rate_rounded,
                        title: 'Đánh giá sản phẩm',
                        onTap: () => Navigator.pushNamed(
                          context,
                          OrderStatusPage.routeName,
                          arguments: const OrderStatusPage(index: 4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Thông báo'),
                        content: const Text(
                            'Bạn có chắc chắn muốn đăng xuất không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('HỦY'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'ĐĂNG XUẤT',
                              style: TextStyle(
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
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
                        const Duration(
                          seconds: 1,
                        ),
                      );

                      if (!mounted) return;

                      Navigator.of(context, rootNavigator: true).pop();
                      await context.read<UserProvider>().signOut();

                      if (!mounted) return;

                      Navigator.of(context).pushNamedAndRemoveUntil(
                          LoginPage.routeName, (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryDark),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: AppColors.border,
      );
}
