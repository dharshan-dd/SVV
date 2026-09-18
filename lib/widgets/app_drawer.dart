import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/index.dart';
import '../providers/app_providers.dart';
import '../theme/app_tokens.dart';
import 'premium/feedback.dart';

/// Primary navigation. Reads all colour from [AppTokens] so it follows the
/// selected theme, and derives its labels and icons from [AppRoutes] so the
/// drawer can never drift out of sync with the router.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _sections = <String, List<String>>{
    'Overview': ['/', '/dashboard', '/weekly-dashboard', '/monthly-dashboard'],
    'Daily Operations': [
      '/day-record-entry',
      '/day-records',
      '/daily-tracking',
      '/plan-notes',
    ],
    'Records': ['/collection-history', '/bag-history', '/gpay-dashboard'],
    'Configuration': ['/branches', '/models', '/bags', '/schedules'],
    'Insights': ['/reports', '/settings'],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final service = ref.read(supabaseServiceProvider);
    final user = Supabase.instance.client.auth.currentSession?.user;
    final current = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: t.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(user: user),
            Divider(height: 1, color: t.sidebarForeground.withValues(alpha: 0.10)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
                children: [
                  for (final entry in _sections.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppTokens.space6, AppTokens.space4, AppTokens.space6, AppTokens.space2),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          color: t.sidebarMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    for (final path in entry.value)
                      if (AppRoutes.meta(path) != null)
                        _NavItem(
                          route: AppRoutes.meta(path)!,
                          selected: current == path,
                        ),
                  ],
                  const SizedBox(height: AppTokens.space4),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppTokens.space4),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: t.sidebarForeground.withValues(alpha: 0.10),
                  ),
                ),
              ),
              child: user != null
                  ? _SidebarButton(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      tone: t.danger,
                      onTap: () async {
                        final confirmed = await ConfirmationDialog.show(
                          context,
                          title: 'Sign out?',
                          message:
                              'You will need to sign in again to access '
                              'collection records.',
                          confirmLabel: 'Sign Out',
                          icon: Icons.logout_rounded,
                        );
                        if (!confirmed || !context.mounted) return;
                        await service.client.auth.signOut();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        context.goTop('/login');
                      },
                    )
                  : _SidebarButton(
                      icon: Icons.login_rounded,
                      label: 'Sign In',
                      tone: t.sidebarActive,
                      onTap: () {
                        Navigator.pop(context);
                        context.goTop('/login');
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final User? user;
  const _Brand({this.user});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.space5, AppTokens.space6, AppTokens.space5, AppTokens.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.headerStart, t.headerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: t.sidebarActive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: t.sidebarActive.withValues(alpha: 0.30),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/final_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.account_balance_rounded,
                color: t.sidebarActive,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SRI VETRI VINAYAGA',
                  style: TextStyle(
                    color: t.sidebarForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  'AUTO FINANCE',
                  style: TextStyle(
                    color: t.sidebarActive,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? 'Daily Collection System',
                  style: TextStyle(color: t.sidebarMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final AppRoute route;
  final bool selected;
  const _NavItem({required this.route, required this.selected});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final active = widget.selected;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3, vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            onTap: () {
              Navigator.pop(context);
              // Top-level destination: replaces the stack by design.
              context.goTop(widget.route.path);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3, vertical: 11),
              decoration: BoxDecoration(
                color: active
                    ? t.sidebarActiveBg
                    : _hover
                        ? t.sidebarForeground.withValues(alpha: 0.05)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Row(
                children: [
                  // Active rail
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: active ? t.sidebarActive : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Icon(
                    widget.route.icon,
                    size: 19,
                    color: active ? t.sidebarActive : t.sidebarMuted,
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Text(
                      widget.route.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? t.sidebarActive
                            : t.sidebarForeground,
                        fontSize: 13.5,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                      ),
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

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space3, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: tone, size: 19),
              const SizedBox(width: AppTokens.space3),
              Text(
                label,
                style: TextStyle(
                  color: tone,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
