import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

class AddressHelper {

  /// حفظ العنوان محليًا وتحديث الهيدر
  static Future<bool> saveUserAddressInSharedPref(AddressModel address) async {
    final SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    final String userAddress = jsonEncode(address.toJson());

    // تحديث ترويسة الطلبات بالمعطيات المتوفرة
    Get.find<ApiClient>().updateHeader(
      sharedPreferences.getString(AppConstants.token),
      address.zoneIds, // ممكن تكون null، الـ ApiClient يجب أن يتعامل معها
      [],
      sharedPreferences.getString(AppConstants.languageCode),
      Get.find<SplashController>().module?.id,
      address.latitude,
      address.longitude,
    );

    return sharedPreferences.setString(AppConstants.userAddress, userAddress);
  }

  /// قراءة العنوان بشكل آمن
  /// ترجع null إذا ما في عنوان محفوظ أو إذا حدث خطأ بالتحويل
  static AddressModel? getUserAddressFromSharedPref() {
    try {
      final SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
      final String? raw = sharedPreferences.getString(AppConstants.userAddress);

      if (raw == null || raw.isEmpty) {
        return null;
      }

      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      final AddressModel address = AddressModel.fromJson(map);

      // ممكن تركّب فلتر إضافي إن حبيت (مثلاً لو zoneIds مفقودة)
      // if (address.zoneIds == null) return null;

      return address;
    } catch (e) {
      if (!GetPlatform.isWeb) {
        debugPrint('AddressHelper.getUserAddressFromSharedPref error: $e');
      }
      return null; // الأهم: لا نرمي استثناء
    }
  }

  /// حذف العنوان المحفوظ
  static bool clearAddressFromSharedPref() {
    final SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    sharedPreferences.remove(AppConstants.userAddress);
    return true;
  }
}
