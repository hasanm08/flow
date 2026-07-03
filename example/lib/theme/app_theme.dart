import 'package:flutter/material.dart';

/// Flow design system colors.
abstract final class FlowColors {
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4F46E5);
  static const secondary = Color(0xFF06B6D4);
  static const accent = Color(0xFFF59E0B);
  static const surface = Color(0xFF0F172A);
  static const surfaceLight = Color(0xFF1E293B);
  static const card = Color(0xFF334155);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
  );
}

ThemeData buildFlowTheme({Brightness brightness = Brightness.dark}) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: FlowColors.primary,
    brightness: brightness,
    primary: FlowColors.primary,
    secondary: FlowColors.secondary,
    surface: isDark ? FlowColors.surface : const Color(0xFFF8FAFC),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? FlowColors.textPrimary : Colors.black87,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? FlowColors.surfaceLight : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: isDark ? FlowColors.surfaceLight : Colors.white,
      indicatorColor: FlowColors.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
