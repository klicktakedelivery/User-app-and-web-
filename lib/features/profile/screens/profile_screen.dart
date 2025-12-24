import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/widgets/notification_status_change_bottom_sheet.dart';
import 'package:sixam_mart/features/profile/widgets/profile_button_widget.dart';
import 'package:sixam_mart/features/profile/widgets/profile_card_widget.dart';
import 'package:sixam_mart/features/profile/widgets/web_profile_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/services/api_cache_manager.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _currencyList = <String>[
    'USD', 'EUR', 'GBP', 'DKK', 'SEK', 'NOK', 'CHF', 'CAD', 'AUD', 'NZD',
    'SAR', 'AED', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD', 'ILS', 'TRY',
    'EGP', 'MAD', 'DZD', 'TND', 'IQD', 'LBP',
  ];

  SharedPreferences _sp() => Get.find<SharedPreferences>();
  ApiClient _api() => Get.find<ApiClient>();

  String _currentCurrency() {
    final c = _sp().getString(AppConstants.currencyCode);
    if (c != null && c.trim().isNotEmpty) return c.trim().toUpperCase();
    return 'USD';
  }

  bool _isCurrencyAuto() => _sp().getBool(AppConstants.currencyAuto) ?? true;

  Future<void> _applyAutoCurrency() async {
    await _api().enableAutoCurrency(refreshHeader: true);
    await ApiCacheManager.clearAllCache();
  }

  Future<void> _applyManualCurrency(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;

    await _api().setManualCurrency(normalized, refreshHeader: true);
    await ApiCacheManager.clearAllCache();
  }

  void _openCurrencyBottomSheet() {
    if (!AuthHelper.isLoggedIn()) return;

    bool isAuto = _isCurrencyAuto();
    String selected = _currentCurrency();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Dimensions.radiusExtraLarge),
              ),
            ),
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  Row(
                    children: [
                      const Icon(Icons.currency_exchange),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Text(
                          'currency'.tr,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                        ),
                      ),
                      Text(
                        selected,
                        style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isAuto,
                    onChanged: (v) {
                      setModalState(() => isAuto = v);
                    },
                    title: Text(
                      'auto_currency_by_location'.tr,
                      style: robotoMedium,
                    ),
                    subtitle: Text(
                      isAuto ? 'auto_mode_enabled'.tr : 'manual_mode_enabled'.tr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  IgnorePointer(
                    ignoring: isAuto,
                    child: Opacity(
                      opacity: isAuto ? 0.5 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _currencyList.contains(selected) ? selected : _currencyList.first,
                            items: _currencyList
                                .map((c) => DropdownMenuItem<String>(
                                      value: c,
                                      child: Text(c, style: robotoMedium),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setModalState(() => selected = v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          child: Text('cancel'.tr),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isAuto) {
                              await _applyAutoCurrency();
                              if (mounted) setState(() {});
                              Get.back();
                              Get.snackbar('done'.tr, 'auto_currency_applied'.tr, snackPosition: SnackPosition.BOTTOM);
                            } else {
                              await _applyManualCurrency(selected);
                              if (mounted) setState(() {});
                              Get.back();
                              Get.snackbar('done'.tr, 'currency_changed'.tr, snackPosition: SnackPosition.BOTTOM);
                            }
                          },
                          child: Text('apply'.tr),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.paddingSizeSmall),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  @override
  void initState() {
    super.initState();

    if (AuthHelper.isLoggedIn() && Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showWalletCard = Get.find<SplashController>().configModel!.customerWalletStatus == 1
        || Get.find<SplashController>().configModel!.loyaltyPointStatus == 1;

    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      key: UniqueKey(),
      body: GetBuilder<ProfileController>(
        builder: (profileController) {
          bool isLoggedIn = AuthHelper.isLoggedIn();

          return (isLoggedIn && profileController.userInfoModel == null)
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: FooterView(
                    minHeight: isLoggedIn ? (ResponsiveHelper.isDesktop(context) ? 0.4 : 0.6) : 0.35,
                    child: (isLoggedIn && ResponsiveHelper.isDesktop(context))
                        ? const WebProfileWidget()
                        : Container(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            width: Dimensions.webMaxWidth,
                            height: context.height,
                            child: Center(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeLarge,
                                      vertical: Dimensions.paddingSizeSmall,
                                    ),
                                    child: SafeArea(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          !ResponsiveHelper.isDesktop(context)
                                              ? IconButton(
                                                  onPressed: () => Get.back(),
                                                  icon: const Icon(Icons.arrow_back_ios),
                                                )
                                              : const SizedBox(),
                                          Text('profile'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                                          const SizedBox(width: 50),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: Dimensions.paddingSizeExtremeLarge,
                                      right: Dimensions.paddingSizeExtremeLarge,
                                      bottom: Dimensions.paddingSizeLarge,
                                    ),
                                    child: Row(
                                      children: [
                                        ClipOval(
                                          child: CustomImage(
                                            placeholder: Images.guestIcon,
                                            image:
                                                '${(profileController.userInfoModel != null && isLoggedIn) ? profileController.userInfoModel!.imageFullUrl : ''}',
                                            height: 70,
                                            width: 70,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: Dimensions.paddingSizeDefault),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isLoggedIn
                                                    ? '${profileController.userInfoModel?.fName ?? ''} ${profileController.userInfoModel?.lName ?? ''}'
                                                    : 'guest_user'.tr,
                                                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                                              ),
                                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                              isLoggedIn
                                                  ? Text(
                                                      '${'joined'.tr} ${DateConverter.containTAndZToUTCFormat(profileController.userInfoModel!.createdAt!)}',
                                                      style: robotoMedium.copyWith(
                                                        fontSize: Dimensions.fontSizeSmall,
                                                        color: Theme.of(context).primaryColor,
                                                      ),
                                                    )
                                                  : InkWell(
                                                      onTap: () async {
                                                        if (!ResponsiveHelper.isDesktop(context)) {
                                                          await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
                                                          if (AuthHelper.isLoggedIn()) {
                                                            profileController.getUserInfo();
                                                          }
                                                        } else {
                                                          Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)));
                                                        }
                                                      },
                                                      child: Text(
                                                        'login_to_view_all_feature'.tr,
                                                        style: robotoMedium.copyWith(
                                                          fontSize: Dimensions.fontSizeSmall,
                                                          color: Theme.of(context).primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ),

                                        isLoggedIn
                                            ? InkWell(
                                                onTap: () => Get.toNamed(RouteHelper.getUpdateProfileRoute()),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Theme.of(context).cardColor,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                                        blurRadius: 5,
                                                        spreadRadius: 1,
                                                        offset: const Offset(3, 3),
                                                      )
                                                    ],
                                                  ),
                                                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                                  child: const Icon(Icons.edit_outlined, size: 24, color: Colors.blue),
                                                ),
                                              )
                                            : InkWell(
                                                onTap: () async {
                                                  if (!ResponsiveHelper.isDesktop(context)) {
                                                    await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
                                                    if (AuthHelper.isLoggedIn()) {
                                                      profileController.getUserInfo();
                                                    }
                                                  } else {
                                                    Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)));
                                                  }
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                                    color: Theme.of(context).primaryColor,
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: Dimensions.paddingSizeSmall,
                                                    horizontal: Dimensions.paddingSizeLarge,
                                                  ),
                                                  child: Text('login'.tr, style: robotoMedium.copyWith(color: Theme.of(context).cardColor)),
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
                                        color: Theme.of(context).cardColor,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimensions.paddingSizeLarge,
                                        vertical: Dimensions.paddingSizeDefault,
                                      ),
                                      child: Column(
                                        children: [
                                          const SizedBox(height: Dimensions.paddingSizeLarge),

                                          (showWalletCard && isLoggedIn)
                                              ? Row(
                                                  children: [
                                                    Get.find<SplashController>().configModel!.loyaltyPointStatus == 1
                                                        ? Expanded(
                                                            child: ProfileCardWidget(
                                                              image: Images.loyaltyIcon,
                                                              data: profileController.userInfoModel!.loyaltyPoint != null
                                                                  ? profileController.userInfoModel!.loyaltyPoint.toString()
                                                                  : '0',
                                                              title: 'loyalty_points'.tr,
                                                            ),
                                                          )
                                                        : const SizedBox(),

                                                    SizedBox(
                                                      width: Get.find<SplashController>().configModel!.loyaltyPointStatus == 1
                                                          ? Dimensions.paddingSizeSmall
                                                          : 0,
                                                    ),

                                                    isLoggedIn
                                                        ? Expanded(
                                                            child: ProfileCardWidget(
                                                              image: Images.shoppingBagIcon,
                                                              data: profileController.userInfoModel!.orderCount.toString(),
                                                              title: 'total_order'.tr,
                                                            ),
                                                          )
                                                        : const SizedBox(),

                                                    SizedBox(
                                                      width: Get.find<SplashController>().configModel!.customerWalletStatus == 1
                                                          ? Dimensions.paddingSizeSmall
                                                          : 0,
                                                    ),

                                                    Get.find<SplashController>().configModel!.customerWalletStatus == 1
                                                        ? Expanded(
                                                            child: ProfileCardWidget(
                                                              image: Images.walletProfile,
                                                              data: PriceConverter.convertPrice(profileController.userInfoModel!.walletBalance),
                                                              title: 'wallet_balance'.tr,
                                                            ),
                                                          )
                                                        : const SizedBox(),
                                                  ],
                                                )
                                              : const SizedBox(),

                                          const SizedBox(height: Dimensions.paddingSizeDefault),

                                          ProfileButtonWidget(
                                            icon: Icons.tonality_outlined,
                                            title: 'dark_mode'.tr,
                                            isButtonActive: Get.isDarkMode,
                                            onTap: () {
                                              Get.find<ThemeController>().toggleTheme();
                                            },
                                          ),
                                          const SizedBox(height: Dimensions.paddingSizeSmall),

                                          // ✅ زر تغيير العملة
                                          isLoggedIn
                                              ? ProfileButtonWidget(
                                                  icon: Icons.currency_exchange,
                                                  title: '${'currency'.tr} (${_currentCurrency()})',
                                                  onTap: _openCurrencyBottomSheet,
                                                )
                                              : const SizedBox(),
                                          SizedBox(height: isLoggedIn ? Dimensions.paddingSizeSmall : 0),

                                          isLoggedIn
                                              ? GetBuilder<AuthController>(
                                                  builder: (authController) {
                                                    return ProfileButtonWidget(
                                                      icon: Icons.notifications,
                                                      title: 'notification'.tr,
                                                      isButtonActive: authController.notification,
                                                      onTap: () {
                                                        Get.bottomSheet(const NotificationStatusChangeBottomSheet());
                                                      },
                                                    );
                                                  },
                                                )
                                              : const SizedBox(),
                                          SizedBox(height: isLoggedIn ? Dimensions.paddingSizeSmall : 0),

                                          isLoggedIn && Get.find<SplashController>().configModel!.centralizeLoginSetup!.manualLoginStatus!
                                              ? ProfileButtonWidget(
                                                  icon: Icons.lock,
                                                  title: 'change_password'.tr,
                                                  onTap: () {
                                                    Get.toNamed(
                                                      RouteHelper.getResetPasswordRoute(phone: '', email: '', token: '', page: 'password-change'),
                                                    );
                                                  },
                                                )
                                              : const SizedBox(),
                                          SizedBox(
                                            height: isLoggedIn && Get.find<SplashController>().configModel!.centralizeLoginSetup!.manualLoginStatus!
                                                ? Dimensions.paddingSizeSmall
                                                : 0,
                                          ),

                                          isLoggedIn
                                              ? ProfileButtonWidget(
                                                  icon: Icons.delete,
                                                  title: 'delete_account'.tr,
                                                  iconImage: Images.profileDelete,
                                                  color: Theme.of(context).colorScheme.error,
                                                  onTap: () {
                                                    Get.dialog(
                                                      ConfirmationDialog(
                                                        icon: Images.support,
                                                        title: 'are_you_sure_to_delete_account'.tr,
                                                        description: 'it_will_remove_your_all_information'.tr,
                                                        isLogOut: true,
                                                        onYesPressed: () => profileController.deleteUser(),
                                                      ),
                                                      useSafeArea: false,
                                                    );
                                                  },
                                                )
                                              : const SizedBox(),
                                          SizedBox(height: isLoggedIn ? Dimensions.paddingSizeLarge : 0),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text('${'version'.tr}:', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
                                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                              Text(
                                                AppConstants.appVersion.toStringAsFixed(2),
                                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                );
        },
      ),
    );
  }
}
