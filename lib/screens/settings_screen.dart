import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:microfinance_app/theme/index.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';
import 'package:microfinance_app/widgets/premium/index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings state.
//
// The persistence logic below is unchanged from the original implementation —
// same SharedPreferences keys, same defaults, same method names — so any stored
// user preferences continue to load correctly.
//
// The one behavioural change: `darkMode` is no longer surfaced as its own
// toggle, because it was writing a key that nothing read. Theme selection now
// goes through `themeControllerProvider`, which keeps `dark_mode` in sync for
// backwards compatibility.
// ─────────────────────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool showDailySummary;
  final bool enableNotifications;
  final bool darkMode;
  final bool showPlanNotes;
  final bool autoRefresh;
  final String currency;

  const SettingsState({
    this.showDailySummary = true,
    this.enableNotifications = false,
    this.darkMode = true,
    this.showPlanNotes = true,
    this.autoRefresh = false,
    this.currency = 'INR',
  });

  SettingsState copyWith({
    bool? showDailySummary,
    bool? enableNotifications,
    bool? darkMode,
    bool? showPlanNotes,
    bool? autoRefresh,
    String? currency,
  }) {
    return SettingsState(
      showDailySummary: showDailySummary ?? this.showDailySummary,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      darkMode: darkMode ?? this.darkMode,
      showPlanNotes: showPlanNotes ?? this.showPlanNotes,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      currency: currency ?? this.currency,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      showDailySummary: prefs.getBool('show_daily_summary') ?? true,
      enableNotifications: prefs.getBool('enable_notifications') ?? false,
      darkMode: prefs.getBool('dark_mode') ?? true,
      showPlanNotes: prefs.getBool('show_plan_notes') ?? true,
      autoRefresh: prefs.getBool('auto_refresh') ?? false,
      currency: prefs.getString('currency') ?? 'INR',
    );
  }

  Future<void> setShowDailySummary(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_daily_summary', value);
    state = state.copyWith(showDailySummary: value);
  }

  Future<void> setEnableNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', value);
    state = state.copyWith(enableNotifications: value);
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    state = state.copyWith(darkMode: value);
  }

  Future<void> setShowPlanNotes(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_plan_notes', value);
    state = state.copyWith(showPlanNotes: value);
  }

  Future<void> setAutoRefresh(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_refresh', value);
    state = state.copyWith(autoRefresh: value);
  }

  Future<void> setCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', value);
    state = state.copyWith(currency: value);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final themeChoice = ref.watch(themeControllerProvider);

    return PremiumScaffold(
      title: 'Settings',
      description: 'Appearance, display and data preferences',
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.space5, AppTokens.space6, AppTokens.space5, AppTokens.space8),
        children: [
          // ── Appearance ────────────────────────────────────────────────
          const PremiumSectionHeader(
            title: 'Appearance',
            description: 'Applies instantly across the whole application',
          ),
          const SizedBox(height: AppTokens.space4),
          _ThemeSelector(
            selected: themeChoice,
            onSelect: (choice) async {
              await ref.read(themeControllerProvider.notifier).select(choice);
              if (!context.mounted) return;
              AppToast.success(context, '${choice.label} theme applied.');
            },
          ),

          const SizedBox(height: AppTokens.space8),

          // ── Display ───────────────────────────────────────────────────
          const PremiumSectionHeader(
            title: 'Display',
            description: 'Choose what appears on the dashboard',
          ),
          const SizedBox(height: AppTokens.space4),
          _SettingsGroup(
            children: [
              _ToggleTile(
                icon: Icons.summarize_rounded,
                label: 'Show Daily Summary',
                description: "Display today's totals on the dashboard",
                value: settings.showDailySummary,
                onChanged: (v) async {
                  await notifier.setShowDailySummary(v);
                  if (context.mounted) _saved(context);
                },
              ),
              _ToggleTile(
                icon: Icons.sticky_note_2_rounded,
                label: 'Show Plan Notes',
                description: 'Surface planning notes alongside collections',
                value: settings.showPlanNotes,
                onChanged: (v) async {
                  await notifier.setShowPlanNotes(v);
                  if (context.mounted) _saved(context);
                },
              ),
            ],
          ),

          const SizedBox(height: AppTokens.space8),

          // ── Data ──────────────────────────────────────────────────────
          const PremiumSectionHeader(
            title: 'Data',
            description: 'Refresh behaviour and regional formatting',
          ),
          const SizedBox(height: AppTokens.space4),
          _SettingsGroup(
            children: [
              _ToggleTile(
                icon: Icons.notifications_rounded,
                label: 'Enable Notifications',
                description: 'Receive alerts for collection activity',
                value: settings.enableNotifications,
                onChanged: (v) async {
                  await notifier.setEnableNotifications(v);
                  if (context.mounted) _saved(context);
                },
              ),
              _ToggleTile(
                icon: Icons.autorenew_rounded,
                label: 'Auto Refresh',
                description: 'Reload dashboard data automatically',
                value: settings.autoRefresh,
                onChanged: (v) async {
                  await notifier.setAutoRefresh(v);
                  if (context.mounted) _saved(context);
                },
              ),
              _DropdownTile(
                icon: Icons.currency_rupee_rounded,
                label: 'Currency',
                description: 'Used when formatting amounts',
                value: settings.currency,
                items: const ['INR', 'USD', 'EUR', 'GBP'],
                onChanged: (v) async {
                  if (v == null) return;
                  await notifier.setCurrency(v);
                  if (context.mounted) _saved(context);
                },
              ),
            ],
          ),

          const SizedBox(height: AppTokens.space8),
          _AboutCard(),
        ],
      ),
    );
  }

  void _saved(BuildContext context) =>
      AppToast.success(context, 'Settings saved successfully.');
}

