import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/main/pages/order/order_detail.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/models/notifications.dart';
import 'package:phone_store/provider/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class NotificationPage extends StatefulWidget {
  static const routeName = '/notification-page';
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with TickerProviderStateMixin {
  final Map<int, bool> expandedGroups = {};
  Stream<List<NotificationModel>>? _notificationStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notiProvider = context.read<NotificationProvider>();

      _notificationStream = notiProvider.getNotificationList();
      setState(() {});
    });
  }

  String formatSmartTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final timeFormatter = DateFormat('HH:mm');

    if (now.day == date.day &&
        now.month == date.month &&
        now.year == date.year) {
      return "Hôm nay ${timeFormatter.format(date)}";
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == date.day &&
        yesterday.month == date.month &&
        yesterday.year == date.year) {
      return "Hôm qua ${timeFormatter.format(date)}";
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        centerTitle: true,
        shadowColor: Colors.black12,
        leading: AppbarIcon(),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
      ),
      body: _notificationStream == null
          ? Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 60,
              ),
            )
          : StreamBuilder<List<NotificationModel>>(
              stream: _notificationStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (!snapshot.hasData) {
                  return _buildEmptyState();
                }

                final notifications = snapshot.data!;
                notifications.removeWhere(
                  (e) => e.notificationList.isEmpty,
                );

                for (var item in notifications) {
                  item.notificationList.sort(
                    (a, b) => b.timestamp.compareTo(a.timestamp),
                  );
                }

                notifications.sort((a, b) {
                  final aList = a.notificationList;
                  final bList = b.notificationList;

                  if (aList.isEmpty && bList.isEmpty) return 0;
                  if (aList.isEmpty) return 1;
                  if (bList.isEmpty) return -1;

                  return bList.first.timestamp.compareTo(
                    aList.first.timestamp,
                  );
                });

                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 100,
                    top: 2,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, groupIndex) {
                    final group = notifications[groupIndex];
                    final isExpanded = expandedGroups[groupIndex] ?? false;

                    return _buildNotiCard(
                      groupIndex,
                      group.notificationList,
                      isExpanded,
                      group.read,
                      group.id,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_rounded,
              color: AppColors.primaryDark,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Bạn chưa có bất kỳ thông báo nào!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.iconDisabled,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: AppColors.surface,
                    ),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 200, color: AppColors.surface),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 100, color: AppColors.surface),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotiCard(int index, List<NotificationList> list, bool isExpanded,
      bool read, String orderId) {
    if (list.isEmpty) return const SizedBox.shrink();

    final firstNoti = list.first;
    final others = list.skip(1).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: read
              ? Colors.transparent
              : AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!read) {
                        context
                            .read<NotificationProvider>()
                            .readNotification(orderId);
                      }
                      Navigator.pushNamed(
                        context,
                        DetailOrder.routeName,
                        arguments: DetailOrder(orderId: orderId),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: read
                                  ? Colors.grey.shade100
                                  : AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              read
                                  ? Icons.notifications_none_rounded
                                  : Icons.notifications_active_rounded,
                              color: read ? Colors.grey : AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firstNoti.title,
                                  style: TextStyle(
                                    fontWeight: read
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  firstNoti.body,
                                  maxLines: isExpanded ? null : 1,
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatSmartTime(firstNoti.timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!read) {
                      context
                          .read<NotificationProvider>()
                          .readNotification(orderId);
                    }
                    setState(() => expandedGroups[index] = !isExpanded);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded && others.isNotEmpty) ...[
            Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey.shade100,
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(
              height: 10,
            ),
            ...others.map((noti) => _buildSubNotiItem(noti, orderId)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubNotiItem(NotificationList noti, String orderId) {
    return Container(
      margin: const EdgeInsets.only(left: 50, right: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          DetailOrder.routeName,
          arguments: DetailOrder(
            orderId: orderId,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              noti.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              noti.body,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              formatSmartTime(noti.timestamp),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
