// ===============================================
// حل مشكلة Shared Preferences Null Error
// ===============================================

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static SharedPreferences? _prefs;
  
  // تهيئة Shared Preferences مرة واحدة فقط
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  // الحصول على القيمة بأمان
  static String? getString(String key) {
    try {
      return _prefs?.getString(key);
    } catch (e) {
      print('Error getting $key: $e');
      return null;
    }
  }
  
  // حفظ القيمة بأمان
  static Future<bool> setString(String key, String value) async {
    try {
      await init(); // تأكد من التهيئة
      return await _prefs!.setString(key, value);
    } catch (e) {
      print('Error setting $key: $e');
      return false;
    }
  }
  
  // مثال: الحصول على Address بأمان
  static String? getAddress() {
    return getString('address') ?? 'No address set';
  }
  
  // مثال: حفظ Address
  static Future<bool> saveAddress(String address) async {
    return await setString('address', address);
  }
}

// ===============================================
// الاستخدام في main.dart:
// ===============================================
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Shared Preferences قبل تشغيل التطبيق
  await PreferencesHelper.init();
  
  runApp(MyApp());
}
*/