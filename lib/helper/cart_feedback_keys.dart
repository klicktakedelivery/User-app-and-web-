import 'package:flutter/material.dart';

/// مفاتيح عامة لتأثيرات السلة (Fly to cart / badges / إلخ)
class CartFeedbackKeys {
  CartFeedbackKeys._();

  /// نربطه بزر السلة (FAB) في Dashboard
  static final GlobalKey cartFabKey = GlobalKey(debugLabel: 'cart_fab_key');
}
