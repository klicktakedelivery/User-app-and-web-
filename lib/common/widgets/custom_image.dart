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

    // Web proxy يحتاج encoding للـ url
    if (kIsWeb) {
      final encoded = Uri.encodeComponent(image);
      return '${AppConstants.baseUrl}/image-proxy?url=$encoded';
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    // decode حجم مناسب لتقليل استهلاك الذاكرة
    int? memWidth;
    int? memHeight;

    if (width != null) {
      memWidth = (width! * 2).round();
    }
    if (height != null) {
      memHeight = (height! * 2).round();
    }

    final resolvedUrl = _resolveUrl();

    final Widget img = CachedNetworkImage(
      color: color,
      imageUrl: resolvedUrl,
      height: height,
      width: width,
      fit: fit,

      // أداء + ذاكرة
      memCacheWidth: memWidth,
      memCacheHeight: memHeight,

      // يقلل الوميض وإعادة الرسم عند تبدّل الرابط
      useOldImageOnUrlChange: true,

      // انتقالات خفيفة (تحسن الإحساس وتقلل spikes)
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

    // ✅ مهم للأداء: لا تشغّل AnimatedScale إلا لو فعلاً في Hover (عادة على الويب/الديسكتوب)
    if (!isHovered) return img;

    return AnimatedScale(
      scale: 1.1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: img,
    );
  }
}
