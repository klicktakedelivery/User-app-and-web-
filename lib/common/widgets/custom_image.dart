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

  // لو كان مشروعك يستخدم تلوين الصورة (مثلاً للأيقونات) خليه
  // وإذا ما تحتاجه احذف الحقل واماكن استخدامه
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

  /// يرجّع رابط صحيح:
  /// - لو image رابط كامل http/https يرجعه كما هو
  /// - لو image مسار نسبي يرجعه على baseUrl + storage
  /// - على الويب: ممكن تمريره عبر proxy لو موجود عندكم
  String? _resolveUrl(String raw) {
    final v = raw.trim();
    if (v.isEmpty || v.toLowerCase() == 'null') return null;

    // رابط كامل
    if (v.startsWith('http://') || v.startsWith('https://')) {
      if (kIsWeb) {
        // لو عندكم image-proxy على السيرفر (مثل اللي عندك في النسخة الثانية)
        // خليها شغّالة. إذا ما عندك هذا المسار احذف هالبلوك وخلاص.
        final encoded = Uri.encodeComponent(v);
        return '${AppConstants.baseUrl}/image-proxy?url=$encoded';
      }
      return v;
    }

    // مسار نسبي
    final base = AppConstants.baseUrl;

    // لو يبدأ بـ / خليه resolve مباشر
    if (v.startsWith('/')) {
      return Uri.parse(base).resolve(v).toString();
    }

    // غالباً صوركم داخل storage/
    return Uri.parse(base).resolve('storage/$v').toString();
  }

  @override
  Widget build(BuildContext context) {
    final String? url = _resolveUrl(image);

    final double? h = (height != null && height!.isFinite && height! > 0) ? height : null;
    final double? w = (width != null && width!.isFinite && width! > 0) ? width : null;

    if (url == null) {
      return _buildPlaceholder(h: h, w: w);
    }

    // تحسين كاش الذاكرة بشكل آمن (مفيد للموبايل)
    int? memWidth;
    int? memHeight;
    if (w != null && w < 2000) {
      memWidth = (w * 1.5).round().clamp(50, 800);
    }
    if (h != null && h < 2000) {
      memHeight = (h * 1.5).round().clamp(50, 800);
    }

    final Widget fallback = _buildPlaceholder(h: h, w: w);

    final Widget imageWidget = kIsWeb
        ? Image.network(
            url,
            height: h,
            width: w,
            fit: fit,
            color: color,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, __, ___) => fallback,
          )
        : CachedNetworkImage(
            imageUrl: url,
            height: h,
            width: w,
            fit: fit,
            color: color,

            memCacheWidth: memWidth,
            memCacheHeight: memHeight,
            maxWidthDiskCache: 800,
            maxHeightDiskCache: 800,

            fadeInDuration: const Duration(milliseconds: 100),
            fadeOutDuration: const Duration(milliseconds: 100),

            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          );

    // hover effect اختياري (يشتغل لو أنت تمرر isHovered من MouseRegion برا)
    return AnimatedScale(
      scale: isHovered ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: imageWidget,
    );
  }

  Widget _buildPlaceholder({double? h, double? w}) {
    return Image.asset(
      placeholder.isNotEmpty
          ? placeholder
          : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
      height: h,
      width: w,
      fit: fit,
      color: color,
      filterQuality: FilterQuality.low,
    );
  }
}
