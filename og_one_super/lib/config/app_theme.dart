// lib/config/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // BRAND COLORS – NearbyFundi
  // ─────────────────────────────────────────────
  static const Color primary = Color(0xFF001D45);       // Navy 700
  static const Color primaryDark = Color(0xFF001533);   // Navy 800
  static const Color primaryLight = Color(0xFF0A3670);  // Navy 600
  static const Color secondary = Color(0xFFF5C30E);     // Gold 500
  static const Color accent = Color(0xFF074B83);        // Bolt 800

  // Navy scale
  static const Color navy50 = Color(0xFFEAF1FB);
  static const Color navy100 = Color(0xFFCFE0F5);
  static const Color navy200 = Color(0xFF9FC0EB);
  static const Color navy600 = Color(0xFF0A3670);
  static const Color navy700 = Color(0xFF001D45);
  static const Color navy800 = Color(0xFF001533);
  static const Color navy900 = Color(0xFF000C1F);
  static const Color navy950 = Color(0xFF00050F);

  // Gold scale
  static const Color gold400 = Color(0xFFFFC61F);
  static const Color gold500 = Color(0xFFF5C30E);
  static const Color gold600 = Color(0xFFD9A300);

  // Bolt scale
  static const Color bolt50 = Color(0xFFF0F7FF);
  static const Color bolt100 = Color(0xFFE0EFFE);
  static const Color bolt200 = Color(0xFFBAE0FD);
  static const Color bolt800 = Color(0xFF074B83);
  static const Color bolt900 = Color(0xFF0C3F6E);

  // Neutrals
  static const Color light = Color(0xFFFFFFFF);
  static const Color greyText = Color(0xFF074B83);
  static const Color borderLight = Color(0xFF9FC0EB);
  static const Color dividerColor = Color(0xFF9FC0EB);
  static const Color scaffoldLight = Color(0xFFEAF1FB);

  // Dark mode
  static const Color darkBackground = Color(0xFF00050F);
  static const Color darkSurface = Color(0xFF000C1F);
  static const Color darkSurfaceLight = Color(0xFF001533);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9FC0EB);
  static const Color darkBorder = Color(0xFF001533);
  static const Color darkCard = Color(0xFF000C1F);

  // Status
  static const Color success = Color(0xFF0A8A6D);
  static const Color error = Color(0xFFE53935);
  static const Color warning = secondary;

  // Design tokens
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  static TextStyle _nunito({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static BoxDecoration cardDecoration({double radius = radiusLg}) {
    return BoxDecoration(
      color: light,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderLight, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.07),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration darkCardDecoration({double radius = radiusLg}) {
    return BoxDecoration(
      color: darkSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: darkBorder, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // TEXT THEME
  // ─────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    final base = GoogleFonts.nunitoTextTheme();

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        inherit: true,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: primaryText,
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        inherit: true,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryText,
        letterSpacing: -0.3,
      ),
      displaySmall: base.displaySmall?.copyWith(
        inherit: true,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        inherit: true,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        inherit: true,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleLarge: base.titleLarge?.copyWith(
        inherit: true,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleMedium: base.titleMedium?.copyWith(
        inherit: true,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleSmall: base.titleSmall?.copyWith(
        inherit: true,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        inherit: true,
        fontSize: 16,
        color: primaryText,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        inherit: true,
        fontSize: 14,
        color: secondaryText,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        inherit: true,
        fontSize: 12,
        color: secondaryText,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        inherit: true,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      labelMedium: base.labelMedium?.copyWith(
        inherit: true,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: primaryText,
      ),
      labelSmall: base.labelSmall?.copyWith(
        inherit: true,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryText,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: scaffoldLight,
    fontFamily: GoogleFonts.nunito().fontFamily,
    textTheme: _buildTextTheme(primary, greyText),

    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: navy100,
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: primary,
      secondaryContainer: Color(0xFFFFF3C4),
      onSecondaryContainer: primary,
      tertiary: accent,
      onTertiary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: primary,
      surfaceContainerHighest: navy50,
      outline: borderLight,
      outlineVariant: navy100,
    ),

    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 0.8,
      space: 1,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: _nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      iconTheme: const IconThemeData(color: primary, size: 24),
    ),

    listTileTheme: ListTileThemeData(
      textColor: primary,
      iconColor: primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: _nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      subtitleTextStyle: _nunito(
        fontSize: 13,
        color: greyText,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: borderLight.withValues(alpha: 0.5)),
      ),
      labelStyle: _nunito(color: greyText, fontSize: 14),
      hintStyle: _nunito(color: greyText.withValues(alpha: 0.7), fontSize: 14),
      errorStyle: _nunito(color: error, fontSize: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: navy200,
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: _nunito(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: _nunito(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: _nunito(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: borderLight, width: 0.8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primary,
      unselectedItemColor: greyText,
      backgroundColor: Colors.white,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: navy50,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _nunito(fontSize: 12, fontWeight: FontWeight.w600, color: primary);
        }
        return _nunito(fontSize: 12, fontWeight: FontWeight.w500, color: greyText);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 24);
        }
        return const IconThemeData(color: greyText, size: 24);
      }),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary.withValues(alpha: 0.45);
        }
        return Colors.grey.shade300;
      }),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: navy50,
      selectedColor: primary,
      disabledColor: navy100,
      labelStyle: _nunito(fontSize: 13, fontWeight: FontWeight.w500, color: primary),
      secondaryLabelStyle: _nunito(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl),
      ),
      titleTextStyle: _nunito(fontSize: 20, fontWeight: FontWeight.w700, color: primary),
      contentTextStyle: _nunito(fontSize: 15, color: greyText, height: 1.5),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: primary,
      contentTextStyle: _nunito(fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: navy100,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: primary,
      elevation: 4,
      shape: CircleBorder(),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: _nunito(fontSize: 12, color: Colors.white),
    ),
  );

  // ─────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: GoogleFonts.nunito().fontFamily,
    textTheme: _buildTextTheme(darkTextPrimary, darkTextSecondary),

    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: navy800,
      onPrimaryContainer: navy100,
      secondary: secondary,
      onSecondary: primary,
      secondaryContainer: Color(0xFF3D3200),
      onSecondaryContainer: gold400,
      tertiary: accent,
      onTertiary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: Colors.white,
      surfaceContainerHighest: darkSurfaceLight,
      outline: darkBorder,
      outlineVariant: navy800,
    ),

    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 0.6,
      space: 1,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: _nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
    ),

    listTileTheme: ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: _nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      subtitleTextStyle: _nunito(
        fontSize: 13,
        color: darkTextSecondary,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: darkBorder.withValues(alpha: 0.6)),
      ),
      labelStyle: _nunito(color: darkTextSecondary, fontSize: 14),
      hintStyle: _nunito(color: darkTextSecondary.withValues(alpha: 0.7), fontSize: 14),
      errorStyle: _nunito(color: error, fontSize: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: navy800,
        disabledForegroundColor: Colors.white54,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: _nunito(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondary,
        side: const BorderSide(color: secondary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: _nunito(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondary,
        textStyle: _nunito(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: darkBorder, width: 0.6),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: secondary,
      unselectedItemColor: darkTextSecondary,
      backgroundColor: darkSurface,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: darkSurfaceLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _nunito(fontSize: 12, fontWeight: FontWeight.w600, color: secondary);
        }
        return _nunito(fontSize: 12, fontWeight: FontWeight.w500, color: darkTextSecondary);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: secondary, size: 24);
        }
        return const IconThemeData(color: darkTextSecondary, size: 24);
      }),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return secondary;
        return Colors.grey.shade600;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return secondary.withValues(alpha: 0.45);
        }
        return Colors.grey.shade700;
      }),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceLight,
      selectedColor: secondary,
      disabledColor: navy800,
      labelStyle: _nunito(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
      secondaryLabelStyle: _nunito(fontSize: 13, fontWeight: FontWeight.w500, color: primary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl),
        side: const BorderSide(color: darkBorder, width: 0.6),
      ),
      titleTextStyle: _nunito(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      contentTextStyle: _nunito(fontSize: 15, color: darkTextSecondary, height: 1.5),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: darkSurfaceLight,
      contentTextStyle: _nunito(fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: secondary,
      linearTrackColor: darkSurfaceLight,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: primary,
      elevation: 4,
      shape: CircleBorder(),
    ),

    iconTheme: const IconThemeData(color: Colors.white),
    primaryIconTheme: const IconThemeData(color: Colors.white),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: darkSurfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: _nunito(fontSize: 12, color: Colors.white),
    ),
  );
}