import 'package:carousel_slider/carousel_slider.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BannerView extends StatefulWidget {
  final bool isFeatured;
  const BannerView({super.key, required this.isFeatured});

  @override
  State<BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<BannerView> {
  bool _didPrecache = false;

  Future<void> _precacheFirstImages(List<String?> banners) async {
    if (_didPrecache || banners.isEmpty) return;
    _didPrecache = true;

    final first = banners[0];
    final second = banners.length > 1 ? banners[1] : null;

    try {
      if (!mounted) return;

      if (first != null && first.isNotEmpty) {
        await precacheImage(NetworkImage(first), context);
        if (!mounted) return;
      }

      if (second != null && second.isNotEmpty) {
        await precacheImage(NetworkImage(second), context);
        if (!mounted) return;
      }
    } catch (_) {
      // تجاهل أي خطأ في precache
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannerController>(builder: (bannerController) {
      final List<String?>? bannerList =
          widget.isFeatured ? bannerController.featuredBannerList : bannerController.bannerImageList;

      final List<dynamic>? bannerDataList =
          widget.isFeatured ? bannerController.featuredBannerDataList : bannerController.bannerDataList;

      if (bannerList != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _precacheFirstImages(bannerList);
        });
      }

      if (bannerList != null && bannerList.isEmpty) {
        return const SizedBox.shrink();
      }

      final double bannerHeight = GetPlatform.isDesktop ? 500 : MediaQuery.of(context).size.width * 0.45;

      return Container(
        width: MediaQuery.of(context).size.width,
        height: bannerHeight,
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        child: bannerList != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CarouselSlider.builder(
                      options: CarouselOptions(
                        autoPlay: true,
                        enlargeCenterPage: true,
                        disableCenter: true,
                        viewportFraction: 0.95,
                        autoPlayInterval: const Duration(seconds: 7),
                        onPageChanged: (index, reason) {
                          bannerController.setCurrentIndex(index, true);
                        },
                      ),
                      itemCount: bannerList.isEmpty ? 1 : bannerList.length,
                      itemBuilder: (context, index, _) {
                        final String imageUrl = (bannerList[index] ?? '').toString();

                        return InkWell(
                          onTap: () async {
                            if (bannerDataList == null || bannerDataList.length <= index) return;

                            final data = bannerDataList[index];

                            if (data is Item) {
                              Get.find<ItemController>().navigateToItemPage(data, context);
                            } else if (data is Store) {
                              final store = data;

                              if (widget.isFeatured && Get.find<SplashController>().moduleList != null) {
                                for (final ModuleModel module in Get.find<SplashController>().moduleList!) {
                                  if (module.id == store.moduleId) {
                                    Get.find<SplashController>().setModule(module);
                                    break;
                                  }
                                }
                              }

                              Get.toNamed(
                                RouteHelper.getStoreRoute(
                                  id: store.id,
                                  page: widget.isFeatured ? 'module' : 'banner',
                                ),
                                arguments: StoreScreen(store: store, fromModule: widget.isFeatured),
                              );
                            } else if (data is BasicCampaignModel) {
                              Get.toNamed(RouteHelper.getBasicCampaignRoute(data));
                            } else {
                              final String url = data.toString();
                              if (await canLaunchUrlString(url)) {
                                await launchUrlString(url, mode: LaunchMode.externalApplication);
                              } else {
                                showCustomSnackBar('unable_to_found_url'.tr);
                              }
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                              child: RepaintBoundary(
                                child: CustomImage(
                                  image: imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  if (bannerList.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(bannerList.length, (index) {
                        final int totalBanner = bannerList.length;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: index == bannerController.currentIndex
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  child: Text(
                                    '${index + 1}/$totalBanner',
                                    style: robotoRegular.copyWith(
                                      color: Theme.of(context).cardColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 5,
                                  width: 6,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  ),
                                ),
                        );
                      }),
                    ),
                ],
              )
            : Shimmer(
                duration: const Duration(seconds: 2),
                enabled: true,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    color: Colors.grey[300],
                  ),
                ),
              ),
      );
    });
  }
}
