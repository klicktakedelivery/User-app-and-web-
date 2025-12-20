import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/common/models/error_response.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ApiClient extends GetxService {
  final String appBaseUrl;
  final SharedPreferences sharedPreferences;
  static final String noInternetMessage = 'connection_to_api_server_failed'.tr;
  final int timeoutInSeconds = 40;

  String? token;
  late Map<String, String> _mainHeaders;

  // آخر قيم معروفة للهيدر (حتى نقدر نعمل refresh بعد تغيير العملة)
  List<int>? _lastZoneIds;
  List<int>? _lastOperationIds;
  String? _lastLanguageCode;
  int? _lastModuleId;
  String? _lastLatitude;
  String? _lastLongitude;

  ApiClient({required this.appBaseUrl, required this.sharedPreferences}) {
    token = sharedPreferences.getString(AppConstants.token);
    if (kDebugMode) {
      print('Token: $token');
    }

    // ✅ default: Auto currency ON (إذا أول مرة)
    _ensureCurrencyDefaults();

    AddressModel? addressModel;
    try {
      addressModel = AddressModel.fromJson(
        jsonDecode(sharedPreferences.getString(AppConstants.userAddress)!),
      );
    } catch (_) {}

    int? moduleID;
    if (GetPlatform.isWeb && sharedPreferences.containsKey(AppConstants.moduleId)) {
      try {
        moduleID = ModuleModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.moduleId)!)).id;
      } catch (_) {}
    }

    updateHeader(
      token,
      addressModel?.zoneIds,
      addressModel?.areaIds,
      sharedPreferences.getString(AppConstants.languageCode),
      moduleID,
      addressModel?.latitude,
      addressModel?.longitude,
    );
  }

  // ==========================================
  // Currency: Auto (Zone) + Manual Override
  // ==========================================
  void _ensureCurrencyDefaults() {
    try {
      if (!sharedPreferences.containsKey(AppConstants.currencyAuto)) {
        sharedPreferences.setBool(AppConstants.currencyAuto, true);
      }
      // لا نفرض override افتراضي
      // currency_code (applied) ممكن يكون فاضي أول مرة
    } catch (_) {}
  }

  bool isCurrencyAuto() {
    try {
      return sharedPreferences.getBool(AppConstants.currencyAuto) ?? true;
    } catch (_) {
      return true;
    }
  }

  String? getCurrencyOverride() {
    try {
      final c = sharedPreferences.getString(AppConstants.currencyOverrideCode);
      if (c != null && c.trim().isNotEmpty) return c.trim().toUpperCase();
    } catch (_) {}
    return null;
  }

  /// ✅ Source of Truth للـ Header:
  /// - إذا Manual (currency_auto=false) => override_code هو اللي يمشي
  /// - إذا Auto => currency_code (المخزنة من الزون) هي اللي تمشي
  /// - fallback أخير: حاول userAddress.zone_data.currency_code
  String _resolveCurrencyCode(List<int>? zoneIDs) {
    // 0) Manual override wins
    if (!isCurrencyAuto()) {
      final o = getCurrencyOverride();
      if (o != null && o.isNotEmpty) {
        // حافظ currency_code applied كمان
        try {
          sharedPreferences.setString(AppConstants.currencyCode, o);
        } catch (_) {}
        return o;
      }
      // إذا manual بس ما في override، ارجع للمخزنة أو USD
    }

    // 1) من SharedPrefs currency_code (المطبقة)
    try {
      final cached = sharedPreferences.getString(AppConstants.currencyCode);
      if (cached != null && cached.trim().isNotEmpty) return cached.trim().toUpperCase();
    } catch (_) {}

    // 2) fallback من userAddress.zone_data (لو موجودة)
    try {
      final addrStr = sharedPreferences.getString(AppConstants.userAddress);
      if (addrStr == null || addrStr.trim().isEmpty) return 'USD';

      final addrJson = jsonDecode(addrStr);
      final zones = addrJson is Map ? addrJson['zone_data'] : null;

      if (zones is List) {
        for (final z in zones) {
          if (z is! Map) continue;

          final zid = z['id'];
          final zoneId = zid == null ? null : int.tryParse(zid.toString());

          final match = zoneIDs == null || (zoneId != null && zoneIDs.contains(zoneId));
          if (!match) continue;

          final dynamic code = z['currency_code'] ?? z['currencyCode'];
          final cc = code?.toString().trim();
          if (cc != null && cc.isNotEmpty) {
            // ✅ خزن كعملة مطبقة فقط (Auto mode عادة)
            sharedPreferences.setString(AppConstants.currencyCode, cc.toUpperCase());
            return cc.toUpperCase();
          }
        }
      }
    } catch (_) {}

    return 'USD';
  }

  /// ✅ تضبط العملة "المطبقة" فقط (بدون تغيير auto/manual flags)
  Future<void> setCurrency(String code, {bool refreshHeader = true}) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;

    await sharedPreferences.setString(AppConstants.currencyCode, normalized);

    if (refreshHeader) {
      refreshHeaderNow();
    }
  }

  /// ✅ Manual Override: المستخدم اختار عملة بنفسه
  Future<void> setManualCurrency(String code, {bool refreshHeader = true}) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;

    await sharedPreferences.setBool(AppConstants.currencyAuto, false);
    await sharedPreferences.setString(AppConstants.currencyOverrideCode, normalized);

    // طبّقها كعملة حالية
    await sharedPreferences.setString(AppConstants.currencyCode, normalized);

    if (refreshHeader) {
      refreshHeaderNow();
    }
  }

  /// ✅ رجّع Auto (حسب الزون)
  Future<void> enableAutoCurrency({bool refreshHeader = true}) async {
    await sharedPreferences.setBool(AppConstants.currencyAuto, true);
    await sharedPreferences.remove(AppConstants.currencyOverrideCode);

    // ✅ حاسم: امسح العملة المطبقة حتى لا تبقى ماسكة من الـ manual
    // وبالتالي _resolveCurrencyCode سيأخذها من zone_data عند أول refreshHeader
    await sharedPreferences.remove(AppConstants.currencyCode);

    if (refreshHeader) {
      refreshHeaderNow();
    }
  }

  String getCurrency() => sharedPreferences.getString(AppConstants.currencyCode) ?? 'USD';

  /// alias (للتوافق لو في أماكن قديمة بتنادي refreshHeader)
  void refreshHeader() => refreshHeaderNow();

  void refreshHeaderNow() {
    updateHeader(
      token,
      _lastZoneIds,
      _lastOperationIds,
      _lastLanguageCode,
      _lastModuleId,
      _lastLatitude,
      _lastLongitude,
    );
  }

  // ==========================================
  // Headers
  // ==========================================
  Map<String, String> updateHeader(
    String? token,
    List<int>? zoneIDs,
    List<int>? operationIds,
    String? languageCode,
    int? moduleID,
    String? latitude,
    String? longitude, {
    bool setHeader = true,
  }) {
    // حفظ آخر قيم (مهم للـ refresh)
    this.token = token;
    _lastZoneIds = zoneIDs;
    _lastOperationIds = operationIds;
    _lastLanguageCode = languageCode;
    _lastModuleId = moduleID;
    _lastLatitude = latitude;
    _lastLongitude = longitude;

    final Map<String, String> header = {};

    if (moduleID != null || sharedPreferences.getString(AppConstants.cacheModuleId) != null) {
      header.addAll({
        AppConstants.moduleId:
            '${moduleID ?? ModuleModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.cacheModuleId)!)).id}'
      });
    }

    final currencyCode = _resolveCurrencyCode(zoneIDs);

    header.addAll({
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.zoneId: zoneIDs != null ? jsonEncode(zoneIDs) : '',
      // AppConstants.operationAreaId: operationIds != null ? jsonEncode(operationIds) : '',
      AppConstants.localizationKey: languageCode ?? AppConstants.languages[0].languageCode!,
      AppConstants.latitude: latitude ?? '',
      AppConstants.longitude: longitude ?? '',

      // ✅ Currency header
      AppConstants.currencyHeaderKey: currencyCode,

      'Authorization': token != null ? 'Bearer $token' : '',
    });

    if (setHeader) {
      _mainHeaders = header;
      debugPrint(
        'HEADER_DBG zoneIDs=$zoneIDs lat=$latitude lng=$longitude '
        'currency=${header[AppConstants.currencyHeaderKey]} module=${header[AppConstants.moduleId]} '
        'auto=${isCurrencyAuto()} override=${getCurrencyOverride()}',
      );
    }

    return header;
  }

  Map<String, String> getHeader() => _mainHeaders;

  // ==========================================
  // HTTP Methods
  // ==========================================
  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    try {
      if (kDebugMode) {
        log('====> API Call: $uri\nHeader: ${headers ?? _mainHeaders}');
      }
      final http.Response response = await http
          .get(
            Uri.parse(appBaseUrl + uri),
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      if (kDebugMode) {
        print('------------${e.toString()}');
      }
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
    int? timeout,
    bool handleError = true,
  }) async {
    try {
      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${headers ?? _mainHeaders}');
        print('====> API Body: $body');
      }

      final Map<dynamic, dynamic> newBody = {};
      if (body != null) {
        body.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            newBody.addAll({key: value});
          }
        });
      }

      final http.Response response = await http
          .post(
            Uri.parse(appBaseUrl + uri),
            body: jsonEncode(newBody),
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeout ?? timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postMultipartData(
    String uri,
    Map<String, String> body,
    List<MultipartBody> multipartBody, {
    List<MultipartDocument>? multipartDoc,
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    try {
      debugPrint('====> API Call: $uri\nHeader: ${headers ?? _mainHeaders}');
      debugPrint('====> API Body: $body with ${multipartBody.length} and multipart ${multipartDoc?.length}');
      final http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse(appBaseUrl + uri));
      request.headers.addAll(headers ?? _mainHeaders);

      for (final MultipartBody multipart in multipartBody) {
        if (multipart.file != null) {
          if (kIsWeb) {
            final Uint8List list = await multipart.file!.readAsBytes();
            final http.MultipartFile part = http.MultipartFile(
              multipart.key,
              multipart.file!.readAsBytes().asStream(),
              list.length,
              filename: basename(multipart.file!.path),
              contentType: MediaType('image', 'jpg'),
            );
            request.files.add(part);
          } else {
            final File file = File(multipart.file!.path);
            request.files.add(http.MultipartFile(
              multipart.key,
              file.readAsBytes().asStream(),
              file.lengthSync(),
              filename: file.path.split('/').last,
            ));
          }
        }
      }

      if (multipartDoc != null && multipartDoc.isNotEmpty) {
        for (final MultipartDocument file in multipartDoc) {
          if (kIsWeb) {
            final PlatformFile platformFile = file.file!.files.first;
            request.files.add(
              http.MultipartFile.fromBytes(
                file.key,
                platformFile.bytes!,
                filename: platformFile.name,
              ),
            );
          } else {
            final File other = File(file.file!.files.single.path!);
            final Uint8List list0 = await other.readAsBytes();
            final part = http.MultipartFile(
              file.key,
              other.readAsBytes().asStream(),
              list0.length,
              filename: basename(other.path),
            );
            request.files.add(part);
          }
        }
      }

      request.fields.addAll(body);
      final http.Response response = await http.Response.fromStream(await request.send());
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> putData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    try {
      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${headers ?? _mainHeaders}');
        print('====> API Body: $body');
      }
      final http.Response response = await http
          .put(
            Uri.parse(appBaseUrl + uri),
            body: jsonEncode(body),
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> deleteData(
    String uri, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    try {
      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${headers ?? _mainHeaders}');
      }
      final http.Response response = await http
          .delete(
            Uri.parse(appBaseUrl + uri),
            headers: headers ?? _mainHeaders,
          )
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Response handleResponse(http.Response response, String uri, bool handleError) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {}

    Response response0 = Response(
      body: body ?? response.body,
      bodyString: response.body.toString(),
      request: Request(
        headers: response.request!.headers,
        method: response.request!.method,
        url: response.request!.url,
      ),
      headers: response.headers,
      statusCode: response.statusCode,
      statusText: response.reasonPhrase,
    );

    if (response0.statusCode != 200 && response0.body != null && response0.body is! String) {
      if (response0.body.toString().startsWith('{errors: [{code:')) {
        final ErrorResponse errorResponse = ErrorResponse.fromJson(response0.body);
        response0 = Response(
          statusCode: response0.statusCode,
          body: response0.body,
          statusText: errorResponse.errors![0].message,
        );
      } else if (response0.body.toString().startsWith('{message')) {
        response0 = Response(
          statusCode: response0.statusCode,
          body: response0.body,
          statusText: response0.body['message'],
        );
      }
    } else if (response0.statusCode != 200 && response0.body == null) {
      response0 = Response(statusCode: 0, statusText: noInternetMessage);
    }

    if (kDebugMode) {
      print('====> API Response: [${response0.statusCode}] $uri');
      if (!ResponsiveHelper.isWeb() || response.statusCode != 500) {
        print('${response0.body}');
      }
    }

    if (handleError) {
      if (response0.statusCode == 200) {
        return response0;
      } else {
        ApiChecker.checkApi(response0);
        return const Response();
      }
    } else {
      return response0;
    }
  }
}

class MultipartBody {
  String key;
  XFile? file;

  MultipartBody(this.key, this.file);
}

class MultipartDocument {
  String key;
  FilePickerResult? file;

  MultipartDocument(this.key, this.file);
}
