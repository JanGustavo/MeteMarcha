// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  // ── Base (Dark) ───────────────────────────────────────────────────
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const card = Color(0xFF222222);
  static const divider = Color(0xFF2E2E2E);

  // ── Base (Light) ──────────────────────────────────────────────────
  static const lightBackground = Color(0xFFF5F5F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightDivider = Color(0xFFE0E0E0);

  // ── Primary (vermelho) ────────────────────────────────────────────
  static const primary = Color(0xFFD32F2F);
  static const primaryLight = Color(0xFFEF5350);
  static const primaryDark = Color(0xFFB71C1C);

  // ── Text (Dark) ───────────────────────────────────────────────────
  static const onBackground = Color(0xFFEEEEEE);
  static const onSurface = Color(0xFF9E9E9E);
  static const onPrimary = Color(0xFFFFFFFF);

  // ── Text (Light) ──────────────────────────────────────────────────
  static const lightOnBackground = Color(0xFF1A1A1A);
  static const lightOnSurface = Color(0xFF757575);
  static const lightOnPrimary = Color(0xFFFFFFFF);

  // ── Semânticas ────────────────────────────────────────────────────
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA000);
  static const info = Color(0xFF42A5F5);
  static const skip = Color(0xFF616161);

  // ── Cores dos Treinos (A, B, C...) ─────────────────────────────────
  static Color getWorkoutColor(String letter) {
    switch (letter.toUpperCase()) {
      case 'A':
        return const Color(0xFFEF5350); // Coral Red
      case 'B':
        return const Color(0xFF26A69A); // Teal
      case 'C':
        return const Color(0xFF5C6BC0); // Indigo
      case 'D':
        return const Color(0xFFFFA726); // Gold / Orange
      case 'E':
        return const Color(0xFF66BB6A); // Green
      default:
        return const Color(0xFF757575); // Gray (6ª cor em diante / custom)
    }
  }
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          background: AppColors.background,
          surface: AppColors.surface,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          onBackground: AppColors.onBackground,
          onSurface: AppColors.onSurface,
          outline: AppColors.divider,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.card,
        dividerColor: AppColors.divider,

        // ── AppBar ──────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),

        // ── Buttons ─────────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.surface,
            disabledForegroundColor: AppColors.onSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            side: const BorderSide(color: AppColors.divider),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
        ),

        // ── Inputs ──────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppColors.onSurface),
          hintStyle: TextStyle(color: AppColors.onSurface.withOpacity(0.4)),
        ),

        // ── Card ────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.divider),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        ),

        // ── ListTile ────────────────────────────────────────────────
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.transparent,
          iconColor: AppColors.onSurface,
          textColor: AppColors.onBackground,
        ),

        // ── BottomNav ───────────────────────────────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurface,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),

        // ── SnackBar ────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.card,
          contentTextStyle: const TextStyle(color: AppColors.onBackground),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),

        // ── ProgressIndicator ────────────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.divider,
        ),

        // ── Segmented Button ─────────────────────────────────────────
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected))
                return AppColors.primary;
              return AppColors.surface;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected))
                return AppColors.onPrimary;
              return AppColors.onSurface;
            }),
            side: WidgetStateProperty.all(
                const BorderSide(color: AppColors.divider)),
          ),
        ),

        // ── Typography ───────────────────────────────────────────────
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: AppColors.onBackground, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(
              color: AppColors.onBackground, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(
              color: AppColors.onBackground, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(
              color: AppColors.onBackground, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
              color: AppColors.onBackground, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: AppColors.onBackground, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.onBackground),
          bodyMedium: TextStyle(color: AppColors.onSurface),
          bodySmall: TextStyle(color: AppColors.onSurface, fontSize: 12),
          labelLarge: TextStyle(
              color: AppColors.onPrimary, fontWeight: FontWeight.w700),
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          background: AppColors.lightBackground,
          surface: AppColors.lightSurface,
          primary: AppColors.primary,
          onPrimary: AppColors.lightOnPrimary,
          onBackground: AppColors.lightOnBackground,
          onSurface: AppColors.lightOnSurface,
          outline: AppColors.lightDivider,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCard,
        dividerColor: AppColors.lightDivider,

        // ── AppBar ──────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBackground,
          foregroundColor: AppColors.lightOnBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.lightOnBackground,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),

        // ── Buttons ─────────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.lightOnPrimary,
            disabledBackgroundColor: AppColors.lightSurface,
            disabledForegroundColor: AppColors.lightOnSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.lightOnBackground,
            side: const BorderSide(color: AppColors.lightDivider),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),

        // ── Inputs ──────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppColors.lightOnSurface),
          hintStyle: TextStyle(color: AppColors.lightOnSurface.withOpacity(0.5)),
        ),

        // ── Card ────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.lightDivider),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        ),

        // ── ListTile ────────────────────────────────────────────────
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.transparent,
          iconColor: AppColors.lightOnSurface,
          textColor: AppColors.lightOnBackground,
        ),

        // ── BottomNav ───────────────────────────────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightSurface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.lightOnSurface,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),

        // ── SnackBar ────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.lightSurface,
          contentTextStyle: const TextStyle(color: AppColors.lightOnBackground),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          elevation: 2,
        ),

        // ── ProgressIndicator ────────────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.lightDivider,
        ),

        // ── Segmented Button ─────────────────────────────────────────
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected))
                return AppColors.primary;
              return AppColors.lightSurface;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected))
                return AppColors.lightOnPrimary;
              return AppColors.lightOnBackground;
            }),
            side: WidgetStateProperty.all(
                const BorderSide(color: AppColors.lightDivider)),
          ),
        ),

        // ── Typography ───────────────────────────────────────────────
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: AppColors.lightOnBackground, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(
              color: AppColors.lightOnBackground, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(
              color: AppColors.lightOnBackground, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(
              color: AppColors.lightOnBackground, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
              color: AppColors.lightOnBackground, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: AppColors.lightOnBackground, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.lightOnBackground),
          bodyMedium: TextStyle(color: AppColors.lightOnSurface),
          bodySmall: TextStyle(color: AppColors.lightOnSurface, fontSize: 12),
          labelLarge: TextStyle(
              color: AppColors.lightOnPrimary, fontWeight: FontWeight.w700),
        ),
      );
}

