import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class BadWeatherWidget extends StatefulWidget {
  final bool inParcel;
  const BadWeatherWidget({super.key, this.inParcel = false});

  @override
  State<BadWeatherWidget> createState() => _BadWeatherWidgetState();
}

class _BadWeatherWidgetState extends State<BadWeatherWidget> {
  @override
  void initState() {
    super.initState();

    // احصل على السعر الإضافي بناءً على المنطقة والوحدة الزمنية الحالية والوحدة.
    final zoneId =
        AddressHelper.getUserAddressFromSharedPref()?.zoneId?.toString() ?? '';
    final moduleId = ModuleHelper.getModule()?.id.toString() ??
        ModuleHelper.getCacheModule()?.id.toString() ??
        '';
    final dateTime = DateConverter.dateToDateTime(DateTime.now());
    final guestId = AuthHelper.getGuestId(); // غالباً String جاهز

    Get.find<CheckoutController>().getSurgePrice(
      zoneId: zoneId,
      moduleId: moduleId,
      dateTime: dateTime,
      guestId: guestId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(builder: (checkoutController) {
      // إذا كان هناك ملاحظة للعميل بسبب الطقس السيئ، اعرضها.
      if (checkoutController.surgePrice?.customerNoteStatus == 1) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isDesktop(context)
                ? 0
                : widget.inParcel
                ? 0
                : Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeLarge,
          ),
          child: Row(
            children: [
              Image.asset(Images.weather, height: 50, width: 50),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  checkoutController.surgePrice?.customerNote ?? '',
                  style: robotoRegular,
                ),
              ),
            ],
          ),
        );
      } else {
        return const SizedBox();
      }
    });
  }
}
