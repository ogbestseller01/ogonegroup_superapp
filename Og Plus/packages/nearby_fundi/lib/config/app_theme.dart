import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ================================================================
  // PRIMARY COLORS – NearbyFundi Navy
  // ================================================================

  /// Navy 700 – mandatory brand
  static const Color primary = Color(0xFF001D45);
  static const Color primaryDark = Color(0xFF001533);
  static const Color primaryLight = Color(0xFF0A3670);

  /// Gold 500
  static const Color secondary = Color(0xFFF5C30E);

  /// Bolt 800
  static const Color accent = Color(0xFF074B83);

  // ================================================================
  // NAVY SCALE
  // ================================================================

  static const Color navy50 = Color(0xFFEAF1FB);
  static const Color navy100 = Color(0xFFCFE0F5);
  static const Color navy200 = Color(0xFF9FC0EB);
  static const Color navy600 = Color(0xFF0A3670);
  static const Color navy700 = Color(0xFF001D45);
  static const Color navy800 = Color(0xFF001533);
  static const Color navy900 = Color(0xFF000C1F);
  static const Color navy950 = Color(0xFF00050F);

  // ================================================================
  // GOLD SCALE
  // ================================================================

  static const Color gold400 = Color(0xFFFFC61F);
  static const Color gold500 = Color(0xFFF5C30E);
  static const Color gold600 = Color(0xFFD9A300);

  // ================================================================
  // BOLT SCALE
  // ================================================================

  static const Color bolt50 = Color(0xFFF0F7FF);
  static const Color bolt100 = Color(0xFFE0EFFE);
  static const Color bolt200 = Color(0xFFBAE0FD);
  static const Color bolt800 = Color(0xFF074B83);
  static const Color bolt900 = Color(0xFF0C3F6E);

  // ================================================================
  // NEUTRALS
  // ================================================================

  static const Color light = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF000C1F);
  static const Color greyText = Color(0xFF074B83);
  static const Color borderLight = Color(0xFF9FC0EB);
  static const Color dividerColor = Color(0xFF9FC0EB);
  static const Color scaffoldLight = Color(0xFFEAF1FB);
  static const Color scaffoldDark = Color(0xFF00050F);

  // ================================================================
  // DARK MODE
  // ================================================================

  static const Color darkBackground = Color(0xFF00050F);
  static const Color darkSurface = Color(0xFF000C1F);
  static const Color darkSurfaceLight = Color(0xFF001533);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// Kept for compatibility. Text in dark mode is now white everywhere.
  static const Color darkTextSecondary = Color(0xFFFFFFFF);
  static const Color darkBorder = Color(0xFF001533);
  static const Color darkCard = Color(0xFF000C1F);

  /// Soft white used for hints and placeholders in dark mode.
  static const Color darkHint = Color(0xB3FFFFFF); // white 70%

  // ================================================================
  // STATUS
  // ================================================================

  static const Color success = Color(0xFF0A8A6D);
  static const Color error = Color(0xFFE53935);
  static const Color warning = secondary;

  // ================================================================
  // ALIASES (keep compatibility with existing code)
  // ================================================================

  static const Color primaryColor = primary;
  static const Color secondaryColor = secondary;
  static const Color accentColor = accent;
  static const Color background = light;
  static const Color surface = light;
  static const Color textSecondary = greyText;
  static const Color border = borderLight;
  static const Color errorColor = error;
  static const Color successColor = success;
  static const Color warningColor = warning;

  // ================================================================
  // CHAT COLORS
  // ================================================================

  static const Color chatBubbleSent = primary;
  static const Color chatBubbleReceived = Color(0xFF001533); // darkSurfaceLight

  static const Color chatTextSent = Colors.white;
  static const Color chatTextReceived = Colors.white;

  static const Color chatTimestampSent = Color(0xCCFFFFFF);
  static const Color chatTimestampReceived = Color(0xB3FFFFFF);

  static const Color chatInputBackground = Color(0xFF001533);
  static const Color chatDivider = Color(0xFF001533);

  static const Color chatOnlineDot = Color(0xFF0A8A6D);
  static const Color chatOfflineDot = Color(0xFF9E9E9E);

  static const Color chatUnreadBadge = Color(0xFFE53935);

  // ================================================================
  // RADIUS
  // ================================================================

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusExtraLarge = 24.0;
  static const double borderRadiusMessageBubble = 16.0;

  // ================================================================
  // GETTERS
  // ================================================================

  static Color get backgroundColor => light;
  static Color get surfaceColor => light;
  static Color get darkText => dark;

  // ================================================================
  // TEXT STYLES
  // ================================================================

  static TextStyle get bodyText =>
      GoogleFonts.nunito(fontSize: 14, color: greyText);

  static TextStyle get headline2 => GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: dark,
  );

  static TextStyle get buttonText => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: light,
  );

  // ================================================================
  // CHAT TEXT
  // ================================================================

  static TextStyle get chatMessageText =>
      GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400);

  static TextStyle get chatTimestampText =>
      GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w400);

  static TextStyle get chatNameText =>
      GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get chatEmptyText => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: greyText,
  );

  static TextStyle get chatHeaderText =>
      GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600);

  // ================================================================
  // CARD DECORATION
  // ================================================================

  static BoxDecoration cardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: light,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderLight, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: primary.withOpacity(0.07),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration darkCardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: darkSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: darkBorder, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ================================================================
  // CHAT BUBBLE
  // ================================================================

  static BoxDecoration chatBubbleDecoration({
    required bool isSent,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: isSent ? chatBubbleSent : chatBubbleReceived,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(isSent ? radius : 4),
        bottomRight: Radius.circular(isSent ? 4 : radius),
      ),
    );
  }

  // ================================================================
  // CHAT INPUT
  // ================================================================

  static BoxDecoration chatInputContainerDecoration({bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? darkSurfaceLight : light,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }

  // ================================================================
  // CHAT LIST ITEM
  // ================================================================

  static BoxDecoration chatListItemDecoration({bool isActive = false}) {
    return BoxDecoration(
      color: isActive ? primary.withOpacity(0.06) : Colors.transparent,
      border: Border(
        bottom: BorderSide(
          color: borderLight.withOpacity(0.5),
          width: 0.5,
        ),
      ),
    );
  }

  // ================================================================
  // CARD THEME
  // ================================================================

  static CardThemeData get cardTheme => lightTheme.cardTheme;

  // ================================================================
  // INPUT DECORATION (helper used directly by screens)
  // ================================================================

  static InputDecoration inputDecoration({
    String? label,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primary) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: light,
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(color: primary, width: 2),
      errorBorder: _inputBorder(color: error, width: 2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: GoogleFonts.nunito(color: greyText, fontSize: 14),
    );
  }

  // ================================================================
  // CHAT FIELD
  // ================================================================

  static InputDecoration chatFieldDecoration({
    String? hint,
    bool isDark = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusExtraLarge),
      borderSide: BorderSide.none,
    );

    return InputDecoration(
      hintText: hint ?? 'Type a message...',
      hintStyle: GoogleFonts.nunito(
        color: isDark ? darkHint : greyText,
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark ? darkSurfaceLight : navy50,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  // ================================================================
  // PRIVATE HELPERS
  // ================================================================

  static OutlineInputBorder _inputBorder({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      borderSide: color == null
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color focus,
    required Color text,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(color: focus, width: 2),
      errorBorder: _inputBorder(color: error, width: 2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(inherit: true, color: text),
      hintStyle: TextStyle(inherit: true, color: text),
    );
  }

  static TextStyle _t(
      TextStyle? base,
      double size,
      FontWeight? weight,
      Color color, {
        double? height,
        double? letterSpacing,
      }) {
    return (base ?? const TextStyle()).copyWith(
      inherit: true,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ================================================================
  // SHARED TEXT THEME BUILDER
  // ================================================================

  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    final b = GoogleFonts.nunitoTextTheme();

    return b.copyWith(
      displayLarge: _t(b.displayLarge, 32, FontWeight.w800, primaryText,
          letterSpacing: -0.5),
      displayMedium: _t(b.displayMedium, 28, FontWeight.w700, primaryText,
          letterSpacing: -0.3),
      headlineMedium:
      _t(b.headlineMedium, 24, FontWeight.w700, primaryText),
      titleLarge: _t(b.titleLarge, 20, FontWeight.w600, primaryText),
      titleMedium: _t(b.titleMedium, 16, FontWeight.w600, primaryText),
      titleSmall: _t(b.titleSmall, 14, FontWeight.w600, primaryText),
      bodyLarge: _t(b.bodyLarge, 16, null, primaryText, height: 1.5),
      bodyMedium: _t(b.bodyMedium, 14, null, secondaryText, height: 1.5),
      bodySmall: _t(b.bodySmall, 12, null, secondaryText),
      labelLarge: _t(b.labelLarge, 14, FontWeight.w600, primaryText),
      labelMedium: _t(b.labelMedium, 12, FontWeight.w500, primaryText),
      labelSmall: _t(b.labelSmall, 11, FontWeight.w500, secondaryText),
    );
  }

  // ================================================================
  // LIGHT THEME
  // ================================================================

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: scaffoldLight,
    hintColor: greyText,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      tertiary: accent,
      error: error,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: primary,
      onSurface: primary,
    ),
    dividerColor: dividerColor,
    fontFamily: GoogleFonts.nunito().fontFamily,
    textTheme: _buildTextTheme(primary, greyText),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      iconTheme: const IconThemeData(color: primary),
    ),
    listTileTheme: ListTileThemeData(
      textColor: primary,
      iconColor: primary,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      subtitleTextStyle: GoogleFonts.nunito(fontSize: 12, color: greyText),
    ),
    inputDecorationTheme:
    _inputTheme(fill: Colors.white, focus: primary, text: greyText),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      color: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primary,
      unselectedItemColor: greyText,
      backgroundColor: Colors.white,
      elevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primary.withOpacity(0.12),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) => GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? primary : greyText,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? primary : greyText,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: primary, size: 24),
      unselectedIconTheme: const IconThemeData(color: greyText, size: 23),
      selectedLabelTextStyle: GoogleFonts.nunito(
        color: primary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: GoogleFonts.nunito(
        color: greyText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: primary.withOpacity(0.10),
      useIndicator: true,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.selected)
            ? primary
            : Colors.grey.shade400,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.selected)
            ? primary.withOpacity(0.5)
            : Colors.grey.shade300,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: navy50,
      selectedColor: primary,
      labelStyle: const TextStyle(inherit: true, color: primary),
      secondaryLabelStyle: const TextStyle(inherit: true, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: primary,
    ),
  );

  // ================================================================
  // DARK THEME  (all text is white)
  // ================================================================

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: darkBackground,
    hintColor: darkHint,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      tertiary: accent,
      error: error,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: primary,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white,
    ),
    dividerColor: darkBorder,
    fontFamily: GoogleFonts.nunito().fontFamily,
    textTheme: _buildTextTheme(Colors.white, Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    listTileTheme: ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      subtitleTextStyle: GoogleFonts.nunito(
        fontSize: 12,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: _inputTheme(
      fill: darkSurfaceLight,
      focus: secondary,
      text: darkHint,
    ),

    // Gold background, white text
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: gold600,
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
      ),
    ),

    // Gold border and text
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondary,
        side: const BorderSide(color: secondary),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Gold text
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondary,
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder, width: 0.5),
      ),
      color: darkSurface,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: secondary,
      unselectedItemColor: Colors.white,
      backgroundColor: darkSurface,
      elevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: secondary.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) => GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: Colors.white,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) => IconThemeData(
          color:
          states.contains(WidgetState.selected) ? secondary : Colors.white,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: darkBackground,
      selectedIconTheme: const IconThemeData(color: secondary, size: 24),
      unselectedIconTheme: const IconThemeData(color: Colors.white, size: 23),
      selectedLabelTextStyle: GoogleFonts.nunito(
        color: secondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: GoogleFonts.nunito(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: secondary.withOpacity(0.15),
      useIndicator: true,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.selected)
            ? secondary
            : Colors.grey.shade600,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.selected)
            ? secondary.withOpacity(0.5)
            : Colors.grey.shade700,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceLight,
      selectedColor: secondary,
      labelStyle: const TextStyle(inherit: true, color: Colors.white),
      secondaryLabelStyle: const TextStyle(inherit: true, color: primary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkBorder, width: 0.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: darkSurface,
      contentTextStyle: const TextStyle(inherit: true, color: Colors.white),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: secondary),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 0.5),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: primary,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    primaryIconTheme: const IconThemeData(color: Colors.white),
  );
}

