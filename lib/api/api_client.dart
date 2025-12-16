import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/common/models/error_response.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient extends GetxService {
  final String appBaseUrl;
  final SharedPreferences sharedPreferences;
  static final String noInternetMessage = 'connection_to_api_server_failed'.tr;
  final int timeoutInSeconds = 40;

  String? token;
  late Map<String, String> _mainHeaders;

  ApiClient({required this.appBaseUrl, required this.sharedPreferences}) {
    token = sharedPreferences.getString(AppConstants.token);

    if (kDebugMode) {
      final masked = token == null || token!.trim().isEmpty ? 'null' : '***';
      print('Token: $masked');
    }

    AddressModel? addressModel;
    try {
      final addrStr = sharedPreferences.getString(AppConstants.userAddress);
      if (addrStr != null && addrStr.isNotEmpty) {
        addressModel = AddressModel.fromJson(jsonDecode(addrStr));
      }
    } catch (_) {}

    int? moduleID;
    try {
      final cached = sharedPreferences.getString(AppConstants.cacheModuleId);
      if (cached != null && cached.isNotEmpty) {
        moduleID = ModuleModel.fromJson(jsonDecode(cached)).id;
      }
    } catch (_) {}

    updateHeader(
      token,
      addressModel?.zoneIds,
      addressModel?.areaIds, // غير مستخدم حاليًا
      sharedPreferences.getString(AppConstants.languageCode),
      moduleID,
      addressModel?.latitude,
      addressModel?.longitude,
    );
  }

  //==================== Helpers (mask/sanitize) ====================//

  String _maskBearer(String? v) {
    if (v == null) return '';
    return v.replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer ***');
  }

  Map<String, String> _maskHeaders(Map<String, String> headers) {
    final m = Map<String, String>.from(headers);
    if (m.containsKey('Authorization')) {
      m['Authorization'] = _maskBearer(m['Authorization']);
    }
    return m;
  }

  Map<String, dynamic> _maskBody(Map<String, dynamic> body) {
    final m = Map<String, dynamic>.from(body);
    for (final k in ['token', 'auth_token', 'password', 'new_password', 'otp']) {
      if (m.containsKey(k)) m[k] = '***';
    }
    return m;
  }

  Map<String, String> _sanitizeHeaders(
    Map<String, String>? headers, {
    String? bearerToken,
  }) {
    final out = <String, String>{};
    (headers ?? {}).forEach((key, val) {
      final k = key.trim();
      if (k.isEmpty) return;
      final v = val.trim();
      if (v.isEmpty) return;
      out[k] = v;
    });
    if (bearerToken != null && bearerToken.trim().isNotEmpty && bearerToken != 'null') {
      out['Authorization'] = 'Bearer ${bearerToken.trim()}';
    } else {
      out.remove('Authorization');
    }
    return out;
  }

  Uri _buildUri(String path, {Map<String, dynamic>? query}) {
    final base = appBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    Uri uri = Uri.parse('$base$p');

    if (query != null && query.isNotEmpty) {
      final qp = <String, String>{};
      query.forEach((k, v) {
        final key = k.toString().trim();
        if (key.isEmpty) return;
        if (v == null || v.toString().isEmpty) return;
        qp[key] = v.toString();
      });
      uri = uri.replace(queryParameters: qp);
    }

    return uri;
  }

  //==================== Header builder ====================//

  Map<String, String> updateHeader(
    String? token,
    List<int>? zoneIDs,
    List<int>? operationIds, // (محجوز - غير مستخدم حالياً)
    String? languageCode,
    int? moduleID,
    String? latitude,
    String? longitude, {
    bool setHeader = true,
  }) {
    final header = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.localizationKey:
          languageCode ?? AppConstants.languages[0].languageCode!,
    };

    if (moduleID != null) {
      header[AppConstants.moduleId] = '$moduleID';
    } else {
      final cached = sharedPreferences.getString(AppConstants.cacheModuleId);
      if (cached != null && cached.isNotEmpty) {
        try {
          header[AppConstants.moduleId] =
              '${ModuleModel.fromJson(jsonDecode(cached)).id}';
        } catch (_) {}
      }
    }

    if (zoneIDs != null && zoneIDs.isNotEmpty) {
      header[AppConstants.zoneId] = jsonEncode(zoneIDs);
    }

    // lat/lng كسلاسل بدون jsonEncode
    if (latitude != null && latitude.trim().isNotEmpty) {
      header[AppConstants.latitude] = latitude.trim();
    }
    if (longitude != null && longitude.trim().isNotEmpty) {
      header[AppConstants.longitude] = longitude.trim();
    }

    final sanitized = _sanitizeHeaders(header, bearerToken: token);
    if (setHeader) {
      _mainHeaders = sanitized;
    }
    return sanitized;
  }

  Map<String, String> getHeader() => _mainHeaders;

  /// حدّث التوكِن أثناء التشغيل (مثلاً بعد تسجيل الدخول/الخروج)
  void setAuthToken(String? newToken) {
    token = newToken;
    _mainHeaders = _sanitizeHeaders(_mainHeaders, bearerToken: token);
  }

  /// حدّث الموقع/الزون/الموديول واللغة أثناء التشغيل
  void setGeoAndZone({
    String? latitude,
    String? longitude,
    List<int>? zoneIDs,
    int? moduleId,
    String? languageCode,
  }) {
    updateHeader(
      token,
      zoneIDs,
      null,
      languageCode ?? _mainHeaders[AppConstants.localizationKey],
      moduleId,
      latitude ?? _mainHeaders[AppConstants.latitude],
      longitude ?? _mainHeaders[AppConstants.longitude],
    );
  }

  //==================== JSON HTTP ====================//

  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    final hdrs = _sanitizeHeaders(headers ?? _mainHeaders, bearerToken: token);
    final fullUri = _buildUri(uri, query: query);
    try {
      if (kDebugMode) {
        print('====> API Call: $fullUri\nHeader: ${_maskHeaders(hdrs)}');
      }
      final response = await http
          .get(fullUri, headers: hdrs)
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      if (kDebugMode) print('------------${e.toString()}');
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postData(
    String uri,
    Map<String, dynamic>? body, {
    Map<String, String>? headers,
    int? timeout,
    bool handleError = true,
  }) async {
    final hdrs = _sanitizeHeaders(headers ?? _mainHeaders, bearerToken: token);
    try {
      final newBody = <String, dynamic>{};
      (body ?? {}).forEach((key, value) {
        final k = key.toString();
        if (k.isEmpty) return;
        if (value == null || value.toString().isEmpty) return;
        newBody[k] = value;
      });

      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${_maskHeaders(hdrs)}');
        print('====> API Body: ${_maskBody(newBody)}');
      }

      final response = await http
          .post(
            _buildUri(uri),
            body: jsonEncode(newBody),
            headers: hdrs,
          )
          .timeout(Duration(seconds: timeout ?? timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> putData(
    String uri,
    Map<String, dynamic>? body, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    final hdrs = _sanitizeHeaders(headers ?? _mainHeaders, bearerToken: token);
    try {
      final safeBody = <String, dynamic>{};
      (body ?? {}).forEach((key, value) {
        final k = key.toString();
        if (k.isEmpty) return;
        if (value == null || value.toString().isEmpty) return;
        safeBody[k] = value;
      });

      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${_maskHeaders(hdrs)}');
        print('====> API Body: ${_maskBody(safeBody)}');
      }

      final response = await http
          .put(_buildUri(uri), body: jsonEncode(safeBody), headers: hdrs)
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
    final hdrs = _sanitizeHeaders(headers ?? _mainHeaders, bearerToken: token);
    try {
      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${_maskHeaders(hdrs)}');
      }
      final response = await http
          .delete(_buildUri(uri), headers: hdrs)
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  //==================== x-www-form-urlencoded ====================//

  Future<Response> postForm(
    String uri,
    Map<String, dynamic>? body, {
    Map<String, String>? headers,
    int? timeout,
    bool handleError = true,
  }) async {
    final base = _sanitizeHeaders(headers ?? _mainHeaders, bearerToken: token);
    final hdrs = <String, String>{
      ...base,
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    };

    final form = <String, String>{};
    (body ?? {}).forEach((key, value) {
      final k = key.toString();
      if (k.isEmpty) return;
      if (value == null || value.toString().isEmpty) return;
      form[k] = value.toString();
    });

    if (kDebugMode) {
      print('====> API Call (FORM POST): $uri\nHeader: ${_maskHeaders(hdrs)}');
      print('====> API Body (FORM): ${_maskBody(Map<String, dynamic>.from(form))}');
    }

    try {
      final response = await http
          .post(_buildUri(uri), headers: hdrs, body: form)
          .timeout(Duration(seconds: timeout ?? timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> putForm(
    String uri,
    Map<String, dynamic>? body, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    final base = _sanitizeHeaders(headers ?? _mainHeaders, bearerToken: token);
    final hdrs = <String, String>{
      ...base,
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    };

    final form = <String, String>{};
    (body ?? {}).forEach((key, value) {
      final k = key.toString();
      if (k.isEmpty) return;
      if (value == null || value.toString().isEmpty) return;
      form[k] = value.toString();
    });

    if (kDebugMode) {
      print('====> API Call (FORM PUT): $uri\nHeader: ${_maskHeaders(hdrs)}');
      print('====> API Body (FORM PUT): ${_maskBody(Map<String, dynamic>.from(form))}');
    }

    try {
      final response = await http
          .put(_buildUri(uri), headers: hdrs, body: form)
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  //==================== Multipart ====================//

  Future<Response> postMultipartData(
    String uri,
    Map<String, String> body,
    List<MultipartBody> multipartBody, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    final hdrs = _sanitizeHeaders(headers ?? _mainHeaders, bearerToken: token);
    try {
      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${_maskHeaders(hdrs)}');
        print('====> API Body: ${_maskBody(Map<String, dynamic>.from(body))} with ${multipartBody.length} file(s)');
      }

      final request = http.MultipartRequest('POST', _buildUri(uri));
      request.headers.addAll(hdrs);

      for (final multipart in multipartBody) {
        if (multipart.file != null) {
          final bytes = await multipart.file!.readAsBytes();
          final filename = (multipart.file!.name.isNotEmpty
                  ? multipart.file!.name
                  : '${DateTime.now().toIso8601String()}.bin')
              .replaceAll('/', '_');
          request.files.add(http.MultipartFile.fromBytes(
            multipart.key,
            bytes,
            filename: filename,
          ));
        }
      }

      final newBody = <String, String>{};
      body.forEach((k, v) {
        final key = k.trim();
        final val = v.trim();
        if (key.isEmpty || val.isEmpty) return;
        newBody[key] = val;
      });
      request.fields.addAll(newBody);

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  //==================== Response handling ====================//

  Response handleResponse(http.Response response, String uri, bool handleError) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {}

    Response r = Response(
      body: decoded ?? response.body, // response.body ليس null في Dart
      bodyString: response.body.toString(),
      request: Request(
        headers: response.request?.headers ?? {},
        method: response.request?.method ?? 'GET',
        url: response.request?.url ?? _buildUri(uri),
      ),
      headers: response.headers,
      statusCode: response.statusCode,
      statusText: response.reasonPhrase,
    );

    // لا نستخدم r.body == null لتفادي تحذير unnecessary_null_comparison
    if (r.statusCode != 200 && decoded is Map) {
      try {
        final txt = decoded.toString();
        if (txt.startsWith('{errors: [{code:')) {
          final er = ErrorResponse.fromJson(decoded);
          r = Response(
            statusCode: r.statusCode,
            body: decoded,
            statusText: er.errors![0].message,
          );
        } else if (decoded.containsKey('message')) {
  r = Response(
    statusCode: r.statusCode,
    body: decoded,
    statusText: decoded['message'],
  );
}

      } catch (_) {}
    } else if (r.statusCode != 200 && decoded == null) {
      // غالباً خطأ شبكة أو رد غير JSON
      r = Response(statusCode: 0, statusText: noInternetMessage);
    }

    if (kDebugMode) {
      print('====> API Response: [${r.statusCode}] $uri');
      if (!ResponsiveHelper.isWeb() || response.statusCode != 500) {
        print('${r.body}');
      }
    }

    if (!handleError) return r;
    if (r.statusCode == 200) return r;

    ApiChecker.checkApi(r);
    return const Response();
  }
}

class MultipartBody {
  String key;
  XFile? file;
  MultipartBody(this.key, this.file);
}
