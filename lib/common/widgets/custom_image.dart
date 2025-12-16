import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';

class CustomImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final bool isNotification;
  final String placeholder;
  final bool isHovered;
  final Color? color;

  const CustomImage({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.isNotification = false,
    this.placeholder = '',
    this.isHovered = false,
    this.color,
  });

  String _resolveUrl() {
    if (image.isEmpty) return image;

    if (kIsWeb) {
      final encoded = Uri.encodeComponent(image);
      return '${AppConstants.baseUrl}/image-proxy?url=$encoded';
    }
    return image;
  }

  int? _safeMemSize(double? v, double dpr) {
    if (v == null) return null;
    if (!v.isFinite || v.isNaN) return null;
    if (v <= 0) return null;

    final px = (v * dpr).round();
    if (px <= 0) return null;

    // سقف منطقي لتجنب قيم ضخمة تكسر الذاكرة
    return math.min(px, 4096);
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final int? memWidth = _safeMemSize(width, dpr);
    final int? memHeight = _safeMemSize(height, dpr);

    final resolvedUrl = _resolveUrl();

    final Widget img = CachedNetworkImage(
      color: color,
      imageUrl: resolvedUrl,
      height: height,
      width: width,
      fit: fit,

      memCacheWidth: memWidth,
      memCacheHeight: memHeight,

      useOldImageOnUrlChange: true,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 120),

      imageBuilder: (context, imageProvider) => Image(
        image: imageProvider,
        height: height,
        width: width,
        fit: fit,
        color: color,
        filterQuality: FilterQuality.low,
      ),

      placeholder: (context, url) => Image.asset(
        placeholder.isNotEmpty
            ? placeholder
            : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
        height: height,
        width: width,
        fit: fit,
        color: color,
        filterQuality: FilterQuality.low,
      ),

      errorWidget: (context, url, error) => Image.asset(
        placeholder.isNotEmpty
            ? placeholder
            : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
        height: height,
        width: width,
        fit: fit,
        color: color,
        filterQuality: FilterQuality.low,
      ),
    );

    if (!isHovered) return img;

    return AnimatedScale(
      scale: 1.1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: img,
    );
  }
}

/// ✅ بوابة واحدة لأي مكان يحتاج ImageProvider (DecorationImage / CircleAvatar / إلخ)
class CustomImageProvider {
  static String resolveUrl(String url) {
    if (url.isEmpty) return url;

    if (kIsWeb) {
      final encoded = Uri.encodeComponent(url);
      return '${AppConstants.baseUrl}/image-proxy?url=$encoded';
    }
    return url;
  }

  static ImageProvider provider(String url) {
    return CachedNetworkImageProvider(resolveUrl(url));
  }
}
