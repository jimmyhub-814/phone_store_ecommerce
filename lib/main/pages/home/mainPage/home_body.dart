import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/main/pages/home/mainPage/bestSellerItem.dart';
import 'package:phone_store/main/pages/home/mainPage/big_carousel.dart';
import 'package:phone_store/main/pages/home/mainPage/phoneItems.dart';
import 'package:phone_store/main/pages/home/mainPage/searchbar.dart';
import 'package:phone_store/main/pages/home/mainPage/cartPage.dart';
import 'package:phone_store/provider/category_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:provider/provider.dart';

class HomeBody extends StatefulWidget {
  static const routeName = '/homeBody';
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  Future<void> loadData() async {
    context.read<CategoryProvider>().fetchCategoriesList();
    context.read<ProductProvider>().fetchProductsList();
    // context.read<CartProvider>().fetchCartList();
    // context.read<UserProvider>().loadInfo();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                      Scaffold.of(context).openDrawer();
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
                            alpha:
                            0.2,
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, CartPage.routeName);
                      },
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: AppColors.surface,
                        size: 25,
                      ),
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
                  child: PhoneItemsWidget(),
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
                    height: 80,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
