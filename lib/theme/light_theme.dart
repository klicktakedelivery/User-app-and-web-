import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';

ThemeData light({Color primaryColor = const Color(0xFF4CAF50) /*أخضر نابض بالحياة*/}) => ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: primaryColor,
  secondaryHeaderColor: const Color(0xFFFDD835), // أصفر ذهبي مشرق
  disabledColor: const Color(0xFFBDBDBD),
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFAFAFA), // خلفية فاتحة ناعمة
  hintColor: const Color(0xFF757575),
  cardColor: Colors.white,
  shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.08),
  
  // نصوص واضحة وجميلة
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.bold, fontSize: 32, letterSpacing: -0.5),
    displayMedium: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.bold, fontSize: 28),
    displaySmall: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.w600, fontSize: 24),
    headlineMedium: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.w600, fontSize: 20),
    titleLarge: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.w600, fontSize: 18),
    titleMedium: TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.w500, fontSize: 16),
    bodyLarge: TextStyle(color: Color(0xFF212121), fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(color: Color(0xFF616161), fontSize: 14, height: 1.5),
    labelLarge: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.w600, fontSize: 14),
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
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF4CAF50), // أخضر نابض
      disabledForegroundColor: Colors.white60,
      disabledBackgroundColor: const Color(0xFFE0E0E0),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      elevation: 2,
      shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.4),
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
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF4CAF50),
    primaryContainer: Color(0xFFC8E6C9),
    secondary: Color(0xFFFDD835),
    secondaryContainer: Color(0xFFFFF9C4),
    surface: Colors.white,
    surfaceContainerHighest: Color(0xFFF5F5F5),
    error: Color(0xFFEF5350),
    onPrimary: Colors.white,
    onSecondary: Color(0xFF212121),
    onSurface: Color(0xFF212121),
    onError: Colors.white,
    outline: Color(0xFFE0E0E0),
  ),
  
  // شريط التطبيق العلوي
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF212121),
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 2,
    titleTextStyle: TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.bold,
      fontSize: 22,
      letterSpacing: -0.5,
    ),
    iconTheme: IconThemeData(color: Color(0xFF4CAF50), size: 24),
  ),
  
  // قوائم منبثقة أنيقة
  popupMenuTheme: const PopupMenuThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shadowColor: Color(0x1A000000), // 10% alpha
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
  ),
  
  // نوافذ حوار جميلة
  dialogTheme: const DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 24,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
    titleTextStyle: TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
  ),
  
  // زر عائم جذاب
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF4CAF50),
    foregroundColor: Colors.white,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    iconSize: 28,
  ),
  
  // شريط سفلي عصري
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: Colors.transparent,
    color: Colors.white,
    elevation: 8,
    height: 70,
    padding: EdgeInsets.symmetric(vertical: 8),
    shape: CircularNotchedRectangle(),
  ),
  
  // شريط تنقل سفلي
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Color(0xFF4CAF50),
    unselectedItemColor: Color(0xFF757575),
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
    color: Color(0x99E0E0E0), // 60% alpha
    space: 1,
  ),
  
  // علامات تبويب جميلة
  tabBarTheme: const TabBarThemeData(
    dividerColor: Colors.transparent,
    labelColor: Color(0xFF4CAF50),
    unselectedLabelColor: Color(0xFF757575),
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
    fillColor: const Color(0xFFF5F5F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
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
    hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
    labelStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14),
    prefixIconColor: const Color(0xFF4CAF50),
    suffixIconColor: const Color(0xFF9E9E9E),
  ),
  
  // بطاقات جميلة
  cardTheme: const CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 2,
    shadowColor: Color(0x14000000), // black with 8% alpha
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  
  // شريط تمرير أنيق
  sliderTheme: const SliderThemeData(
    activeTrackColor: Color(0xFF4CAF50),
    inactiveTrackColor: Color(0xFFE0E0E0),
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
      return const Color(0xFFBDBDBD);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0x804CAF50); // 50% alpha
      }
      return const Color(0xFFE0E0E0);
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
    checkColor: WidgetStateProperty.all(Colors.white),
    side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  ),
  
  // شريط تقدم جذاب
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF4CAF50),
    linearTrackColor: Color(0xFFE0E0E0),
    circularTrackColor: Color(0xFFE0E0E0),
  ),
  
  // رقائق أنيقة
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFF5F5F5),
    selectedColor: const Color(0xFF4CAF50),
    disabledColor: const Color(0xFFEEEEEE),
    deleteIconColor: const Color(0xFF757575),
    labelStyle: const TextStyle(color: Color(0xFF212121), fontSize: 13),
    secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  
  // قائمة منسدلة جميلة
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(Colors.white),
      elevation: WidgetStateProperty.all(8),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  ),
  
  // Snackbar عصري
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF323232),
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
    elevation: 6,
  ),
  
  // شريط بحث أنيق
  searchBarTheme: SearchBarThemeData(
    backgroundColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
    elevation: WidgetStateProperty.all(0),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    hintStyle: WidgetStateProperty.all(
      const TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
    ),
  ),
  
  // قائمة تمرير جانبية
  drawerTheme: const DrawerThemeData(
    backgroundColor: Colors.white,
    elevation: 16,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
    ),
  ),
  
  // صفحة أسفلية
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    elevation: 16,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
  
  // تلميح أداة
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: const Color(0xFF616161),
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  
  // شريط أدوات
  listTileTheme: const ListTileThemeData(
    iconColor: Color(0xFF4CAF50),
    textColor: Color(0xFF212121),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    minLeadingWidth: 40,
  ),
  
  // تمديد
  expansionTileTheme: const ExpansionTileThemeData(
    iconColor: Color(0xFF4CAF50),
    textColor: Color(0xFF212121),
    collapsedIconColor: Color(0xFF757575),
    collapsedTextColor: Color(0xFF757575),
  ),
);