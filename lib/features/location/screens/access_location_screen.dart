import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:sixam_mart/common/widgets/address_widget.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/no_internet_screen.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/location/screens/web_landing_page.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class AccessLocationScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromHome;
  final String? route;

  const AccessLocationScreen({
    super.key,
    required this.fromSignUp,
    required this.fromHome,
    required this.route,
  });

  @override
  State<AccessLocationScreen> createState() => _AccessLocationScreenState();
}

class _AccessLocationScreenState extends State<AccessLocationScreen> {
  bool _canExit = GetPlatform.isWeb;

  @override
  void initState() {
    super.initState();

    if (AuthHelper.isLoggedIn()) {
      Get.find<AddressController>().getAddressList();
    }

    _checkInternetOnce();
  }

  Future<void> _checkInternetOnce() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    if (!mounted) return;

    final bool isConnected = results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile);
    if (!isConnected) {
      Get.offAll(() => const NoInternetScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (_canExit) {
          if (GetPlatform.isAndroid || GetPlatform.isIOS) {
            SystemNavigator.pop();
          } else {
            Navigator.pushNamed(context, RouteHelper.getInitialRoute());
          }
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          ),
        );

        _canExit = true;
        Timer(const Duration(seconds: 2), () {
          _canExit = false;
        });
      },
      child: Scaffold(
        appBar: CustomAppBar(title: 'set_location'.tr, backButton: widget.fromHome),
        endDrawer: const MenuDrawer(),
        endDrawerEnableOpenDragGesture: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.zero : const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: GetBuilder<AddressController>(
              builder: (addressController) {
                final bool isLoggedIn = AuthHelper.isLoggedIn();
                final bool isDesktop = ResponsiveHelper.isDesktop(context);
                final bool noSavedAddress = AddressHelper.getUserAddressFromSharedPref() == null;

                if (isDesktop && noSavedAddress) {
                  return WebLandingPage(
                    fromSignUp: widget.fromSignUp,
                    fromHome: widget.fromHome,
                    route: widget.route,
                  );
                }

                if (!isLoggedIn) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: FooterView(
                        child: SizedBox(
                          width: 700,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(Images.deliveryLocation, height: 220),
                              const SizedBox(height: Dimensions.paddingSizeLarge),
                              Text(
                                'find_stores_and_items'.tr.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                                child: Text(
                                  'by_allowing_location_access'.tr,
                                  textAlign: TextAlign.center,
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeLarge),
                              Padding(
                                padding: ResponsiveHelper.isWeb()
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                                child: BottomButton(fromSignUp: widget.fromSignUp, route: widget.route),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Logged in
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: FooterView(
                          child: Column(
                            mainAxisAlignment: (addressController.addressList != null && addressController.addressList!.isNotEmpty)
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              if (addressController.addressList == null)
                                const Center(child: CircularProgressIndicator())
                              else if (addressController.addressList!.isEmpty)
                                NoDataScreen(text: 'no_saved_address_found'.tr)
                              else
                                ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: addressController.addressList!.length,
                                  itemBuilder: (context, index) {
                                    return Center(
                                      child: SizedBox(
                                        width: 700,
                                        child: AddressWidget(
                                          address: addressController.addressList![index],
                                          fromAddress: false,
                                          onTap: () {
                                            Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);

                                            final AddressModel address = addressController.addressList![index];
                                            Get.find<LocationController>().saveAddressAndNavigate(
                                              address,
                                              widget.fromSignUp,
                                              widget.route,
                                              widget.route != null,
                                              isDesktop,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: Dimensions.paddingSizeLarge),
                              isDesktop ? BottomButton(fromSignUp: widget.fromSignUp, route: widget.route) : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    isDesktop ? const SizedBox() : BottomButton(fromSignUp: widget.fromSignUp, route: widget.route),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BottomButton extends StatelessWidget {
  final bool fromSignUp;
  final String? route;

  const BottomButton({
    super.key,
    required this.fromSignUp,
    required this.route,
  });

  void _openPickMap(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    if (isDesktop) {
      showGeneralDialog(
        context: context,
        pageBuilder: (_, __, ___) {
          return SizedBox(
            height: 300,
            width: 300,
            child: PickMapScreen(
              fromSignUp: fromSignUp,
              canRoute: route != null,
              fromAddAddress: false,
              route: route ?? RouteHelper.accessLocation,
            ),
          );
        },
      );
    } else {
      Get.toNamed(
        RouteHelper.getPickMapRoute(
          route ?? (fromSignUp ? RouteHelper.signUp : RouteHelper.accessLocation),
          route != null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 700,
        child: Column(
          children: [
            CustomButton(
              buttonText: 'user_current_location'.tr,
              icon: Icons.my_location,
              onPressed: () {
                // ✅ التقط isDesktop قبل أي await (حل use_build_context_synchronously)
                final bool isDesktop = ResponsiveHelper.isDesktop(context);

                // ✅ مسار واحد فقط: current location -> saveAddressAndNavigate
                Get.find<LocationController>().checkPermission(() async {
                  Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);

                  try {
                    final AddressModel address = await Get.find<LocationController>().getCurrentLocation(true);

                    // لا نغلق الـ loader هنا
                    // LocationController سيغلقه حسب النجاح/الفشل/التغطية
                    Get.find<LocationController>().saveAddressAndNavigate(
                      address,
                      fromSignUp,
                      route,
                      route != null,
                      isDesktop,
                    );
                  } catch (_) {
                    if (Get.isDialogOpen ?? false) Get.back();
                    showCustomSnackBar('something_went_wrong'.tr);
                  }
                });
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                minimumSize: const Size(Dimensions.webMaxWidth, 50),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => _openPickMap(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                    child: Icon(Icons.map, color: Theme.of(context).primaryColor),
                  ),
                  Text(
                    'set_from_map'.tr,
                    textAlign: TextAlign.center,
                    style: robotoBold.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
