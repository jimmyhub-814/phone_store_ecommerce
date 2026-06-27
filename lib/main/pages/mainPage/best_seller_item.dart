import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/main/pages/shared_widgets/custom_card.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class BestSellerItem extends StatefulWidget {
  const BestSellerItem({super.key});

  @override
  State<BestSellerItem> createState() => _BestSellerItemState();
}

class _BestSellerItemState extends State<BestSellerItem> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());
  }

  void _tryLoad() {
    if (!mounted) return;
    final provider = context.read<ProductProvider>();

    if (provider.isLoading) { 
      void listener() {
        if (!provider.isLoading && provider.products.isNotEmpty) {
          provider.loadRecommendations();
          provider.removeListener(listener);
        }
      }

      provider.addListener(listener);
    } else if (provider.products.isNotEmpty) {
      provider.loadRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dành riêng cho bạn',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Consumer<ProductProvider>(
          builder: (context, provider, child) { 
            if (!provider.isLoading &&
                provider.products.isNotEmpty &&
                provider.recommendedProducts == provider.products) { 
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.loadRecommendations();
              });
            }

            if (provider.isLoading || provider.products.isEmpty) {
              return _buildShimmer();
            }

            final products = provider.recommendedProducts;
            print('products: ${provider.products.length}');
            print('recommended: ${provider.recommendedProducts.length}');
            return Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) =>
                      CustomCard(product: products[index]),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Center(
                  child: Text(
                    'No more products found.',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}
