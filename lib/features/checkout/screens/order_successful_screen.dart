import 'dart:async';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_failed_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderSuccessfulScreen extends StatefulWidget {
  final String? orderID;
  final String? contactPersonNumber;
  final bool? createAccount;
  final String guestId;
  const OrderSuccessfulScreen({
    super.key,
    required this.orderID,
    this.contactPersonNumber,
    this.createAccount = false,
    required this.guestId,
  });

  @override
  State<OrderSuccessfulScreen> createState() => _OrderSuccessfulScreenState();
}

class _OrderSuccessfulScreenState extends State<OrderSuccessfulScreen> {

  bool? _isCashOnDeliveryActive = false;
  String? orderId;

  @override
  void initState() {
    super.initState();

    /// معالجة orderID في حال احتوت على '?'
    orderId = widget.orderID ?? '';
    if(orderId!.contains('?')){
      orderId = orderId!.split('?').first.trim();
    }

    /// تأكد أن orderId ليست فارغة قبل الاتصال
    if(orderId != null && orderId!.isNotEmpty){
      Get.find<OrderController>().trackOrder(orderId!, null, false, contactNumber: widget.contactPersonNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await Get.offAllNamed(RouteHelper.getInitialRoute());
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
        endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
        body: GetBuilder<OrderController>(builder: (orderController){

          double total = 0;
          bool success = true;
          bool parcel = false;
          bool takeAway = false;
          double? maximumCodOrderAmount;

          final track = orderController.trackModel;

          if(track != null) {

            /// حماية من null
            final config = Get.find<SplashController>().configModel;

            total = ((track.orderAmount ?? 0) / 100) * (config?.loyaltyPointItemPurchasePoint ?? 0);

            success =
                track.paymentStatus == 'paid' ||
                    track.paymentMethod == 'cash_on_delivery' ||
                    track.paymentMethod == 'partial_payment' ||
                    track.paymentMethod == 'wallet';

            parcel = track.orderType == 'parcel';
            takeAway = track.orderType == 'take_away';

            final userAddress = AddressHelper.getUserAddressFromSharedPref();

            if(userAddress?.zoneData != null){
              for(ZoneData zData in userAddress!.zoneData!) {

                /// حساب الحد الأعلى للـ COD
                for(Modules m in zData.modules ?? []) {
                  if(m.id == Get.find<SplashController>().module?.id) {
                    maximumCodOrderAmount = m.pivot?.maximumCodOrderAmount;
                    break;
                  }
                }

                /// تفعيل أو تعطيل الدفع عند الاستلام
                if(zData.id == userAddress.zoneId){
                  _isCashOnDeliveryActive = zData.cashOnDelivery ?? false;
                }
              }
            }

            /// عرض نافذة فشل الدفع
            if (!success &&
                !Get.isDialogOpen! &&
                track.orderStatus != 'canceled' &&
                Get.currentRoute.startsWith(RouteHelper.orderSuccess)) {

              Future.delayed(const Duration(seconds: 1), () {
                Get.dialog(
                  PaymentFailedDialog(
                    orderID: orderId,
                    isCashOnDelivery: _isCashOnDeliveryActive,
                    orderAmount: total,
                    maxCodOrderAmount: maximumCodOrderAmount,
                    orderType: parcel ? 'parcel' : 'delivery',
                    guestId: widget.guestId,
                  ),
                  barrierDismissible: false,
                );
              });
            }
          }

          return track != null ? Center(
            child: SingleChildScrollView(
              child: FooterView(
                child: SizedBox(
                  width: Dimensions.webMaxWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Image.asset(
                        success ? Images.checked : Images.warning,
                        width: 100, height: 100,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Text(
                        success
                            ? parcel
                            ? 'you_placed_the_parcel_request_successfully'.tr
                            : 'you_placed_the_order_successfully'.tr
                            : 'your_order_is_failed_to_place'.tr,
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                      ),

                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      widget.createAccount == true ? Padding(
                        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('and_create_account_successfully'.tr, style: robotoMedium),
                            InkWell(
                              onTap: () {
                                if(ResponsiveHelper.isDesktop(context)){
                                  Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)));
                                }else{
                                  Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                child: Text('sign_in'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                              ),
                            ),
                          ],
                        ),
                      ) : const SizedBox(),

                      AuthHelper.isGuestLoggedIn()
                          ? SelectableText(
                        '${'order_id'.tr}: $orderId',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                          : const SizedBox(),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeLarge,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                        child: Text(
                          success
                              ? parcel
                              ? 'your_parcel_request_is_placed_successfully'.tr
                              : takeAway
                              ? 'thank_you_for_your_order'.tr
                              : 'your_order_is_placed_successfully'.tr
                              : 'your_order_is_failed_to_place_because'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 30),

                      Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: CustomButton(
                          width: ResponsiveHelper.isDesktop(context) ? 300 : double.infinity,
                          buttonText: 'back_to_home'.tr,
                          onPressed: () {
                            if(AuthHelper.isLoggedIn()) {
                              Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
                            }
                            Get.offAllNamed(RouteHelper.getInitialRoute());
                          },
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ) : const Center(child: CircularProgressIndicator());
        }),
      ),
    );
  }
}
