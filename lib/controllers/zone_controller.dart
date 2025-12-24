import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

import '../services/api_service.dart';

class ZoneController extends GetxController {
  final Rx<ZoneData?> _zoneData = Rx<ZoneData?>(null);
  final RxBool _isLoading = false.obs;

  ZoneData? get zoneData => _zoneData.value;
  bool get isLoading => _isLoading.value;

  double? _lastLat;
  double? _lastLng;

  /// ✅ يجلب الزون حسب lat/lng (مع كاش + منع تكرار الطلب داخل ApiService)
  /// ملاحظة: إذا تغير الموقع لازم تسمح بإعادة الجلب
  Future<void> fetchZoneData(double lat, double lng, {bool forceRefresh = false}) async {
    // إذا نفس الإحداثيات والبيانات موجودة، لا تعيد الطلب
    if (!forceRefresh &&
        _zoneData.value != null &&
        _lastLat == lat &&
        _lastLng == lng) {
      if (kDebugMode) {
        print('✅ Zone data already loaded for same location');
      }
      return;
    }

    if (_isLoading.value) return;

    _isLoading.value = true;

    try {
      if (kDebugMode) {
        print('📍 Fetching zone for lat=$lat lng=$lng');
      }

      final data = await ApiService().getZoneId(lat, lng);

      if (data != null && data is Map) {
        final map = Map<String, dynamic>.from(data);


        final z = ZoneData.fromJson(map);
        _zoneData.value = z;

        _lastLat = lat;
        _lastLng = lng;

        // ✅ أهم خطوة: تحديث الهيدر بالزون + lat/lng فوراً
        await _syncApiHeaderWithZone(
          zoneIds: z.zoneId,
          lat: lat,
          lng: lng,
        );

        if (kDebugMode) {
          print('✅ Zone loaded: ids=${z.zoneId}, name=${z.name}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Zone API returned null/invalid data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching zone: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// تحديث هيدر ApiClient عند تغيير الزون
  Future<void> _syncApiHeaderWithZone({
    required List<int> zoneIds,
    required double lat,
    required double lng,
  }) async {
    try {
      if (!Get.isRegistered<ApiClient>()) return;
      if (!Get.isRegistered<SharedPreferences>()) return;

      final apiClient = Get.find<ApiClient>();
      final sp = Get.find<SharedPreferences>();

      // language من SharedPrefs (نفس اللي عندك)
      final lang = sp.getString(AppConstants.languageCode);

      // moduleId لا نمرره هنا، لأن ApiClient أصلاً يقرأ cacheModuleId لو موجود
      apiClient.updateHeader(
        apiClient.token,
        zoneIds,
        null,
        lang,
        null,
        lat.toString(),
        lng.toString(),
      );

      if (kDebugMode) {
        print('🧩 ApiClient header synced with zoneIds=$zoneIds');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to sync ApiClient header with zone: $e');
      }
    }
  }

  /// مسح البيانات (مثلاً عند تغيير الموقع)
  void clearZoneData() {
    _zoneData.value = null;
    _lastLat = null;
    _lastLng = null;
  }
}

class ZoneData {
  final List<int> zoneId;
  final String name;

  ZoneData({required this.zoneId, required this.name});

  factory ZoneData.fromJson(Map<String, dynamic> json) {
    return ZoneData(
      zoneId: List<int>.from(json['zone_id'] ?? []),
      name: json['zone_data'] != null && (json['zone_data'] as List).isNotEmpty
          ? (json['zone_data'][0]['name'] ?? '')
          : '',
    );
  }
}
