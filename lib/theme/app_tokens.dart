import 'package:flutter/material.dart';

/// Semantic design tokens for Sri Vetri Vinayaga Finance.
///
/// Every screen reads colours from here via `context.tokens` instead of
/// hard-coding `Color(0x...)`. This is what makes theme switching actually
/// work: swap the token set, and the whole UI follows.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // Surfaces
  final Color background;
  final Color surface;
  final Color card;
  final Color cardElevated;

  // Text
  final Color foreground;
  final Color mutedForeground;
  final Color subtleForeground;

  // Brand
  final Color primary;
  final Color onPrimary;
  final Color accent; // gold
  final Color onAccent;
  final Color accentSoft; // gold at low emphasis, for fills

  // Lines
  final Color border;
  final Color borderStrong;
  final Color divider;

  // Status
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // Navigation shell
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarMuted;
  final Color sidebarActive;
  final Color sidebarActiveBg;
  final Color headerStart;
  final Color headerEnd;

  // Feedback
  final Color skeleton;
  final Color overlay;
  final Color shadow;

  const AppTokens({
    required this.background,
    required this.surface,
    required this.card,
    required this.cardElevated,
    required this.foreground,
    required this.mutedForeground,
    required this.subtleForeground,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarMuted,
    required this.sidebarActive,
    required this.sidebarActiveBg,
    required this.headerStart,
    required this.headerEnd,
    required this.skeleton,
    required this.overlay,
    required this.shadow,
  });

  // ── Spacing / radii scale (constant across themes) ────────────────────────
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusPill = 999;

  // ── LIGHT ─────────────────────────────────────────────────────────────────
  // White surfaces, navy text, restrained gold accent.
  static const light = AppTokens(
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFFBFCFE),
    foreground: Color(0xFF0B1F3A),
    mutedForeground: Color(0xFF52627A),
    subtleForeground: Color(0xFF8494A8),
    primary: Color(0xFF0B1F3A),
    onPrimary: Color(0xFFFFFFFF),
    // Darkened gold so it clears 4.5:1 against white for text use.
    accent: Color(0xFF8A6A12),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFC9A227),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    divider: Color(0xFFEDF1F6),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFB91C1C),
    info: Color(0xFF1D4ED8),
    sidebar: Color(0xFF0B1F3A),
    sidebarForeground: Color(0xFFE8EEF7),
    sidebarMuted: Color(0xFF8FA3BF),
    sidebarActive: Color(0xFFD4AF37),
    sidebarActiveBg: Color(0x1FD4AF37),
    headerStart: Color(0xFF0B1F3A),
    headerEnd: Color(0xFF17375E),
    skeleton: Color(0xFFE8EDF3),
    overlay: Color(0x800B1F3A),
    shadow: Color(0x140B1F3A),
  );

  // ── DARK ──────────────────────────────────────────────────────────────────
  // Near-black navy, white text, gold as the action colour.
  static const dark = AppTokens(
    background: Color(0xFF070D18),
    surface: Color(0xFF0C1524),
    card: Color(0xFF111B2E),
    cardElevated: Color(0xFF16223A),
    foreground: Color(0xFFE8EEF7),
    mutedForeground: Color(0xFF93A3BA),
    subtleForeground: Color(0xFF6B7D96),
    primary: Color(0xFFD4AF37),
    onPrimary: Color(0xFF0A1424),
    accent: Color(0xFFD4AF37),
    onAccent: Color(0xFF0A1424),
    accentSoft: Color(0xFFE0C158),
    border: Color(0xFF1E2B42),
    borderStrong: Color(0xFF2C3D59),
    divider: Color(0xFF18243A),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    sidebar: Color(0xFF0A1220),
    sidebarForeground: Color(0xFFE8EEF7),
    sidebarMuted: Color(0xFF8293AC),
    sidebarActive: Color(0xFFD4AF37),
    sidebarActiveBg: Color(0x24D4AF37),
    headerStart: Color(0xFF0A1220),
    headerEnd: Color(0xFF13233D),
    skeleton: Color(0xFF1A2639),
    overlay: Color(0xB3000000),
    shadow: Color(0x40000000),
  );

  // ── PREMIUM NAVY ──────────────────────────────────────────────────────────
  // Richer, warmer navy than `dark`. Same identity, more presence.
  static const navy = AppTokens(
    background: Color(0xFF0B1F3A),
    surface: Color(0xFF102A4C),
    card: Color(0xFF14325A),
    cardElevated: Color(0xFF1A3D6B),
    foreground: Color(0xFFF2F6FC),
    mutedForeground: Color(0xFFA9BDD9),
    subtleForeground: Color(0xFF8099BC),
    primary: Color(0xFFD4AF37),
    onPrimary: Color(0xFF08172B),
    accent: Color(0xFFD4AF37),
    onAccent: Color(0xFF08172B),
    accentSoft: Color(0xFFE6CC72),
    border: Color(0xFF1F4675),
    borderStrong: Color(0xFF2C5A91),
    divider: Color(0xFF1A3C66),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFCD34D),
    danger: Color(0xFFFB7185),
    info: Color(0xFF7DD3FC),
    sidebar: Color(0xFF08172B),
    sidebarForeground: Color(0xFFF2F6FC),
    sidebarMuted: Color(0xFF95AECD),
    sidebarActive: Color(0xFFD4AF37),
    sidebarActiveBg: Color(0x26D4AF37),
    headerStart: Color(0xFF08172B),
    headerEnd: Color(0xFF1A3D6B),
    skeleton: Color(0xFF1B3E6C),
    overlay: Color(0xB308172B),
    shadow: Color(0x4D000000),
  );

  // ── HIGH CONTRAST ─────────────────────────────────────────────────────────
  // Accessibility-first. Pure black on white, heavy borders, no soft greys.
  static const highContrast = AppTokens(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFF2F2F2),
    foreground: Color(0xFF000000),
    mutedForeground: Color(0xFF1F1F1F),
    subtleForeground: Color(0xFF3A3A3A),
    primary: Color(0xFF00204D),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF6B4E00),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFF8A6A12),
    border: Color(0xFF000000),
    borderStrong: Color(0xFF000000),
    divider: Color(0xFF000000),
    success: Color(0xFF00560F),
    warning: Color(0xFF6B3A00),
    danger: Color(0xFF9B0000),
    info: Color(0xFF00337A),
    sidebar: Color(0xFF000000),
    sidebarForeground: Color(0xFFFFFFFF),
    sidebarMuted: Color(0xFFD6D6D6),
    sidebarActive: Color(0xFFFFD34D),
    sidebarActiveBg: Color(0x33FFD34D),
    headerStart: Color(0xFF000000),
    headerEnd: Color(0xFF00204D),
    skeleton: Color(0xFFDCDCDC),
    overlay: Color(0xCC000000),
    shadow: Color(0x33000000),
  );

  @override
  AppTokens copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? cardElevated,
    Color? foreground,
    Color? mutedForeground,
    Color? subtleForeground,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? border,
    Color? borderStrong,
    Color? divider,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? sidebar,
    Color? sidebarForeground,
    Color? sidebarMuted,
    Color? sidebarActive,
    Color? sidebarActiveBg,
    Color? headerStart,
    Color? headerEnd,
    Color? skeleton,
    Color? overlay,
    Color? shadow,
  }) {
    return AppTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      subtleForeground: subtleForeground ?? this.subtleForeground,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      sidebar: sidebar ?? this.sidebar,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      sidebarMuted: sidebarMuted ?? this.sidebarMuted,
      sidebarActive: sidebarActive ?? this.sidebarActive,
      sidebarActiveBg: sidebarActiveBg ?? this.sidebarActiveBg,
      headerStart: headerStart ?? this.headerStart,
      headerEnd: headerEnd ?? this.headerEnd,
      skeleton: skeleton ?? this.skeleton,
      overlay: overlay ?? this.overlay,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      card: c(card, other.card),
      cardElevated: c(cardElevated, other.cardElevated),
      foreground: c(foreground, other.foreground),
      mutedForeground: c(mutedForeground, other.mutedForeground),
      subtleForeground: c(subtleForeground, other.subtleForeground),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      accentSoft: c(accentSoft, other.accentSoft),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      divider: c(divider, other.divider),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      info: c(info, other.info),
      sidebar: c(sidebar, other.sidebar),
      sidebarForeground: c(sidebarForeground, other.sidebarForeground),
      sidebarMuted: c(sidebarMuted, other.sidebarMuted),
      sidebarActive: c(sidebarActive, other.sidebarActive),
      sidebarActiveBg: c(sidebarActiveBg, other.sidebarActiveBg),
      headerStart: c(headerStart, other.headerStart),
      headerEnd: c(headerEnd, other.headerEnd),
      skeleton: c(skeleton, other.skeleton),
      overlay: c(overlay, other.overlay),
      shadow: c(shadow, other.shadow),
    );
  }
}

/// `context.tokens` — the single accessor every screen uses.
extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
