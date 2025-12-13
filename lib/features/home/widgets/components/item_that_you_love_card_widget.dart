import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/common/widgets/hover/on_hover.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';

class ItemThatYouLoveCard extends StatelessWidget {
  final Item item;
  final int? index;
  const ItemThatYouLoveCard({super.key, required this.item, this.index});

  @override
  Widget build(BuildContext context) {
    // ✅ سحب الـ controllers مرة واحدة بدل Get.find عشرات المرات
    final itemController = Get.find<ItemController>();
    final localization = Get.find<LocalizationController>();
    final splash = Get.find<SplashController>();

    final bool isLtr = localization.isLtr;
    final bool showUnit = (splash.configModel?.moduleConfig?.module?.unit ?? false) && item.unitType != null;

    final double? discount = item.discount;
    final String? discountType = item.discountType;

    final bool isAvailable = itemController.isAvailable(item);
    final bool showRating = (item.ratingCount ?? 0) > 0;

    // حماية من null بدل الـ !
    final bool showHalalTag = (item.isStoreHalalActive ?? false) && (item.isHalalItem ?? false);

    final double startingPrice = itemController.getStartingPrice(item) ?? 0;

    return RepaintBoundary(
      child: OnHover(
        isItem: true,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
            boxShadow: ResponsiveHelper.isMobile(context)
                ? [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              )
            ]
                : null,
          ),
          child: CustomInkWell(
            onTap: () => itemController.navigateToItemPage(item, context),
            radius: Dimensions.radiusDefault,
            child: TextHover(
              builder: (hovered) {
                return Column(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              child: CustomImage(
                                isHovered: hovered,
                                image: '${item.imageFullUrl}',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),

                          DiscountTag(
                            discount: discount,
                            discountType: discountType,
                            freeDelivery: false,
                          ),

                          if (showHalalTag)
                            const Positioned(
                              top: 40,
                              right: 15,
                              child: CustomAssetImageWidget(
                                Images.halalTag,
                                height: 20,
                                width: 20,
                              ),
                            ),

                          AddFavouriteView(item: item),

                          if (!isAvailable) const NotAvailableWidget(),

                          Positioned(
                            bottom: -10,
                            left: 0,
                            right: 0,
                            child: CartCountView(
                              item: item,
                              index: index,
                              child: Center(
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 65,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(112),
                                    color: Theme.of(context).primaryColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 1),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    "add".tr,
                                    style: robotoBold.copyWith(color: Theme.of(context).cardColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Expanded(
                      flex: isLtr ? 3 : 4,
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name ?? '',
                              style: robotoBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),

                            if (showRating)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.star, size: 15, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    (item.avgRating ?? 0).toStringAsFixed(1),
                                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    "(${item.ratingCount ?? 0})",
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                  ),
                                ],
                              ),

                            if (showUnit)
                              Text(
                                item.unitType ?? '',
                                style: robotoRegular.copyWith(
                                  color: Theme.of(context).disabledColor,
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),

                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if ((discount ?? 0) > 0)
                                  Text(
                                    PriceConverter.convertPrice(startingPrice),
                                    style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                      color: Theme.of(context).disabledColor,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                SizedBox(
                                  width: (discount ?? 0) > 0 ? Dimensions.paddingSizeExtraSmall : 0,
                                ),
                                Text(
                                  PriceConverter.convertPrice(
                                    startingPrice,
                                    discount: discount,
                                    discountType: discountType,
                                  ),
                                  textDirection: TextDirection.ltr,
                                  style: robotoMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
