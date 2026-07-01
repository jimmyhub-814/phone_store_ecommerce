import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/main/pages/order/change_shipping_info.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/models/user.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:provider/provider.dart';

class ShippingInfoScreen extends StatefulWidget {
  static const String routeName = '/shipping-info';

  const ShippingInfoScreen({super.key});

  @override
  State<ShippingInfoScreen> createState() => _ShippingInfoScreenState();
}

class _ShippingInfoScreenState extends State<ShippingInfoScreen> {
  late TextEditingController addressController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  FocusNode? addressFocusNode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppbarIcon(),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Chọn địa chỉ nhận hàng',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
          ),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          List<ShippingInfo>? shippingInfoList = provider.user?.shippingInfo;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: shippingInfoList != null && shippingInfoList.isNotEmpty
                ? ListView.builder(
                    itemCount: shippingInfoList.length,
                    itemBuilder: (BuildContext context, int index) {
                      ShippingInfo item = shippingInfoList[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded,
                                            color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Xóa địa chỉ'),
                                      ],
                                    ),
                                    content: const Text(
                                      'Bạn có chắc chắn muốn xóa địa chỉ này không?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) async {
                            await context
                                .read<UserProvider>()
                                .deleteShippingInfo(item.id);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    color: Colors.white, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'Xóa',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: index == 0
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: index == 0 ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => context
                                      .read<UserProvider>()
                                      .setDefaultShippingInfo(item.id),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == 0
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: index == 0
                                            ? AppColors.primary
                                            : Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: index == 0
                                        ? const Icon(Icons.check,
                                            size: 14, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      context
                                          .read<UserProvider>()
                                          .setDefaultShippingInfo(item.id);
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            color: AppColors.primary
                                                .withValues(alpha: .08),
                                          ),
                                          child: const Icon(
                                            Icons.location_on_rounded,
                                            color: AppColors.primary,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      item.fullName,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (index == 0) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary
                                                            .withValues(
                                                                alpha: .1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: const Text(
                                                        'Mặc định',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                item.phone,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                item.address,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  height: 1.45,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              ChangeOrderInfo.routeName,
                                              arguments: ChangeOrderInfo(
                                                id: item.id,
                                                userName: item.fullName,
                                                userPhone: item.phone,
                                                userAddress: item.address,
                                              ),
                                            );
                                          },
                                          icon: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: .08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'Chưa có địa chỉ nhận hàng nào!',
                    ),
                  ),
          );
        },
      ),
      floatingActionButton: Consumer<UserProvider>(
        builder: (context, provider, child) {
          List<ShippingInfo>? shippingInfoList = provider.user?.shippingInfo;
          return FloatingActionButton.extended(
            onPressed: shippingInfoList?.length == 10
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đã đạt giới hạn 10 địa chỉ giao hàng.',
                        ),
                      ),
                    )
                : () {
                    Navigator.pushNamed(
                      context,
                      ChangeOrderInfo.routeName,
                    );
                  },
            elevation: 0,
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            icon: const Icon(
              Icons.add,
              color: AppColors.surface,
            ),
            label: const Text(
              "Địa chỉ mới",
              style: TextStyle(
                color: AppColors.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
