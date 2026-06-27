import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/main/pages/hamburger/widgets/chat_with_seller.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/main/pages/shared_widgets/custom_card.dart';
import 'package:phone_store/models/feedback.dart';
import 'package:phone_store/models/message_model.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/models/variants.dart';
import 'package:phone_store/main/pages/order/checkout_order.dart';
import 'package:phone_store/main/pages/mainPage/search_page.dart';
import 'package:phone_store/models/view_history.dart';
import 'package:phone_store/provider/cart_provider.dart';
import 'package:phone_store/main/pages/mainPage/cart_page.dart';
import 'package:phone_store/provider/favorite_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/main/pages/shared_widgets/safe_image.dart';
import 'package:phone_store/services/recommendation_product_service.dart';
import 'package:provider/provider.dart';

class PhoneProfilePage extends StatefulWidget {
  final String id;
  static const routeName = '/phone_profile';
  const PhoneProfilePage({super.key, required this.id});

  @override
  State<PhoneProfilePage> createState() => _PhoneProfilePageState();
}

class _PhoneProfilePageState extends State<PhoneProfilePage> {
  late final PageController _pageController = PageController();
  final ValueNotifier<int> selectedVariantIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> selectedVariantIndexB = ValueNotifier<int>(0);
  final ValueNotifier<int> counter = ValueNotifier<int>(1);
  late Future<Product?> _productFuture;
  Future<List<FeedBack>>? feedbackFuture;
  Future<List<Product>>? _relatedFuture;
  bool _initialized = false;
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final productProvider = context.read<ProductProvider>();
    _productFuture = productProvider.getProduct(widget.id);
    feedbackFuture ??= context.read<ProductProvider>().getFeedBack(widget.id);

