import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/cubit/conversation_cubit.dart';
import 'package:phone_store/main/pages/hamburger/hamburger_menu.dart';
import 'package:phone_store/main/pages/hamburger/widgets/chat_with_seller.dart';
import 'package:phone_store/main/pages/mainPage/best_seller_item.dart';
import 'package:phone_store/main/pages/mainPage/big_carousel.dart';
import 'package:phone_store/main/pages/mainPage/cart_page.dart';
import 'package:phone_store/main/pages/mainPage/category_item.dart';
import 'package:phone_store/main/pages/mainPage/search_bar.dart';
import 'package:phone_store/models/conversation.dart';
import 'package:phone_store/provider/category_provider.dart';
import 'package:phone_store/provider/product_provider.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home-screen';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _dismissAllLoadings();
      loadData();
    });
  }

  void _dismissAllLoadings() {
    final navigator = Navigator.of(context, rootNavigator: true);
    while (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> loadData({bool isRefresh = false}) async {
    final productProvider = context.read<ProductProvider>();
    final conversationCubit = context.read<ConversationCubit>();
    conversationCubit.init();

    productProvider.resetRecommendations();

    await productProvider.fetchProductsList(forceRefresh: isRefresh);

    if (!mounted) return;

    context.read<CategoryProvider>().fetchCategoriesList();
    await productProvider.loadRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      strokeWidth: 4,
      onRefresh: () => loadData(isRefresh: true),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.textSecondary, AppColors.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.1, 0.4],
              ),
            ),
          ),
          Scaffold(
            drawer: const HamburgerBar(),
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 80,
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          color: AppColors.surface.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.surface.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.menu_open_outlined,
                              color: AppColors.surface,
                              size: 18,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Menu',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, CartPage.routeName);
                            },
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              color: AppColors.surface,
                              size: 22,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              final ref = Collections.conversations
                                  .doc(AuthHelper.userId!);

                              ref.update(
                                {
                                  '${Conversation.unreadCountField}.${UnreadCountBy.user.name}':
                                      0,
                                },
                              );

                              Navigator.pushNamed(
                                  context, MessagePage.routeName);
                            },
                            child: BlocBuilder<ConversationCubit,
                                ConversationState>(
                              builder: (context, state) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_rounded,
                                      color: AppColors.surface,
                                      size: 22,
                                    ),
                                    if (state.unreadCount > 0)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            state.unreadCount < 9
                                                ? state.unreadCount.toString()
                                                : '9+',
                                            textAlign: TextAlign.center,
                                            style: AppTextstyles.extraSmallText
                                                .copyWith(
                                              color: AppColors.surface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 8,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 10,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: SearchBarWidget()),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: BigCarouselWidget()),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: CategoryItem(),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: BestSellerItem(),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
