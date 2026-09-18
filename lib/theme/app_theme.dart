import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Builds a complete [ThemeData] from an [AppTokens] set.
///
/// Everything Material renders by default — AppBar, Card, TextField, Dialog,
/// Switch, Dropdown, SnackBar, DataTable, Chip, Divider — is wired to tokens
/// here. That means a screen using stock widgets themes correctly with no
/// per-screen work at all.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppTokens.light, Brightness.light);
  static ThemeData dark() => _build(AppTokens.dark, Brightness.dark);
  static ThemeData navy() => _build(AppTokens.navy, Brightness.dark);
  static ThemeData highContrast() =>
      _build(AppTokens.highContrast, Brightness.light, focusWidth: 3);

  static ThemeData _build(
    AppTokens t,
    Brightness brightness, {
    double focusWidth = 2,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.primary,
      onPrimary: t.onPrimary,
      secondary: t.accent,
      onSecondary: t.onAccent,
      tertiary: t.info,
      onTertiary: t.onPrimary,
      error: t.danger,
      onError: brightness == Brightness.dark
          ? const Color(0xFF1A0505)
          : Colors.white,
      surface: t.surface,
      onSurface: t.foreground,
      surfaceContainerHighest: t.cardElevated,
      onSurfaceVariant: t.mutedForeground,
      outline: t.border,
      outlineVariant: t.divider,
      shadow: t.shadow,
      scrim: t.overlay,
      inverseSurface: t.foreground,
      onInverseSurface: t.background,
      inversePrimary: t.accent,
    );

    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      canvasColor: t.background,
      dividerColor: t.divider,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[t],

      // ── Typography ─────────────────────────────────────────────────────
      fontFamily: 'Segoe UI',
      textTheme: _textTheme(t),

      // ── App bar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: t.surface,
        foregroundColor: t.foreground,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: t.foreground, size: 22),
        actionsIconTheme: IconThemeData(color: t.mutedForeground, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: t.foreground,
        ),
      ),

      // ── Cards ──────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.card,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: t.border),
        ),
      ),

      // ── Inputs ─────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.cardElevated,
        border: inputBorder(t.border),
        enabledBorder: inputBorder(t.border),
        focusedBorder: inputBorder(t.accent, focusWidth),
        errorBorder: inputBorder(t.danger),
        focusedErrorBorder: inputBorder(t.danger, focusWidth),
        disabledBorder: inputBorder(t.divider),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: t.mutedForeground, fontSize: 14),
        floatingLabelStyle: TextStyle(color: t.accent, fontSize: 13),
        hintStyle: TextStyle(color: t.subtleForeground, fontSize: 14),
        helperStyle: TextStyle(color: t.subtleForeground, fontSize: 12),
        errorStyle: TextStyle(color: t.danger, fontSize: 12),
        prefixIconColor: t.mutedForeground,
        suffixIconColor: t.mutedForeground,
      ),

      // ── Buttons ────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: t.primary,
          foregroundColor: t.onPrimary,
          disabledBackgroundColor: t.border,
          disabledForegroundColor: t.subtleForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.foreground,
          side: BorderSide(color: t.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.accent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: t.mutedForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
      ),

      // ── Surfaces & overlays ────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: t.border),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: t.foreground,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 14,
          height: 1.5,
          color: t.mutedForeground,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: t.sidebar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        width: 292,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusLg),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.card,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: t.border),
        ),
        textStyle: TextStyle(color: t.foreground, fontSize: 14),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              side: BorderSide(color: t.border),
            ),
          ),
        ),
        textStyle: TextStyle(color: t.foreground, fontSize: 14),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.foreground,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        textStyle: TextStyle(color: t.background, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.cardElevated,
        contentTextStyle: TextStyle(color: t.foreground, fontSize: 14),
        actionTextColor: t.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: t.border),
        ),
      ),

      // ── Controls ───────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.onAccent : t.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.border,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.borderStrong,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? t.accent
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(t.onAccent),
        side: BorderSide(color: t.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.borderStrong,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.accent,
        inactiveTrackColor: t.border,
        thumbColor: t.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        linearTrackColor: t.skeleton,
        circularTrackColor: Colors.transparent,
      ),

      // ── Lists, tabs, tables ────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: t.mutedForeground,
        textColor: t.foreground,
        selectedColor: t.accent,
        selectedTileColor: t.sidebarActiveBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: t.accent,
        unselectedLabelColor: t.mutedForeground,
        indicatorColor: t.accent,
        dividerColor: t.divider,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(t.cardElevated),
        headingTextStyle: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: t.mutedForeground,
        ),
        dataTextStyle: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 13.5,
          color: t.foreground,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.cardElevated,
        side: BorderSide(color: t.border),
        labelStyle: TextStyle(color: t.foreground, fontSize: 12.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: t.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: t.mutedForeground, size: 22),

      // ── Motion ─────────────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(AppTokens t) {
    TextStyle s(double size, FontWeight w, Color c,
            {double? ls, double? h}) =>
        TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: size,
          fontWeight: w,
          color: c,
          letterSpacing: ls,
          height: h,
        );

    return TextTheme(
      displaySmall: s(30, FontWeight.w800, t.foreground, ls: -0.6),
      headlineMedium: s(24, FontWeight.w800, t.foreground, ls: -0.4),
      headlineSmall: s(20, FontWeight.w700, t.foreground, ls: -0.3),
      titleLarge: s(18, FontWeight.w700, t.foreground, ls: -0.2),
      titleMedium: s(15.5, FontWeight.w600, t.foreground),
      titleSmall: s(13.5, FontWeight.w600, t.mutedForeground),
      bodyLarge: s(15, FontWeight.w400, t.foreground, h: 1.5),
      bodyMedium: s(14, FontWeight.w400, t.foreground, h: 1.5),
      bodySmall: s(12.5, FontWeight.w400, t.mutedForeground, h: 1.45),
      labelLarge: s(14, FontWeight.w600, t.foreground),
      labelMedium: s(12.5, FontWeight.w600, t.mutedForeground),
      labelSmall: s(11, FontWeight.w600, t.subtleForeground, ls: 0.4),
    );
  }
}