// ==================================================================
// CHAT THEME EXTENSION
// ==================================================================

extension ChatTheme on ThemeData {
  Color get chatBubbleSent => AppTheme.chatBubbleSent;
  Color get chatBubbleReceived => AppTheme.chatBubbleReceived;
  Color get chatTextSent => AppTheme.chatTextSent;
  Color get chatTextReceived => AppTheme.chatTextReceived;
  Color get chatTimestampSent => AppTheme.chatTimestampSent;
  Color get chatTimestampReceived => AppTheme.chatTimestampReceived;
  Color get chatOnlineDot => AppTheme.chatOnlineDot;
  Color get chatUnreadBadge => AppTheme.chatUnreadBadge;

  TextStyle get chatMessageText => AppTheme.chatMessageText;
  TextStyle get chatTimestampText => AppTheme.chatTimestampText;
  TextStyle get chatNameText => AppTheme.chatNameText;
  TextStyle get chatEmptyText => AppTheme.chatEmptyText;
  TextStyle get chatHeaderText => AppTheme.chatHeaderText;
}

// ==================================================================
// THEME HELPER
// ==================================================================

extension ThemeHelper on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isLightMode => Theme.of(this).brightness == Brightness.light;

  Color get primaryColor => Theme.of(this).primaryColor;
  Color get scaffoldBackgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(this).cardColor;
  Color get hintColor => Theme.of(this).hintColor;
  Color get dividerColor => Theme.of(this).dividerColor;
  Color get shadowColor => Theme.of(this).shadowColor;

  Color get chatBubbleSent => Theme.of(this).chatBubbleSent;
  Color get chatBubbleReceived => Theme.of(this).chatBubbleReceived;
  Color get chatOnlineDot => Theme.of(this).chatOnlineDot;
  Color get chatUnreadBadge => Theme.of(this).chatUnreadBadge;

  TextStyle get chatMessageText => Theme.of(this).chatMessageText;
  TextStyle get chatTimestampText => Theme.of(this).chatTimestampText;
  TextStyle get chatNameText => Theme.of(this).chatNameText;
  TextStyle get chatEmptyText => Theme.of(this).chatEmptyText;
  TextStyle get chatHeaderText => Theme.of(this).chatHeaderText;
}