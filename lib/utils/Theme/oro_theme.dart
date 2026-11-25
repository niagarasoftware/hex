import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Oro brand palette. Legacy names retained for existing screens.
const Color brandOrange = Color(0xFFFA7900);
const Color primaryPurple = Color(0xFF10294E);
const Color activeBgLavender = Color(0xFFE1EAF6);
const Color brandIconBg = Color(0xFF10294E);
const Color textDark = Color(0xFF1D293B);
const Color textMuted = Color(0xFF64748B);
const Color iconMuted = Color(0xFF64748B);
const Color avatarGreen = Color(0xFF16865C);

Color primaryDark = brandIconBg;
Color primary = primaryPurple;
Color primaryLight = brandIconBg;
Color primaryBackground = const Color(0xFFF4F6FA);
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
  final Color onSuccessGreen;
  final Color warningOrange;
  final Color onWarningOrange;
  final Color dangerRed;
  final Color onDangerRed;

  const OroThemeColors({
    required this.brandDark,
    required this.brandPrimary,
    required this.activeLavender,
    required this.cardBorder,
    required this.softBackground,
    required this.successGreen,
    this.onSuccessGreen = Colors.white,
    required this.warningOrange,
    this.onWarningOrange = Colors.white,
    required this.dangerRed,
    this.onDangerRed = Colors.white,
  });

  @override
  OroThemeColors copyWith({
    Color? brandDark,
    Color? brandPrimary,
    Color? activeLavender,
    Color? cardBorder,
    Color? softBackground,
    Color? successGreen,
    Color? onSuccessGreen,
    Color? warningOrange,
    Color? onWarningOrange,
    Color? dangerRed,
    Color? onDangerRed,
  }) {
    return OroThemeColors(
      brandDark: brandDark ?? this.brandDark,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      activeLavender: activeLavender ?? this.activeLavender,
      cardBorder: cardBorder ?? this.cardBorder,
      softBackground: softBackground ?? this.softBackground,
      successGreen: successGreen ?? this.successGreen,
      onSuccessGreen: onSuccessGreen ?? this.onSuccessGreen,
      warningOrange: warningOrange ?? this.warningOrange,
      onWarningOrange: onWarningOrange ?? this.onWarningOrange,
      dangerRed: dangerRed ?? this.dangerRed,
      onDangerRed: onDangerRed ?? this.onDangerRed,
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
      onSuccessGreen: Color.lerp(onSuccessGreen, other.onSuccessGreen, t)!,
      warningOrange: Color.lerp(warningOrange, other.warningOrange, t)!,
      onWarningOrange: Color.lerp(onWarningOrange, other.onWarningOrange, t)!,
      dangerRed: Color.lerp(dangerRed, other.dangerRed, t)!,
      onDangerRed: Color.lerp(onDangerRed, other.onDangerRed, t)!,
    );
  }
}

class OroTheme {
  static const OroThemeColors lightCustomColors = OroThemeColors(
    brandDark: brandIconBg,
    brandPrimary: primaryPurple,
    activeLavender: activeBgLavender,
    cardBorder: Color(0xFFE2E8F0),
    softBackground: Color(0xFFF4F6FA),
    successGreen: avatarGreen,
    onSuccessGreen: Colors.white,
    warningOrange: Color(0xFFD97706),
    onWarningOrange: Colors.white,
    dangerRed: Color(0xFFDC3545),
    onDangerRed: Colors.white,
  );

  static const OroThemeColors darkCustomColors = OroThemeColors(
    brandDark: Color(0xFF263B55),
    brandPrimary: Color(0xFFA9C7F2),
    activeLavender: Color(0xFF263B55),
    cardBorder: Color(0xFF334155),
    softBackground: Color(0xFF101827),
    successGreen: Color(0xFF22C55E),
    onSuccessGreen: Color(0xFF10294E),
    warningOrange: Color(0xFFF59E0B),
    onWarningOrange: Color(0xFF10294E),
    dangerRed: Color(0xFFEF4444),
    onDangerRed: Colors.white,
  );

  static const OroThemeColors _lightCustomColors = lightCustomColors;
  static const OroThemeColors _darkCustomColors = darkCustomColors;

