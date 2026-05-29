import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/main/pages/home/fav/favorite.dart';
import 'package:phone_store/main/pages/home/hamburger/hamburger_menu.dart';
import 'package:phone_store/main/pages/home/mainPage/home_body.dart';
import 'package:phone_store/main/pages/home/noti/notification.dart';
import 'package:phone_store/provider/category_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/homePage';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPage = 0;

  final List<Widget> screens = const [
    HomeBody(),
    FavoritePage(),
    NotificationPage(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadData());
  }

  bool _isLoadingData = false;

  Future<void> loadData({bool isRefresh = false}) async {
    if (_isLoadingData) return;
    _isLoadingData = true;

    final categoryProvider = context.read<CategoryProvider>();

    final productProvider = context.read<ProductProvider>();

    await Future.wait([
      categoryProvider.fetchCategoriesList(),
      productProvider.fetchProductsList(),
    ]);

    if (isRefresh) {
      await Future.delayed(
        const Duration(
          milliseconds: 1500,
        ),
      );
    }

    _isLoadingData = false;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProductProvider>().isLoading;
    if (isLoading && _currentPage == 0) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: LoadingAnimationWidget.waveDots(
            color: AppColors.primary,
            size: 60,
          ),
        ),
      );
    } else {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        strokeWidth: 4,
        onRefresh: () => loadData(isRefresh: true),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          resizeToAvoidBottomInset: false,
          drawer: const HamburgerBar(),
          body: Stack(
            children: [
              IndexedStack(
                index: _currentPage,
                children: screens,
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: FloatingBottomBar(
                  currentIndex: _currentPage,
                  onTap: (index) {
                    setState(() => _currentPage = index);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomItem({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        child: AnimatedScale(
          scale: selected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Icon(
            icon,
            size: selected ? 26 : 24,
            color: selected ? AppColors.primary : AppColors.scaffoldBg,
          ),
        ),
      ),
    );
  }
}

class FloatingBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            icon: Icons.home,
            index: 0,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _BottomItem(
            icon: Icons.favorite,
            index: 1,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _BottomItem(
            icon: Icons.notifications,
            index: 2,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
