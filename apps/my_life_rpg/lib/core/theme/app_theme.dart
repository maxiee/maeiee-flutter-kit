// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// 应用主题配置
/// 统一管理 ThemeData，确保整个应用风格一致
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // 核心色彩
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bgDarker,
      primary: AppColors.accentMain,
      secondary: AppColors.accentSystem,
      error: AppColors.accentDanger,
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
    ),

    // Scaffold
    scaffoldBackgroundColor: AppColors.bgDarker,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDarkest,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.panelHeader,
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderDim),
      ),
      margin: EdgeInsets.zero,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderDim),
      ),
      titleTextStyle: AppTextStyles.panelHeader.copyWith(
        color: AppColors.accentMain,
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDim,
      thickness: 1,
      space: 1,
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInput,
      labelStyle: AppTextStyles.caption.copyWith(color: Colors.grey),
      hintStyle: AppTextStyles.body.copyWith(color: Colors.white24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.borderBright),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.borderBright),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.accentMain),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.accentDanger),
      ),
    ),

    // Text Selection
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accentSafe,
      selectionColor: AppColors.accentMain,
      selectionHandleColor: AppColors.accentMain,
    ),

    // Icon
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),

    // IconButton
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
      ),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentMain.withOpacity(0.2),
        foregroundColor: AppColors.accentMain,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.accentMain),
        ),
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
      ),
    ),

    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        textStyle: AppTextStyles.body,
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentMain,
        side: const BorderSide(color: AppColors.accentMain),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
      ),
    ),

    // DropdownMenu
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.bgCard),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.borderDim),
          ),
        ),
      ),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgPanel,
      contentTextStyle: AppTextStyles.body,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppColors.borderDim),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ProgressIndicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accentMain,
      linearTrackColor: Colors.black,
      linearMinHeight: 2,
    ),

    // Tooltip
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderDim),
      ),
      textStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentMain;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStatePropertyAll(Colors.black),
      side: const BorderSide(color: AppColors.borderBright),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentMain;
        }
        return AppColors.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentMain.withOpacity(0.3);
        }
        return AppColors.borderDim;
      }),
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      dense: true,
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgDarkest,
      selectedItemColor: AppColors.accentMain,
      unselectedItemColor: AppColors.textSecondary,
    ),

    // Typography
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.heroNumber,
      titleMedium: AppTextStyles.panelHeader,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelSmall: AppTextStyles.micro,
    ),

    // Scrollbar
    scrollbarTheme: const ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(AppColors.borderBright),
      radius: Radius.circular(4),
      thickness: WidgetStatePropertyAll(4),
    ),
  );
}
