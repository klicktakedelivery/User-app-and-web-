import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
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
  
  Future<void> fetchModules() async {
    // تحميل مرة واحدة فقط
    if (_modules.isNotEmpty) {
      if (kDebugMode) {
        print('✅ Modules already loaded');
      }
      return;
    }
    
    _isLoading.value = true;
    
    try {
      const cacheKey = 'modules';
      var data = await ApiCacheManager.getCachedData(cacheKey);
      
      if (data == null) {
        if (kDebugMode) {
          print('📡 Fetching modules from API...');
        }
        data = await ApiService().getModules();
        
        await ApiCacheManager.cacheData(cacheKey, data,
          cacheDuration: const Duration(hours: 1)); // Modules نادراً ما تتغير
      }
      
      _modules.value = (data as List)
          .map((json) => Module.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching modules: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }
  
  // إعادة تحميل Modules
  Future<void> refreshModules() async {
    _modules.clear();
    await fetchModules();
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