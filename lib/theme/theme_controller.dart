import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// The theme options exposed in Settings.
enum AppThemeChoice {
  light('light', 'Light', 'White surfaces, navy text, gold accents'),
  dark('dark', 'Dark', 'Near-black navy with gold accents'),
  system('system', 'System', 'Follow your device setting'),
  navy('navy', 'Premium Navy', 'Rich navy surfaces, gold highlights'),
  highContrast('high_contrast', 'High Contrast', 'Maximum legibility');

  final String id;
  final String label;
  final String description;
  const AppThemeChoice(this.id, this.label, this.description);

  static AppThemeChoice fromId(String? id) => AppThemeChoice.values.firstWhere(
        (c) => c.id == id,
        orElse: () => AppThemeChoice.system,
      );

  IconData get icon => switch (this) {
        AppThemeChoice.light => Icons.light_mode_rounded,
        AppThemeChoice.dark => Icons.dark_mode_rounded,
        AppThemeChoice.system => Icons.brightness_auto_rounded,
        AppThemeChoice.navy => Icons.auto_awesome_rounded,
        AppThemeChoice.highContrast => Icons.contrast_rounded,
      };
}

const _prefsKey = 'app_theme_choice';
const _legacyDarkModeKey = 'dark_mode';

/// Read the saved choice *before* `runApp` so the first frame is already
/// correct. This is how we avoid a flash of the wrong theme on launch.
Future<AppThemeChoice> loadInitialThemeChoice() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(_prefsKey);
    if (saved != null) return AppThemeChoice.fromId(saved);

    // One-time migration: the old Settings screen wrote a `dark_mode` bool
    // that nothing ever read. Honour it so existing users keep their intent.
    final legacy = prefs.getBool(_legacyDarkModeKey);
    if (legacy != null) {
      final migrated =
          legacy ? AppThemeChoice.dark : AppThemeChoice.light;
      await prefs.setString(_prefsKey, migrated.id);
      return migrated;
    }
  } catch (_) {
    // Storage unavailable (e.g. restricted web context) — fall through.
  }
  return AppThemeChoice.system;
}

class ThemeController extends StateNotifier<AppThemeChoice> {
  ThemeController(super.initial);

  Future<void> select(AppThemeChoice choice) async {
    if (choice == state) return;
    state = choice; // update UI first; persistence is best-effort
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, choice.id);
      // Keep the legacy key in sync so any old code path stays coherent.
      await prefs.setBool(
        _legacyDarkModeKey,
        choice == AppThemeChoice.dark || choice == AppThemeChoice.navy,
      );
    } catch (_) {
      /* preference is still applied for this session */
    }
  }
}

/// Overridden in `main()` with the pre-loaded choice.
final initialThemeChoiceProvider = Provider<AppThemeChoice>(
  (ref) => throw UnimplementedError('initialThemeChoiceProvider not overridden'),
);

final themeControllerProvider =
    StateNotifierProvider<ThemeController, AppThemeChoice>((ref) {
  return ThemeController(ref.read(initialThemeChoiceProvider));
});

/// Resolves a choice into the `theme` / `darkTheme` / `themeMode` triple that
/// `MaterialApp` needs. Navy and High Contrast are fixed palettes, so they are
/// pinned with an explicit [ThemeMode] rather than left to the platform.
class ResolvedTheme {
  final ThemeData theme;
  final ThemeData darkTheme;
  final ThemeMode mode;
  const ResolvedTheme(this.theme, this.darkTheme, this.mode);

  factory ResolvedTheme.of(AppThemeChoice choice) {
    final light = AppTheme.light();
    final dark = AppTheme.dark();
    return switch (choice) {
      AppThemeChoice.light => ResolvedTheme(light, dark, ThemeMode.light),
      AppThemeChoice.dark => ResolvedTheme(light, dark, ThemeMode.dark),
      AppThemeChoice.system => ResolvedTheme(light, dark, ThemeMode.system),
      AppThemeChoice.navy =>
        ResolvedTheme(AppTheme.navy(), AppTheme.navy(), ThemeMode.dark),
      AppThemeChoice.highContrast => ResolvedTheme(
          AppTheme.highContrast(),
          AppTheme.highContrast(),
          ThemeMode.light,
        ),
    };
  }
}

final resolvedThemeProvider = Provider<ResolvedTheme>((ref) {
  return ResolvedTheme.of(ref.watch(themeControllerProvider));
});
