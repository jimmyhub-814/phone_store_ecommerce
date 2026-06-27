import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_key.dart';
import 'package:phone_store/app_constants/app_textStyles.dart'; 
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/models/user.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:uuid/uuid.dart';

class ChangeOrderInfo extends StatefulWidget {
  final String? id;
  final String? userPhone;
  final String? userName;
  final String? userAddress;
  static const String routeName = '/changeOrderInfo';

  const ChangeOrderInfo(
      {super.key, this.id, this.userPhone, this.userAddress, this.userName});

  @override
  State<ChangeOrderInfo> createState() => _ChangeOrderInfoState();
}

class _ChangeOrderInfoState extends State<ChangeOrderInfo> {
  late TextEditingController addressController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  FocusNode? addressFocusNode;
  bool isLoading = false;

  bool validateInput() {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
        ),
      );
      return false;
    }

    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Số điện thoại không hợp lệ!',
          ),
        ),
      );
      return false;
    }

    // Địa chỉ phải có ít nhất 2 dấu phẩy
    final commaCount = ','.allMatches(address).length;

    if (commaCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn địa chỉ đầy đủ (ít nhất phường/xã, quận/huyện, tỉnh/thành phố)',
          ),
        ),
      );
      return false;
    }
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Địa chỉ phải có ít nhất phường/xã, quận/huyện và tỉnh/thành phố',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    addressFocusNode = FocusNode();
    addressFocusNode = FocusNode();

    nameController = TextEditingController(text: widget.userName ?? '');

    phoneController = TextEditingController(text: widget.userPhone ?? '');

    addressController = TextEditingController(text: widget.userAddress ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    addressFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppbarIcon(),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Địa chỉ mới',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Họ và tên',
              style: AppTextstyles.headingH7
                  .copyWith(color: AppColors.iconDisabled),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: nameController,
              maxLines: 1,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: widget.userName,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.scaffoldBg,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  child: Icon(Icons.person, color: Colors.black54, size: 20),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Số điện thoại',
              style: AppTextstyles.headingH7
                  .copyWith(color: AppColors.iconDisabled),
            ),
            const SizedBox(height: 10),
            TextFormField(
              buildCounter: (_,
                      {int? currentLength, int? maxLength, bool? isFocused}) =>
                  const SizedBox.shrink(),
              controller: phoneController,
              maxLength: 10,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLines: 1,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: widget.userPhone,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.scaffoldBg,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 1.0),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.phone, color: Colors.black54, size: 20),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Địa chỉ',
              style: AppTextstyles.headingH7
                  .copyWith(color: AppColors.iconDisabled),
            ),
            const SizedBox(height: 10),
            placesAutoCompleteTextField(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 0,
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed: isLoading
                ? null
                : () async {
                    if (!validateInput()) return;

                    setState(() {
                      isLoading = true;
                    });

                    try {
                      final shippingInfo = ShippingInfo(
                        id: widget.id ?? const Uuid().v4(),
                        fullName: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        address: addressController.text.trim(),
                      );

                      await context
                          .read<UserProvider>()
                          .saveShippingInfo(context, shippingInfo);

                      if (!mounted) return;

                      Navigator.pop(context, true);
                    } finally {
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  },
            child: isLoading
                ? const SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : const Text(
                    'Hoàn thành',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget placesAutoCompleteTextField() {
    return GooglePlaceAutoCompleteTextField(
      textEditingController: addressController,
      googleAPIKey: AppKey.googleAPIKey,
      focusNode: addressFocusNode,
      boxDecoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      inputDecoration: InputDecoration(
        hintText: widget.userAddress,
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.scaffoldBg,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.location_on, color: Colors.black54, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      debounceTime: 400,
      countries: const ["vn"],
      isLatLngRequired: true,
      getPlaceDetailWithLatLng: (Prediction prediction) {},
      itemClick: (Prediction prediction) {
        FocusScope.of(context).unfocus();
        Future.delayed(
          const Duration(milliseconds: 100),
          () {
            addressController.text = prediction.description ?? "";
            addressController.selection = TextSelection.fromPosition(
              TextPosition(offset: prediction.description?.length ?? 0),
            );
          },
        );
      },
      seperatedBuilder: const Divider(),
      containerHorizontalPadding: 0,
      isCrossBtnShown: true,
    );
  }
}
