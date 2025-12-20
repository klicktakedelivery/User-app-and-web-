// ===============================================
// نظام Caching ذكي لتقليل استدعاءات API
// + Zone Currency Sync (Currency follows Zone even when cache hits)
// ===============================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ApiCacheManager {
  static final Map<String, CachedData> _memoryCache = {};
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> _ensureInit() async {
    if (_prefs == null) {
      await init();
    }
  }

  /// استخراج العملة من رد zone (بأكثر من شكل محتمل)
  static String? _extractCurrencyFromZoneResponse(dynamic data) {
    try {
      if (data is Map) {
        // مباشر
        final direct = (data['currency_code'] ?? data['currencyCode'])?.toString();
        if (direct != null && direct.trim().isNotEmpty) return direct.trim();

        // داخل zone
        final zone = data['zone'];
        if (zone is Map) {
          final zc = (zone['currency_code'] ?? zone['currencyCode'])?.toString();
          if (zc != null && zc.trim().isNotEmpty) return zc.trim();
        }

        // داخل zone_data (List)
        final zoneData = data['zone_data'];
        if (zoneData is List && zoneData.isNotEmpty) {
          for (final z in zoneData) {
            if (z is! Map) continue;
            final zc = (z['currency_code'] ?? z['currencyCode'])?.toString();
            if (zc != null && zc.trim().isNotEmpty) return zc.trim();
          }
        }

        // داخل data (بعض الباك اند يلف الرد)
        final inner = data['data'];
        if (inner is Map) {
          final ic = (inner['currency_code'] ?? inner['currencyCode'])?.toString();
          if (ic != null && ic.trim().isNotEmpty) return ic.trim();

          final innerZoneData = inner['zone_data'];
          if (innerZoneData is List && innerZoneData.isNotEmpty) {
            for (final z in innerZoneData) {
              if (z is! Map) continue;
              final zc = (z['currency_code'] ?? z['currencyCode'])?.toString();
              if (zc != null && zc.trim().isNotEmpty) return zc.trim();
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// تطبيق العملة (إذا كانت Zone key)
  static Future<void> _applyZoneCurrencyIfNeeded(String key, dynamic data) async {
    // نحن نهتم فقط بكاش الزون
    if (!key.startsWith('zone_')) return;

    final code = _extractCurrencyFromZoneResponse(data);
    if (code == null || code.trim().isEmpty) return;

    final normalized = code.trim().toUpperCase();

    try {
      await _ensureInit();
      await _prefs?.setString(AppConstants.currencyCode, normalized);
    } catch (_) {}

    // لو ApiClient موجود، حدّث الهيدر فوراً
    try {
      if (Get.isRegistered<ApiClient>()) {
        await Get.find<ApiClient>().setCurrency(normalized, refreshHeader: true);
      }
    } catch (_) {}

    if (kDebugMode) {
      print('💱 CacheManager applied Zone Currency: $normalized (key=$key)');
    }
  }

  // حفظ البيانات في الكاش
  static Future<void> cacheData(
    String key,
    dynamic data, {
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    await _ensureInit();

    final cachedData = CachedData(
      data: data,
      cachedAt: DateTime.now(),
      duration: cacheDuration,
    );

    // حفظ في الذاكرة (سريع)
    _memoryCache[key] = cachedData;

    // ✅ لو هذا كاش Zone: طبّق العملة فوراً
    await _applyZoneCurrencyIfNeeded(key, data);

    // حفظ في SharedPreferences (للاستمرارية)
    try {
      await _prefs?.setString(
        'cache_$key',
        jsonEncode({
          'data': data,
          'cachedAt': cachedData.cachedAt.toIso8601String(),
          'durationMinutes': cacheDuration.inMinutes,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error caching data: $e');
      }
    }
  }

  // جلب البيانات من الكاش
  static Future<dynamic> getCachedData(String key) async {
    await _ensureInit();

    // فحص الذاكرة أولاً (أسرع)
    if (_memoryCache.containsKey(key)) {
      final cached = _memoryCache[key]!;
      if (!cached.isExpired) {
        if (kDebugMode) {
          print('✅ Cache HIT (Memory): $key');
        }

        // ✅ لو هذا كاش Zone: طبّق العملة حتى لو رجعت من الذاكرة
        await _applyZoneCurrencyIfNeeded(key, cached.data);

        return cached.data;
      } else {
        _memoryCache.remove(key);
      }
    }

    // فحص SharedPreferences
    try {
      final cachedString = _prefs?.getString('cache_$key');
      if (cachedString != null) {
        final cachedJson = jsonDecode(cachedString);
        final cachedAt = DateTime.parse(cachedJson['cachedAt']);
        final duration = Duration(minutes: cachedJson['durationMinutes']);

        final cached = CachedData(
          data: cachedJson['data'],
          cachedAt: cachedAt,
          duration: duration,
        );

        if (!cached.isExpired) {
          if (kDebugMode) {
            print('✅ Cache HIT (Storage): $key');
          }

          _memoryCache[key] = cached; // حفظ في الذاكرة للمرات القادمة

          // ✅ لو هذا كاش Zone: طبّق العملة حتى لو رجعت من التخزين
          await _applyZoneCurrencyIfNeeded(key, cached.data);

          return cached.data;
        } else {
          await _prefs?.remove('cache_$key');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reading cache: $e');
      }
    }

    if (kDebugMode) {
      print('❌ Cache MISS: $key');
    }
    return null;
  }

  // مسح كاش معين
  static Future<void> clearCache(String key) async {
    await _ensureInit();
    _memoryCache.remove(key);
    await _prefs?.remove('cache_$key');
  }

  // مسح كل الكاش
  static Future<void> clearAllCache() async {
    await _ensureInit();

    _memoryCache.clear();
    final keys = _prefs?.getKeys().where((k) => k.startsWith('cache_'));
    if (keys != null) {
      for (var key in keys) {
        await _prefs?.remove(key);
      }
    }
  }
}

class CachedData {
  final dynamic data;
  final DateTime cachedAt;
  final Duration duration;

  CachedData({
    required this.data,
    required this.cachedAt,
    required this.duration,
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > duration;
}
