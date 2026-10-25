import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';

final _cache = <AppPalette, ThemeData>{};

/// The theme for [p], built once and reused. Building one is costly
/// (`ColorScheme.fromSeed` computes whole tonal palettes), and the app root
/// asks for its themes on every settings change, which made switching themes
/// stutter.
ThemeData themeFor(AppPalette p) => _cache.putIfAbsent(p, () => _build(p));

ThemeData _build(AppPalette p) {
  final brightness = p.brightness;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: brightness,
      ).copyWith(
        primary: p.primary,
        onPrimary: p.onPrimary,
        surface: p.surface,
        onSurface: p.ink,
        error: p.warn,
      );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: p.border, width: 1.5),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: AppText.family,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    extensions: [p],
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.primary,
      selectionHandleColor: p.primary,
      selectionColor: p.primary.withValues(alpha: 0.3),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      hintStyle: AppText.body.copyWith(color: p.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: p.primary, width: 2),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: p.warn, width: 1.2),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: p.warn, width: 1.6),
      ),
      errorStyle: AppText.sub.copyWith(color: p.warn),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: AppText.body.copyWith(color: p.background),
      actionTextColor: p.highlight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.faint,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppText.section.copyWith(color: p.ink),
      contentTextStyle: AppText.body.copyWith(color: p.muted),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onPrimary : p.faint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.primary : p.track,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
  );
}
