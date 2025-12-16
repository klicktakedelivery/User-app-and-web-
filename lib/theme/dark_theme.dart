import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';

ThemeData dark({Color primaryColor = const Color(0xFFD32F2F) /*أحمر داكن*/}) => ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: primaryColor,
  secondaryHeaderColor: const Color(0xFFFFC107), // أصفر ذهبي للأزرار الثانوية
  disabledColor: const Color(0xFF555555), // رمادي غامق للعناصر المعطلة
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black, // الخلفية سوداء بالكامل
  hintColor: const Color(0xFFCCCCCC), // نصوص المساعدة بالرمادي الفاتح
  cardColor: const Color(0xFF1C1C1E), // بطاقات بلون أسود داكن جميل
  shadowColor: Colors.white.withOpacity(0.03),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
    bodyLarge: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFFFC107), // الأزرار باللون الأصفر الذهبي
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black, // لون النص في الأزرار
      backgroundColor: const Color(0xFFFFC107), // لون زر أصفر ذهبي
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      elevation: 4,
    ),
  ),
  colorScheme: ColorScheme.dark(
    primary: primaryColor,
    secondary: const Color(0xFFFFC107),
    surface: const Color(0xFF121212),
    error: const Color(0xFFD32F2F),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Color(0xFF29292D),
    surfaceTintColor: Color(0xFF29292D),
  ),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white10),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFFFFC107),
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(
  surfaceTintColor: Colors.black,
  color: Colors.black,
  height: 60,
  padding: EdgeInsets.symmetric(vertical: 5),
),
  dividerTheme: const DividerThemeData(
    thickness: 0.5,
    color: Color(0xFFA0A4A8),
  ),
  tabBarTheme: const TabBarThemeData(
    dividerColor: Colors.transparent,
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white54,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Color(0xFFFFC107), width: 2),
    ),
  ),
);
