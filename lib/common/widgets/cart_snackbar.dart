import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/route_helper.dart';

import 'cart_fly_to_cart_feedback.dart';

/// Wrapper موحّد لأي "تمت الإضافة للسلة"
/// حالياً نستعمل مفاتيح وهمية ليشتغل الـ Bottom Toast فوراً (Fallback)
/// وبعدها رح نوصل مفاتيح حقيقية عشان يشتغل الـ Fly-to-cart.
void showCartSnackBar({
  double? addedAmount,
  String currencySymbol = '\$',
  ImageProvider? imageProvider,
}) {
  // مفاتيح وهمية -> داخل showCartFlyToCartFeedback رح يفشل استخراج الإحداثيات
  // وبالتالي يعرض Bottom Toast الجميل تلقائياً.
  final dummyFromKey = GlobalKey();
  final dummyToKey = GlobalKey();

  showCartFlyToCartFeedback(
    fromKey: dummyFromKey,
    toKey: dummyToKey,
    imageProvider: imageProvider,
    addedAmount: addedAmount,
    currencySymbol: currencySymbol,
    messageTrKey: 'item_added_to_cart',
    onViewCart: () => Get.toNamed(RouteHelper.getCartRoute()),
  );
}