  static ThemeData lightTheme = ThemeData.light(useMaterial3: true).copyWith(
    primaryColorDark: brandIconBg,
    primaryColor: primaryPurple,
    primaryColorLight: activeBgLavender,
    scaffoldBackgroundColor: const Color(0xFFF4F6FA),
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
      unselectedIconTheme: IconThemeData(color: Colors.white),
      selectedIconTheme: IconThemeData(color: primaryPurple),
      unselectedLabelTextStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
      selectedLabelTextStyle: TextStyle(color: primaryPurple, fontSize: 11, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryPurple,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryPurple,
      unselectedItemColor: Colors.white,
      selectedIconTheme: IconThemeData(color: primaryPurple),
      unselectedIconTheme: IconThemeData(color: Colors.white),
      selectedLabelStyle: TextStyle(color: primaryPurple, fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
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
        borderSide: const BorderSide(color: Color(0xFFDC3545)),
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
      primary: primaryPurple, // 0xFF10294E
      onPrimary: Colors.white,
      primaryContainer: activeBgLavender, // 0xFFE1EAF6
      onPrimaryContainer: brandIconBg, // 0xFF10294E
      secondary: brandOrange,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFE5CC),
      onSecondaryContainer: Color(0xFF713800),
      tertiary: avatarGreen, // 0xFF16865C
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD1FAE5),
      onTertiaryContainer: Color(0xFF065F46),
      surface: Colors.white,
      onSurface: textDark, // 0xFF1D293B
      onSurfaceVariant: textMuted, // 0xFF64748B
      surfaceContainerLowest: Color(0xFFF4F6FA),
      surfaceContainerLow: Color(0xFFF1F5F9),
      surfaceContainer: Color(0xFFE2E8F0),
      surfaceContainerHigh: Color(0xFFCBD5E1),
      surfaceContainerHighest: Color(0xFFE1EAF6),
      outline: iconMuted, // 0xFF64748B
      outlineVariant: Color(0xFFE2E8F0),
      error: Color(0xFFDC3545),
      onError: Colors.white,
      errorContainer: Color(0xFFFDE8E8),
      onErrorContainer: Color(0xFF991B1B),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
    primaryColorDark: brandIconBg,
    primaryColor: const Color(0xFFA9C7F2),
    primaryColorLight: const Color(0xFFA9C7F2),
    scaffoldBackgroundColor: const Color(0xFF101827),
    extensions: const [_darkCustomColors],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF10294E),
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
      indicatorColor: Color(0xFFA9C7F2),
      labelColor: Color(0xFFE1EAF6),
      unselectedLabelColor: Color(0xFF94A3B8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFA9C7F2),
        foregroundColor: primaryPurple,
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
        foregroundColor: const Color(0xFFA9C7F2),
        side: const BorderSide(color: Color(0xFF334155)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF101827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF10294E),
      elevation: 0,
      labelType: NavigationRailLabelType.all,
      indicatorColor: Color(0xFF263B55),
      unselectedIconTheme: IconThemeData(color: Colors.white),
      selectedIconTheme: IconThemeData(color: Color(0xFFD6E5FF)),
      unselectedLabelTextStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
      selectedLabelTextStyle: TextStyle(color: Color(0xFFD6E5FF), fontSize: 11, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF10294E),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFFD6E5FF),
      unselectedItemColor: Colors.white,
      selectedIconTheme: IconThemeData(color: Color(0xFFD6E5FF)),
      unselectedIconTheme: IconThemeData(color: Colors.white),
      selectedLabelStyle: TextStyle(color: Color(0xFFD6E5FF), fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFA9C7F2);
          }
          return const Color(0xFF1D293B);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryPurple;
          }
          return const Color(0xFFCBD5E1);
        }),
        iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryPurple;
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
      color: const Color(0xFF1D293B),
      shadowColor: Colors.black,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
    ),
    cardColor: const Color(0xFF1D293B),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFA9C7F2),
      onPrimary: Color(0xFF10294E),
      primaryContainer: Color(0xFF263B55),
      onPrimaryContainer: Color(0xFFD6E5FF),
      secondary: brandOrange,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF59300D),
      onSecondaryContainer: Color(0xFFFFDCC0),
      tertiary: Color(0xFF22C55E),
      onTertiary: Color(0xFF10294E),
      tertiaryContainer: Color(0xFF064E3B),
      onTertiaryContainer: Color(0xFFA7F3D0),
      surface: Color(0xFF1D293B),
      onSurface: Color(0xFFF4F6FA),
      onSurfaceVariant: Color(0xFFCBD5E1),
      surfaceContainerLowest: Color(0xFF101827),
      surfaceContainerLow: Color(0xFF162032),
      surfaceContainer: Color(0xFF1D293B),
      surfaceContainerHigh: Color(0xFF334155),
      surfaceContainerHighest: Color(0xFF475569),
      outline: Color(0xFF94A3B8),
      outlineVariant: Color(0xFF334155),
      error: Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
    ),
  );
}
