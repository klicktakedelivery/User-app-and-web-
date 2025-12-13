import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:get/get.dart';

class ApiChecker {
  static void checkApi(Response response, {bool getXSnackBar = false}) {

    // Debug log عشان نعرف مصدر الخطأ بالتفصيل
    debugPrint(
      '🔴 API CHECK => '
      'CODE: ${response.statusCode}, '
      'TEXT: ${response.statusText}, '
      'URL: ${response.request?.url}, '
      'BODY: ${response.bodyString}',
    );

    if (response.statusCode == 401) {
      Get.find<AuthController>().clearSharedData(removeToken: false).then((value) {
        Get.find<FavouriteController>().removeFavourite();
        Get.offAllNamed(RouteHelper.getInitialRoute());
      });
    } else {
      // لا تعرض السناك بار إلا لو في خطأ حقيقي
      if (response.statusCode != null && response.statusCode! >= 400) {
        if (response.statusText != 'The guest id field is required.' &&
            (response.statusText ?? '').isNotEmpty) {
          showCustomSnackBar(response.statusText, getXSnackBar: getXSnackBar);
        } else {
          showCustomSnackBar('حدث خطأ غير متوقع، حاول لاحقًا', getXSnackBar: getXSnackBar);
        }
      }
    }
  }
}
