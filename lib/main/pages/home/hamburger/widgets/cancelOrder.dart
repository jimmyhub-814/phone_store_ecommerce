import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';

class CancelOrderPage extends StatelessWidget {
  const CancelOrderPage({super.key});
  static const routeName = '/cancelOrder';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: AppbarIcon(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Success đẹp
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha:0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.done_rounded,
                  size: 75,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Tiêu đề
              const Text(
                'Hủy đơn thành công',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Mô tả
              Text(
                'Đơn hàng của bạn đã được hủy. Chúng tôi luôn sẵn sàng hỗ trợ nếu bạn cần thêm thông tin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 35),

              // Button quay lại
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Quay lại",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
