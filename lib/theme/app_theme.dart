import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pastel palette from the Exam Duel design system ("pastel bento").
class Pastel {
  static const lime = Color(0xFFD8F26B);
  static const lav = Color(0xFFB9A8FF);
  static const sky = Color(0xFFA8D5F2);
  static const peach = Color(0xFFFFC36B);
  static const pink = Color(0xFFF6B8E4);
  static const coral = Color(0xFFFF8F70);

  /// Coral is too pale for text on light backgrounds (2:1); this reads at 4.6:1.
  static const coralDeep = Color(0xFFC2410C);
  static const mint = Color(0xFF9FE6C4);
  static const aqua = Color(0xFF8EDFD3);
  static const okBg = Color(0xFF9FE6C4);
  static const badBg = Color(0xFFFF9E82);
  static const ink = Color(0xFF15202B);

  /// Gold, for coins.
  static const coin = Color(0xFFF2B705);

  /// The game's own colour stripe, used on progress bars and in confetti.
  static const stripe = [lime, sky, lav, peach, pink, mint];

  static const all = [lime, lav, sky, peach, pink, coral, mint, aqua];
}

/// The user picks one accent; it also sets Eve's iris colour.
class AccentChoice {
  final String id;
  final String name;
  final Color acc;
  final Color soft;
  final Color softDark;
  final Color iris;
  const AccentChoice(this.id, this.name, this.acc, this.soft, this.softDark, this.iris);

  static const honey = AccentChoice('honey', 'Honey', Color(0xFFFFC36B), Color(0xFFFFF0D6), Color(0xFF3A2C14), Color(0xFFE59A12));
  static const aqua = AccentChoice('aqua', 'Aqua', Color(0xFF8EDFD3), Color(0xFFDDF6F2), Color(0xFF12342F), Color(0xFF13A3A6));
  static const lavender = AccentChoice('lavender', 'Lavender', Color(0xFFB9A8FF), Color(0xFFECE7FF), Color(0xFF2A2550), Color(0xFF7B5CF0));

  static const values = [honey, aqua, lavender];
  static AccentChoice byId(String? id) =>
      values.firstWhere((a) => a.id == id, orElse: () => aqua);
}

/// Semantic colours, resolved per brightness. Read with `context.c`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg, surface, surface2, ink, muted, line, nav, navFg, acc, accSoft;
  final Color iris;
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.muted,
    required this.line,
    required this.nav,
    required this.navFg,
    required this.acc,
    required this.accSoft,
    required this.iris,
  });

  factory AppColors.of(bool dark, AccentChoice a) => dark
      ? AppColors(
          bg: const Color(0xFF0F161E),
          surface: const Color(0xFF1A2430),
          surface2: const Color(0xFF243142),
          ink: const Color(0xFFF2F0EA),
          muted: const Color(0xFFA9B3BF),
          line: const Color(0x1FF2F0EA),
          nav: const Color(0xFF05090D),
          navFg: const Color(0xFF8C96A2),
          acc: a.acc,
          accSoft: a.softDark,
          iris: a.iris,
        )
      : AppColors(
          bg: const Color(0xFFF4F2EC),
          surface: Colors.white,
          surface2: const Color(0xFFECE9E1),
          ink: Pastel.ink,
          muted: const Color(0xFF5F6670),
          line: const Color(0x1F15202B),
          nav: Pastel.ink,
          navFg: const Color(0xFF9AA4AF),
          acc: a.acc,
          accSoft: a.soft,
          iris: a.iris,
        );

  /// Primary button fill: dark ink in light mode, cream in dark mode.
  Color get primary => ink;
  Color get onPrimary => bg;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      nav: l(nav, other.nav),
      navFg: l(navFg, other.navFg),
      acc: l(acc, other.acc),
      accSoft: l(accSoft, other.accSoft),
      iris: l(iris, other.iris),
    );
  }
}

extension AppThemeX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
}

/// Type styles: Urbanist for display and numbers, Figtree for body.
class T {
  static TextStyle disp(double size, {Color? color, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.urbanist(
        fontSize: size,
        fontWeight: w,
        height: 1.0,
        letterSpacing: -0.035 * size,
        color: color,
      );

  static TextStyle num(double size, {Color? color}) => GoogleFonts.urbanist(
        fontSize: size,
        fontWeight: FontWeight.w300,
        height: 0.9,
        letterSpacing: -0.05 * size,
        color: color,
      );

  static TextStyle body(double size, {Color? color, FontWeight w = FontWeight.w500, double height = 1.4}) =>
      GoogleFonts.figtree(fontSize: size, fontWeight: w, color: color, height: height);

  static TextStyle micro({Color? color}) => GoogleFonts.figtree(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: color,
      );
}

ThemeData buildTheme({required bool dark, required AccentChoice accent}) {
  final colors = AppColors.of(dark, accent);
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: colors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: colors.ink,
      secondary: colors.acc,
      surface: colors.surface,
      onSurface: colors.ink,
    ),
    textTheme: GoogleFonts.figtreeTextTheme(base.textTheme).apply(
      bodyColor: colors.ink,
      displayColor: colors.ink,
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: colors.ink),
    extensions: [colors],
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
