import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

class MiddleSectionBannerView extends StatefulWidget {
  const MiddleSectionBannerView({super.key});

  @override
  State<MiddleSectionBannerView> createState() => _MiddleSectionBannerViewState();
}

class _MiddleSectionBannerViewState extends State<MiddleSectionBannerView> {
  final CarouselSliderController carouselController = CarouselSliderController();

  bool _didPrecache = false;

  Future<void> _precacheFirstTwo(List<String> urls) async {
    if (_didPrecache || urls.isEmpty) return;
    _didPrecache = true;

    try {
      await precacheImage(NetworkImage(urls[0]), context);
      if (urls.length > 1) {
        await precacheImage(NetworkImage(urls[1]), context);
      }
    } catch (_) {
      // تجاهل
    }
  }

  @override
  Widget build(BuildContext context) {
    final splash = Get.find<SplashController>();
    final bool isPharmacy =
        splash.module != null && splash.module!.moduleType.toString() == AppConstants.pharmacy;

    final double cardHeight = isPharmacy ? 187 : 135;

    return GetBuilder<CampaignController>(builder: (campaignController) {
      final list = campaignController.basicCampaignList;

      if (list == null) {
        return MiddleSectionBannerShimmerView(isPharmacy: isPharmacy);
      }

      if (list.isEmpty) {
        return const SizedBox.shrink();
      }

      // اجمع روابط الصور واعمل precache لأول صورتين
      final urls = list
          .map((e) => (e.imageFullUrl ?? '').toString())
          .where((u) => u.isNotEmpty)
          .toList();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _precacheFirstTwo(urls);
      });

      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeDefault,
          horizontal: Dimensions.paddingSizeSmall,
        ),
        child: Column(
          children: [
            RepaintBoundary(
              child: CarouselSlider.builder(
                carouselController: carouselController,
                itemCount: list.length,
                options: CarouselOptions(
                  height: cardHeight,
                  //autoPlay: true,
                  enlargeCenterPage: true,
                  disableCenter: true,
                  viewportFraction: 0.95,
                  onPageChanged: (index, reason) {
                    campaignController.setCurrentIndex(index, true);
                  },
                ),
                itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                  final campaign = list[itemIndex];
                  final imageUrl = (campaign.imageFullUrl ?? '').toString();

                  return InkWell(
                    onTap: () => Get.toNamed(RouteHelper.getBasicCampaignRoute(campaign)),
                    child: Container(
                      height: cardHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                        child: CustomImage(
                          image: imageUrl,
                          fit: BoxFit.cover,
                          height: cardHeight,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            // ✅ مؤشرات أسرع: for-loop بدل indexOf/map (يزيل O(n^2))
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(list.length, (index) {
                final bool isActive = index == campaignController.currentIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: isActive
                      ? Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
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
        ),
      );
    });
  }
}

class MiddleSectionBannerShimmerView extends StatelessWidget {
  final bool isPharmacy;
  const MiddleSectionBannerShimmerView({super.key, required this.isPharmacy});

  @override
  Widget build(BuildContext context) {
    final double cardHeight = isPharmacy ? 187 : 135;

    return Shimmer(
      duration: const Duration(seconds: 2),
      enabled: true,
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: 3,
            options: CarouselOptions(
              height: cardHeight,
              enlargeCenterPage: true,
              disableCenter: true,
              viewportFraction: 0.95,
            ),
            itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
              return Container(
                height: cardHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
