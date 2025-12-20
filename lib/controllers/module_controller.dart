import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/util/app_constants.dart';

import '../services/api_cache_manager.dart';
import '../services/api_service.dart';

class ModuleController extends GetxController {
  final RxList<Module> _modules = <Module>[].obs;
  final RxBool _isLoading = false.obs;

  List<Module> get modules => _modules;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // تحميل Modules عند بدء التطبيق
    fetchModules();
  }

  String _currentLangCode() {
    try {
      if (Get.isRegistered<SharedPreferences>()) {
        final sp = Get.find<SharedPreferences>();
        return (sp.getString(AppConstants.languageCode) ?? 'en').trim();
      }
    } catch (_) {}
    return 'en';
  }

  String _modulesCacheKey() => 'modules_${_currentLangCode()}';

  Future<void> fetchModules({bool forceRefresh = false}) async {
    // منع طلبات متزامنة
    if (_isLoading.value) return;

    // تحميل مرة واحدة فقط (إلا إذا طلبنا refresh صريح)
    if (!forceRefresh && _modules.isNotEmpty) {
      if (kDebugMode) {
        print('✅ Modules already loaded (memory)');
      }
      return;
    }

    _isLoading.value = true;

    try {
      final cacheKey = _modulesCacheKey();

      dynamic data;
      if (!forceRefresh) {
        data = await ApiCacheManager.getCachedData(cacheKey);
      }

      if (data == null) {
        if (kDebugMode) {
          print('📡 Fetching modules from API... (lang=${_currentLangCode()})');
        }
        data = await ApiService().getModules();

        // Modules نادراً ما تتغير - كاش لمدة ساعة
        await ApiCacheManager.cacheData(
          cacheKey,
          data,
          cacheDuration: const Duration(hours: 1),
        );
      } else {
        if (kDebugMode) {
          print('🧠 Loaded modules from cache (key=$cacheKey)');
        }
      }

      _modules.value = (data as List).map((json) => Module.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching modules: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// إعادة تحميل Modules (تحديث فعلي، وليس فقط من الكاش)
  Future<void> refreshModules() async {
    _modules.clear();
    await fetchModules(forceRefresh: true);
  }
}

class Module {
  final int id;
  final String name;
  final String moduleType;
  final String icon;
  final String thumbnail;

  Module({
    required this.id,
    required this.name,
    required this.moduleType,
    required this.icon,
    required this.thumbnail,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      name: json['module_name'] ?? '',
      moduleType: json['module_type'] ?? '',
      icon: json['icon_full_url'] ?? '',
      thumbnail: json['thumbnail_full_url'] ?? '',
    );
  }
}
