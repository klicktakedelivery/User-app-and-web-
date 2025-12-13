import 'package:sixam_mart/common/widgets/card_design/store_card_with_distance.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/card_design/store_card.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:get/get.dart';

class NewOnMartView extends StatelessWidget {
  final bool isPharmacy;
  final bool isShop;
  final bool isNewStore;
  const NewOnMartView({
    super.key,
    required this.isPharmacy,
    required this.isShop,
    this.isNewStore = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      final List<Store>? storeList = storeController.latestStoreList;

      if (storeList == null) {
        return const _NewOnMartShimmerView();
      }

      if (storeList.isEmpty) {
        return const SizedBox.shrink();
      }

      final bool bigCard = (isPharmacy || isShop);
      final double listHeight = bigCard ? 215 : 140;

      // تقدير عرض العنصر لتحسين layout (مش لازم يكون دقيق 100%)
      final double itemExtent = bigCard ? 230 : 210;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: TitleWidget(
                title: '${'new_on'.tr} ${AppConstants.appName}',
                onTap: () => Get.toNamed(RouteHelper.getAllStoreRoute('latest')),
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeSmall),

            RepaintBoundary(
              child: SizedBox(
                height: listHeight,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(
                    left: bigCard ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall,
                  ),
                  itemCount: storeList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeDefault),
                  itemBuilder: (context, index) {
                    final store = storeList[index];

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: Dimensions.paddingSizeSmall,
                        top: Dimensions.paddingSizeSmall,
                      ),
                      child: bigCard
                          ? StoreCardWithDistance(store: store, isNewStore: isNewStore)
                          : StoreCard(store: store),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _NewOnMartShimmerView extends StatelessWidget {
  const _NewOnMartShimmerView();

  @override
  Widget build(BuildContext context) {
    // Shimmer خفيف يشبه عرض المتاجر
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(title: '${'new_on'.tr} ${AppConstants.appName}'),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          const PopularStoreShimmer(),
        ],
      ),
    );
  }
}

class PopularStoreShimmer extends StatelessWidget {
  const PopularStoreShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            height: 150,
            width: 200,
            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10, spreadRadius: 1)],
            ),
            child: Shimmer(
              duration: const Duration(seconds: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 90,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Dimensions.radiusSmall),
                      ),
                      color: Colors.grey[300],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(height: 10, width: 100, color: Colors.grey[300]),
                          const SizedBox(height: 5),
                          Container(height: 10, width: 130, color: Colors.grey[300]),
                          const SizedBox(height: 5),
                          const RatingBar(rating: 0.0, size: 12, ratingCount: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
