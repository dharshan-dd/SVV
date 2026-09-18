import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:microfinance_app/navigation/index.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/services/supabase_service.dart';
import 'package:microfinance_app/theme/app_tokens.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';
import 'package:microfinance_app/widgets/premium/index.dart';

/// Main dashboard.
///
/// Data layer is unchanged: the same `getDailySummary(DateTime.now())` call
/// through the same provider, and the same summary keys
/// (`total_final_amount`, `total_collected`, `total_expense`,
/// `total_adap_amount`). Only layout, hierarchy and theming were reworked.
class DashboardHomeScreen extends ConsumerStatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  ConsumerState<DashboardHomeScreen> createState() =>
      _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends ConsumerState<DashboardHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _animCtrl.forward();
    _loadSummary();
  }

  void _loadSummary() {
    final svc = ref.read(supabaseServiceProvider);
    _summaryFuture = svc
        .getDailySummary(DateTime.now())
        .catchError((_) => <String, dynamic>{});
  }

  Future<void> _refreshSummary() async {
    setState(_loadSummary);
    await _summaryFuture;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fmt = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: t.background,
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshSummary,
        color: t.accent,
        backgroundColor: t.card,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              _WelcomeHeader(),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  width >= 900 ? AppTokens.space8 : AppTokens.space5,
                  AppTokens.space6,
                  width >= 900 ? AppTokens.space8 : AppTokens.space5,
                  AppTokens.space8,
                ),
                sliver: SliverList.list(
                  children: [
                    // ── Key financial summary ───────────────────────────
                    const PremiumSectionHeader(
                      title: 'Key Figures',
                      description: "Today's position at a glance",
                    ),
                    const SizedBox(height: AppTokens.space4),
                    _KpiGrid(future: _summaryFuture, fmt: fmt),

                    const SizedBox(height: AppTokens.space8),

                    // ── Quick actions ───────────────────────────────────
                    const PremiumSectionHeader(
                      title: 'Quick Actions',
                      description: 'Common tasks for the working day',
                    ),
                    const SizedBox(height: AppTokens.space4),
                    _QuickActions(onReturn: _refreshSummary),

                    const SizedBox(height: AppTokens.space8),

                    // ── Today's summary ─────────────────────────────────
                    const PremiumSectionHeader(
                      title: "Today's Summary",
                      description: 'Full breakdown of recorded values',
                    ),
                    const SizedBox(height: AppTokens.space4),
                    _TodaySummary(future: _summaryFuture, fmt: fmt),

                    const SizedBox(height: AppTokens.space8),

                    // ── Management ──────────────────────────────────────
                    const PremiumSectionHeader(
                      title: 'Management',
                      description: 'Records, history and configuration',
                    ),
                    const SizedBox(height: AppTokens.space4),
                    const _ManagementGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branded header. The only gradient surface in the app, used once.
class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return SliverAppBar(
      expandedHeight: 168,
      pinned: true,
      backgroundColor: t.headerStart,
      foregroundColor: t.sidebarForeground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: t.sidebarForeground),
      actions: [
        IconButton(
          tooltip: 'Reports',
          icon: const Icon(Icons.analytics_rounded),
          onPressed: () => context.drillTo('/reports'),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.drillTo('/settings'),
        ),
        const SizedBox(width: AppTokens.space2),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [t.headerStart, t.headerEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -46,
                top: -46,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.sidebarActive.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                right: 58,
                bottom: -34,
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.sidebarActive.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.space5, 66, AppTokens.space5, AppTokens.space4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.sidebarActive.withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusPill),
                            border: Border.all(
                              color:
                                  t.sidebarActive.withValues(alpha: 0.32),
                            ),
                          ),
                          child: Text(
                            'SRI VETRI VINAYAGA · AUTO FINANCE',
                            style: TextStyle(
                              color: t.sidebarActive,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space3),
                    Text(
                      greeting,
                      style: TextStyle(
                        color: t.sidebarMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(now),
                      style: TextStyle(
                        color: t.sidebarForeground,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// KPI row. Wraps to a grid on narrow screens instead of squeezing four
/// cards into a phone width.
class _KpiGrid extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final NumberFormat fmt;

  const _KpiGrid({required this.future, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final data = snap.data ?? const <String, dynamic>{};

        double read(String key) => (data[key] as num?)?.toDouble() ?? 0.0;

        final tiles = <Widget>[
          StatCard(
            label: 'Net Final',
            value: fmt.format(read('total_final_amount')),
            icon: Icons.account_balance_rounded,
            tone: t.success,
            loading: loading,
          ),
          StatCard(
            label: 'Collected',
            value: fmt.format(read('total_collected')),
            icon: Icons.payments_rounded,
            tone: t.info,
            loading: loading,
          ),
          StatCard(
            label: 'Amount Given',
            value: fmt.format(read('total_adap_amount')),
            icon: Icons.account_balance_wallet_rounded,
            tone: t.accent,
            loading: loading,
          ),
          StatCard(
            label: 'Expenses',
            value: fmt.format(read('total_expense')),
            icon: Icons.receipt_long_rounded,
            tone: t.danger,
            loading: loading,
          ),
        ];

        return LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 880
                ? 4
                : c.maxWidth >= 560
                    ? 4
                    : 2;
            const gap = AppTokens.space3;
            final itemWidth =
                (c.maxWidth - (gap * (columns - 1))) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final tile in tiles)
                  SizedBox(width: itemWidth, child: tile),
              ],
            );
          },
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Future<void> Function() onReturn;
  const _QuickActions({required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final items = <(String, IconData, String, Color)>[
      ('Day Record', Icons.post_add_rounded, '/day-record-entry', t.accent),
      ('Plan Notes', Icons.sticky_note_2_rounded, '/plan-notes', t.info),
      ('Weekly', Icons.calendar_view_week_rounded, '/weekly-dashboard',
          t.success),
      ('Reports', Icons.analytics_rounded, '/reports', t.warning),
      ('GPay', Icons.account_balance_wallet_rounded, '/gpay-dashboard',
          t.accent),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 720 ? 5 : 3;
        const gap = AppTokens.space3;
        final itemWidth = (c.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, icon, route, tone) in items)
              SizedBox(
                width: itemWidth,
                child: _ActionTile(
                  label: label,
                  icon: icon,
                  tone: tone,
                  onTap: () async {
                    // Drill down so the back stack survives.
                    await context.drillTo(route);
                    await onReturn();
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.space4, horizontal: AppTokens.space2),
              decoration: BoxDecoration(
                color: _hover
                    ? widget.tone.withValues(alpha: 0.14)
                    : widget.tone.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(
                  color: widget.tone
                      .withValues(alpha: _hover ? 0.48 : 0.22),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: widget.tone, size: 21),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.foreground,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final NumberFormat fmt;

  const _TodaySummary({required this.future, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return PremiumCard(
            child: Column(
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        const Skeleton(width: 130, height: 11),
                        const Spacer(),
                        const Skeleton(width: 74, height: 13),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }

        final data = snap.data ?? const <String, dynamic>{};
        final entries =
            data.entries.where((e) => e.value != null).toList();

        if (entries.isEmpty) {
          return PremiumCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 190,
              child: EmptyState(
                icon: Icons.event_note_rounded,
                title: 'No records for today',
                description:
                    'Once a day record is entered, the breakdown will appear '
                    'here.',
                actionLabel: 'Add Day Record',
                onAction: () => context.drillTo('/day-record-entry'),
              ),
            ),
          );
        }

        return PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space5,
                      vertical: AppTokens.space4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entries[i]
                              .key
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: t.mutedForeground,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space4),
                      Text(
                        entries[i].value is num
                            ? fmt.format(entries[i].value)
                            : entries[i].value.toString(),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: t.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < entries.length - 1)
                  Divider(height: 1, color: t.divider),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid();

  @override
  Widget build(BuildContext context) {
    // Labels and icons come from the route registry, so this grid stays in
    // sync with the drawer automatically.
    const paths = [
      '/daily-tracking',
      '/collection-history',
      '/bag-history',
      '/day-records',
      '/branches',
      '/models',
      '/bags',
      '/schedules',
      '/plan-notes',
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 1080
            ? 4
            : c.maxWidth >= 720
                ? 3
                : c.maxWidth >= 420
                    ? 2
                    : 1;
        const gap = AppTokens.space3;
        final itemWidth = (c.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final p in paths)
              if (AppRoutes.meta(p) != null)
                SizedBox(
                  width: itemWidth,
                  child: _ManagementCard(route: AppRoutes.meta(p)!),
                ),
          ],
        );
      },
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final AppRoute route;
  const _ManagementCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PremiumCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4, vertical: AppTokens.space4),
      onTap: () => context.drillTo(route.path),
      semanticLabel: '${route.title}. ${route.subtitle}',
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Icon(route.icon, color: t.accent, size: 18),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  route.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.foreground,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  route.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.mutedForeground,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: t.subtleForeground, size: 18),
        ],
      ),
    );
  }
}