    _productFuture.then((product) async {
      if (product != null) {
        final historyRef = Collections.viewHistory(AuthHelper.userId!);
        final snapshot =
            await historyRef.orderBy(ViewHistory.createAtField).limit(1).get();

        final histories =
            snapshot.docs.map((e) => ViewHistory.fromMap(e.data())).toList();

        if (histories.length >= 15) {
          final oldest = await historyRef
              .orderBy(ViewHistory.createAtField)
              .limit(1)
              .get();
          await oldest.docs.first.reference.delete();
        }

        final recommendationService = RecommendationService();

        await recommendationService.trackView(
            AuthHelper.userId!, product, null);

        _relatedFuture ??=
            productProvider.relatedItem(product.id, product.categoryId);
        setState(() {});
      }
    });

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (_currentPageNotifier.value != page) {
        _currentPageNotifier.value = page;
      }
    });

    _initialized = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    selectedVariantIndex.dispose();
    selectedVariantIndexB.dispose();
    counter.dispose();
    super.dispose();
  }

  void _onVariantSelected(int index, Product product) {
    selectedVariantIndex.value = index;
    final variantImage = product.listVariants[index].image;

    final allImages = [
      if (product.mainImage.isNotEmpty) product.mainImage,
      ...product.extraImages,
      ...product.listVariants.map((v) => v.image),
    ];

    final pageIndex = allImages.indexOf(variantImage);

    if (pageIndex != -1) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void addToCart(String productId, int quantity, Variants variants) {
    final cartProvider = context.read<CartProvider>();

    final cartItem = cartProvider.cart.firstWhereOrNull((item) =>
        item.productId == productId && item.variantsId == variants.id);

    if ((cartItem?.quantity ?? 0) + quantity > variants.phoneQuantity) {
      _showSnack('Số lượng không đủ');
      return;
    }

    cartProvider.addCart(productId, quantity, variants.id);
    _showSnack('Đã thêm vào giỏ hàng');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            body: Center(
              child: LoadingAnimationWidget.waveDots(
                  color: AppColors.primary, size: 50),
            ),
          );
        }

        final product = snapshot.data!;
        _relatedFuture ??= context
            .read<ProductProvider>()
            .relatedItem(product.id, product.categoryId);
        return _buildProductUI(product);
      },
    );
  }

  Widget _buildProductUI(Product product) {
    final List<String> allImages = [
      if (product.mainImage.isNotEmpty) product.mainImage,
      ...product.extraImages,
      ...product.listVariants.map((v) => v.image ?? product.mainImage),
    ];

    return ValueListenableBuilder(
      valueListenable: selectedVariantIndex,
      builder: (context, variantIdx, _) {
        final variant = product.listVariants[variantIdx];
        final double price = variant.phonePrice;
        final double discount = variant.phoneDiscount;
        final double finalPrice = price - (price * discount / 100);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: AppbarIcon(),
            centerTitle: true,
            title: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchPage(),
                      ),
                    ),
                    child: Hero(
                      tag: 'search-bar',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: Color(0xFFBDBDBD),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tìm kiếm...',
                                style: TextStyle(
                                  color: Color(0xFFBDBDBD),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, CartPage.routeName),
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFEEEEEE)),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: allImages.length,
                          itemBuilder: (context, i) {
                            return SafeImage(
                              url: allImages[i],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      if (allImages.length > 1)
                        Positioned(
                          bottom: 15,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ValueListenableBuilder<int>(
                              valueListenable: _currentPageNotifier,
                              builder: (context, currentPage, _) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    allImages.length,
                                    (i) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width: currentPage == i ? 16 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: currentPage == i
                                            ? AppColors.primary
                                            : const Color(0xFFBDBDBD),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                                height: 1.3,
                              ),
                            ),
                          ),
                          Consumer<FavoriteProvider>(
                            builder: (context, provider, _) {
                              final isFav = provider.checkItem(product.id);
                              return GestureDetector(
                                onTap: () =>
                                    provider.toggleFavorite(product.id),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isFav
                                        ? AppColors.accent
                                            .withValues(alpha: 0.1)
                                        : const Color(0xFFF5F6FA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav
                                        ? AppColors.accent
                                        : const Color(0xFFBDBDBD),
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFF59E0B), size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  product.fbInfo.averageRating.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${product.fbInfo.totalRating} đánh giá)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• Đã bán ${product.salesVolume}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${NumberFormat("#,###", "en_US").format(finalPrice)}đ',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (discount > 0) ...[
                            Text(
                              '${NumberFormat("#,###", "en_US").format(price)}đ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFBDBDBD),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${discount.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (product.listVariants.length > 1)
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phân loại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            product.listVariants.length,
                            (i) {
                              final isSelected = variantIdx == i;
                              return GestureDetector(
                                onTap: () => _onVariantSelected(i, product),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                            .withValues(alpha: 0.08)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFE5E7EB),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.listVariants[i].phoneType,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin sản phẩm',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDescription(product.phoneDescription),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Đánh giá',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${product.fbInfo.averageRating} (${product.fbInfo.totalRating})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder(
                        future: feedbackFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: LoadingAnimationWidget.waveDots(
                                  color: AppColors.primary, size: 40),
                            );
                          }

                          final feedbacks = snapshot.data ?? [];
                          if (feedbacks.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Chưa có đánh giá nào',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            );
                          }

                          final isExpanded = ValueNotifier(false);

                          return ValueListenableBuilder(
                            valueListenable: isExpanded,
                            builder: (context, expanded, _) {
                              final displayed = expanded
                                  ? feedbacks
                                  : feedbacks.take(1).toList();
                              return Column(
                                children: [
                                  for (int i = 0;
                                      i < displayed.length;
                                      i++) ...[
                                    _buildReviewItem(displayed[i]),
                                    if (i != displayed.length - 1)
                                      const SizedBox(height: 12),
                                  ],
                                  if (feedbacks.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: TextButton(
                                        onPressed: () =>
                                            isExpanded.value = !expanded,
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              expanded
                                                  ? 'Ẩn bớt'
                                                  : 'Xem thêm ${feedbacks.length - 1} đánh giá',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            AnimatedRotation(
                                              turns: expanded ? 0.5 : 0,
                                              duration: const Duration(
                                                milliseconds: 250,
                                              ),
                                              child: const Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sản phẩm liên quan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder(
                        future: _relatedFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: LoadingAnimationWidget.waveDots(
                                  color: AppColors.primary, size: 40),
                            );
                          }
                          final related = snapshot.data ?? [];
                          if (related.isEmpty) {
                            return const Center(
                              child: Text(
                                'Không có sản phẩm liên quan',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            );
                          }
                          return GridView.builder(
                            primary: false,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: related.length,
                            itemBuilder: (_, i) =>
                                CustomCard(product: related[i]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              _buildBottomBar(context, product, variant, finalPrice),
        );
      },
    );
  }

  Widget _buildReviewItem(FeedBack item) {
    final hasContent = item.feedBackText.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: SafeImage(
            url: item.userAvatar,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.userName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < item.vote
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 15,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (hasContent)
                Text(
                  item.feedBackText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                )
              else
                const Text(
                  'Đã đánh giá sản phẩm',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Product product,
      Variants variant, double finalPrice) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFEEEEEE),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildBarIcon(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () {
                final productMessage = ProductMessage(
                  productId: product.id,
                  productName: product.title,
                  productImage: product.mainImage,
                  productPrice: finalPrice,
                );

                Navigator.pushNamed(
                  context,
                  MessagePage.routeName,
                  arguments: MessagePage(
                    product: product,
                    productMessage: productMessage,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildBarIcon(
              icon: Icons.add_shopping_cart_outlined,
              onTap: () => _showVariantSheet(
                context: context,
                product: product,
                mode: 'cart',
                finalPrice: finalPrice,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _showVariantSheet(
                  context: context,
                  product: product,
                  mode: 'buy',
                  finalPrice: finalPrice,
                ),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: counter,
                      builder: (_, count, __) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Mua ngay',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${NumberFormat("#,###", "en_US").format(finalPrice * count)}đ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  void _showVariantSheet({
    required BuildContext context,
    required Product product,
    required String mode,
    required double finalPrice,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return ValueListenableBuilder(
          valueListenable: selectedVariantIndexB,
          builder: (ctx, bIndex, _) {
            final v = product.listVariants[bIndex];
            final vPrice =
                v.phonePrice - (v.phonePrice * v.phoneDiscount / 100);

            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SafeImage(
                              url: v.image ?? product.mainImage,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${NumberFormat("#,###", "en_US").format(vPrice)}đ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kho: ${v.phoneQuantity}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(
                                    0xFF9CA3AF,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: const Color(0xFFF0F0F0)),
                      const SizedBox(height: 16),
                      if (product.listVariants.length > 1) ...[
                        const Text(
                          'Phân loại',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            product.listVariants.length,
                            (i) {
                              final isSelected = bIndex == i;
                              return GestureDetector(
                                onTap: () => selectedVariantIndexB.value = i,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                            .withValues(alpha: 0.08)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFE5E7EB),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.listVariants[i].phoneType,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(height: 1, color: const Color(0xFFF0F0F0)),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Số lượng',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ValueListenableBuilder<int>(
                            valueListenable: counter,
                            builder: (_, count, __) {
                              return Row(
                                children: [
                                  _qtyBtn(
                                    icon: Icons.remove_rounded,
                                    onTap: () {
                                      if (counter.value > 1) counter.value--;
                                    },
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '$count',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _qtyBtn(
                                    icon: Icons.add_rounded,
                                    onTap: () {
                                      if (counter.value < v.phoneQuantity) {
                                        counter.value++;
                                      } else {
                                        _showSnack('Số lượng đã đạt tối đa');
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (mode == 'cart') {
                              addToCart(product.id, counter.value, v);
                              Navigator.pop(ctx);
                            } else {
                              final selectedVariant =
                                  product.listVariants[bIndex];
                              Navigator.pushNamed(
                                context,
                                CheckoutOrder.routeName,
                                arguments: CheckoutOrder(
                                  orderProduct: [
                                    OrderProduct(
                                      id: product.id,
                                      variantsId: selectedVariant.id,
                                      variantsName: selectedVariant.phoneType,
                                      phoneName: product.title,
                                      phonePrice: selectedVariant.phonePrice,
                                      phoneDiscount:
                                          selectedVariant.phoneDiscount,
                                      quantity: counter.value,
                                      phoneImage: selectedVariant.image ??
                                          product.mainImage,
                                    )
                                  ],
                                  totalPrice: vPrice * counter.value,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mode == 'cart'
                                ? Colors.white
                                : AppColors.primary,
                            foregroundColor: mode == 'cart'
                                ? AppColors.primary
                                : Colors.white,
                            side: mode == 'cart'
                                ? const BorderSide(color: AppColors.primary)
                                : null,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            mode == 'cart' ? 'Thêm vào giỏ' : 'Mua ngay',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDescription(String text) {
    const int threshold = 150;
    final bool isLong = text.length > threshold;

    if (!isLong) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
          height: 1.6,
        ),
      );
    }

    final isExpanded = ValueNotifier(false);
    return ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (context, expanded, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: Text(
                '${text.substring(0, threshold)}...',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              secondChild: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => isExpanded.value = !expanded,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? 'Ẩn bớt' : 'Xem thêm',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF4B5563)),
      ),
    );
  }
}
