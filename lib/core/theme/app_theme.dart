import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ────────────────────────────────────────────────────────────

/// Raw colour palette (M3 *reference* tokens). Tonal numbers follow Material 3
/// convention: 100 = white, 0 = black. Roles (surface, onSurface, …) are
/// assigned in [AppTheme]'s `ColorScheme`; widgets should read from
/// `Theme.of(context).colorScheme`, not from this class.
///
/// Semantic colours that have no Material role (success, warning) live here as
/// flat tokens — pair with their `on*` counterpart for foreground content.
class AppColors {
  AppColors._();

  // ── Brand — Lavender (from logo) ──────────────────────────────────────
  // The logo's lavender (#C1AAE6 / #D3C4EF) is too light to carry white text,
  // so the brand colour is NOT used for high-emphasis CTAs. Instead it lives
  // as a low-emphasis tonal accent — selected chips, tags, section tints —
  // wired through `ColorScheme.primaryContainer`. High-emphasis surfaces (CTA
  // buttons, prices, active states) use neutral charcoal via `primary`.
  static const Color brand = Color(0xFF6750A4); // deep violet — accent text/icon on light
  static const Color brandContainer = Color(0xFFE8DEF8); // soft lavender — chip / tag surface
  static const Color onBrandContainer = Color(0xFF463371); // deep violet — on brandContainer

  // ── Neutral tonal palette (high = light) ──────────────────────────────
  static const Color neutral100 = Color(0xFFFFFFFF); // page background
  static const Color neutral98 = Color(0xFFF7F7F7); // surfaceContainerLow
  static const Color neutral95 = Color(0xFFEFEFEF); // surfaceContainer
  static const Color neutral92 = Color(0xFFE8E8E8); // surfaceContainerHigh
  static const Color neutral90 = Color(0xFFE5E5E5); // outline / containerHighest
  static const Color neutral60 = Color(0xFF9E9E9E); // onSurfaceVariant
  static const Color neutral10 = Color(0xFF1A1A1A); // onSurface

  // ── Semantic (no M3 role) ─────────────────────────────────────────────
  static const Color error = Color(0xFFB00020);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // ── Fit Advisor (semantic, no M3 role) ────────────────────────────────
  // Sage — Fit Match (true-to-size)
  static const Color fitMatch = Color(0xFF4A6B45);
  static const Color onFitMatch = Color(0xFFFFFFFF);
  static const Color fitMatchContainer = Color(0xFFDCE5D5);
  static const Color onFitMatchContainer = Color(0xFF2A3F26);

  // Amber — Fit Caveat (partial match)
  static const Color fitCaveat = Color(0xFFB08840);
  static const Color onFitCaveat = Color(0xFFFFFFFF);
  static const Color fitCaveatContainer = Color(0xFFF2E5CC);
  static const Color onFitCaveatContainer = Color(0xFF4D3A1A);

  // Dusty Rose — Fit Out of Range (outside available size range)
  static const Color fitOutOfRange = Color(0xFF9B7160);
  static const Color onFitOutOfRange = Color(0xFFFFFFFF);
  static const Color fitOutOfRangeContainer = Color(0xFFEFE0DA);
  static const Color onFitOutOfRangeContainer = Color(0xFF4A2F22);
}

// ─── Spacing Tokens ───────────────────────────────────────────────────────────

/// 8px-grid spacing tokens. Use `AppSpacing.md` instead of magic numbers.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double smMd = 12; // between sm and md
  static const double md = 16;
  static const double mdLg = 20; // between md and lg
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double iosTabBarHeight = 50; // iOS UITabBar / iOS26 floating
  static const double androidNavBarHeight = 80; // Material NavigationBar
}

// ─── Opacity Tokens ──────────────────────────────────────────────────────────

/// Standardised opacity levels for overlays, scrim, and disabled states.
/// Use `Colors.black.withValues(alpha: AppOpacity.overlay)` instead of magic numbers.
class AppOpacity {
  AppOpacity._();

  static const double subtle = 0.03; // hover tint, zebra row
  static const double light = 0.05; // card tint
  static const double medium = 0.08; // shadow, divider tint
  static const double strong = 0.3; // disabled state
  static const double overlay = 0.6; // image scrim / modal backdrop
}

// ─── Duration Tokens ──────────────────────────────────────────────────────────

