import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/common/widgets/hover/on_hover.dart';
import 'package:sixam_mart/common/widgets/organic_tag.dart';

class ReviewItemCard extends StatelessWidget {
  final bool isFeatured;
  final Item? item;
  const ReviewItemCard({super.key, this.isFeatured = false, this.item});

  @override
  Widget build(BuildContext context) {
    final it = item;
    if (it == null) return const SizedBox.shrink();

    // ✅ Controllers مرة واحدة
    final splash = Get.find<SplashController>();
    final itemController = Get.find<ItemController>();

    final bool isShop = splash.module != null &&
        splash.module!.moduleType.toString() == AppConstants.ecommerce;
    final bool isFood = splash.module != null &&
        splash.module!.moduleType.toString() == AppConstants.food;

    final double? discount = it.discount;
    final String? discountType = it.discountType;

    final double startingPrice = itemController.getStartingPrice(it) ?? 0;

    final bool showRating = (it.ratingCount ?? 0) > 0;
    final bool showHalalTag = (it.isStoreHalalActive ?? false) && (it.isHalalItem ?? false);
    final bool showUnit = (splash.configModel?.moduleConfig?.module?.unit ?? false) && it.unitType != null;

    return RepaintBoundary(
      child: TextHover(
        builder: (hovered) {
          return OnHover(
            isItem: true,
            child: isShop ? _shopCard(
              context: context,
              hovered: hovered,
              itemController: itemController,
              item: it,
              isFeatured: isFeatured,
              discount: discount,
              discountType: discountType,
              startingPrice: startingPrice,
              showRating: showRating,
            ) : _normalCard(
              context: context,
              hovered: hovered,
              itemController: itemController,
              splash: splash,
              item: it,
              isFood: isFood,
              isFeatured: isFeatured,
              discount: discount,
              discountType: discountType,
              startingPrice: startingPrice,
              showRating: showRating,
              showHalalTag: showHalalTag,
              showUnit: showUnit,
            ),
          );
        },
      ),
    );
  }

  Widget _shopCard({
    required BuildContext context,
    required bool hovered,
    required ItemController itemController,
    required Item item,
    required bool isFeatured,
    required double? discount,
    required String? discountType,
    required double startingPrice,
    required bool showRating,
  }) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: CustomInkWell(
        onTap: () => itemController.navigateToItemPage(item, context),
        radius: Dimensions.radiusDefault,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: Dimensions.paddingSizeSmall,
                      left: Dimensions.paddingSizeSmall,
                      right: Dimensions.paddingSizeSmall,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
                      child: CustomImage(
                        isHovered: hovered,
                        placeholder: Images.placeholder,
                        image: '${item.imageFullUrl}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  AddFavouriteView(item: item),
                  DiscountTag(
                    isFloating: true,
                    discount: itemController.getDiscount(item),
                    discountType: itemController.getDiscountType(item),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Column(
                  crossAxisAlignment: isFeatured ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.storeName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).disabledColor,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                    Text(item.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold),
                    if (showRating)
                      Row(
                        mainAxisAlignment: isFeatured ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 14, color: Theme.of(context).primaryColor),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Text((item.avgRating ?? 0).toStringAsFixed(1),
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Text(
                            "(${item.ratingCount ?? 0})",
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.start,
                      children: [
                        if ((discount ?? 0) > 0)
                          Text(
                            PriceConverter.convertPrice(startingPrice),
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).disabledColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        SizedBox(width: (discount ?? 0) > 0 ? Dimensions.paddingSizeExtraSmall : 0),
                        Text(
                          PriceConverter.convertPrice(
                            startingPrice,
                            discount: discount,
                            discountType: discountType,
                          ),
                          style: robotoMedium,
                          textDirection: TextDirection.ltr,
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
    );
  }

  Widget _normalCard({
    required BuildContext context,
    required bool hovered,
    required ItemController itemController,
    required SplashController splash,
    required Item item,
    required bool isFood,
    required bool isFeatured,
    required double? discount,
    required String? discountType,
    required double startingPrice,
    required bool showRating,
    required bool showHalalTag,
    required bool showUnit,
  }) {
    return Container(
      width: 210,
      height: 285,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
                    child: CustomImage(
                      isHovered: hovered,
                      placeholder: Images.placeholder,
                      image: '${item.imageFullUrl}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),

                AddFavouriteView(top: 10, right: 10, item: item),

                if (showHalalTag)
                  const Positioned(
                    top: 35,
                    right: 10,
                    child: CustomAssetImageWidget(
                      Images.halalTag,
                      height: 20,
                      width: 20,
                    ),
                  ),

                DiscountTag(
                  isFloating: true,
                  discount: itemController.getDiscount(item),
                  discountType: itemController.getDiscountType(item),
                ),

                OrganicTag(item: item, placeInImage: false),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(Dimensions.radiusDefault),
                              topRight: Radius.circular(Dimensions.radiusDefault),
                            ),
                            color: Theme.of(context).cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          child: isFood
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              Text(
                                item.storeName ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: robotoRegular.copyWith(
                                  color: Theme.of(context).disabledColor,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                              Text(item.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold),
                              if (showRating)
                                Row(
                                  mainAxisAlignment: isFeatured ? MainAxisAlignment.start : MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star, size: 14, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                    Text((item.avgRating ?? 0).toStringAsFixed(1),
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                    Text(
                                      "(${item.ratingCount ?? 0})",
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).disabledColor,
                                      ),
                                    ),
                                  ],
                                ),
                              Column(
                                children: [
                                  if ((discount ?? 0) > 0)
                                    Text(
                                      PriceConverter.convertPrice(startingPrice),
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                        color: Theme.of(context).disabledColor,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  Text(
                                    PriceConverter.convertPrice(
                                      startingPrice,
                                      discount: discount,
                                      discountType: discountType,
                                    ),
                                    style: robotoMedium,
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                            ],
                          )
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              Text(item.name ?? '', style: robotoBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (showRating)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star, size: 15, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                    Text((item.avgRating ?? 0).toStringAsFixed(1), style: robotoRegular),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                    Text(
                                      "(${item.ratingCount ?? 0})",
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).disabledColor,
                                      ),
                                    ),
                                  ],
                                ),
                              if (showUnit)
                                Text(
                                  '(${item.unitType ?? ''})',
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                              Column(
                                children: [
                                  if ((discount ?? 0) > 0)
                                    Text(
                                      PriceConverter.convertPrice(startingPrice),
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                        color: Theme.of(context).disabledColor,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  Text(
                                    PriceConverter.convertPrice(
                                      startingPrice,
                                      discount: discount,
                                      discountType: discountType,
                                    ),
                                    style: robotoMedium,
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Positioned(
                          top: -15,
                          left: 0,
                          right: 0,
                          child: CartCountView(
                            item: item,
                            child: Center(
                              child: Container(
                                alignment: Alignment.center,
                                width: 65,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(112),
                                  color: Theme.of(context).cardColor,
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
                                  style: robotoBold.copyWith(color: Theme.of(context).primaryColor),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
