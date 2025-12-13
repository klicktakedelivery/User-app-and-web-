import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

class PromotionalBannerView extends StatefulWidget {
  const PromotionalBannerView({super.key});

  @override
  State<PromotionalBannerView> createState() => _PromotionalBannerViewState();
}

class _PromotionalBannerViewState extends State<PromotionalBannerView> {
  String? _lastUrl;
  bool _didPrecache = false;

  Future<void> _precache(String url) async {
    if (_didPrecache && _lastUrl == url) return;
    _didPrecache = true;
    _lastUrl = url;

    try {
      // precache لصورة الشبكة لتقليل “النتعة” عند ظهورها لأول مرة
      await precacheImage(NetworkImage(url), context);
    } catch (_) {
      // تجاهل أي خطأ (لا نخرب الواجهة)
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannerController>(builder: (bannerController) {
      final String? url =
          bannerController.promotionalBanner?.bottomSectionBannerFullUrl;

      if (url == null || url.isEmpty) {
        // لو البيانات لسه ما وصلت: shimmer
        return const PromotionalBannerShimmerView();
      }

      // precache بعد أول فريم (مرة واحدة لكل رابط)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _precache(url);
      });

      return RepaintBoundary(
        child: Container(
          height: 90,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeDefault,
            horizontal: Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
            child: CustomImage(
              image: url,
              fit: BoxFit.cover,
              height: 80,
              width: double.infinity,
            ),
          ),
        ),
      );
    });
  }
}

class PromotionalBannerShimmerView extends StatelessWidget {
  const PromotionalBannerShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      enabled: true,
      child: Container(
        height: 90,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        ),
      ),
    );
  }
}
