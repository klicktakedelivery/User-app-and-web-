import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/app_constants.dart';

class CustomImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final bool isNotification;
  final String placeholder;
  final bool isHovered;

  const CustomImage({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.isNotification = false,
    this.placeholder = '',
    this.isHovered = false,
  });

  String? _resolveUrl(String raw) {
    final String v = raw.trim();
    if (v.isEmpty || v.toLowerCase() == 'null') return null;

    if (v.startsWith('http://') || v.startsWith('https://')) return v;

    final String base = AppConstants.baseUrl;
    if (v.startsWith('/')) {
      return Uri.parse(base).resolve(v).toString();
    }

    return Uri.parse(base).resolve('storage/$v').toString();
  }

  @override
  Widget build(BuildContext context) {
    final String? url = _resolveUrl(image);

    // ✅ تصفية Infinity/NaN/0
    final double? h = (height != null && height!.isFinite && height! > 0) ? height : null;
    final double? w = (width != null && width!.isFinite && width! > 0) ? width : null;

    if (url == null) {
      debugPrint('❌ [CustomImage] EMPTY image URL received.');
      return Image.asset(
        placeholder.isNotEmpty
            ? placeholder
            : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
        height: h,
        width: w,
        fit: fit,
      );
    }

    final Widget fallback = Image.asset(
      placeholder.isNotEmpty
          ? placeholder
          : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
      height: h,
      width: w,
      fit: fit,
    );

    return AnimatedScale(
      scale: isHovered ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: kIsWeb
          ? Image.network(
              url,
              height: h,
              width: w,
              fit: fit,
              errorBuilder: (_, __, ___) => fallback,
            )
          : CachedNetworkImage(
              imageUrl: url,
              height: h,
              width: w,
              fit: fit,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}
