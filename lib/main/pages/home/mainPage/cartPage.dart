import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/models/cart.dart';
import 'package:phone_store/main/pages/home/mainPage/buyItem.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/provider/cart_provider.dart';
import 'package:phone_store/main/pages/home/mainPage/phone_profile.dart';
import 'package:phone_store/main/pages/home/shared_widgets/safeImage.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  static const routeName = "/cartPage";
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool hasShownSnackbar = false;
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
        final products = provider.productList;
        double totalPrice = provider.getTotalItemCount();
        if (products.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.waveDots(
              color: AppColors.primary,
              size: 60,
            ),
          );
        }
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
                    ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
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
                      final product = products.where(
                        (product) => product.id == cartItem.productId,
                      );
                      if (product.isEmpty) {
                        return const SizedBox();
                      }
                      final p = product.first;
                      final variants = p.listVariants
                          .firstWhere((e) => e.id == cartItem.variantsId);
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
                                arguments: PhoneProfilePage(id: p.id) ,
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
                                    color: Colors.black.withValues(alpha: 0.1),
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
                                    value:
                                        provider.selectedItems[cartItem.id] ??
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
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: SafeImage(
                                          url: variants.image,
                                          width: size.width / 5.5,
                                          height: size.width / 5.5,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
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
                                            p.title,
                                            style: AppTextstyles.headingH7Bold
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
                                                      color: AppColors.accent,
                                                      letterSpacing: 0.38,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Text(
                                                    '${NumberFormat("#,###", "en_US").format(variants.phonePrice)}đ',
                                                    style: AppTextstyles
                                                        .smallText
                                                        .copyWith(
                                                      color: AppColors.border,
                                                      decoration: TextDecoration
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
                                                padding: const EdgeInsets.only(
                                                  top: 5,
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Spacer(),
                                                    Container(
                                                      width: 74,
                                                      height: 25,
                                                      decoration: BoxDecoration(
                                                        color: const Color
                                                            .fromARGB(
                                                          255,
                                                          242,
                                                          242,
                                                          242,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          8,
                                                        ),
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
                                                              provider
                                                                  .getTotalItemCount();
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
                                                              child: const Icon(
                                                                Icons.remove,
                                                                size: 14,
                                                              ),
                                                            ),
                                                          ),

                                                          // Số lượng
                                                          Text(
                                                            '${cartItem.quantity}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 11,
                                                            ),
                                                          ),

                                                          // Nút cộng
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

                                                              provider
                                                                  .getTotalItemCount();
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
                                                              child: const Icon(
                                                                  Icons.add,
                                                                  size: 14),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
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
                          Text(
                            '${NumberFormat("#,###", "en_US").format(totalPrice)}đ',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
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
                      final List<OrderProduct> selectedProducts =
                          cart.where((cart) {
                        return selectedIds.contains(cart.id);
                      }).map((cart) {
                        final product =
                            products.firstWhere((p) => p.id == cart.id);
                        final variants = product.listVariants
                            .firstWhere((e) => e.id == cart.variantsId);
                        return OrderProduct(
                          id: product.id,
                          variantsId: variants.id,
                          variantsName: variants.phoneType,
                          phonePrice: variants.phonePrice,
                          quantity: cart.quantity,
                          phoneImage: variants.image,
                          phoneName: product.title,
                          phoneDiscount: variants.phoneDiscount,
                        );
                      }).toList();

                      Navigator.pushNamed(
                        context,
                        BuyItem.routeName,
                        arguments: BuyItem(
                          totalPrice: totalPrice,
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
                          const SizedBox(
                            width: 3,
                          ),
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
