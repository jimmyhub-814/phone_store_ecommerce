import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/models/cart.dart';
import 'package:phone_store/main/pages/order/checkout_order.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/provider/cart_provider.dart';
import 'package:phone_store/main/pages/mainPage/phone_profile.dart';
import 'package:phone_store/main/pages/shared_widgets/safe_image.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  static const routeName = "/cart-screen";
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool hasShownSnackbar = false;
  double _lastKnownTotal = 0;

  final Map<String, Future<Product?>> _productFutures = {};

  CartProvider? _cartProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cartProvider = context.read<CartProvider>();
  }

  @override
  void dispose() {
    _cartProvider?.clearSelection();
    super.dispose();
  }

  Future<Product?> _getCachedProduct(BuildContext context, String productId) {
    return _productFutures.putIfAbsent(
      productId,
      () => context.read<ProductProvider>().getProduct(productId),
    );
  }

  void removeItemFromCart(String id, String variantsId) {
    context.read<CartProvider>().removeFromCart(id);
  }

  void _removeItem(BuildContext context, Cart cartItem) async {
    final provider = context.read<CartProvider>();

    if (cartItem.quantity == 1) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Product'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  removeItemFromCart(cartItem.id, cartItem.variantsId);
                  Navigator.of(context).pop(true);
                },
                child: const Text("Delete"),
              ),
            ],
          );
        },
      );
    } else {
      provider.decrease(cartItem.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Consumer<CartProvider>(
      builder: (context, provider, child) {
        final cart = provider.cart;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBar(
              backgroundColor: AppColors.surface,
              leading: AppbarIcon(),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Giỏ hàng',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '(${cart.length})',
                    style: AppTextstyles.smallText.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  iconSize: 20,
                  onPressed: () {
                    final selected = provider.selectedItems.values
                        .where((item) => item == true)
                        .toList();
                    if (selected.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chưa có sản phẩm nào được chọn'),
                        ),
                      );
                      return;
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Delete Product'),
                            content: const Text(
                                'Are you sure you want to delete these item?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  provider.deleteProductById();
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text("Delete"),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          body: cart.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: AppColors.primary,
                          size: 80,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Hãy thêm sản phẩm bạn thích nào!",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (BuildContext context, int index) {
                      var cartItem = cart[index];
                      return FutureBuilder<Product?>(
                        future: _getCachedProduct(context, cartItem.productId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  left: 15,
                                  right: 15,
                                  bottom: 10,
                                ),
                                height: 110,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                              ),
                            );
                          }

                          final product = snapshot.data;
                          if (product == null) {
                            return const SizedBox();
                          }

                          final variants = product.listVariants.firstWhere(
                            (e) => e.id == cartItem.variantsId,
                            orElse: () => product.listVariants.first,
                          );

                          return Dismissible(
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: AppColors.surface,
                                    title: const Text('Delete Product'),
                                    content: const Text(
                                        'Are you sure to delete this item?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          context
                                              .read<CartProvider>()
                                              .removeFromCart(cartItem.id);

                                          Navigator.of(context).pop(true);
                                        },
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            key: Key(cartItem.id),
                            onDismissed: (direction) {
                              context
                                  .read<CartProvider>()
                                  .removeFromCart(cartItem.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Complete!'),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    PhoneProfilePage.routeName,
                                    arguments: PhoneProfilePage(id: product.id),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    color: AppColors.surface,
                                  ),
                                  width: size.width,
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: provider
                                                .selectedItems[cartItem.id] ??
                                            false,
                                        onChanged: (bool? value) {
                                          provider.toggleSelection(cartItem.id);
                                        },
                                        side: const BorderSide(
                                          color: Colors.grey,
                                          width: 1,
                                        ),
                                        activeColor: AppColors.primary,
                                        checkColor: AppColors.surface,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(7),
                                            child: SafeImage(
                                              url: variants.image ??
                                                  product.mainImage,
                                              width: size.width / 5.5,
                                              height: size.width / 5.5,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SizedBox(
                                          width: size.width,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                product.title,
                                                style: AppTextstyles
                                                    .headingH7Bold
                                                    .copyWith(
                                                  color: AppColors.iconPrimary,
                                                ),
                                              ),
                                              Text(
                                                variants.phoneType,
                                                style: AppTextstyles.smallText
                                                    .copyWith(
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                              Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${NumberFormat("#,###", "en_US").format(
                                                          variants.phonePrice -
                                                              ((variants.phonePrice *
                                                                      variants
                                                                          .phoneDiscount) /
                                                                  100),
                                                        )}đ',
                                                        style: const TextStyle(
                                                          color:
                                                              AppColors.accent,
                                                          letterSpacing: 0.38,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        '${NumberFormat("#,###", "en_US").format(variants.phonePrice)}đ',
                                                        style: AppTextstyles
                                                            .smallText
                                                            .copyWith(
                                                          color:
                                                              AppColors.border,
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                          decorationColor:
                                                              AppColors.border,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              GestureDetector(
                                                onTap: () {},
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5),
                                                  child: Row(
                                                    children: [
                                                      const Spacer(),
                                                      Container(
                                                        width: 74,
                                                        height: 25,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color
                                                              .fromARGB(
                                                            255,
                                                            242,
                                                            242,
                                                            242,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            InkWell(
                                                              onTap: () {
                                                                _removeItem(
                                                                    context,
                                                                    cartItem);
                                                              },
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                8,
                                                              ),
                                                              child: Container(
                                                                width: 25,
                                                                height: 25,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child:
                                                                    const Icon(
                                                                  Icons.remove,
                                                                  size: 14,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              '${cartItem.quantity}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 11,
                                                              ),
                                                            ),
                                                            InkWell(
                                                              onTap: () {
                                                                if (variants
                                                                        .phoneQuantity >
                                                                    cartItem
                                                                        .quantity) {
                                                                  provider
                                                                      .increase(
                                                                    cartItem.id,
                                                                  );
                                                                } else {
                                                                  if (!hasShownSnackbar) {
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
                                                                    hasShownSnackbar =
                                                                        true;
                                                                  }
                                                                }
                                                              },
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              child: Container(
                                                                width: 25,
                                                                height: 25,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child:
                                                                    const Icon(
                                                                        Icons
                                                                            .add,
                                                                        size:
                                                                            14),
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
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          bottomNavigationBar: SizedBox(
            height: 70,
            child: BottomAppBar(
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total: ${provider.getTotalSelection()}',
                              style: AppTextstyles.smallTextBold),
                          FutureBuilder<double>(
                            future: provider.getTotalItemCount(context),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                _lastKnownTotal = snapshot.data!;
                              }
                              return Text(
                                '${NumberFormat("#,###", "en_US").format(_lastKnownTotal)}đ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      final selectedIds = provider.selectedItems.entries
                          .where((entry) => entry.value == true)
                          .map((entry) => entry.key)
                          .toList();

                      if (selectedIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng chọn ít nhất một sản phẩm',
                            ),
                          ),
                        );
                        return;
                      }

                      final selectedCartItems = cart
                          .where((c) => selectedIds.contains(c.id))
                          .toList();

                      final List<OrderProduct> selectedProducts = [];
                      double selectedTotalPrice = 0;

                      for (final cartItem in selectedCartItems) {
                        final product = await _getCachedProduct(
                            context, cartItem.productId);
                        if (product == null) continue;

                        final variants = product.listVariants.firstWhere(
                          (e) => e.id == cartItem.variantsId,
                          orElse: () => product.listVariants.first,
                        );

                        final priceAfterDiscount = variants.phonePrice -
                            ((variants.phonePrice * variants.phoneDiscount) /
                                100);
                        selectedTotalPrice +=
                            priceAfterDiscount * cartItem.quantity;

                        selectedProducts.add(
                          OrderProduct(
                            id: product.id,
                            variantsId: variants.id,
                            variantsName: variants.phoneType,
                            phonePrice: variants.phonePrice,
                            quantity: cartItem.quantity,
                            phoneImage: variants.image ?? product.mainImage,
                            phoneName: product.title,
                            phoneDiscount: variants.phoneDiscount,
                          ),
                        );
                      }

                      if (selectedProducts.isEmpty || !context.mounted) return;

                      Navigator.pushNamed(
                        context,
                        CheckoutOrder.routeName,
                        arguments: CheckoutOrder(
                          totalPrice: selectedTotalPrice,
                          orderProduct: selectedProducts,
                        ),
                      );
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mua ngay',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '(${provider.getTotalSelection()})',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.surface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
