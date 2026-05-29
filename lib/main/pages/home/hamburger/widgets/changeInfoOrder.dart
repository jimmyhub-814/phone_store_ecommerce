import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_key.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';

class ChangeOrderInfo extends StatefulWidget {
  final String userPhone;
  final String userName;
  final String userAddress;
  static const String routeName = '/changeOrderInfo';

  const ChangeOrderInfo(
      {super.key,
      required this.userPhone,
      required this.userAddress,
      required this.userName});

  @override
  State<ChangeOrderInfo> createState() => _ChangeOrderInfoState();
}

class _ChangeOrderInfoState extends State<ChangeOrderInfo> {
  late TextEditingController addressController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  FocusNode? addressFocusNode;

  @override
  void initState() {
    super.initState();
    addressFocusNode = FocusNode();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    nameController.text = widget.userName;
    phoneController.text = widget.userPhone;
    addressController.text = widget.userAddress;
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
          'Thay đổi thông tin',
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
            const Center(
              child: Text(
                'Thông tin giao hàng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
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
                hintText:
                    widget.userName.isEmpty ? 'Chưa cập nhật' : widget.userName,
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
                hintText: widget.userPhone.isEmpty
                    ? 'Chưa cập nhật'
                    : widget.userPhone,
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
            onPressed: () {
              if (nameController.text.isEmpty ||
                  phoneController.text.isEmpty ||
                  addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Vui lòng điền đầy đủ thông tin',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(context, {
                "userName": nameController.text,
                "userPhone": phoneController.text,
                "userAddress": addressController.text,
              });
            },
            child: const Text(
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
        hintText: widget.userAddress.isNotEmpty
            ? widget.userAddress
            : 'Chưa cập nhật',
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
