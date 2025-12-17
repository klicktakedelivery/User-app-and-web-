import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';

ThemeData dark({Color primaryColor = const Color(0xFF4CAF50) /*أخضر نابض بالحياة*/}) => ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: primaryColor,
  secondaryHeaderColor: const Color(0xFFFDD835), // أصفر ذهبي مشرق
  disabledColor: const Color(0xFF6B6B6B),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF121212), // خلفية سوداء ناعمة
  hintColor: const Color(0xFFB0BEC5),
  cardColor: const Color(0xFF1E1E1E), // بطاقات داكنة أنيقة
  shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.1), // ظل أخضر خفيف
  
  // نصوص واضحة وجميلة
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32, letterSpacing: -0.5),
    displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
    displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 24),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
    titleMedium: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 16),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
    labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
  ),
  
  // أزرار نصية أنيقة
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF4CAF50),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  ),
  
  // أزرار رئيسية جذابة
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: const Color(0xFF121212),
      backgroundColor: const Color(0xFF4CAF50), // أخضر نابض
      disabledForegroundColor: Colors.white38,
      disabledBackgroundColor: const Color(0xFF2C2C2C),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      elevation: 0,
      shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
    ),
  ),
  
  // أزرار محددة أنيقة
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF4CAF50),
      side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),
  
  // نظام ألوان متناسق
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF4CAF50),
    primaryContainer: const Color(0xFF2E7D32),
    secondary: const Color(0xFFFDD835),
    secondaryContainer: const Color(0xFFF9A825),
    surface: const Color(0xFF1E1E1E),
    surfaceContainerHighest: const Color(0xFF2C2C2C),
    error: const Color(0xFFEF5350),
    onPrimary: const Color(0xFF121212),
    onSecondary: const Color(0xFF121212),
    onSurface: Colors.white,
    onError: Colors.white,
    outline: const Color(0xFF4A4A4A),
  ),
  
  // شريط التطبيق العلوي
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 22,
      letterSpacing: -0.5,
    ),
    iconTheme: IconThemeData(color: Color(0xFF4CAF50), size: 24),
  ),
  
  // قوائم منبثقة أنيقة
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF2C2C2C),
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  
  // نوافذ حوار جميلة
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF2C2C2C),
    surfaceTintColor: Colors.transparent,
    elevation: 24,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
  ),
  
  // زر عائم جذاب
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF4CAF50),
    foregroundColor: const Color(0xFF121212),
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    iconSize: 28,
  ),
  
  // شريط سفلي عصري
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: Colors.transparent,
    color: Color(0xFF1E1E1E),
    elevation: 8,
    height: 70,
    padding: EdgeInsets.symmetric(vertical: 8),
    shape: CircularNotchedRectangle(),
  ),
  
  // شريط تنقل سفلي
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF1E1E1E),
    selectedItemColor: Color(0xFF4CAF50),
    unselectedItemColor: Colors.white54,
    selectedIconTheme: IconThemeData(size: 28),
    unselectedIconTheme: IconThemeData(size: 24),
    elevation: 8,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
  ),
  
  // فواصل أنيقة
  dividerTheme: const DividerThemeData(
    thickness: 1,
    color: Color(0x14FFFFFF), // Colors.white with alpha 0.08
    space: 1,
  ),
  
  // علامات تبويب جميلة
  tabBarTheme: const TabBarThemeData(
    dividerColor: Colors.transparent,
    labelColor: Color(0xFF4CAF50),
    unselectedLabelColor: Colors.white60,
    labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Color(0xFF4CAF50), width: 3),
      borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
    ),
    indicatorSize: TabBarIndicatorSize.label,
  ),
  
  // حقول الإدخال الأنيقة
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
    ),
    hintStyle: const TextStyle(color: Color(0xFF808080), fontSize: 14),
    labelStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
    prefixIconColor: const Color(0xFF4CAF50),
    suffixIconColor: const Color(0xFFB0BEC5),
  ),
  
  // بطاقات جميلة
  cardTheme: const CardThemeData(
    color: Color(0xFF1E1E1E),
    surfaceTintColor: Colors.transparent,
    elevation: 2,
    shadowColor: Colors.black38,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  
  // شريط تمرير أنيق
  sliderTheme: const SliderThemeData(
    activeTrackColor: Color(0xFF4CAF50),
    inactiveTrackColor: Color(0xFF2C2C2C),
    thumbColor: Color(0xFF4CAF50),
    overlayColor: Color(0x334CAF50), // 20% alpha
    trackHeight: 4,
  ),
  
  // مفتاح تبديل عصري
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF4CAF50);
      }
      return const Color(0xFF6B6B6B);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0x804CAF50); // 50% alpha
      }
      return const Color(0xFF3A3A3A);
    }),
  ),
  
  // مربع اختيار أنيق
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF4CAF50);
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(const Color(0xFF121212)),
    side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  ),
  
  // شريط تقدم جذاب
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF4CAF50),
    linearTrackColor: Color(0xFF2C2C2C),
    circularTrackColor: Color(0xFF2C2C2C),
  ),
  
  // رقائق أنيقة
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF2C2C2C),
    selectedColor: const Color(0xFF4CAF50),
    disabledColor: const Color(0xFF1A1A1A),
    deleteIconColor: Colors.white70,
    labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
    secondaryLabelStyle: const TextStyle(color: Color(0xFF121212), fontSize: 13),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  
  // قائمة منسدلة جميلة
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(const Color(0xFF2C2C2C)),
      elevation: WidgetStateProperty.all(8),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  ),
  
  // Snackbar عصري
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF2C2C2C),
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
    elevation: 6,
  ),
  
  // شريط بحث أنيق
  searchBarTheme: SearchBarThemeData(
    backgroundColor: WidgetStateProperty.all(const Color(0xFF2C2C2C)),
    elevation: WidgetStateProperty.all(0),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    hintStyle: WidgetStateProperty.all(
      const TextStyle(color: Color(0xFF808080), fontSize: 15),
    ),
  ),
);