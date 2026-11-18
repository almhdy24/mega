import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

class MegaTheme {
  MegaTheme._();

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: MegaColors.primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD4EEDF),
      onPrimaryContainer: MegaColors.primaryDark,
      secondary: MegaColors.accent,
      onSecondary: MegaColors.primaryDark,
      error: MegaColors.danger,
      onError: Colors.white,
      surface: MegaColors.surfaceLight,
      onSurface: MegaColors.textLight,
      outline: MegaColors.outlineLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MegaColors.backgroundLight,
      fontFamilyFallback: const ['sans-serif'],
      appBarTheme: const AppBarTheme(
        backgroundColor: MegaColors.backgroundLight,
        foregroundColor: MegaColors.textLight,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: MegaColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MegaColors.outlineLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MegaColors.surfaceLight,
        elevation: 2,
        indicatorColor: MegaColors.primaryContainerLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MegaColors.primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MegaColors.textMutedLight,
          );
        }),
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: MegaColors.primaryLight,
      onPrimary: Colors.black,
      primaryContainer: MegaColors.surfaceDarkElevated,
      onPrimaryContainer: MegaColors.textDark,
      secondary: MegaColors.accent,
      onSecondary: Colors.black,
      error: MegaColors.danger,
      onError: Colors.white,
      surface: MegaColors.surfaceDark,
      onSurface: MegaColors.textDark,
      outline: MegaColors.outlineDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MegaColors.backgroundDark,
      fontFamilyFallback: const ['sans-serif'],
      appBarTheme: const AppBarTheme(
        backgroundColor: MegaColors.backgroundDark,
        foregroundColor: MegaColors.textDark,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: MegaColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MegaColors.outlineDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MegaColors.surfaceDark,
        elevation: 2,
        indicatorColor: MegaColors.surfaceDarkElevated,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MegaColors.primaryLight,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MegaColors.textMutedDark,
          );
        }),
      ),
    );
  }

  static const Color primaryContainerLight = Color(0xFFD8EFE4);
}