/// Theme picker. Each option previews its own palette, so the choice is
/// legible before it is applied.
class _ThemeSelector extends StatelessWidget {
  final AppThemeChoice selected;
  final ValueChanged<AppThemeChoice> onSelect;

  const _ThemeSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 640;
    return Wrap(
      spacing: AppTokens.space3,
      runSpacing: AppTokens.space3,
      children: [
        for (final choice in AppThemeChoice.values)
          SizedBox(
            width: narrow
                ? MediaQuery.sizeOf(context).width - (AppTokens.space5 * 2)
                : 232,
            child: _ThemeOption(
              choice: choice,
              selected: choice == selected,
              onTap: () => onSelect(choice),
            ),
          ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  /// Swatch colours representative of each theme, shown as a preview strip.
  List<Color> get _swatch => switch (choice) {
        AppThemeChoice.light => const [
            Color(0xFFFFFFFF),
            Color(0xFFF5F7FA),
            Color(0xFF0B1F3A),
            Color(0xFFC9A227),
          ],
        AppThemeChoice.dark => const [
            Color(0xFF070D18),
            Color(0xFF111B2E),
            Color(0xFFE8EEF7),
            Color(0xFFD4AF37),
          ],
        AppThemeChoice.system => const [
            Color(0xFFFFFFFF),
            Color(0xFF070D18),
            Color(0xFF8494A8),
            Color(0xFFD4AF37),
          ],
        AppThemeChoice.navy => const [
            Color(0xFF0B1F3A),
            Color(0xFF14325A),
            Color(0xFFF2F6FC),
            Color(0xFFD4AF37),
          ],
        AppThemeChoice.highContrast => const [
            Color(0xFFFFFFFF),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFF6B4E00),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: '${choice.label} theme. ${choice.description}',
      child: PremiumCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppTokens.space4),
        accentBorder: selected ? t.accent : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  choice.icon,
                  size: 18,
                  color: selected ? t.accent : t.mutedForeground,
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Text(
                    choice.label,
                    style: TextStyle(
                      color: t.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, size: 18, color: t.accent),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              choice.description,
              style: TextStyle(
                color: t.mutedForeground,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            // Palette preview
            Container(
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                border: Border.all(color: t.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  for (final c in _swatch)
                    Expanded(child: Container(color: c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, color: t.divider, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4, vertical: AppTokens.space3),
      child: Row(
        children: [
          Icon(icon, size: 19, color: t.mutedForeground),
          const SizedBox(width: AppTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: t.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style:
                        TextStyle(color: t.mutedForeground, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4, vertical: AppTokens.space3),
      child: Row(
        children: [
          Icon(icon, size: 19, color: t.mutedForeground),
          const SizedBox(width: AppTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: t.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style:
                        TextStyle(color: t.mutedForeground, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: t.cardElevated,
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(color: t.border),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox.shrink(),
              isDense: true,
              dropdownColor: t.card,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              style: TextStyle(
                color: t.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              icon: Icon(Icons.expand_more_rounded,
                  size: 18, color: t.mutedForeground),
              items: items
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PremiumCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/final_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.account_balance_rounded, color: t.accent, size: 20),
            ),
          ),
          const SizedBox(width: AppTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sri Vetri Vinayaga Auto Finance',
                  style: TextStyle(
                    color: t.foreground,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Collection Management · Version 1.0.0',
                  style: TextStyle(color: t.mutedForeground, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
