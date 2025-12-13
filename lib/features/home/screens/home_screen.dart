import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/widgets/all_store_filter_widget.dart';
import 'package:sixam_mart/features/home/widgets/cashback_logo_widget.dart';
import 'package:sixam_mart/features/home/widgets/cashback_dialog_widget.dart';
import 'package:sixam_mart/features/home/widgets/refer_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/home/screens/modules/food_home_screen.dart';
import 'package:sixam_mart/features/home/screens/modules/grocery_home_screen.dart';
import 'package:sixam_mart/features/home/screens/modules/pharmacy_home_screen.dart';
import 'package:sixam_mart/features/home/screens/modules/shop_home_screen.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/home/screens/taxi_home_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/home/screens/web_new_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/module_view.dart';
import 'package:sixam_mart/features/parcel/screens/parcel_category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// تحميل بيانات الهوم سكرين (محسّن: مرحلتين + يمنع الضغط المفاجئ)
  static Future<void> loadData(bool reload, {bool fromModule = false}) async {
    final splashController = Get.find<SplashController>();
    final module = splashController.configModel?.moduleConfig?.module;

    // أساسيات خفيفة ومهمة
    Get.find<LocationController>().syncZoneData();
    Get.find<FlashSaleController>().setEmptyFlashSale(fromModule: fromModule);

    if (AuthHelper.isLoggedIn()) {
      // خفيف ومفيد
      Get.find<StoreController>().getVisitAgainStoreList(fromModule: fromModule);
    }

    final hasNormalModule = splashController.module != null &&
        module != null &&
        !(module.isParcel ?? false) &&
        !(module.isTaxi ?? false);

    // =========================
    // المرحلة 1 (Critical): أقل عدد Calls ممكن لظهور الصفحة بسرعة
    // =========================
    if (hasNormalModule) {
      await Get.find<BannerController>().getBannerList(reload);
      await Get.find<CategoryController>().getCategoryList(reload);
      await Get.find<BannerController>().getPromotionalBannerList(reload);
      await Get.find<CampaignController>().getBasicCampaignList(reload);
      await Get.find<CampaignController>().getItemCampaignList(reload);
    }

    // بيانات المستخدم (بعد الأساسيات)
    if (AuthHelper.isLoggedIn()) {
      await Get.find<ProfileController>().getUserInfo();
      Get.find<NotificationController>().getNotificationList(reload);
      Get.find<CouponController>().getCouponList();
    }

    // مهم لكنه لا يحتاج “تفجير” كل شيء
    await splashController.getModules();

    final updatedConfig = splashController.configModel;
    final updatedModule = updatedConfig?.moduleConfig?.module;

    // لو ما في موديل محدد: هذا يعتبر أساسي للشاشة
    if (splashController.module == null && updatedConfig?.module == null) {
      await Get.find<BannerController>().getFeaturedBanner();
      await Get.find<StoreController>().getFeaturedStoreList();
      if (AuthHelper.isLoggedIn()) {
        Get.find<AddressController>().getAddressList();
      }
    }

    // Parcel
    if (splashController.module != null && (updatedModule?.isParcel ?? false)) {
      Get.find<ParcelController>().getParcelCategoryList();
    }

    // Pharmacy: الأساسيات فقط هنا
    if (splashController.module != null &&
        splashController.module!.moduleType.toString() == AppConstants.pharmacy) {
      Get.find<ItemController>().getBasicMedicine(reload, false);
      Get.find<StoreController>().getFeaturedStoreList();
    }

    // =========================
    // المرحلة 2 (Deferred): أشياء ثقيلة تسبب CPU spikes + Jank
    // =========================
    Future.delayed(const Duration(milliseconds: 400), () async {
      // حماية ضد أي حالة غير متوقعة
      if (!Get.isRegistered<SplashController>()) return;

      final sc = Get.find<SplashController>();
      final mod = sc.module;

      if (mod == null) return;

      final isParcel = mod.moduleType.toString() == AppConstants.parcel;
      final isTaxi = mod.moduleType.toString() == AppConstants.taxi;

      if (!isParcel && !isTaxi && hasNormalModule) {
        final moduleType = mod.moduleType.toString();

        Get.find<StoreController>().getRecommendedStoreList();
        Get.find<ItemController>().getDiscountedItemList(offset: '1', firstTimeCategoryLoad: true);
        Get.find<ItemController>().getPopularItemList(offset: '1', firstTimeCategoryLoad: true);
        Get.find<ItemController>().getReviewedItemList(offset: '1', firstTimeCategoryLoad: true);
        Get.find<StoreController>().getPopularStoreList(reload, 'all', false);
        Get.find<StoreController>().getLatestStoreList(reload, 'all', false);
        Get.find<StoreController>().getTopOfferStoreList(reload, false);
        Get.find<ItemController>().getRecommendedItemList(reload, 'all', false);
        Get.find<StoreController>().getStoreList(1, reload);
        Get.find<AdvertisementController>().getAdvertisementList();

        if (moduleType == AppConstants.grocery) {
          Get.find<FlashSaleController>().getFlashSale(reload, false);
        }

        if (moduleType == AppConstants.ecommerce) {
          Get.find<ItemController>().getFeaturedCategoriesItemList(false, false);
          Get.find<FlashSaleController>().getFlashSale(reload, false);
          Get.find<BrandsController>().getBrandList();
        }
      }

      // Pharmacy الثقيل مؤجل
      if (mod.moduleType.toString() == AppConstants.pharmacy) {
        await Get.find<ItemController>().getCommonConditions(false);
        if (Get.find<ItemController>().commonConditions != null &&
            Get.find<ItemController>().commonConditions!.isNotEmpty) {
          Get.find<ItemController>()
              .getConditionsWiseItem(Get.find<ItemController>().commonConditions![0].id!, false);
        }
      }
    });
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool searchBgShow = false;
  final GlobalKey _headerKey = GlobalKey();

  // يمنع تحميل API أكثر من مرة بسبب rebuilds
  bool _didInitLoad = false;

  // تحسين جَنك السكروول: Debounce بدل ما نسوي Future.delayed لكل حركة
  Timer? _favDebounce;

  // يمنع switchModule داخل build (لأنه يسبب rebuilds متكررة)
  bool _didAutoSwitchSingleModule = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_didInitLoad) return;
      _didInitLoad = true;

      // تحميل البيانات بعد أول فريم (تمام) لكن بشكل أخف (مرحلتين)
      await HomeScreen.loadData(false);

      Get.find<SplashController>().getReferBottomSheetStatus();

      final profile = Get.find<ProfileController>().userInfoModel;
      final splash = Get.find<SplashController>();

      if ((profile?.isValidForDiscount ?? false) && splash.showReferBottomSheet) {
        _showReferBottomSheet();
      }

      if (!ResponsiveHelper.isWeb()) {
        final savedAddress = AddressHelper.getUserAddressFromSharedPref();
        if (savedAddress != null) {
          Get.find<LocationController>().getZone(
            savedAddress.latitude,
            savedAddress.longitude,
            false,
            updateInAddress: true,
          );
        }
      }
    });
  }

  void _onScroll() {
    final homeController = Get.find<HomeController>();
    if (!homeController.showFavButton) return;

    // بدل flip-flop كل مرة: نخفي مرة واحدة، ونرجع بعد سكون السكروول
    homeController.changeFavVisibility();
    _favDebounce?.cancel();
    _favDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        homeController.changeFavVisibility();
      }
    });
  }

  @override
  void dispose() {
    _favDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showReferBottomSheet() {
    ResponsiveHelper.isDesktop(context)
        ? Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        insetPadding: const EdgeInsets.all(22),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: const ReferBottomSheetWidget(),
      ),
      useSafeArea: false,
    ).then((value) => Get.find<SplashController>().saveReferBottomSheetStatus(false))
        : showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: const ReferBottomSheetWidget(),
        );
      },
    ).then((value) => Get.find<SplashController>().saveReferBottomSheetStatus(false));
  }

  Future<void> loadTaxiApis() async {
    await Get.find<TaxiHomeController>().getTaxiBannerList(true);
    await Get.find<TaxiHomeController>().getTopRatedCarList(1, true);
    if (AuthHelper.isLoggedIn()) {
      await Get.find<AddressController>().getAddressList();
      await Get.find<TaxiHomeController>().getTaxiCouponList(true);
      await Get.find<TaxiCartController>().getCarCartList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAddress = AddressHelper.getUserAddressFromSharedPref();

    return GetBuilder<SplashController>(builder: (splashController) {
      // ✨ مهم: لا تعمل switchModule داخل build بشكل متكرر
      if (!_didAutoSwitchSingleModule &&
          splashController.moduleList != null &&
          splashController.moduleList!.length == 1) {
        _didAutoSwitchSingleModule = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) splashController.switchModule(0, true);
        });
      }

      final showMobileModule = !ResponsiveHelper.isDesktop(context) &&
          splashController.module == null &&
          splashController.configModel!.module == null;

      final isParcel = splashController.module != null &&
          splashController.module!.moduleType.toString() == AppConstants.parcel;
      final isPharmacy = splashController.module != null &&
          splashController.module!.moduleType.toString() == AppConstants.pharmacy;
      final isFood = splashController.module != null &&
          splashController.module!.moduleType.toString() == AppConstants.food;
      final isShop = splashController.module != null &&
          splashController.module!.moduleType.toString() == AppConstants.ecommerce;
      final isGrocery = splashController.module != null &&
          splashController.module!.moduleType.toString() == AppConstants.grocery;
      final isTaxi = splashController.module != null &&
          splashController.module!.moduleType.toString() == AppConstants.taxi;

      return GetBuilder<HomeController>(builder: (homeController) {
        return Scaffold(
          appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
          endDrawer: const MenuDrawer(),
          endDrawerEnableOpenDragGesture: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: isParcel
              ? const ParcelCategoryScreen()
              : SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                splashController.setRefreshing(true);

                if (splashController.module != null && !isTaxi) {
                  // ✅ بدل تكرار 100 استدعاء هنا، استخدم نفس نظام التحميل المحسن
                  await HomeScreen.loadData(true);
                } else if (isTaxi) {
                  await loadTaxiApis();
                } else {
                  await Get.find<BannerController>().getFeaturedBanner();
                  await splashController.getModules();
                  if (AuthHelper.isLoggedIn()) {
                    await Get.find<AddressController>().getAddressList();
                  }
                  await Get.find<StoreController>().getFeaturedStoreList();
                }

                splashController.setRefreshing(false);
              },
              child: ResponsiveHelper.isDesktop(context)
                  ? WebNewHomeScreen(scrollController: _scrollController)
                  : CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  /// App Bar
                  SliverAppBar(
                    floating: true,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    surfaceTintColor: Theme.of(context).colorScheme.surface,
                    backgroundColor: ResponsiveHelper.isDesktop(context)
                        ? Colors.transparent
                        : Theme.of(context).colorScheme.surface,
                    title: Center(
                      child: Container(
                        width: Dimensions.webMaxWidth,
                        height: Get.find<LocalizationController>().isLtr ? 60 : 70,
                        color: Theme.of(context).colorScheme.surface,
                        child: Row(
                          children: [
                            (splashController.module != null &&
                                splashController.configModel!.module == null &&
                                splashController.moduleList != null &&
                                splashController.moduleList!.length != 1)
                                ? InkWell(
                              onTap: () {
                                splashController.removeModule();
                                Get.find<StoreController>().resetStoreData();
                              },
                              child: Image.asset(
                                Images.moduleIcon,
                                height: 25,
                                width: 25,
                                color: Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                            )
                                : const SizedBox(),
                            SizedBox(
                              width: (splashController.module != null &&
                                  splashController.configModel!.module == null &&
                                  splashController.moduleList != null &&
                                  splashController.moduleList!.length != 1)
                                  ? Dimensions.paddingSizeSmall
                                  : 0,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => Get.find<LocationController>()
                                    .navigateToLocationScreen('home'),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: Dimensions.paddingSizeSmall,
                                    horizontal:
                                    ResponsiveHelper.isDesktop(context)
                                        ? Dimensions.paddingSizeSmall
                                        : 0,
                                  ),
                                  child: GetBuilder<LocationController>(
                                      builder: (locationController) {
                                        final addressTypeKey = AuthHelper.isLoggedIn()
                                            ? (userAddress?.addressType ?? 'your_location')
                                            : 'your_location';

                                        final addressLine = userAddress?.address ?? '';

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              addressTypeKey.tr,
                                              style: robotoMedium.copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge!
                                                    .color,
                                                fontSize: Dimensions.fontSizeDefault,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    addressLine,
                                                    style: robotoRegular.copyWith(
                                                      color: Theme.of(context).disabledColor,
                                                      fontSize: Dimensions.fontSizeSmall,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.expand_more,
                                                  color: Theme.of(context).disabledColor,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      }),
                                ),
                              ),
                            ),
                            InkWell(
                              child: GetBuilder<NotificationController>(
                                  builder: (notificationController) {
                                    return Stack(
                                      children: [
                                        Icon(
                                          CupertinoIcons.bell,
                                          size: 25,
                                          color: Theme.of(context).textTheme.bodyLarge!.color,
                                        ),
                                        notificationController.hasNotification
                                            ? Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            height: 10,
                                            width: 10,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                width: 1,
                                                color: Theme.of(context).cardColor,
                                              ),
                                            ),
                                          ),
                                        )
                                            : const SizedBox(),
                                      ],
                                    );
                                  }),
                              onTap: () => Get.toNamed(
                                RouteHelper.getNotificationRoute(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: const [SizedBox()],
                  ),

                  /// Search Button
                  !showMobileModule && !isTaxi
                      ? SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverDelegate(
                      callback: (val) {},
                      child: Center(
                        child: Container(
                          height: 50,
                          width: Dimensions.webMaxWidth,
                          color: searchBgShow
                              ? Get.find<ThemeController>().darkTheme
                              ? Theme.of(context).colorScheme.surface
                              : Theme.of(context).cardColor
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeSmall,
                          ),
                          child: InkWell(
                            onTap: () => Get.toNamed(
                              RouteHelper.getSearchRoute(),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeSmall,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.search,
                                    size: 25,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                  Expanded(
                                    child: Text(
                                      Get.find<SplashController>()
                                          .configModel!
                                          .moduleConfig!
                                          .module!
                                          .showRestaurantText!
                                          ? 'search_food_or_restaurant'.tr
                                          : 'search_item_or_store'.tr,
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                      : const SliverToBoxAdapter(),

                  SliverToBoxAdapter(
                    child: Center(
                      child: SizedBox(
                        width: Dimensions.webMaxWidth,
                        child: !showMobileModule
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            isGrocery
                                ? const GroceryHomeScreen()
                                : isPharmacy
                                ? const PharmacyHomeScreen()
                                : isFood
                                ? const FoodHomeScreen()
                                : isShop
                                ? const ShopHomeScreen()
                                : isTaxi
                                ? const TaxiHomeScreen()
                                : const SizedBox(),
                          ],
                        )
                            : ModuleView(
                          splashController: splashController,
                        ),
                      ),
                    ),
                  ),

                  !showMobileModule && !isTaxi
                      ? SliverPersistentHeader(
                    key: _headerKey,
                    pinned: true,
                    delegate: SliverDelegate(
                      height: 85,
                      callback: (val) {
                        searchBgShow = val;
                      },
                      child: const AllStoreFilterWidget(),
                    ),
                  )
                      : const SliverToBoxAdapter(),

                  SliverToBoxAdapter(
                    child: !showMobileModule && !isTaxi
                        ? Center(
                      child: GetBuilder<StoreController>(
                          builder: (storeController) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: ResponsiveHelper.isDesktop(context) ? 0 : 100,
                              ),
                              child: PaginatedListView(
                                scrollController: _scrollController,
                                totalSize: storeController.storeModel?.totalSize,
                                offset: storeController.storeModel?.offset,
                                onPaginate: (int? offset) async =>
                                await storeController.getStoreList(offset!, false),
                                itemView: ItemsView(
                                  isStore: true,
                                  items: null,
                                  isFoodOrGrocery: (isFood || isGrocery),
                                  stores: storeController.storeModel?.stores,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveHelper.isDesktop(context)
                                        ? Dimensions.paddingSizeExtraSmall
                                        : Dimensions.paddingSizeSmall,
                                    vertical: ResponsiveHelper.isDesktop(context)
                                        ? Dimensions.paddingSizeExtraSmall
                                        : Dimensions.paddingSizeDefault,
                                  ),
                                ),
                              ),
                            );
                          }),
                    )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: AuthHelper.isLoggedIn() &&
              homeController.cashBackOfferList != null &&
              homeController.cashBackOfferList!.isNotEmpty
              ? (homeController.showFavButton
              ? Padding(
            padding: EdgeInsets.only(
              bottom: 50.0,
              right: ResponsiveHelper.isDesktop(context) ? 50 : 0,
            ),
            child: InkWell(
              onTap: () => Get.dialog(const CashBackDialogWidget()),
              child: const CashBackLogoWidget(),
            ),
          )
              : null)
              : null,
        );
      });
    });
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;
  Function(bool isPinned)? callback;
  bool isPinned = false;

  SliverDelegate({required this.child, this.height = 50, this.callback});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    isPinned = shrinkOffset == maxExtent;
    callback?.call(isPinned);
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height ||
        oldDelegate.minExtent != height ||
        child != oldDelegate.child;
  }
}
