import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/card_design/item_card.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/home/widgets/views/special_offer_view.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';

class MostPopularItemView extends StatelessWidget {
  final bool isFood;
  final bool isShop;
  const MostPopularItemView({super.key, required this.isFood, required this.isShop});

  @override
  Widget build(BuildContext context) {
    // ✅ لا نغطي على باراميتر isShop — نسميه اسم مختلف
    final bool isEcommerceModule = Get.find<SplashController>().module != null &&
        Get.find<SplashController>().module!.moduleType.toString() == AppConstants.ecommerce;

    // لو ودّك تعتمد على اللي يجي من الخارج، استخدم هذا:
    // final bool effectiveIsShop = isShop;
    // لكن بما إن كودك كان يعتمد على module، نخليه زي ما هو:
    final bool effectiveIsShop = isEcommerceModule;

    // تقدير عرض البطاقة لتحسين الأداء في horizontal list
    // (مو لازم يكون دقيق 100%، المهم ثابت تقريبًا)
    const double itemExtent = 220;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: GetBuilder<ItemController>(builder: (itemController) {
        final List<Item>? itemList = itemController.popularItemList;

        if (itemList == null) {
          return const ItemShimmerView(isPopularItem: true);
        }

        if (itemList.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: Dimensions.paddingSizeDefault,
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                ),
                child: TitleWidget(
                  title: effectiveIsShop ? 'most_popular_products'.tr : 'most_popular_items'.tr,
                  image: Images.mostPopularIcon,
                  onTap: () => Get.toNamed(RouteHelper.getItemViewAllScreen(true, false)),
                ),
              ),

              SizedBox(
                height: 285,
                width: Get.width,
                child: RepaintBoundary(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                    itemCount: itemList.length,
                    itemExtent: itemExtent + Dimensions.paddingSizeDefault, // يحسّن layout
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeDefault,
                          right: Dimensions.paddingSizeDefault,
                          top: Dimensions.paddingSizeDefault,
                        ),
                        child: RepaintBoundary(
                          child: ItemCard(
                            isPopularItem: effectiveIsShop ? false : true,
                            isPopularItemCart: true,
                            item: itemList[index],
                            isShop: effectiveIsShop,
                            isFood: isFood,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
