import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/home/widgets/components/custom_circle_list_view_package.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';

class CircleListView extends StatefulWidget {
  const CircleListView({super.key});

  @override
  State<CircleListView> createState() => _CircleListViewState();
}

class _CircleListViewState extends State<CircleListView> {
  Gallery3DController? _galleryController;
  int _lastCount = 0;

  // نحتفظ بالقائمة المحضّرة
  List<Item> _preparedList = const [];

  List<Item> _prepareList(List<Item> original) {
    if (original.isEmpty) return const [];

    // لو 1 أو 2 نخليهم 3 عناصر عشان شكل السلايدر
    if (original.length == 1) {
      return [original[0], original[0], original[0]];
    }
    if (original.length == 2) {
      return [original[0], original[1], original[0]];
    }
    return List<Item>.from(original);
  }

  void _ensureGalleryController(int itemCount) {
    if (_galleryController == null || _lastCount != itemCount) {
      _lastCount = itemCount;
      _galleryController = Gallery3DController(itemCount: itemCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CampaignController>(builder: (campaignController) {
      final original = campaignController.itemCampaignList;

      if (original == null) {
        return const CircleListViewShimmerView();
      }

      final prepared = _prepareList(original);
      if (prepared.isEmpty) {
        return const SizedBox.shrink();
      }

      _preparedList = prepared;
      _ensureGalleryController(_preparedList.length);

      return SizedBox(
        height: 200,
        width: MediaQuery.of(context).size.width,
        child: RepaintBoundary(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Gallery3D(
              controller: _galleryController!,
              width: MediaQuery.of(context).size.width,
              height: 200,
              isClip: true,

              // ما نحتاج setState هنا لأنه ما في UI يعتمد على currentIndex
              onItemChanged: (index) {},

              itemConfig: const GalleryItemConfig(
                width: 220,
                height: 200,
                radius: 10,
                isShowTransformMask: false,
              ),
              onClickItem: (index) {
                if (kDebugMode) {
                  // ignore: avoid_print
                  print("currentIndex:$index");
                }
              },
              itemBuilder: (context, index) {
                final item = _preparedList[index];

                return InkWell(
                  onTap: () => Get.find<ItemController>()
                      .navigateToItemPage(item, context, isCampaign: true),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: CustomImage(
                      image: '${item.imageFullUrl}',
                      fit: BoxFit.cover,
                      height: 200,
                      width: 220,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

class CircleListViewShimmerView extends StatelessWidget {
  const CircleListViewShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(
              title: 'just_for_you'.tr,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
            child: SizedBox(
              height: 200,
              width: MediaQuery.of(context).size.width,
              child: RepaintBoundary(
                child: Gallery3D(
                  controller: Gallery3DController(itemCount: 3),
                  width: MediaQuery.of(context).size.width,
                  height: 200,
                  isClip: true,
                  itemConfig: const GalleryItemConfig(
                    width: 220,
                    height: 200,
                    radius: 10,
                    isShowTransformMask: false,
                  ),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault),
                      child: Shimmer(
                        duration: const Duration(seconds: 2),
                        enabled: true,
                        child: Container(color: Colors.grey[300]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
