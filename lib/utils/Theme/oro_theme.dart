import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// HexSidebar Theme Palette Constants (Centralized Single Source of Truth)
const Color primaryPurple = Color(0xFF673AB7);
const Color activeBgLavender = Color(0xFFEDE7F6);
const Color brandIconBg = Color(0xFF5B22B6);
const Color textDark = Color(0xFF1E293B);
const Color textMuted = Color(0xFF475569);
const Color iconMuted = Color(0xFF64748B);
const Color avatarGreen = Color(0xFF1B873F);

Color primaryDark = brandIconBg;
Color primary = primaryPurple;
Color primaryLight = brandIconBg;
Color primaryBackground = const Color(0xFFF8FAFC);
Color primaryTextColor = textDark;
Color secondaryTextColor = textMuted;

// Theme Extension for Custom Application Accent Colors
class OroThemeColors extends ThemeExtension<OroThemeColors> {
  final Color brandDark;
  final Color brandPrimary;
  final Color activeLavender;
  final Color cardBorder;
  final Color softBackground;
  final Color successGreen;
  final Color warningOrange;
  final Color dangerRed;

  const OroThemeColors({
    required this.brandDark,
    required this.brandPrimary,
    required this.activeLavender,
    required this.cardBorder,
    required this.softBackground,
    required this.successGreen,
    required this.warningOrange,
    required this.dangerRed,
  });

  @override
  OroThemeColors copyWith({
    Color? brandDark,
    Color? brandPrimary,
    Color? activeLavender,
    Color? cardBorder,
    Color? softBackground,
    Color? successGreen,
    Color? warningOrange,
    Color? dangerRed,
  }) {
    return OroThemeColors(
      brandDark: brandDark ?? this.brandDark,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      activeLavender: activeLavender ?? this.activeLavender,
      cardBorder: cardBorder ?? this.cardBorder,
      softBackground: softBackground ?? this.softBackground,
      successGreen: successGreen ?? this.successGreen,
      warningOrange: warningOrange ?? this.warningOrange,
      dangerRed: dangerRed ?? this.dangerRed,
    );
  }

