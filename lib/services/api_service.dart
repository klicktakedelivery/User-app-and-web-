import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_cache_manager.dart';
import 'package:flutter/foundation.dart';
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  final String baseUrl = 'https://admin.klicktake.com/api/v1';
  
  // منع استدعاءات متكررة لنفس الـ endpoint
  final Map<String, Future<dynamic>> _pendingRequests = {};
  
  // طلب API مع منع Duplicates
  Future<dynamic> _makeRequest(String key, Future<http.Response> Function() requestFn) async {
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
  
  Future<dynamic> getZoneId(double lat, double lng) async {
    final key = 'zone_${lat}_$lng';
    final data = await _makeRequest(
      key,
      () => http.get(Uri.parse('$baseUrl/config/get-zone-id?lat=$lat&lng=$lng')),
    );
    
    // حفظ في الكاش لمدة 15 دقيقة
    await ApiCacheManager.cacheData(key, data, cacheDuration: const Duration(minutes: 15));
    return data;
  }
  
  Future<List<dynamic>> getModules() async {
    const key = 'modules';
    final data = await _makeRequest(
      key,
      () => http.get(
        Uri.parse('$baseUrl/module'),
        headers: {'Content-Type': 'application/json; charset=UTF-8', 'X-localization': 'en'},
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
    final key = 'stores_${moduleId}_${zoneId}_$featured';
    final data = await _makeRequest(
      key,
      () => http.get(
        Uri.parse('$baseUrl/stores/get-stores/all?featured=${featured ? 1 : 0}&offset=1&limit=50'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'zoneId': jsonEncode(zoneId),
          'X-localization': 'en',
          'latitude': latitude?.toString() ?? '',
          'longitude': longitude?.toString() ?? '',
        },
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
    final key = 'categories_$moduleId';
    final data = await _makeRequest(
      key,
      () => http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'X-localization': 'en',
          'moduleId': moduleId.toString(),
          'zoneId': jsonEncode(zoneId),
        },
      ),
    );
    
    // Categories - كاش لمدة 30 دقيقة
    await ApiCacheManager.cacheData(key, data, cacheDuration: const Duration(minutes: 30));
    return data as List<dynamic>;
  }
}

// استيراد kDebugMode
