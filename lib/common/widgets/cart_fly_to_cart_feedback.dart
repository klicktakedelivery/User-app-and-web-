import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Usage example:
/// showCartFlyToCartFeedback(
///   fromKey: productImageKey,
///   toKey: cartIconKey,
///   imageProvider: NetworkImage(imageUrl),
///   addedAmount: 12.5,
///   currencySymbol: '\$',
/// );
void showCartFlyToCartFeedback({
  required GlobalKey fromKey,
  required GlobalKey toKey,
  ImageProvider? imageProvider,
  double? addedAmount,
  String currencySymbol = '\$',
  String messageTrKey = 'item_added_to_cart',
  Duration duration = const Duration(milliseconds: 2200),
  VoidCallback? onViewCart,
}) {
  // ✅ خذ overlay حتى لو Get.context صار null (السيناريو الشائع)
  final OverlayState? overlay =
      Get.key.currentState?.overlay ??
      Overlay.maybeOf(Get.overlayContext ?? Get.context!, rootOverlay: true);

  if (overlay == null) return;

  final start = _globalRectOfKey(fromKey);
  final target = _globalRectOfKey(toKey);

  if (start == null || target == null) {
    _showBottomInfoOnly(
      overlay: overlay,
      message: messageTrKey.tr,
      addedAmount: addedAmount,
      currencySymbol: currencySymbol,
      duration: duration,
      onViewCart: onViewCart,
    );
    return;
  }


  OverlayEntry? entry;

  entry = OverlayEntry(
    builder: (_) => _CartFeedbackOverlay(
      start: start,
      target: target,
      imageProvider: imageProvider,
      message: messageTrKey.tr,
      addedAmount: addedAmount,
      currencySymbol: currencySymbol,
      duration: duration,
      onViewCart: onViewCart,
      onDone: () {
        try {
          entry?.remove();
        } catch (_) {}
      },
    ),
  );

  overlay.insert(entry);
}

Rect? _globalRectOfKey(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null) return null;

  final render = ctx.findRenderObject();
  if (render is! RenderBox || !render.hasSize) return null;

  final offset = render.localToGlobal(Offset.zero);
  return offset & render.size;
}

Color _withOpacity(Color color, double opacity) {
  final a = (opacity.clamp(0.0, 1.0) * 255).round();
  return color.withAlpha(a);
}

void _showBottomInfoOnly({
  required OverlayState overlay,
  required String message,
  required double? addedAmount,
  required String currencySymbol,
  required Duration duration,
  VoidCallback? onViewCart,
}) {
  OverlayEntry? entry;

  entry = OverlayEntry(
    builder: (_) => _BottomOnlyToast(
      message: message,
      addedAmount: addedAmount,
      currencySymbol: currencySymbol,
      duration: duration,
      onViewCart: onViewCart,
      onDone: () {
        try {
          entry?.remove();
        } catch (_) {}
      },
    ),
  );

  overlay.insert(entry);
}

class _CartFeedbackOverlay extends StatefulWidget {
  final Rect start;
  final Rect target;

  final ImageProvider? imageProvider;
  final String message;
  final double? addedAmount;
  final String currencySymbol;

  final Duration duration;
  final VoidCallback? onViewCart;
  final VoidCallback onDone;

  const _CartFeedbackOverlay({
    required this.start,
    required this.target,
    required this.imageProvider,
    required this.message,
    required this.addedAmount,
    required this.currencySymbol,
    required this.duration,
    required this.onDone,
    this.onViewCart,
  });

  @override
  State<_CartFeedbackOverlay> createState() => _CartFeedbackOverlayState();
}

class _CartFeedbackOverlayState extends State<_CartFeedbackOverlay> with TickerProviderStateMixin {
  late final AnimationController _flyCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final AnimationController _toastCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  late final AnimationController _amountCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _flyT = CurvedAnimation(parent: _flyCtrl, curve: Curves.easeInOutCubic);
  late final Animation<double> _toastIn = CurvedAnimation(parent: _toastCtrl, curve: Curves.easeOutCubic);
  late final Animation<double> _amountT = CurvedAnimation(parent: _amountCtrl, curve: Curves.easeOutBack);

  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    // تسلسل دخول: Toast يظهر مباشرة + طيران + عداد
    _toastCtrl.forward();
    _flyCtrl.forward();

    if ((widget.addedAmount ?? 0) > 0) {
      Future.delayed(const Duration(milliseconds: 140), () {
        if (mounted) _amountCtrl.forward(from: 0);
      });
    }

