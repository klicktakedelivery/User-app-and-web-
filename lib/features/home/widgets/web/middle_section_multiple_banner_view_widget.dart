import 'dart:async';

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
  bool _didPrecache = false;

  void _kickoffPrecache(List<String> urls) {
    if (_didPrecache || urls.isEmpty || !mounted) return;
    _didPrecache = true;

    // ✅ بدون await (يمنع use_build_context_synchronously)
    _safePrecache(urls);
  }

  void _safePrecache(List<String> urls) {
    if (!mounted || urls.isEmpty) return;

    // ✅ التقط context مرة واحدة واستخدمه مباشرة بدون await
    final BuildContext ctx = context;

    try {
      unawaited(precacheImage(NetworkImage(urls[0]), ctx));
      if (urls.length > 1) unawaited(precacheImage(NetworkImage(urls[1]), ctx));
      if (urls.length > 2) unawaited(precacheImage(NetworkImage(urls[2]), ctx));
      if (urls.length > 3) unawaited(precacheImage(NetworkImage(urls[3]), ctx));
    } catch (_) {
      // تجاهل
    }
  }

  @override
  Widget build(BuildContext context) {
    final splash = Get.find<SplashController>();
    final bool isPharmacy =
        splash.module != null && splash.module!.moduleType.toString() == AppConstants.pharmacy;

    // على الويب عادة نعرض بانرين جنب بعض
    final double cardHeight = isPharmacy ? 220 : 170;

    return GetBuilder<CampaignController>(builder: (campaignController) {
      final list = campaignController.basicCampaignList;

      if (list == null) {
        return _WebMiddleSectionBannerShimmer(height: cardHeight);
      }
      if (list.isEmpty) {
        return const SizedBox.shrink();
      }

      // ✅ اجمع روابط الصور واعمل precache (بدون await)
      final urls = list
          .map((e) => (e.imageFullUrl ?? '').toString())
          .where((u) => u.isNotEmpty)
          .toList();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _kickoffPrecache(urls);
      });

      // كل صفحة تعرض 2
      final int pageCount = (list.length / 2).ceil();

      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeDefault,
          horizontal: Dimensions.paddingSizeSmall,
        ),
        child: RepaintBoundary(
          child: CarouselSlider.builder(
            itemCount: pageCount,
            options: CarouselOptions(
              height: cardHeight,
              enlargeCenterPage: false,
              viewportFraction: 1,
              autoPlay: false,
            ),
            itemBuilder: (context, pageIndex, _) {
              final int firstIndex = pageIndex * 2;
              final int secondIndex = firstIndex + 1;

              Widget buildCard(int i) {
                final campaign = list[i];
                final imageUrl = (campaign.imageFullUrl ?? '').toString();

                return Expanded(
                  child: InkWell(
                    onTap: () => Get.toNamed(RouteHelper.getBasicCampaignRoute(campaign)),
                    child: Container(
                      height: cardHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 1),
                        ],
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
                  ),
                );
              }

              return Row(
                children: [
                  buildCard(firstIndex),
                  if (secondIndex < list.length) buildCard(secondIndex) else const Expanded(child: SizedBox()),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}

class _WebMiddleSectionBannerShimmer extends StatelessWidget {
  final double height;
  const _WebMiddleSectionBannerShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeDefault,
          horizontal: Dimensions.paddingSizeSmall,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
