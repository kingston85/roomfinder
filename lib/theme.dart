import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// RoomFinder LR visual identity, taken from Monrovia itself:
/// Atlantic blue for structure, zinc-roof grey for surfaces, the yellow of
/// hand-painted "Room for rent" wall signs for prices, palm green for
/// verified places, laterite red only for warnings.
class Brand {
  static const ocean = Color(0xFF0E4D64); // primary: headers, buttons
  static const oceanDeep = Color(0xFF0A3546); // header gradient end, pressed
  static const zinc = Color(0xFFEEF2F3); // app background
  static const sign = Color(0xFFF5C02E); // price tags, featured
  static const palm = Color(0xFF2F7D4F); // verified
  static const laterite = Color(0xFFB5482E); // errors, report
  static const ink = Color(0xFF14262E); // text
  static const mist = Color(0xFF5E7177); // secondary text
  static const line = Color(0xFFD5DEE1); // borders

  static const radiusL = 20.0;
  static const radiusM = 14.0;
  static const radiusS = 10.0;
}

/// Fonts load from Google Fonts on first use and are cached; if a phone is
/// offline on first launch, the system font is used until they arrive.
TextStyle _safeFont(String family, TextStyle base) {
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    return base;
  }
}

TextStyle display(TextStyle base) => _safeFont('Bricolage Grotesque', base);

TextTheme _textTheme(TextTheme base, Color ink) {
  TextTheme body;
  try {
    body = GoogleFonts.getTextTheme('Figtree', base);
  } catch (_) {
    body = base;
  }
  body = body.apply(bodyColor: ink, displayColor: ink);
  TextStyle d(TextStyle? s, double size, FontWeight w, {double spacing = -0.3}) =>
      display((s ?? const TextStyle()).copyWith(
          fontSize: size, fontWeight: w, letterSpacing: spacing, height: 1.15, color: ink));
  return body.copyWith(
    displaySmall: d(body.displaySmall, 34, FontWeight.w700, spacing: -0.8),
    headlineLarge: d(body.headlineLarge, 30, FontWeight.w700, spacing: -0.6),
    headlineMedium: d(body.headlineMedium, 26, FontWeight.w700, spacing: -0.5),
    headlineSmall: d(body.headlineSmall, 22, FontWeight.w700),
    titleLarge: d(body.titleLarge, 20, FontWeight.w600),
    titleMedium: body.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
    bodyMedium: body.bodyMedium?.copyWith(fontSize: 14.5, height: 1.45),
    labelLarge: body.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
  );
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFE6EEF0) : Brand.ink;
  final scheme = ColorScheme.fromSeed(seedColor: Brand.ocean, brightness: brightness).copyWith(
    primary: dark ? const Color(0xFF7CC4DB) : Brand.ocean,
    onPrimary: dark ? Brand.oceanDeep : Colors.white,
    secondary: Brand.sign,
    onSecondary: Brand.ink,
    tertiary: dark ? const Color(0xFF7FC79A) : Brand.palm,
    error: dark ? const Color(0xFFF0927B) : Brand.laterite,
    surface: dark ? const Color(0xFF101C21) : Colors.white,
    onSurface: ink,
    onSurfaceVariant: dark ? const Color(0xFF9DB0B5) : Brand.mist,
    outline: dark ? const Color(0xFF3A4D53) : Brand.line,
    outlineVariant: dark ? const Color(0xFF26363B) : Brand.line,
    surfaceContainerHighest: dark ? const Color(0xFF1C2C32) : const Color(0xFFE3EAEC),
  );
  final background = dark ? const Color(0xFF0A1418) : Brand.zinc;
  final text = _textTheme(ThemeData(brightness: brightness).textTheme, ink);
  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.radiusM));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Brand.radiusL),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: rounded,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: rounded,
        foregroundColor: ink,
        side: BorderSide(color: scheme.outline),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: text.labelLarge),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Brand.radiusM),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Brand.radiusM),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Brand.radiusM),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Brand.radiusM),
        borderSide: BorderSide(color: scheme.error),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surface,
      selectedColor: scheme.primary,
      checkmarkColor: scheme.onPrimary,
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      labelStyle: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      secondaryLabelStyle: text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600, color: scheme.onPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: Brand.sign.withAlpha(110),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(
        text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.radiusL)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFFE6EEF0) : Brand.ink,
      contentTextStyle: TextStyle(color: dark ? Brand.ink : Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.radiusM)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide(color: scheme.outline),
      ),
    ),
  );
}
