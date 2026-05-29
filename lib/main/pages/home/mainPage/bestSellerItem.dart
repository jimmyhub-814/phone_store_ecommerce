import 'package:flutter/material.dart'; 
import 'package:phone_store/main/pages/home/shared_widgets/customCard.dart';
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
    Future.microtask(() {
      context.read<ProductProvider>().fetchProductsList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nổi bật trong tháng',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Consumer<ProductProvider>(
          
          builder: (context,provider, child) {
        
            if (provider.isLoading) {
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
                itemBuilder: (BuildContext context, int index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(color: Colors.black,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  );
                },
              );
            } else if (provider.products.isEmpty) {
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
                itemBuilder: (BuildContext context, int index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  );
                },
              );
            } else {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: provider.products.length,
                itemBuilder: (BuildContext context, int index) {
                  final product = provider.products[index];
                  return CustomCard(product: product);
                },
              );
            }
          },
        ),
      ],
    );
  }
}
