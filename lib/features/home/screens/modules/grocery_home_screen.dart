import 'package:flutter/material.dart';
import 'package:sixam_mart/features/flash_sale/widgets/flash_sale_view_widget.dart';
import 'package:sixam_mart/features/home/widgets/highlight_widget.dart';
import 'package:sixam_mart/features/home/widgets/views/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/best_reviewed_item_view.dart';
import 'package:sixam_mart/features/home/widgets/views/best_store_nearby_view.dart';
import 'package:sixam_mart/features/home/widgets/views/category_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promo_code_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/item_that_you_love_view.dart';
import 'package:sixam_mart/features/home/widgets/views/just_for_you_view.dart';
import 'package:sixam_mart/features/home/widgets/views/most_popular_item_view.dart';
import 'package:sixam_mart/features/home/widgets/views/new_on_mart_view.dart';
import 'package:sixam_mart/features/home/widgets/views/middle_section_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/recommended_store_view.dart';
import 'package:sixam_mart/features/home/widgets/views/special_offer_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/top_offers_near_me.dart';
import 'package:sixam_mart/features/home/widgets/views/visit_again_view.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

class GroceryHomeScreen extends StatelessWidget {
  const GroceryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthHelper.isLoggedIn();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======= Above-the-fold (يظهر بسرعة) =======
        Container(
          width: MediaQuery.of(context).size.width,
          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
          child: const Column(
            children: [
              BannerView(isFeatured: false),
              SizedBox(height: 12),
            ],
          ),
        ),

        const CategoryView(),

        // ======= Lazy sections (تتبني عند الاقتراب) =======
        _LazySection(child: isLoggedIn ? const VisitAgainView() : const SizedBox.shrink()),
        const _LazySection(child: RecommendedStoreView()),
        const _LazySection(child: SpecialOfferView(isFood: false, isShop: false)),
        const _LazySection(child: HighlightWidget()),
        const _LazySection(child: FlashSaleViewWidget()),
        const _LazySection(child: BestStoreNearbyView()),
        const _LazySection(child: MostPopularItemView(isFood: false, isShop: false)),
        const _LazySection(child: MiddleSectionBannerView()),
        const _LazySection(child: BestReviewItemView()),
        const _LazySection(child: JustForYouView()),
        const _LazySection(child: TopOffersNearMe()),
        const _LazySection(child: ItemThatYouLoveView(forShop: false)),
        _LazySection(child: isLoggedIn ? const PromoCodeBannerView() : const SizedBox.shrink()),
        const _LazySection(child: NewOnMartView(isPharmacy: false, isShop: false)),
        const _LazySection(child: PromotionalBannerView()),
      ],
    );
  }
}

/// يبني الـ child فقط عندما يقترب من منطقة العرض (يقلل جهد الـ build والـ layout)
class _LazySection extends StatefulWidget {
  final Widget child;

  /// مقدار الاقتراب قبل البناء (بالبيكسل)
  final double preloadOffset;

  const _LazySection({
    required this.child,
    this.preloadOffset = 600, // يبني قبل ما يظهر بشوي حتى ما تحس بقفزة
  });

  @override
  State<_LazySection> createState() => _LazySectionState();
}

class _LazySectionState extends State<_LazySection> {
  bool _built = false;

  @override
  Widget build(BuildContext context) {
    if (_built) return widget.child;

    return VisibilityDetectorLite(
      preloadOffset: widget.preloadOffset,
      onVisible: () {
        if (mounted) {
          setState(() => _built = true);
        }
      },
      placeholder: const SizedBox.shrink(),
    );
  }
}

/// بديل خفيف جدًا لـ visibility_detector بدون حزمة إضافية.
/// الفكرة: نراقب هل هذا الودجت دخل مجال الشاشة تقريبًا.
class VisibilityDetectorLite extends StatefulWidget {
  final VoidCallback onVisible;
  final Widget placeholder;
  final double preloadOffset;

  const VisibilityDetectorLite({
    super.key,
    required this.onVisible,
    required this.placeholder,
    required this.preloadOffset,
  });

  @override
  State<VisibilityDetectorLite> createState() => _VisibilityDetectorLiteState();
}

class _VisibilityDetectorLiteState extends State<VisibilityDetectorLite> {
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder يعطينا مكان الودجت بالنسبة للشاشة بشكل غير مباشر
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_fired || !mounted) return;

          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null || !renderBox.hasSize) return;

          final offset = renderBox.localToGlobal(Offset.zero);
          final screenHeight = MediaQuery.of(context).size.height;

          final widgetTop = offset.dy;
          final widgetBottom = widgetTop + renderBox.size.height;

          // إذا اقترب من الشاشة (ضمن هامش preloadOffset) اعتبره “مرئي”
          final isNearViewport = widgetTop < screenHeight + widget.preloadOffset &&
              widgetBottom > -widget.preloadOffset;

          if (isNearViewport) {
            _fired = true;
            widget.onVisible();
          }
        });

        return widget.placeholder;
      },
    );
  }
}
