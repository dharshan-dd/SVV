// Theme mode persistence for Sri Vetri Vinayaga Finance.
//
// Replaces the old, non-functional `dark_mode` bool in
// screens/settings_screen.dart (which was saved but never read by
// MaterialApp). This is the single controller that actually drives
// `MaterialApp.router(theme: ...)` in main.dart.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:microfinance_app/theme/app_theme.dart';

const String kThemeModePrefsKey = 'app_theme_mode';
// Legacy key from the old (non-functional) dark-mode toggle. Read once for
// migration so an existing user's prior choice isn't silently discarded.
const String kLegacyDarkModePrefsKey = 'dark_mode';

/// Reads the persisted theme synchronously-ish (via a Future) so `main()`
/// can seed the provider before the first frame and avoid a theme flash.
Future<AppThemeMode> loadInitialThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(kThemeModePrefsKey);
  if (saved != null) {
    return AppThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => AppThemeMode.system,
    );
  }
  // Migration: honor the old boolean if the user had set it before this
  // feature existed, then leave it in place (harmless) and start writing
  // the new key going forward.
  final legacyDark = prefs.getBool(kLegacyDarkModePrefsKey);
  if (legacyDark != null) {
    return legacyDark ? AppThemeMode.dark : AppThemeMode.light;
  }
  return AppThemeMode.system;
}

class ThemeModeController extends StateNotifier<AppThemeMode> {
  ThemeModeController(AppThemeMode initial) : super(initial);

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kThemeModePrefsKey, mode.name);
  }
}

/// Overridden in `main()` with the persisted value before `runApp` so the
/// correct theme is applied on the very first frame (no flash).
final themeModeProvider =
    StateNotifierProvider<ThemeModeController, AppThemeMode>(
  (ref) => ThemeModeController(AppThemeMode.system),
);
