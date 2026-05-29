import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/chat.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/main/pages/home/shared_widgets/customCard.dart';
import 'package:phone_store/models/feedBack.dart';
import 'package:phone_store/models/message_model.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/models/variants.dart';
import 'package:phone_store/main/pages/home/mainPage/buyItem.dart';
import 'package:phone_store/main/pages/home/mainPage/search_page.dart';
import 'package:phone_store/provider/cart_provider.dart';
import 'package:phone_store/main/pages/home/mainPage/cartPage.dart';
import 'package:phone_store/provider/favorite_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/main/pages/home/shared_widgets/safeImage.dart';
import 'package:provider/provider.dart';

class PhoneProfilePage extends StatefulWidget {
  final String id;
  static const routeName = '/phone_profile';
  const PhoneProfilePage({super.key, required this.id});

  @override
  State<PhoneProfilePage> createState() => _PhoneProfilePageState();
}

class _PhoneProfilePageState extends State<PhoneProfilePage> {
  late final PageController _pageController =
      PageController(viewportFraction: 1);
  final ValueNotifier<int> selectedVariantIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> selectedVariantIndexB = ValueNotifier<int>(0);
  late Future<Product?> _productFuture;
  Future<List<FeedBack>>? feedbackFuture;
  Future<List<Product>>? _relatedFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final productProvider = context.read<ProductProvider>();

    _productFuture = productProvider.getProduct(widget.id);

    feedbackFuture ??= context.read<ProductProvider>().getFeedBack(widget.id);

    _productFuture.then((product) {
      _relatedFuture ??= productProvider.relatedItem(
        product!.id,
        product.categoryId,
      );

      setState(() {});
    });