  @override
  OroThemeColors lerp(ThemeExtension<OroThemeColors>? other, double t) {
    if (other is! OroThemeColors) return this;
    return OroThemeColors(
      brandDark: Color.lerp(brandDark, other.brandDark, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      activeLavender: Color.lerp(activeLavender, other.activeLavender, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      softBackground: Color.lerp(softBackground, other.softBackground, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      warningOrange: Color.lerp(warningOrange, other.warningOrange, t)!,
      dangerRed: Color.lerp(dangerRed, other.dangerRed, t)!,
    );
  }
}

class OroTheme {
  static const OroThemeColors _lightCustomColors = OroThemeColors(
    brandDark: brandIconBg,
    brandPrimary: primaryPurple,
    activeLavender: activeBgLavender,
    cardBorder: Color(0xFFE2E8F0),
    softBackground: Color(0xFFF8FAFC),
    successGreen: avatarGreen,
    warningOrange: Color(0xFFD97706),
    dangerRed: Color(0xFFDC2626),
  );

  static const OroThemeColors _darkCustomColors = OroThemeColors(
    brandDark: Color(0xFF311B92),
    brandPrimary: Color(0xFF9575CD),
    activeLavender: Color(0xFF311B92),
    cardBorder: Color(0xFF334155),
    softBackground: Color(0xFF0F172A),
    successGreen: Color(0xFF22C55E),
    warningOrange: Color(0xFFF59E0B),
    dangerRed: Color(0xFFEF4444),
  );

  static ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColorDark: brandIconBg,
    primaryColor: primaryPurple,
    primaryColorLight: activeBgLavender,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    extensions: const [_lightCustomColors],
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryPurple,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPurple,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryPurple,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: primaryPurple,
      elevation: 0,
      labelType: NavigationRailLabelType.all,
      indicatorColor: activeBgLavender,
      unselectedIconTheme: IconThemeData(color: Color(0xFF94A3B8)),
      selectedIconTheme: IconThemeData(color: primaryPurple),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: primaryPurple,
      disabledColor: const Color(0xFFE2E8F0),
      labelStyle: const TextStyle(color: textDark, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFFF1F5F9),
      filled: true,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      labelStyle: const TextStyle(color: textMuted),
      hintStyle: const TextStyle(color: iconMuted),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return const Color(0xFF94A3B8);
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryPurple;
        }
        return const Color(0xFFE2E8F0);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryPurple;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryPurple;
          }
          return const Color(0xFFF1F5F9);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return textDark;
        }),
        iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return textMuted;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      surfaceTintColor: Colors.transparent,
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: primaryPurple,
      labelColor: primaryPurple,
      unselectedLabelColor: textMuted,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.roboto(fontSize: 22, color: textDark, fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.roboto(fontSize: 15, color: textDark, fontWeight: FontWeight.bold),
      titleSmall: GoogleFonts.roboto(fontSize: 13, color: textMuted, fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.roboto(fontSize: 18, color: textDark, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.roboto(fontSize: 14, color: textMuted, fontWeight: FontWeight.bold),
      labelLarge: GoogleFonts.roboto(fontSize: 15, color: textDark, fontWeight: FontWeight.bold),
      labelSmall: GoogleFonts.roboto(fontSize: 13, color: textMuted),
      bodyLarge: GoogleFonts.roboto(fontSize: 15, color: textDark),
      bodyMedium: GoogleFonts.roboto(fontSize: 13, color: textDark, fontWeight: FontWeight.w600),
      bodySmall: GoogleFonts.roboto(fontSize: 12, color: textMuted),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.04),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    cardColor: Colors.white,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryPurple, // 0xFF673AB7
      onPrimary: Colors.white,
      primaryContainer: activeBgLavender, // 0xFFEDE7F6
      onPrimaryContainer: brandIconBg, // 0xFF5B22B6
      secondary: brandIconBg, // 0xFF5B22B6
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF1F5F9),
      onSecondaryContainer: textDark,
      tertiary: avatarGreen, // 0xFF1B873F
      onTertiary: Colors.white,
      surface: Colors.white,
      onSurface: textDark, // 0xFF1E293B
      onSurfaceVariant: textMuted, // 0xFF475569
      surfaceContainerLowest: Color(0xFFF8FAFC),
      surfaceContainerLow: Color(0xFFF1F5F9),
      surfaceContainer: Color(0xFFE2E8F0),
      surfaceContainerHigh: Color(0xFFCBD5E1),
      surfaceContainerHighest: Color(0xFFEDE7F6),
      outline: iconMuted, // 0xFF64748B
      outlineVariant: Color(0xFFE2E8F0),
      error: Color(0xFFDC2626),
      onError: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColorDark: brandIconBg,
    primaryColor: primaryPurple,
    primaryColorLight: const Color(0xFF9575CD),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    extensions: const [_darkCustomColors],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1B4B),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: Color(0xFFB39DDB),
      labelColor: Color(0xFFEDE7F6),
      unselectedLabelColor: Color(0xFF94A3B8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFB39DDB),
        side: const BorderSide(color: Color(0xFF334155)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF0F172A),
      elevation: 0,
      labelType: NavigationRailLabelType.all,
      indicatorColor: Color(0xFF311B92),
      unselectedIconTheme: IconThemeData(color: Color(0xFF94A3B8)),
      selectedIconTheme: IconThemeData(color: Color(0xFFEDE7F6)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF673AB7);
          }
          return const Color(0xFF1E293B);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFFCBD5E1);
        }),
        iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFF94A3B8);
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFF334155)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.roboto(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.roboto(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
      titleSmall: GoogleFonts.roboto(fontSize: 13, color: const Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.roboto(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
      labelLarge: GoogleFonts.roboto(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
      labelSmall: GoogleFonts.roboto(fontSize: 13, color: const Color(0xFF94A3B8)),
      bodyLarge: GoogleFonts.roboto(fontSize: 15, color: Colors.white),
      bodyMedium: GoogleFonts.roboto(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
      bodySmall: GoogleFonts.roboto(fontSize: 12, color: const Color(0xFFCBD5E1)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      shadowColor: Colors.black,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
    ),
    cardColor: const Color(0xFF1E293B),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9575CD),
      onPrimary: Color(0xFF1E1B4B),
      primaryContainer: Color(0xFF311B92),
      onPrimaryContainer: Color(0xFFEDE7F6),
      secondary: Color(0xFF7C4DFF),
      onSecondary: Colors.white,
      tertiary: Color(0xFF22C55E),
      onTertiary: Colors.white,
      surface: Color(0xFF0F172A),
      onSurface: Color(0xFFF8FAFC),
      onSurfaceVariant: Color(0xFFCBD5E1),
      surfaceContainerLowest: Color(0xFF020617),
      surfaceContainerLow: Color(0xFF0F172A),
      surfaceContainer: Color(0xFF1E293B),
      surfaceContainerHigh: Color(0xFF334155),
      surfaceContainerHighest: Color(0xFF475569),
      outline: Color(0xFF94A3B8),
      outlineVariant: Color(0xFF334155),
      error: Color(0xFFEF4444),
      onError: Colors.white,
    ),
  );
}
