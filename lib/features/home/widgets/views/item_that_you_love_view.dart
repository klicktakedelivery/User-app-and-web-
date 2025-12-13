import 'dart:math';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/home/widgets/components/item_that_you_love_card_widget.dart';
import 'package:sixam_mart/features/home/widgets/components/review_item_card_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';

class ItemThatYouLoveView extends StatefulWidget {
  final bool forShop;
  const ItemThatYouLoveView({super.key, required this.forShop});

  @override
  State<ItemThatYouLoveView> createState() => _ItemThatYouLoveViewState();
}

class _ItemThatYouLoveViewState extends State<ItemThatYouLoveView> {
  final SwiperController _swiperController = SwiperController();

  PageController? _pageController;
  int _currentPage = 0;
  int _lastLength = 0;

  int _initialPageForLength(int len) {
    if (len <= 1) return 0;
    return 1;
  }

  void _ensurePageController(int len) {
    if (_pageController == null || _lastLength != len) {
      _lastLength = len;
      _currentPage = _initialPageForLength(len);
      _pageController?.dispose();
      _pageController = PageController(initialPage: _currentPage, viewportFraction: 0.8);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemController>(builder: (itemController) {
      final List<Item>? recommendItems = itemController.recommendedItemList;

      if (recommendItems == null) {
        return ItemThatYouLoveShimmerView(forShop: widget.forShop);
      }

      if (recommendItems.isEmpty) {
        return const SizedBox.shrink();
      }

      // ✅ تأكد من الـ PageController بعد ما البيانات وصلت/تغيرت
      if (!widget.forShop) {
        _ensurePageController(recommendItems.length);
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: Dimensions.paddingSizeDefault,
              left: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
            ),
            child: Align(
              alignment: widget.forShop ? Alignment.center : Alignment.centerLeft,
              child: Text(
                'item_that_you_love'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            ),
          ),

          if (widget.forShop)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              child: Stack(
                children: [
                  SizedBox(
                    height: 300,
                    width: Get.width,
                    child: RepaintBoundary(
                      child: Swiper(
                        controller: _swiperController,
                        itemBuilder: (BuildContext context, int index) {
                          return ReviewItemCard(item: recommendItems[index]);
                        },
                        itemCount: recommendItems.length,
                        itemWidth: 250,
                        itemHeight: 300,
                        layout: SwiperLayout.TINDER,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 150,
                    right: 10,
                    child: InkWell(
                      onTap: () => _swiperController.next(),
                      child: Icon(Icons.arrow_forward, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  Positioned(
                    top: 150,
                    left: 10,
                    child: InkWell(
                      onTap: () => _swiperController.previous(),
                      child: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
            )
          else
            AspectRatio(
              aspectRatio: ResponsiveHelper.isTab(context) ? 2.5 : 1.0,
              child: RepaintBoundary(
                child: PageView.builder(
                  itemCount: recommendItems.length,
                  allowImplicitScrolling: true,
                  physics: const ClampingScrollPhysics(),
                  controller: _pageController!,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController!,
                      builder: (context, child) {
                        // ✅ نحسب rotation بشكل آمن حتى قبل ما تثبت الأبعاد
                        final page = (_pageController!.hasClients && _pageController!.page != null)
                            ? _pageController!.page!
                            : _currentPage.toDouble();

                        double value = (index.toDouble() - page);
                        value = (value * 0.038).clamp(-1.0, 1.0);

                        return Transform.rotate(
                          angle: pi * value,
                          child: child,
                        );
                      },
                      child: _carouselCard(index, recommendItems[index]),
                    );
                  },
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _carouselCard(int index, Item item) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Hero(
        // ✅ tag فريد أكثر (لمنع تعارض Hero في صفحات ثانية)
        tag: "love_item_${item.id ?? index}",
        child: RepaintBoundary(
          child: ItemThatYouLoveCard(item: item, index: index),
        ),
      ),
    );
  }
}

class ItemThatYouLoveShimmerView extends StatefulWidget {
  final bool forShop;
  const ItemThatYouLoveShimmerView({super.key, required this.forShop});

  @override
  State<ItemThatYouLoveShimmerView> createState() => _ItemThatYouLoveShimmerViewState();
}

class _ItemThatYouLoveShimmerViewState extends State<ItemThatYouLoveShimmerView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1, viewportFraction: 0.8);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: Dimensions.paddingSizeDefault,
            left: Dimensions.paddingSizeDefault,
            right: Dimensions.paddingSizeDefault,
          ),
          child: widget.forShop
              ? Text('item_that_you_love'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))
              : TitleWidget(title: 'item_that_you_love'.tr),
        ),

        if (widget.forShop)
          Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
            child: SizedBox(
              height: 300,
              width: Get.width,
              child: Swiper(
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Shimmer(
                      duration: const Duration(seconds: 2),
                      enabled: true,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                      ),
                    ),
                  );
                },
                itemCount: 5,
                itemWidth: 250,
                itemHeight: 300,
                layout: SwiperLayout.TINDER,
              ),
            ),
          )
        else
          AspectRatio(
            aspectRatio: 1.05,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 6,
              allowImplicitScrolling: true,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Shimmer(
                    duration: const Duration(seconds: 2),
                    enabled: true,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