    _dismissTimer = Timer(widget.duration, () async {
      if (!mounted) return;
      await _toastCtrl.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _flyCtrl.dispose();
    _toastCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Offset _centerOf(Rect r) => Offset(r.left + r.width / 2, r.top + r.height / 2);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),

          // طيران (Bubble/Thumb) من المنتج للسلة
          AnimatedBuilder(
            animation: _flyT,
            builder: (_, __) {
              final t = _flyT.value;

              final startC = _centerOf(widget.start);
              final endC = _centerOf(widget.target);

              // مسار منحني بسيط: نرفع شوي بالأعلى بمنتصف الطريق
              final mid = Offset(
                (startC.dx + endC.dx) / 2,
                (startC.dy + endC.dy) / 2 - 120,
              );

              Offset quadLerp(Offset a, Offset b, Offset c, double tt) {
                // Quadratic Bezier: (1-t)^2 a + 2(1-t)t b + t^2 c
                final u = 1 - tt;
                return Offset(
                  u * u * a.dx + 2 * u * tt * b.dx + tt * tt * c.dx,
                  u * u * a.dy + 2 * u * tt * b.dy + tt * tt * c.dy,
                );
              }

              final pos = quadLerp(startC, mid, endC, t);

              final size = lerpDouble(34, 18, t) ?? 22;
              final opacity = (t < 0.9) ? 1.0 : (1 - ((t - 0.9) / 0.1)).clamp(0.0, 1.0);

              return Positioned(
                left: pos.dx - size / 2,
                top: pos.dy - size / 2,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: lerpDouble(1.0, 0.85, t) ?? 1.0,
                    child: _FlyBubble(
                      size: size,
                      imageProvider: widget.imageProvider,
                    ),
                  ),
                ),
              );
            },
          ),

          // Toast أسفل الشاشة
          Positioned(
            left: 0,
            right: 0,
            bottom: media.padding.bottom + Dimensions.paddingSizeSmall,
            child: SafeArea(
              top: false,
              child: AnimatedBuilder(
                animation: _toastIn,
                builder: (_, __) {
                  final t = _toastIn.value;
                  final dy = lerpDouble(18, 0, t) ?? 0;

                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Opacity(
                      opacity: t,
                      child: _BottomToast(
                        message: widget.message,
                        amountT: _amountT,
                        addedAmount: widget.addedAmount,
                        currencySymbol: widget.currencySymbol,
                        onViewCart: widget.onViewCart ??
                            () {
                              Get.toNamed(RouteHelper.getCartRoute());
                            },
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
  }
}

class _FlyBubble extends StatelessWidget {
  final double size;
  final ImageProvider? imageProvider;

  const _FlyBubble({required this.size, this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 8),
              color: _withOpacity(Colors.black, 0.18),
            ),
          ],
          gradient: LinearGradient(
            colors: [
              Colors.green.withAlpha(242), // 0.95
              Colors.green.withAlpha(179), // 0.70
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageProvider != null
            ? Image(image: imageProvider!, fit: BoxFit.cover)
            : const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
      ),
    );
  }
}

class _BottomToast extends StatelessWidget {
  final String message;
  final Animation<double> amountT;
  final double? addedAmount;
  final String currencySymbol;
  final VoidCallback onViewCart;

  const _BottomToast({
    required this.message,
    required this.amountT,
    required this.addedAmount,
    required this.currencySymbol,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    final hasAmount = (addedAmount ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Colors.black.withAlpha(219), // 0.86
                Colors.black.withAlpha(184), // 0.72
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withAlpha(26)), // 0.10
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                offset: const Offset(0, 10),
                color: _withOpacity(Colors.black, 0.25),
              ),
            ],
          ),
          child: Row(
            children: [
              // Badge
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(242), // 0.95
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),

              // Texts
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoMedium.copyWith(color: Colors.white, fontSize: 14),
                    ),
                    if (hasAmount) const SizedBox(height: 4),
                    if (hasAmount)
                      AnimatedBuilder(
                        animation: amountT,
                        builder: (_, __) {
                          final v = (addedAmount! * amountT.value);
                          return Text(
                            '+ $currencySymbol ${v.toStringAsFixed(2)}',
                            style: robotoRegular.copyWith(
                              color: Colors.greenAccent,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // CTA
              InkWell(
                onTap: onViewCart,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withAlpha(26), // 0.10
                  ),
                  child: Row(
                    children: [
                      Text(
                        'view_cart'.tr,
                        style: robotoMedium.copyWith(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomOnlyToast extends StatefulWidget {
  final String message;
  final double? addedAmount;
  final String currencySymbol;
  final Duration duration;
  final VoidCallback? onViewCart;
  final VoidCallback onDone;

  const _BottomOnlyToast({
    required this.message,
    required this.addedAmount,
    required this.currencySymbol,
    required this.duration,
    required this.onDone,
    this.onViewCart,
  });

  @override
  State<_BottomOnlyToast> createState() => _BottomOnlyToastState();
}

class _BottomOnlyToastState extends State<_BottomOnlyToast> with TickerProviderStateMixin {
  late final AnimationController _toastCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  late final AnimationController _amountCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  late final Animation<double> _toastIn = CurvedAnimation(parent: _toastCtrl, curve: Curves.easeOutCubic);
  late final Animation<double> _amountT = CurvedAnimation(parent: _amountCtrl, curve: Curves.easeOutBack);

  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _toastCtrl.forward();

    if ((widget.addedAmount ?? 0) > 0) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _amountCtrl.forward(from: 0);
      });
    }

    _dismissTimer = Timer(widget.duration, () async {
      if (!mounted) return;
      await _toastCtrl.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _toastCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: media.padding.bottom + Dimensions.paddingSizeSmall,
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _toastIn,
          builder: (_, __) {
            final t = _toastIn.value;
            final dy = lerpDouble(18, 0, t) ?? 0;

            return Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(
                opacity: t,
                child: _BottomToast(
                  message: widget.message,
                  amountT: _amountT,
                  addedAmount: widget.addedAmount,
                  currencySymbol: widget.currencySymbol,
                  onViewCart: widget.onViewCart ??
                      () {
                        Get.toNamed(RouteHelper.getCartRoute());
                      },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
