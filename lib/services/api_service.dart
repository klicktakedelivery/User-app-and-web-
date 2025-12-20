import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_cache_manager.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = 'https://admin.klicktake.com/api/v1';

  // منع استدعاءات متكررة لنفس الـ endpoint
  final Map<String, Future<dynamic>> _pendingRequests = {};

  ApiClient? _apiClientOrNull() {
    try {
      if (Get.isRegistered<ApiClient>()) {
        return Get.find<ApiClient>();
      }
    } catch (_) {}
    return null;
  }

  SharedPreferences? _spOrNull() {
    try {
      if (Get.isRegistered<SharedPreferences>()) {
        return Get.find<SharedPreferences>();
      }
    } catch (_) {}
    return null;
  }

  String _currencyForCacheKey() {
    try {
      final sp = _spOrNull();
      final c = sp?.getString(AppConstants.currencyCode);
      if (c != null && c.trim().isNotEmpty) return c.trim().toUpperCase();
    } catch (_) {}
    return 'USD';
  }

  /// هيدرز موحدة: أساسها ApiClient.getHeader()
  /// وبعدين بنعمل override للـ zone/module/lat/lng حسب كل endpoint.
  Map<String, String> _buildHeaders({
    List<int>? zoneId,
    int? moduleId,
    double? latitude,
    double? longitude,
    String? currencyCode,
  }) {
    final apiClient = _apiClientOrNull();
    final sp = _spOrNull();

    // أساس الهيدر: من ApiClient لو موجود، وإلا fallback بسيط
    final base = <String, String>{};
    if (apiClient != null) {
      base.addAll(apiClient.getHeader());
    } else {
      base.addAll({
        'Content-Type': 'application/json; charset=UTF-8',
        AppConstants.localizationKey: sp?.getString(AppConstants.languageCode) ?? 'en',
        AppConstants.currencyHeaderKey: sp?.getString(AppConstants.currencyCode) ?? 'USD',
      });
    }

    // Override/إضافة حسب الحاجة
    base['Content-Type'] = 'application/json; charset=UTF-8';

    if (zoneId != null) {
      base[AppConstants.zoneId] = jsonEncode(zoneId);
    }

    if (moduleId != null) {
      base[AppConstants.moduleId] = moduleId.toString();
    }

    if (latitude != null) {
      base[AppConstants.latitude] = latitude.toString();
    }

    if (longitude != null) {
      base[AppConstants.longitude] = longitude.toString();
    }

    // Currency override (إذا أعطيناها صراحة)
    if (currencyCode != null && currencyCode.trim().isNotEmpty) {
      base[AppConstants.currencyHeaderKey] = currencyCode.trim().toUpperCase();
    } else {
      // تأكيد وجودها دائماً
      base[AppConstants.currencyHeaderKey] =
          base[AppConstants.currencyHeaderKey] ?? (sp?.getString(AppConstants.currencyCode) ?? 'USD');
    }

    return base;
  }

  String? _extractCurrencyCodeFromZoneResponse(dynamic data) {
    try {
      if (data is Map) {
        // 1) مباشر
        final direct = (data['currency_code'] ?? data['currencyCode'])?.toString();
        if (direct != null && direct.trim().isNotEmpty) return direct.trim();

        // 2) داخل zone / zone_data
        final zone = data['zone'];
        if (zone is Map) {
          final zc = (zone['currency_code'] ?? zone['currencyCode'])?.toString();
          if (zc != null && zc.trim().isNotEmpty) return zc.trim();
        }

        final zoneData = data['zone_data'];
        if (zoneData is List && zoneData.isNotEmpty) {
          for (final z in zoneData) {
            if (z is! Map) continue;
            final zc = (z['currency_code'] ?? z['currencyCode'])?.toString();
            if (zc != null && zc.trim().isNotEmpty) return zc.trim();
          }
        }

        // 3) داخل data -> (بعض الباك اند يلف الرد)
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

  Future<void> _applyCurrencyIfFound(dynamic zoneResponse) async {
    final code = _extractCurrencyCodeFromZoneResponse(zoneResponse);
    if (code == null || code.trim().isEmpty) return;

    final normalized = code.trim().toUpperCase();

    try {
      final sp = _spOrNull();
      if (sp != null) {
        await sp.setString(AppConstants.currencyCode, normalized);
      }
    } catch (_) {}

    try {
      final apiClient = _apiClientOrNull();
      if (apiClient != null) {
        await apiClient.setCurrency(normalized, refreshHeader: true);
      }
    } catch (_) {}

    if (kDebugMode) {
      print('💱 Currency updated from Zone: $normalized');
    }
  }

  // طلب API مع منع Duplicates
  Future<dynamic> _makeRequest(
    String key,
    Future<http.Response> Function() requestFn,
  ) async {
    // إذا كان هناك طلب قيد التنفيذ، انتظر نتيجته
    if (_pendingRequests.containsKey(key)) {
      if (kDebugMode) {
        print('⏳ Waiting for pending request: $key');
      }
      return await _pendingRequests[key];
    }

    // فحص الكاش أولاً
    final cachedData = await ApiCacheManager.getCachedData(key);
    if (cachedData != null) {
      return cachedData;
    }

    // إنشاء طلب جديد
    if (kDebugMode) {
      print('📡 Making new API request: $key');
    }

    final requestFuture = requestFn().then((response) {
      _pendingRequests.remove(key);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    }).catchError((error) {
      _pendingRequests.remove(key);
      throw error;
    });

    _pendingRequests[key] = requestFuture;
    return await requestFuture;
  }

  // ═══════════════════════════════════════════════
  // API Endpoints
  // ═══════════════════════════════════════════════

  /// ✅ مهم: هنا نلتقط currency_code من السيرفر ونثبتها (Zone-based)
  Future<dynamic> getZoneId(double lat, double lng) async {
    final key = 'zone_${lat}_$lng';

    final headers = _buildHeaders(latitude: lat, longitude: lng);

    final data = await _makeRequest(
      key,
      () => http.get(
        Uri.parse('$baseUrl/config/get-zone-id?lat=$lat&lng=$lng'),
        headers: headers,
      ),
    );

    // إذا السيرفر يرجّع currency_code/zone_data => خزّنها وحدّث الهيدر فوراً
    await _applyCurrencyIfFound(data);

    // حفظ في الكاش لمدة 15 دقيقة
    await ApiCacheManager.cacheData(key, data, cacheDuration: const Duration(minutes: 15));
    return data;
  }

  Future<List<dynamic>> getModules() async {
    const key = 'modules';

    final headers = _buildHeaders();

    final data = await _makeRequest(
      key,
      () => http.get(
        Uri.parse('$baseUrl/module'),
        headers: headers,
      ),
    );

    // Modules نادراً ما تتغير - كاش لمدة ساعة
    await ApiCacheManager.cacheData(key, data, cacheDuration: const Duration(hours: 1));
    return data as List<dynamic>;
  }

  Future<dynamic> getStores({
    required int moduleId,
    required List<int> zoneId,
    double? latitude,
    double? longitude,
    bool featured = false,
  }) async {
    final currency = _currencyForCacheKey();
    final key = "stores_${moduleId}_${zoneId}_$featured\_$currency";

    final headers = _buildHeaders(
      moduleId: moduleId,
      zoneId: zoneId,
      latitude: latitude,
      longitude: longitude,
    );

    final data = await _makeRequest(
      key,
      () => http.get(
        Uri.parse('$baseUrl/stores/get-stores/all?featured=${featured ? 1 : 0}&offset=1&limit=50'),
        headers: headers,
      ),
    );

    // Stores تتغير أكثر - كاش لمدة 5 دقائق
    await ApiCacheManager.cacheData(key, data, cacheDuration: const Duration(minutes: 5));
    return data;
  }

  Future<List<dynamic>> getCategories({
    required int moduleId,
    required List<int> zoneId,
  }) async {
    final currency = _currencyForCacheKey();
    final key = "categories_$moduleId_${zoneId.join(",")}_$currency";

    final headers = _buildHeaders(
      moduleId: moduleId,
      zoneId: zoneId,
    );

    final data = await _makeRequest(
      key,
      () => http.get(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
      ),
    );

    // Categories - كاش لمدة 30 دقيقة
    await ApiCacheManager.cacheData(key, data, cacheDuration: const Duration(minutes: 30));
    return data as List<dynamic>;
  }
}