/// Standard animation durations. Use `AppDuration.standard` instead of
/// `Duration(milliseconds: 200)` to keep motion timing consistent.
class AppDuration {
  AppDuration._();

  static const Duration quick = Duration(milliseconds: 100);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration thinking = Duration(milliseconds: 1800);
  static const Duration toast = Duration(seconds: 4);
}

// ─── Curve Tokens ───────────────────────────────────────────────────────────────

/// Standard easing curves. Pair with `AppDuration` for consistent motion.
class AppCurves {
  AppCurves._();

  static const Curve standard = Curves.easeInOut; // most transitions
  static const Curve enter = Curves.easeOut; // elements entering screen
  static const Curve exit = Curves.easeIn; // elements leaving screen
  static const Curve emphasized = Curves.easeOutCubic; // banners, sheets
}

// ─── Stroke Width Tokens ──────────────────────────────────────────────────────

/// Standard line widths for borders, dividers, and progress strokes.
/// Use `AppStroke.regular` instead of magic numbers like `1.5`.
class AppStroke {
  AppStroke._();

  static const double thin = 1; // hairline borders, dividers
  static const double regular = 1.5; // standard borders (inputs, outlined buttons)
  static const double medium = 2; // progress indicators
  static const double thick = 3; // emphasized progress
}

// ─── Border Radius Tokens ─────────────────────────────────────────────────────

/// Unified border radius constants. Use `AppRadius.card`, etc.
class AppRadius {
  AppRadius._();

