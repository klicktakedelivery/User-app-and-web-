import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter/gestures.dart';

import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/widgets/cookies_view.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/notification_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/dark_theme.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/messages.dart';
import 'services/api_cache_manager.dart';
import 'services/shared_preferences_fix.dart';
import 'controllers/zone_controller.dart';
import 'controllers/module_controller.dart';

import 'helper/get_di.dart' as di;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (ResponsiveHelper.isMobilePhone()) {
    HttpOverrides.global = MyHttpOverrides();
  }

  setPathUrlStrategy();

  // ═══════════════════════════════════════════════════════════
  // 🔧 تهيئة Services الجديدة قبل Firebase
  // ═══════════════════════════════════════════════════════════
  if (kDebugMode) {
    print('🚀 Initializing Klicktake services...');
  }
  
  try {
    // 1. تهيئة Shared Preferences
    await PreferencesHelper.init();
    if (kDebugMode) {
      print('✅ SharedPreferences initialized');
    }
    
    // 2. تهيئة API Cache Manager
    await ApiCacheManager.init();
    if (kDebugMode) {
      print('✅ ApiCacheManager initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Error initializing services: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Firebase initialization (الكود الأصلي)
  // ═══════════════════════════════════════════════════════════
  if (GetPlatform.isWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD0Z911mOoWCVkeGdjhIKwWFPRgvd6ZyAw",
        authDomain: "stackmart-500c7.firebaseapp.com",
        projectId: "stackmart-500c7",
        storageBucket: "stackmart-500c7.appspot.com",
        messagingSenderId: "491987943015",
        appId: "1:491987943015:web:d8bc7ab8dbc9991c8f1ec2",
      ),
    );
  } else if (GetPlatform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCr3arpsLC5D1i4WTl4RiKWT5btWXrS2N0",
        appId: "1:457186597740:android:1679f53e3f6ea87698f149",
        messagingSenderId: "457186597740",
        projectId: "klicktake-29b82",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  final Map<String, Map<String, String>> languages = await di.init();

  // ═══════════════════════════════════════════════════════════
  // 🎯 تسجيل Controllers الجديدة بعد di.init()
  // ═══════════════════════════════════════════════════════════
  try {
    Get.put(ZoneController(), permanent: true);
    Get.put(ModuleController(), permanent: true);
    
    if (kDebugMode) {
      print('✅ Performance controllers registered');
      print('🎉 Klicktake services initialized successfully!');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Error registering controllers: $e');
    }
  }

  NotificationBodyModel? body;
  try {
    if (GetPlatform.isMobile) {
      final RemoteMessage? remoteMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (remoteMessage != null) {
        body = NotificationHelper.convertNotification(remoteMessage.data);
      }
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  } catch (_) {}

  if (ResponsiveHelper.isWeb()) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "380903914182154",
      cookie: true,
      xfbml: true,
      version: "v15.0",
    );
  }

  runApp(MyApp(languages: languages, body: body));
}

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>>? languages;
  final NotificationBodyModel? body;

  const MyApp({super.key, required this.languages, required this.body});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    if (GetPlatform.isWeb) {
      Get.find<SplashController>().initSharedData();

      final address = AddressHelper.getUserAddressFromSharedPref();
      if (address != null && address.zoneIds == null) {
        Get.find<AuthController>().clearSharedAddress();
      }

      if (!AuthHelper.isLoggedIn() && !AuthHelper.isGuestLoggedIn()) {
        await Get.find<AuthController>().guestLogin();
      }

      if ((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) &&
          Get.find<SplashController>().cacheModule != null) {
        Get.find<CartController>().getCartDataOnline();
      }

      Get.find<SplashController>().getConfigData(
        loadLandingData: (GetPlatform.isWeb &&
            AddressHelper.getUserAddressFromSharedPref() == null),
        fromMainFunction: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetBuilder<SplashController>(builder: (splashController) {
          // على الويب: انتظر configModel قبل بناء التطبيق
          if (GetPlatform.isWeb && splashController.configModel == null) {
            return const SizedBox();
          }

          return GetMaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: false,

            navigatorKey: Get.key,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
              },
            ),

            theme: themeController.darkTheme ? dark() : light(),
            locale: localizeController.locale,
            translations: Messages(languages: widget.languages),
            fallbackLocale: Locale(
              AppConstants.languages[0].languageCode!,
              AppConstants.languages[0].countryCode,
            ),
            initialRoute: GetPlatform.isWeb
                ? RouteHelper.getInitialRoute()
                : RouteHelper.getSplashRoute(widget.body),
            getPages: RouteHelper.routes,
            defaultTransition: Transition.topLevel,
            transitionDuration: const Duration(milliseconds: 500),

            builder: (BuildContext context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1)),
                child: Material(
                  child: Stack(
                    children: [
                      child ?? const SizedBox(),

                      GetBuilder<SplashController>(builder: (splashController) {
                        final cookiesText = splashController.configModel != null
                            ? splashController.configModel!.cookiesText ?? ''
                            : '';
                        final shouldShow = !splashController.savedCookiesData &&
                            !splashController.getAcceptCookiesStatus(cookiesText);

                        if (shouldShow) {
                          return ResponsiveHelper.isWeb()
                              ? const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: CookiesView(),
                                )
                              : const SizedBox();
                        }
                        return const SizedBox();
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        });
      });
    });
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}