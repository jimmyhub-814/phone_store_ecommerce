import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/main/pages/hamburger/widgets/policy.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/app_constants/app_utils.dart';

class SupportCenterPage extends StatelessWidget {
  static const routeName = "/support-center";
  
  const SupportCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppbarIcon(),
        title: const Text(
          "Trung tâm hỗ trợ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Bạn cần hỗ trợ điều gì?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Chúng tôi luôn sẵn sàng hỗ trợ bạn 24/7.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 25),
          _supportItem(
            icon: Icons.phone_in_talk_rounded,
            title: "Hotline hỗ trợ",
            subtitle: "Gọi ngay để được hỗ trợ trực tiếp",
            color: Colors.redAccent,
            onTap: () => AppUtils.openLink("tel:0852711187"),
          ),
          _supportItem(
            icon: Icons.perm_phone_msg_sharp,
            title: "Hỗ trợ qua Zalo",
            subtitle: "Trò chuyện nhanh chóng & tiện lợi",
            color: Colors.blueAccent,
            onTap: () => AppUtils.openLink("https://zalo.me/0852711187"),
          ),
          _supportItem(
            icon: Icons.email_rounded,
            title: "Email hỗ trợ",
            subtitle: "Gửi phản hồi hoặc báo lỗi",
            color: Colors.orange,
            onTap: () => AppUtils.openLink("mailto:support@dmcompany.com"),
          ),
          SizedBox(
            height: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PolicyPage(content: 'policy'),
                      ),
                    );
                  },
                  child: const Text(
                    'Chính sách bảo mật',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
                const VerticalDivider(
                  thickness: 1,
                  color: AppColors.primary,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PolicyPage(content: 'terms'),
                      ),
                    );
                  },
                  child: const Text(
                    'Điều khoản sử dụng',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withValues(alpha: 0.05),
                offset: const Offset(0, 4),
                blurRadius: 8,
              )
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