  static const double card = 12;
  static const double button = 8;
  static const double input = 10;
  static const double dialog = 16;
  static const double sheet = 20; // top corners of bottom sheets
  static const double icon = 10;
  static const double pill = 100; // tags / filter chips

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonAll = BorderRadius.all(Radius.circular(button));
  static const BorderRadius inputAll = BorderRadius.all(Radius.circular(input));
  static const BorderRadius dialogAll = BorderRadius.all(Radius.circular(dialog));
  static const BorderRadius sheetTop = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

// ─── Theme ────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.neutral10,
      onPrimary: AppColors.neutral100,
      primaryContainer: AppColors.brandContainer,
      onPrimaryContainer: AppColors.onBrandContainer,
      // Secondary — neutral charcoal (neutral10 as bg → white text, contrast ~14:1)
      secondary: AppColors.neutral10,
      onSecondary: AppColors.neutral100,
      secondaryContainer: AppColors.neutral95,
      onSecondaryContainer: AppColors.neutral10,
      // Tertiary — same as secondary (unused slot, safe fallback)
      tertiary: AppColors.neutral10,
      onTertiary: AppColors.neutral100,
      tertiaryContainer: AppColors.neutral95,
      onTertiaryContainer: AppColors.neutral10,
      // Error
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      // Surface
      surface: AppColors.neutral100,
      onSurface: AppColors.neutral10,
      surfaceContainerLowest: AppColors.neutral100,
      surfaceContainerLow: AppColors.neutral98,
      surfaceContainer: AppColors.neutral95,
      surfaceContainerHigh: AppColors.neutral92,
      surfaceContainerHighest: AppColors.neutral90,
      onSurfaceVariant: AppColors.neutral60,
      // Outline
      outline: AppColors.neutral90,
      outlineVariant: AppColors.neutral95,
      // Misc
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.neutral10,
      onInverseSurface: AppColors.neutral100,
      inversePrimary: AppColors.brand,
    );

    // Shared button style helpers
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.buttonAll);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm + 4, // 12px vertical
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      visualDensity: VisualDensity.standard,

      // ── App Bar ──────────────────────────────────────────────────────────
      // Spec: white bg, no shadow / tint, charcoal icons + title.
      // `foregroundColor` drives icon and title colours.
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1, space: 1),

      // ── Icon ─────────────────────────────────────────────────────────────
      // Spec: icons default to onSurface (charcoal). Use onSurfaceVariant
      // explicitly when an icon is meant to look muted.
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
        ),
      ),

      // ── List Tile ────────────────────────────────────────────────────────
      // Spec: 24px horizontal padding (page-aligned), charcoal icons.
      // Title (bodyLarge) and subtitle (bodyMedium / onSurfaceVariant) inherit
      // from M3 defaults — no need to override.
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: colorScheme.onSurface,
        selectedColor: colorScheme.onSurface,
      ),

      // ── Floating Action Button ───────────────────────────────────────────
      // Spec: solid charcoal CTA, white icon, circular, soft elevation.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 4,
        highlightElevation: 4,
      ),

      // ── Slider ───────────────────────────────────────────────────────────
      // Spec: thin 2px track, classic round thumb, charcoal accent.
      // Bypasses M3 expressive slider; value indicator suppressed (callers
      // surface the value separately).
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.outline,
        thumbColor: colorScheme.primary,
        trackHeight: 1,
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
      ),

      // ── Radio ────────────────────────────────────────────────────────────
      // Spec: selected dot is neutral charcoal — consistent with the switch,
      // checkbox, and confirmation dialog actions (no coloured accent).
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((final states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onSurface;
          return colorScheme.onSurfaceVariant;
        }),
      ),

      // ── Switch ───────────────────────────────────────────────────────────
      // Spec: on-state is neutral charcoal (not the lavender accent). White
      // thumb on a charcoal track when selected; defaults when off.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((final states) {
          if (states.contains(WidgetState.selected)) return colorScheme.surface;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((final states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onSurface;
          return null;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((final states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onSurface;
          return null;
        }),
      ),

      // ── Checkbox ─────────────────────────────────────────────────────────
      // Spec: checked box is neutral charcoal with a white tick.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((final states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onSurface;
          return null;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.surface),
      ),

      // ── Progress Indicator ───────────────────────────────────────────────
      // Spec: spinners/bars are neutral charcoal, not the brand accent.
      // NOTE: RefreshIndicator does NOT read this theme (it falls back to
      // colorScheme.primary), so its `color` is set explicitly at each site.
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.onSurface),

      // ── Expansion Tile ───────────────────────────────────────────────────
      // Spec: no top/bottom dividers (design system forbids stacked lines).
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      // Spec: radius 12px, 1px outline border, no shadow
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: colorScheme.outline),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      // Primary: filled charcoal, white label, radius 8px
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      // Secondary: transparent bg, charcoal border + text, radius 8px
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.onSurface, width: AppStroke.regular),
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      // Ghost: transparent bg, charcoal text, radius 8px
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // ── Input ────────────────────────────────────────────────────────────
      // Spec: outlined style, 1.5px border, radius 10px, focus → onSurface
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4, // 12px
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: colorScheme.outline, width: AppStroke.regular),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: colorScheme.outline, width: AppStroke.regular),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: colorScheme.onSurface, width: AppStroke.regular),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: colorScheme.error, width: AppStroke.regular),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: colorScheme.error, width: AppStroke.regular),
        ),
        hintStyle: GoogleFonts.notoSansTc(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────
      // Spec: white bg, top radius 20px, no elevation
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      // Spec: dark pill, floating bottom, used for silent result feedback
      // (e.g. "saved to album"). Failures use TopNotification banner instead.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.notoSansTc(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      // Spec: white bg, radius 16px, no elevation shadow
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogAll),
        titleTextStyle: null, // inherits from textTheme.titleLarge
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      // Spec: pill shape, outline border, no elevation. Selected state is the
      // signature brand moment — lavender fill (primaryContainer) with deep
      // violet label (onPrimaryContainer) and no border.
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: colorScheme.outline),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        elevation: 0,
        pressElevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        labelStyle: TextStyle(fontSize: 12, color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(
          fontSize: 12,
          color: colorScheme.onPrimaryContainer,
        ),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      // Spec: white bg, top border 1px outline, charcoal active, no pill
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: Colors.transparent, // disable M3 pill indicator
        shadowColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((final states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: active ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((final states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // ── Typography ───────────────────────────────────────────────────────
      textTheme: TextTheme(
        // Display — Playfair Display (editorial headings)
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        // Headline — Outfit (section / card titles)
        headlineLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        // Title — Outfit
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
        // Body — Noto Sans TC (Chinese-compatible)
        bodyLarge: GoogleFonts.notoSansTc(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.notoSansTc(fontSize: 13, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.notoSansTc(fontSize: 11, fontWeight: FontWeight.w400),
        // Label — Outfit Uppercase (buttons, badges, nav)
        labelLarge: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        labelMedium: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