    _initialized = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    selectedVariantIndex.dispose();
    selectedVariantIndexB.dispose();
    super.dispose();
  }

  // Hàm thay đổi khi chọn variant khác
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
    final productProvider = context.read<ProductProvider>();

    final product = productProvider.products.firstWhereOrNull(
      (p) => p.id == productId,
    );

    print("ALL PRODUCTS: ${productProvider.products.map((e) => e.id)}");
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm không tồn tại')),
      );
      return;
    }

    final cartItem = cartProvider.cart.firstWhereOrNull(
      (item) => item.productId == productId && item.variantsId == variants.id,
    );
    print("CART productId: ${cartItem?.productId}");
    final currentQuantity = cartItem?.quantity ?? 0;

    if (currentQuantity + quantity > variants.phoneQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số lượng không đủ'),
        ),
      );
      return;
    }

    cartProvider.addCart(productId, quantity, variants.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm vào giỏ hàng'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context = context;

    return FutureBuilder(
      future: _productFuture,
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
        } else {
          final product = snapshot.data!;
          _relatedFuture ??= context
              .read<ProductProvider>()
              .relatedItem(product.id, product.categoryId);
          return _buildProductUI(product);
        }
      },
    );
  }

  Widget _buildProductUI(Product product) {
    final Size size = MediaQuery.of(context).size;
    List<double> allPrice = [];
    if (product.listVariants.length > 1) {
      for (var i = 0; i < product.listVariants.length; i++) {
        final price = product.listVariants[i].phonePrice -
            (product.listVariants[i].phonePrice *
                product.listVariants[i].phoneDiscount /
                100);
        allPrice.add(price);
      }
    }

    final List<String> allImages = [
      if (product.mainImage.isNotEmpty) product.mainImage,
      ...product.extraImages,
      ...product.listVariants.map((v) => v.image),
    ];

    final ValueNotifier<int> counter = ValueNotifier<int>(1);
    final ValueNotifier<bool> isMax = ValueNotifier<bool>(false);
    return ValueListenableBuilder(
      valueListenable: selectedVariantIndex,
      builder: (context, index, _) {
        final variant = product.listVariants[index];
        final hasVariants = product.listVariants.isNotEmpty;
        final selectedVariants = hasVariants ? variant : null;

        final double price = selectedVariants?.phonePrice ?? 0;
        final double discount = selectedVariants?.phoneDiscount ?? 0;
        final double finalPrice = price - (price * discount / 100);

        return Scaffold(
          backgroundColor: AppColors.primaryDark,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: AppBar(
              leading: AppbarIcon(
                color: AppColors.surface,
              ),
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              foregroundColor: AppColors.surface,
              backgroundColor: AppColors.primaryDark,
              title: SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchPage(),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'search-bar',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                color: AppColors.surface,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 18,
                                      color: AppColors.iconSecondary,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      'Tìm kiếm',
                                      style: TextStyle(
                                        color: AppColors.iconSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, CartPage.routeName);
                      },
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: size.width / 2.2,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  width: size.width,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          if (hasVariants) ...[
                            const SizedBox(height: 5),
                            const Text(
                              'Phân loại',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(
                                product.listVariants.length,
                                (i) {
                                  final isSelected = index == i;

                                  return GestureDetector(
                                    onTap: () => _onVariantSelected(i, product),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.textPrimary
                                              : AppColors.surfaceLight,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                        color: AppColors.surface,
                                      ),
                                      child: Text(
                                        product.listVariants[i].phoneType,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.textPrimary
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Đã bán ${product.salesVolume} ',
                                  style: AppTextstyles.headingH7),
                              const SizedBox(
                                width: 5,
                              ),
                              Consumer<FavoriteProvider>(
                                builder: (context, provider, child) {
                                  return Container(
                                    padding: const EdgeInsets.all(
                                      3,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        provider.toggleFavorite(product.id);
                                      },
                                      child: Icon(
                                        Icons.favorite,
                                        color: provider.checkItem(product.id)
                                            ? AppColors.accent
                                            : AppColors.border,
                                        size: 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Thông tin sản phẩm',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            '${product.phoneDescription} ',
                            style: AppTextstyles.headingH7,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    product.fbInfo.averageRating.toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.star,
                                    size: 15,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Đánh Giá Sản Phẩm (${product.fbInfo.totalRating})',
                                style: AppTextstyles.headingH7Bold,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                            ],
                          ),
                          FutureBuilder(
                            future: feedbackFuture,
                            builder: (context, snapshot) {
                              final ValueNotifier<bool> isExpanded =
                                  ValueNotifier(false);

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: LoadingAnimationWidget.waveDots(
                                    color: AppColors.primary,
                                    size: 60,
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return const Center(
                                  child: Text(
                                    "Đã xảy ra lỗi khi tải đánh giá",
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data == null) {
                                return const Padding(
                                  padding: EdgeInsets.only(
                                    top: 15,
                                    bottom: 10,
                                  ),
                                  child: Center(
                                    child: Text(
                                        "Chưa có đánh giá cho sản phẩm này",
                                        style: AppTextstyles.headingH7Bold),
                                  ),
                                );
                              }

                              // Xử lý nếu dữ liệu không phải list
                              final dataList = snapshot.data;
                              if (dataList?.isEmpty ?? true) {
                                return const Padding(
                                  padding: EdgeInsets.only(
                                    top: 15,
                                    bottom: 10,
                                  ),
                                  child: Center(
                                    child: Text(
                                        "Chưa có đánh giá cho sản phẩm này",
                                        style: AppTextstyles.headingH7Bold),
                                  ),
                                );
                              }

                              final List<FeedBack> feedbacks =
                                  dataList as List<FeedBack>;
                              return ValueListenableBuilder(
                                valueListenable: isExpanded,
                                builder: (context, value, _) {
                                  return Column(
                                    children: [
                                      ...feedbacks.asMap().entries.map(
                                        (entry) {
                                          int index = entry.key;
                                          var item = entry.value;
                                          if (index > 0 && !value) {
                                            return const SizedBox.shrink();
                                          }
                                          return Column(
                                            children: [
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                children: [
                                                  ClipOval(
                                                    child: Container(
                                                      color: AppColors.surface,
                                                      child: SafeImage(
                                                        url: item.userAvatar,
                                                        width: 14,
                                                        height: 14,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Text(
                                                    item.userName,
                                                    style: AppTextstyles
                                                        .headingH7Bold,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 5,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: List.generate(
                                                        item.vote,
                                                        (index) => const Icon(
                                                          Icons.star,
                                                          color: AppColors.star,
                                                          size: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 5,
                                                    ),
                                                    item.feedBackText.isNotEmpty
                                                        ? Text(
                                                            item.feedBackText)
                                                        : const SizedBox
                                                            .shrink()
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      if (feedbacks.length > 1)
                                        TextButton(
                                          onPressed: () {
                                            isExpanded.value =
                                                !isExpanded.value;
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            splashFactory:
                                                NoSplash.splashFactory,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                value ? "Ẩn bớt" : "Xem thêm",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Icon(
                                                value
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                size: 12,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 1,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              const Text('Sản phẩm liên quan',
                                  style: AppTextstyles.headingH7Bold),
                              const SizedBox(width: 10),
                              Container(
                                width: 50,
                                height: 1,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          FutureBuilder(
                            future: _relatedFuture,
                            builder: (context, snapshotss) {
                              if (snapshotss.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: LoadingAnimationWidget.waveDots(
                                    color: AppColors.primary,
                                    size: 60,
                                  ),
                                );
                              }

                              if (!snapshotss.hasData ||
                                  snapshotss.data == null) {
                                return Center(
                                  child: Column(
                                    children: [
                                      const Text("Không tìm thấy sản phẩm"),
                                      SizedBox(
                                        height: size.width,
                                      ),
                                      const Text("Không tìm thấy sản phẩm"),
                                    ],
                                  ),
                                );
                              }

                              final relatedProduct = snapshotss.data!;

                              return relatedProduct.isNotEmpty
                                  ? GridView.builder(
                                      primary: false,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 5,
                                        childAspectRatio: 0.7,
                                      ),
                                      itemCount: relatedProduct.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return CustomCard(
                                            product: relatedProduct[index]);
                                      },
                                    )
                                  : const Center(
                                      child: Text('Không có sản phẩm nào',
                                          style: AppTextstyles.headingH7Bold),
                                    );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  width: size.width,
                  height: size.width / 1.8,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          onPressed: () {
                            if (_pageController.hasClients) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_left_sharp,
                            color: AppColors.surface,
                          ),
                        ),
                      ),

                      // Ảnh
                      Expanded(
                        flex: 4,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: allImages.length,
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double currentPage = 0;
                                try {
                                  currentPage = _pageController.page ??
                                      _pageController.initialPage.toDouble();
                                } catch (_) {}

                                double scale =
                                    (index == currentPage.round()) ? 1.0 : 0;

                                return Transform.scale(
                                  scale: scale,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        color: AppColors.surface,
                                      ),
                                      child: Stack(children: [
                                        SafeImage(
                                          url: allImages[index],
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            alignment: Alignment.center,
                                            height: 18,
                                            width: 30,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(6),
                                              ),
                                            ),
                                            child: Text(
                                                style: AppTextstyles.smallText
                                                    .copyWith(
                                                  color: AppColors.surface,
                                                ),
                                                '${index + 1} / ${allImages.length}'),
                                          ),
                                        )
                                      ]),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Expanded(
                          flex: 1,
                          child: IconButton(
                            onPressed: () {
                              if (_pageController.hasClients) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_right_sharp,
                              color: AppColors.surface,
                            ),
                          )),

                      // Giá
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: size.width / 3.2,
                              padding: const EdgeInsets.only(left: 20, top: 30),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.surface,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        product.fbInfo.averageRating.toString(),
                                        style: AppTextstyles.smallText.copyWith(
                                          color: AppColors.surface,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.star,
                                        color: AppColors.star,
                                        size: 12,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    price > 0
                                        ? '${NumberFormat("#,##0.###", "en_US").format(variant.phonePrice)}đ'
                                        : '',
                                    style: AppTextstyles.smallTextBold.copyWith(
                                      color: AppColors.surface,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: AppColors.surface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              height: 50,
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 10,
                                right: 10,
                                left: 20,
                              ),
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(17),
                                  bottomLeft: Radius.circular(17),
                                ),
                                color: AppColors.primary,
                              ),
                              child: Align(
                                alignment: AlignmentGeometry.centerLeft,
                                child: Text(
                                  finalPrice > 0
                                      ? '${NumberFormat("#,##0.###", "en_US").format(finalPrice)}đ'
                                      : '0',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: AppColors.surface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            height: 62,
            child: BottomAppBar(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.surface,
              child: Row(
                children: [
                  Flexible(
                    flex: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            ProductMessage productMessage = ProductMessage(
                              productId: product.id,
                              productName: product.title,
                              productImage: product.mainImage,
                              productPrice: finalPrice,
                            );
                            Navigator.pushNamed(
                              context,
                              MessagePage.routeName,
                              arguments: MessagePage(product: productMessage),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(24.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.chat,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: AppColors.surface,
                              builder: (ctx) {
                                final mediaQuery = MediaQuery.of(ctx);
                                return ValueListenableBuilder(
                                  valueListenable: selectedVariantIndexB,
                                  builder: (ctx, bIndex, _) {
                                    final variant =
                                        product.listVariants[bIndex];
                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            mediaQuery.size.height * 0.85,
                                      ),
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(15),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadiusGeometry
                                                            .circular(5),
                                                    child: SafeImage(
                                                      url: variant.image,
                                                      width: 100,
                                                      height: 100,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 20,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${NumberFormat("#,###", "en_US").format(
                                                          variant.phonePrice -
                                                              (variant.phonePrice *
                                                                  variant
                                                                      .phoneDiscount /
                                                                  100),
                                                        )}đ',
                                                        style: const TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Kho: ${variant.phoneQuantity}',
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 15,
                                              ),
                                              Container(
                                                width: double.maxFinite,
                                                height: 1,
                                                color: AppColors.border,
                                              ),
                                              const SizedBox(
                                                height: 15,
                                              ),
                                              if (hasVariants) ...[
                                                const Text(
                                                  'Phân loại',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 10,
                                                  runSpacing: 10,
                                                  children: List.generate(
                                                    product.listVariants.length,
                                                    (i) {
                                                      final isSelected =
                                                          bIndex == i;

                                                      return GestureDetector(
                                                        onTap: () =>
                                                            selectedVariantIndexB
                                                                .value = i,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                              color: isSelected
                                                                  ? AppColors
                                                                      .textPrimary
                                                                  : AppColors
                                                                      .primary,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              5,
                                                            ),
                                                            color: isSelected
                                                                ? AppColors
                                                                    .scaffoldBg
                                                                : AppColors
                                                                    .surface,
                                                          ),
                                                          child: Text(
                                                            product
                                                                .listVariants[i]
                                                                .phoneType,
                                                            style: TextStyle(
                                                              color: isSelected
                                                                  ? AppColors
                                                                      .textPrimary
                                                                  : Colors
                                                                      .black,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Container(
                                                width: double.maxFinite,
                                                height: 1,
                                                color: AppColors.border,
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Số lượng',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          if (counter.value >
                                                              1) {
                                                            counter.value--;
                                                          }
                                                        },
                                                        child: const Icon(
                                                          Icons.remove,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 10,
                                                        ),
                                                        child:
                                                            ValueListenableBuilder<
                                                                int>(
                                                          valueListenable:
                                                              counter,
                                                          builder: (context,
                                                              value, child) {
                                                            return Text(
                                                              '$value',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: isMax.value
                                                            ? null
                                                            : () {
                                                                if (variant
                                                                        .phoneQuantity >
                                                                    counter
                                                                        .value) {
                                                                  counter
                                                                      .value++;

                                                                  isMax.value =
                                                                      false;
                                                                } else {
                                                                  isMax.value =
                                                                      true;

                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    const SnackBar(
                                                                      content:
                                                                          Text(
                                                                        'Số lượng sản phẩm đã đạt tối đa',
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                        child: const Icon(
                                                          Icons.add,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  addToCart(product.id,
                                                      counter.value, variant);
                                                  Navigator.pop(ctx);
                                                },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  width: double.infinity,
                                                  height: 50,
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      25,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Thêm giỏ',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.surface,
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
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(24.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Flexible(
                    flex: 6,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.surface,
                          builder: (ctx) {
                            final mediaQuery = MediaQuery.of(ctx);
                            return ValueListenableBuilder(
                              valueListenable: selectedVariantIndexB,
                              builder: (ctx, bIndex, _) {
                                final variantB = product.listVariants[bIndex];

                                final hasVariantsB =
                                    product.listVariants.isNotEmpty;
                                final selectedVariants =
                                    hasVariantsB ? variantB : null;

                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: mediaQuery.size.height * 0.85,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadiusGeometry
                                                        .circular(5),
                                                child: SafeImage(
                                                  url: variantB.image,
                                                  width: 100,
                                                  height: 100,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${NumberFormat("#,###", "en_US").format(
                                                      variantB.phonePrice -
                                                          (variantB.phonePrice *
                                                              variantB
                                                                  .phoneDiscount /
                                                              100),
                                                    )}đ',
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Kho: ${variantB.phoneQuantity}',
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Container(
                                            width: double.maxFinite,
                                            height: 1,
                                            color: AppColors.border,
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          if (hasVariantsB) ...[
                                            const Text(
                                              'Phân loại',
                                              style: TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 10,
                                              runSpacing: 10,
                                              children: List.generate(
                                                product.listVariants.length,
                                                (i) {
                                                  final isSelected =
                                                      bIndex == i;

                                                  return GestureDetector(
                                                    onTap: () =>
                                                        selectedVariantIndexB
                                                            .value = i,
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? AppColors
                                                                  .textSecondary
                                                              : AppColors
                                                                  .primary,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          5,
                                                        ),
                                                        color: isSelected
                                                            ? AppColors
                                                                .surfaceLight
                                                            : AppColors.surface,
                                                      ),
                                                      child: Text(
                                                        product.listVariants[i]
                                                            .phoneType,
                                                        style: TextStyle(
                                                          color: isSelected
                                                              ? AppColors
                                                                  .textSecondary
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                            width: double.maxFinite,
                                            height: 1,
                                            color: AppColors.border,
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Số lượng',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (counter.value > 1) {
                                                        counter.value--;
                                                      }
                                                    },
                                                    child: const Icon(
                                                      Icons.remove,
                                                      color:
                                                          AppColors.primaryDark,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                    ),
                                                    child:
                                                        ValueListenableBuilder<
                                                            int>(
                                                      valueListenable: counter,
                                                      builder: (context, value,
                                                          child) {
                                                        return Text(
                                                          '$value',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: isMax.value
                                                        ? null
                                                        : () {
                                                            if (variantB
                                                                    .phoneQuantity >
                                                                counter.value) {
                                                              counter.value++;

                                                              isMax.value =
                                                                  false;
                                                            } else {
                                                              isMax.value =
                                                                  true;

                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'Số lượng sản phẩm đã đạt tối đa',
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                    child: const Icon(
                                                      Icons.add,
                                                      color:
                                                          AppColors.primaryDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              if (counter.value > 0) {
                                                final List<OrderProduct>
                                                    selectedProducts = [
                                                  OrderProduct(
                                                    id: product.id,
                                                    variantsId:
                                                        selectedVariants!.id,
                                                    variantsName:
                                                        selectedVariants
                                                            .phoneType,
                                                    phoneName: product.title,
                                                    phonePrice: selectedVariants
                                                        .phonePrice,
                                                    phoneDiscount:
                                                        selectedVariants
                                                            .phoneDiscount,
                                                    quantity: counter.value,
                                                    phoneImage:
                                                        selectedVariants.image,
                                                  )
                                                ];

                                                Navigator.pushNamed(
                                                  context,
                                                  BuyItem.routeName,
                                                  arguments: BuyItem(
                                                    orderProduct:
                                                        selectedProducts,
                                                    totalPrice: selectedVariants
                                                            .phonePrice -
                                                        (selectedVariants
                                                                    .phonePrice *
                                                                selectedVariants
                                                                    .phoneDiscount /
                                                                100) *
                                                            counter.value,
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Vui lòng chọn sản phẩm hợp lệ',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              alignment: Alignment.center,
                                              width: double.infinity,
                                              height: 50,
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                              child: const Text(
                                                'Mua ngay',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.surface,
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
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24.5),
                        ),
                        child: Center(
                          child: ValueListenableBuilder<int>(
                            valueListenable: counter,
                            builder: (context, value, child) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Mua ngay",
                                    maxLines: 1,
                                    style: AppTextstyles.smallText.copyWith(
                                      color: AppColors.surface,
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat("#,###", "en_US").format(
                                      finalPrice * counter.value,
                                    )}đ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.surface,
                                      fontWeight: FontWeight.w500,
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
          ),
        );
      },
    );
  }
}
