import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';

import 'package:phone_store/main/pages/shared_widgets/custom_card.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/services/recommendation_product_service.dart';
import 'package:provider/provider.dart';

class CategoryPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  const CategoryPage(
      {super.key, required this.categoryId, required this.categoryName});
  static const routeName = "/category";
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final recommendationService = RecommendationService();
    await recommendationService.trackView(
      AuthHelper.userId!,
      null,
      widget.categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: AppbarIcon(),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: AppColors.primary,
          ),
        ),
      ),
      body: FutureBuilder(
        future: context
            .read<ProductProvider>()
            .getProductsInCategory(widget.categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: AppColors.surface,
              body: Center(
                child: LoadingAnimationWidget.waveDots(
                  color: AppColors.primary,
                  size: 60,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No categories available',
                style: TextStyle(color: AppColors.iconDisabled),
              ),
            );
          } else {
            final products = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              itemCount: products.length,
              itemBuilder: (BuildContext context, int index) {
                return CustomCard(
                  product: products[index],
                );
              },
            );
          }
        },
      ),
    );
  }
}
