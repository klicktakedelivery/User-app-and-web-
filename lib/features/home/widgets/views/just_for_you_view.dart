import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/home/widgets/components/circle_list_view_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';

class JustForYouView extends StatelessWidget {
  const JustForYouView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CampaignController>(builder: (campaignController) {
      final list = campaignController.itemCampaignList;

      if (list == null) {
        return const JustForYouShimmerView();
      }

      if (list.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: TitleWidget(
                title: 'just_for_you'.tr,
                onTap: () => Get.toNamed(RouteHelper.getItemCampaignRoute(isJustForYou: true)),
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // عزل رسم الودجت اللي يتحرك (Swiper/Scroll) عن باقي الصفحة
            const RepaintBoundary(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: CircleListView(),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class JustForYouShimmerView extends StatelessWidget {
  const JustForYouShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(title: 'just_for_you'.tr),
          ),

          const SizedBox(height: Dimensions.paddingSizeDefault),

          Shimmer(
            duration: const Duration(seconds: 2),
            enabled: true,
            child: SizedBox(
              height: 200,
              width: Get.width,
              child: Swiper(
                itemCount: 3,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      color: Colors.grey[300],
                    ),
                  );
                },
                itemWidth: 200,
                layout: SwiperLayout.STACK,
                axisDirection: AxisDirection.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
