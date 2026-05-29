import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/main/pages/home/hamburger/permission/policy_home_page.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';

class PolicyHomePage extends StatelessWidget {
  const PolicyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        leading: AppbarIcon(),
        title: const Text(
          'Chính sách & Điều khoản',
          style: TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPolicyCard(
              context,
              title: "Chính sách bảo mật",
              subtitle: "Cách chúng tôi thu thập và bảo vệ dữ liệu",
              icon: Icons.privacy_tip_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PolicyPage(content: 'policy'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPolicyCard(
              context,
              title: "Điều khoản sử dụng",
              subtitle: "Quy định khi dùng ứng dụng Phone Store",
              icon: Icons.description_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PolicyPage(content: 'terms'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 3),
              color: Colors.black.withValues(alpha: 0.07),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.blueAccent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
