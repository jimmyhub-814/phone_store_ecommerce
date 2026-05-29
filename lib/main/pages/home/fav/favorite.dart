import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/home/shared_widgets/customCard.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/provider/favorite_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:provider/provider.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: const Icon(
                Icons.menu_open_outlined,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            const Text(
              'Yêu thích',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, provider, child) {
          return FutureBuilder<List<Product>>(
            future: provider.loadFavoriteProducts(
                provider.favorite, products),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: LoadingAnimationWidget.waveDots(
                    color: AppColors.primary,
                    size: 60,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.heart_broken,
                        color: AppColors.iconDisabled,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có sản phẩm nào được yêu thích!',
                        style: AppTextstyles.headingH6.copyWith(
                          color: AppColors.iconDisabled,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final products = snapshot.data!;
              return provider.favorite.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 10,
                        bottom: 100,
                      ),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Dismissible(
                          onDismissed: (direction) =>
                              provider.toggleFavorite(product.id),
                          key: ValueKey(product.id),
                          child: CustomCard(product: product),
                        );
                      },
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.heart_broken,
                              color: AppColors.iconPrimary,
                              size: 80,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có sản phẩm nào được yêu thích!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
            },
          );
        },
      ),
    );
  }
}
