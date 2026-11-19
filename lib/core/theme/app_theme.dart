import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.forest,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.forest,
          onPrimary: Colors.white,
          primaryContainer: AppColors.mint,
          onPrimaryContainer: AppColors.forestDark,
          secondary: AppColors.amber,
          onSecondary: AppColors.ink,
          secondaryContainer: AppColors.amberSoft,
          onSecondaryContainer: const Color(0xFF6B4A16),
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          error: AppColors.danger,
          onError: Colors.white,
          outline: AppColors.line,
          outlineVariant: AppColors.line,
        );

    final textTheme = TextTheme(
      displaySmall: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -0.8,
        color: AppColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        height: 1.18,
        letterSpacing: -0.5,
        color: AppColors.ink,
      ),
      headlineSmall: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: AppColors.ink,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.ink,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.ink,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: AppColors.ink,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.ink,
      ),
      bodySmall: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.muted,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.ink,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.ink,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.muted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'PlusJakartaSans',
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.forestDark,
        contentTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
    );
  }
}
