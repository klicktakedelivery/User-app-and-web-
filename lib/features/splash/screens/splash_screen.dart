import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/no_internet_screen.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBodyModel? body;
  const SplashScreen({super.key, required this.body});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;

  bool _requestedConfigOnce = false;

  @override
  void initState() {
    super.initState();

    _initOnce();
    _listenConnectivity();
  }

  void _initOnce() {
    // ✅ مرة واحدة فقط

    final address = AddressHelper.getUserAddressFromSharedPref();
    if (address != null && address.zoneIds == null) {
      Get.find<AuthController>().clearSharedAddress();
    }

    if ((AuthHelper.getGuestId().isNotEmpty || AuthHelper.isLoggedIn()) &&
        Get.find<SplashController>().cacheModule != null) {
      Get.find<CartController>().getCartDataOnline();
    }

    // ✅ اطلب الكونفيغ مرة واحدة بعد أول فريم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_requestedConfigOnce) return;
      _requestedConfigOnce = true;
      Get.find<SplashController>().getConfigData(notificationBody: widget.body);
    });
  }

  void _listenConnectivity() {
    bool firstTime = true;

    _onConnectivityChanged =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      final bool isConnected =
          result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);

      if (!mounted) return;

      if (!firstTime) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: Duration(seconds: isConnected ? 3 : 6000),
            content: Text(
              isConnected ? 'connected'.tr : 'no_connection'.tr,
              textAlign: TextAlign.center,
            ),
          ),
        );

        // ✅ عند رجوع النت: أعد تحميل الكونفيغ (مرة عند كل رجوع اتصال)
        if (isConnected) {
          Get.find<SplashController>().getConfigData(notificationBody: widget.body);
        }
      }

      firstTime = false;
    });
  }

  @override
  void dispose() {
    _onConnectivityChanged?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      body: GetBuilder<SplashController>(builder: (splashController) {
        if (!splashController.hasConnection) {
          // ✅ لا تعمل SplashScreen داخل SplashScreen (يسبب تكرار initState وطلبات API)
          return const NoInternetScreen(child: SizedBox());
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(Images.logo, width: 200),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ],
          ),
        );
      }),
    );
  }
}
