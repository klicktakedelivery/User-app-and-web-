import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../services/api_cache_manager.dart';

class ZoneController extends GetxController {
  final Rx<ZoneData?> _zoneData = Rx<ZoneData?>(null);
  final RxBool _isLoading = false.obs;
  
  ZoneData? get zoneData => _zoneData.value;
  bool get isLoading => _isLoading.value;
  
  // استدعاء API مرة واحدة فقط
  Future<void> fetchZoneData(double lat, double lng) async {
    // إذا كانت البيانات موجودة، لا تستدعي API مرة أخرى
    if (_zoneData.value != null) {
      if (kDebugMode) {
        print('✅ Zone data already loaded');
      }
      return;
    }
    
    _isLoading.value = true;
    
    try {
      final cacheKey = 'zone_${lat}_$lng';
      
      // فحص الكاش
      var data = await ApiCacheManager.getCachedData(cacheKey);
      
      if (data == null) {
        // استدعي API
        if (kDebugMode) {
          print('📡 Fetching zone data from API...');
        }
        // TODO: استبدل هذا بـ ApiService().getZoneId(lat, lng)
        // final response = await http.get(...);
        // data = jsonDecode(response.body);
        
        // حفظ في الكاش
        if (data != null) {
          await ApiCacheManager.cacheData(
            cacheKey, 
            data, 
            cacheDuration: const Duration(minutes: 15),
          );
        }
      }
      
      if (data != null) {
        _zoneData.value = ZoneData.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching zone: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }
  
  // مسح البيانات (مثلاً عند تغيير الموقع)
  void clearZoneData() {
    _zoneData.value = null;
  }
}

class ZoneData {
  final List<int> zoneId;
  final String name;
  
  ZoneData({required this.zoneId, required this.name});
  
  factory ZoneData.fromJson(Map<String, dynamic> json) {
    return ZoneData(
      zoneId: List<int>.from(json['zone_id'] ?? []),
      name: json['zone_data'] != null && 
            (json['zone_data'] as List).isNotEmpty
          ? json['zone_data'][0]['name'] ?? ''
          : '',
    );
  }
}