import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_failed_dialog.dart';

class OrderSuccessfulDialog extends StatefulWidget {
  final String? orderID;
  const OrderSuccessfulDialog({super.key, required this.orderID});

  @override
  State<OrderSuccessfulDialog> createState() => _OrderSuccessfulDialogState();
}

class _OrderSuccessfulDialogState extends State<OrderSuccessfulDialog> {
  bool? _isCashOnDeliveryActive = false;

  @override
  void initState() {
    super.initState();
    Get.find<OrderController>().trackOrder(widget.orderID.toString(), null, false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await Get.offAllNamed(RouteHelper.getInitialRoute());
      },
      child: GetBuilder<OrderController>(builder: (orderController) {
        double total = 0;
        bool success = true;
        bool parcel = false;
        double? maximumCodOrderAmount;

        final track = orderController.trackModel;
        final address = AddressHelper.getUserAddressFromSharedPref();

        if (track != null) {
          // Loyalty points calculation
          final loyaltyPointValue =
              Get.find<SplashController>().configModel?.loyaltyPointItemPurchasePoint ?? 0;
          total = ((track.orderAmount ?? 0) / 100) * loyaltyPointValue;

          // Determine success
          success = track.paymentStatus == 'paid' ||
              track.paymentMethod == 'cash_on_delivery' ||
              track.paymentMethod == 'partial_payment';

          // Determine parcel order type correctly
          parcel = track.orderType == 'parcel';

          // Validate zone data
          if (address?.zoneData != null) {
            for (ZoneData zData in address!.zoneData!) {
              if (zData.modules != null) {
                for (Modules m in zData.modules!) {
                  if (m.id == Get.find<SplashController>().module?.id) {
                    maximumCodOrderAmount = m.pivot?.maximumCodOrderAmount;
                    break;
                  }
                }
              }

              if (zData.id == address.zoneId) {
                _isCashOnDeliveryActive = zData.cashOnDelivery ?? false;
              }
            }
          }

          // If failed → show failed dialog
          if (!success &&
              !Get.isDialogOpen! &&
              track.orderStatus != 'canceled') {
            Future.delayed(const Duration(seconds: 1), () {
              Get.dialog(
                PaymentFailedDialog(
                  orderID: widget.orderID,
                  isCashOnDelivery: _isCashOnDeliveryActive,
                  orderAmount: total,
                  maxCodOrderAmount: maximumCodOrderAmount,
                  orderType: parcel ? 'parcel' : 'delivery',
                  guestId: '',
                ),
                barrierDismissible: false,
              );
            });
          }
        }

        return track != null
            ? Center(
          child: Container(
            width: 500,
            height: 390,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
              BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ResponsiveHelper.isDesktop(context)
                      ? Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.clear),
                    ),
                  )
                      : const SizedBox(),

                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                  Image.asset(
                    success ? Images.checked : Images.warning,
                    width: 55,
                    height: 55,
                  ),

                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  Text(
                    success
                        ? parcel
                        ? 'you_placed_the_parcel_request_successfully'.tr
                        : 'you_placed_the_order_successfully'.tr
                        : 'your_order_is_failed_to_place'.tr,
                    style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                        vertical: Dimensions.paddingSizeSmall),
                    child: Text(
                      success
                          ? parcel
                          ? 'your_parcel_request_is_placed_successfully'.tr
                          : 'your_order_is_placed_successfully'.tr
                          : 'your_order_is_failed_to_place_because'.tr,
                      style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).disabledColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
          ),
        )
            : const Center(child: CircularProgressIndicator());
      }),
    );
  }
}
