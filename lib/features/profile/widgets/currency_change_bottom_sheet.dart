import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/services/api_cache_manager.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyChangeBottomSheet extends StatefulWidget {
  const CurrencyChangeBottomSheet({super.key});

  @override
  State<CurrencyChangeBottomSheet> createState() => _CurrencyChangeBottomSheetState();
}

class _CurrencyChangeBottomSheetState extends State<CurrencyChangeBottomSheet> {
  late final ApiClient _apiClient;
  late final SharedPreferences _sp;

  late bool _auto;
  late String _current;

  List<_CurrencyItem> _currencies = [];

  @override
  void initState() {
    super.initState();
    _apiClient = Get.find<ApiClient>();
    _sp = Get.find<SharedPreferences>();

    _auto = _apiClient.isCurrencyAuto();
    _current = (_apiClient.getCurrency()).toUpperCase();

    _currencies = _loadCurrenciesFromConfig();
    if (_currencies.isEmpty) {
      // fallback محترم لو ما عندك currency list من السيرفر
      _currencies = const [
        _CurrencyItem(code: 'USD', label: 'USD'),
        _CurrencyItem(code: 'EUR', label: 'EUR'),
        _CurrencyItem(code: 'DKK', label: 'DKK'),
        _CurrencyItem(code: 'SEK', label: 'SEK'),
        _CurrencyItem(code: 'NOK', label: 'NOK'),
        _CurrencyItem(code: 'GBP', label: 'GBP'),
      ];
    }
  }

  List<_CurrencyItem> _loadCurrenciesFromConfig() {
    try {
      final config = Get.find<SplashController>().configModel;
      if (config == null) return [];

      // نحاول نقرأ بأكثر من اسم شائع بدون ما نكسر
      final dynamic listAny = (config as dynamic).currencyList ??
          (config as dynamic).currencies ??
          (config as dynamic).currency_data ??
          (config as dynamic).currencyData;

      if (listAny is! List) return [];

      final List<_CurrencyItem> out = [];
      for (final item in listAny) {
        final code = _readCurrencyCode(item);
        if (code == null || code.trim().isEmpty) continue;

        final symbol = _readCurrencySymbol(item);
        final label = symbol != null && symbol.trim().isNotEmpty ? '$code  ($symbol)' : code;

        out.add(_CurrencyItem(code: code.toUpperCase(), label: label));
      }

      // إزالة تكرار + ترتيب بسيط
      final seen = <String>{};
      final unique = <_CurrencyItem>[];
      for (final c in out) {
        if (seen.add(c.code)) unique.add(c);
      }
      unique.sort((a, b) => a.code.compareTo(b.code));
      return unique;
    } catch (_) {
      return [];
    }
  }

  String? _readCurrencyCode(dynamic item) {
    try {
      if (item is Map) {
        return (item['currency_code'] ?? item['code'] ?? item['currencyCode'])?.toString();
      }
      // object style
      final dynamic c = (item as dynamic).currencyCode ?? (item as dynamic).code ?? (item as dynamic).currency_code;
      return c?.toString();
    } catch (_) {
      return null;
    }
  }

  String? _readCurrencySymbol(dynamic item) {
    try {
      if (item is Map) {
        return (item['symbol'] ?? item['currency_symbol'] ?? item['currencySymbol'])?.toString();
      }
      final dynamic s = (item as dynamic).symbol ?? (item as dynamic).currencySymbol ?? (item as dynamic).currency_symbol;
      return s?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _setManual(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;

    await _apiClient.setManualCurrency(normalized, refreshHeader: true);

    // مهم: لأن بعض البيانات قد تكون متخزنة بعملة مختلفة
    await ApiCacheManager.clearAllCache();

    setState(() {
      _auto = false;
      _current = normalized;
    });

    Get.back();
    Get.snackbar('Done', 'Currency set to $normalized', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _enableAuto() async {
    // 1) فعّل auto
    await _apiClient.enableAutoCurrency(refreshHeader: false);

    // 2) احذف العملة المطبقة حتى _resolveCurrencyCode يقرأ من zone_data fallback فوراً
    // (وبالتالي ترجع لعملة الموقع بدون انتظار API جديد)
    try {
      await _sp.remove(AppConstants.currencyCode);
    } catch (_) {}

    // 3) رجّع الهيدر يتكوّن من جديد
    _apiClient.refreshHeaderNow();

    // 4) امسح الكاش حتى لا ترى بيانات قديمة
    await ApiCacheManager.clearAllCache();

    setState(() {
      _auto = true;
      _current = _apiClient.getCurrency().toUpperCase();
    });

    Get.back();
    Get.snackbar('Done', 'Auto currency enabled', snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          Row(
            children: [
              const Icon(Icons.currency_exchange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Currency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _current,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),

          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _auto,
            onChanged: (v) async {
              if (v) {
                await _enableAuto();
              } else {
                // فقط نعرض القائمة داخل البوتوم شيت
                setState(() => _auto = false);
              }
            },
            title: const Text('Auto (based on location)'),
            subtitle: Text(_auto ? 'Using zone currency' : 'Manual selection'),
          ),

          const SizedBox(height: 8),

          if (!_auto) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose a currency',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _currencies.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = _currencies[i];
                  final isSelected = c.code == _current;

                  return ListTile(
                    dense: true,
                    title: Text(c.label),
                    trailing: isSelected ? const Icon(Icons.check_circle) : null,
                    onTap: () => _setManual(c.code),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrencyItem {
  final String code;
  final String label;
  const _CurrencyItem({required this.code, required this.label});
}
