import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/main/pages/shared_widgets/custom_card.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/models/search_history.dart';
import 'package:phone_store/provider/product_provider.dart';

class SearchPage extends StatefulWidget {
  static const routeName = '/search-screen';
  
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _results = [];
  final FocusNode _focusNode = FocusNode();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _focusNode.requestFocus();
      });
    });
  }

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var product = context.read<ProductProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Hero(
                    tag: 'search-bar',
                    child: Material(
                      color: Colors.transparent,
                      child: TextFormField(
                        controller: _searchController,
                        autofocus: false,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          hintText: 'Tìm sản phẩm...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          suffixIcon: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _results = product.getResultOfSearch(
                                          _searchController.text);
                                      isLoading = true;
                                    });

                                    final keyword =
                                        _searchController.text.trim();

                                    if (keyword.isEmpty) return;

                                    final historyRef =
                                        Collections.searchHistory(
                                            AuthHelper.userId!);

                                    final snapshot = await historyRef.get();

                                    final histories = snapshot.docs
                                        .map((e) =>
                                            SearchHistory.fromMap(e.data()))
                                        .toList();

                                    if (histories.length >= 5) {
                                      histories.sort(
                                        (a, b) =>
                                            a.createAt.compareTo(b.createAt),
                                      );

                                      await historyRef
                                          .doc(histories.first.id)
                                          .delete();
                                    }

                                    final id = const Uuid().v4();

                                    await historyRef.doc(id).set({
                                      SearchHistory.idField: id,
                                      SearchHistory.contentField: keyword,
                                      SearchHistory.createAtField:
                                          Timestamp.now(),
                                    });

                                    setState(() {
                                      isLoading = false;
                                    });
                                  },
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                size: 22,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 60,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: _results.isNotEmpty
                  ? GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        Product searchItem = _results[index];

                        return CustomCard(product: searchItem);
                      },
                    )
                  : const Center(
                      child: Text(
                        'Không có sản phẩm nào!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
    );
  }
}
