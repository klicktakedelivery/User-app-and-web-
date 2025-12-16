import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';

ThemeData light({Color primaryColor = const Color(0xFFD32F2F) /* أحمر جميل */}) => ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: primaryColor,
  secondaryHeaderColor: const Color(0xFFFFC107), // أصفر ذهبي للأزرار الثانوية
  disabledColor: const Color(0xFFBABFC4),
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  hintColor: const Color(0xFF9F9F9F),
  cardColor: Colors.white,
  shadowColor: Colors.black.withOpacity(0.05),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black87),
    bodyLarge: TextStyle(color: Colors.black87),
    titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFD32F2F), // نص الأزرار الأساسي بالأحمر
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black, // النص بالأسود على زر أصفر
      backgroundColor: const Color(0xFFFFC107), // الزر أصفر ذهبي
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      elevation: 3,
    ),
  ),
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: const Color(0xFFFFC107),
    surface: const Color(0xFFFCFCFC),
    error: const Color(0xFFD32F2F),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.white,
  ),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFFFFC107),
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(
  surfaceTintColor: Colors.white,
  color: Colors.white,
  height: 60,
  padding: EdgeInsets.symmetric(vertical: 5),
),
  dividerTheme: const DividerThemeData(
    thickness: 0.2,
    color: Color(0xFFA0A4A8),
  ),
  tabBarTheme: const TabBarThemeData(
    dividerColor: Colors.transparent,
    labelColor: Colors.black,
    unselectedLabelColor: Colors.black54,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2),
    ),
  ),
);
