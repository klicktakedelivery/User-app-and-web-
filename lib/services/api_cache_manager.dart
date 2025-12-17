// ===============================================
// نظام Caching ذكي لتقليل استدعاءات API
// ===============================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiCacheManager {
  static final Map<String, CachedData> _memoryCache = {};
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  // حفظ البيانات في الكاش
  static Future<void> cacheData(
    String key,
    dynamic data, {
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    final cachedData = CachedData(
      data: data,
      cachedAt: DateTime.now(),
      duration: cacheDuration,
    );
    
    // حفظ في الذاكرة (سريع)
    _memoryCache[key] = cachedData;
    
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
      print('Error caching data: $e');
    }
  }
  
  // جلب البيانات من الكاش
  static Future<dynamic> getCachedData(String key) async {
    // فحص الذاكرة أولاً (أسرع)
    if (_memoryCache.containsKey(key)) {
      final cached = _memoryCache[key]!;
      if (!cached.isExpired) {
        print('✅ Cache HIT (Memory): $key');
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
          print('✅ Cache HIT (Storage): $key');
          _memoryCache[key] = cached; // حفظ في الذاكرة للمرات القادمة
          return cached.data;
        } else {
          await _prefs?.remove('cache_$key');
        }
      }
    } catch (e) {
      print('Error reading cache: $e');
    }
    
    print('❌ Cache MISS: $key');
    return null;
  }
  
  // مسح كاش معين
  static Future<void> clearCache(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove('cache_$key');
  }
  
  // مسح كل الكاش
  static Future<void> clearAllCache() async {
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

// ===============================================
// مثال على الاستخدام في API Service:
// ===============================================
/*
class ApiService {
  Future<dynamic> getZoneId(double lat, double lng) async {
    final cacheKey = 'zone_${lat}_$lng';
    
    // فحص الكاش أولاً
    final cachedData = await ApiCacheManager.getCachedData(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }
    
    // إذا لم يوجد في الكاش، استدعي API
    final response = await http.get(
      Uri.parse('https://admin.klicktake.com/api/v1/config/get-zone-id?lat=$lat&lng=$lng'),
    );
    
    final data = jsonDecode(response.body);
    
    // حفظ في الكاش (صالح لمدة 10 دقائق)
    await ApiCacheManager.cacheData(
      cacheKey,
      data,
      cacheDuration: Duration(minutes: 10),
    );
    
    return data;
  }
  
  Future<dynamic> getModules() async {
    final cacheKey = 'modules';
    
    final cachedData = await ApiCacheManager.getCachedData(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }
    
    final response = await http.get(
      Uri.parse('https://admin.klicktake.com/api/v1/module'),
    );
    
    final data = jsonDecode(response.body);
    
    // Modules لا تتغير كثيراً، صالح لمدة 30 دقيقة
    await ApiCacheManager.cacheData(
      cacheKey,
      data,
      cacheDuration: Duration(minutes: 30),
    );
    
    return data;
  }
}
*/

// ===============================================
// في main.dart:
// ===============================================
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await ApiCacheManager.init();
  
  runApp(MyApp());
}
*/