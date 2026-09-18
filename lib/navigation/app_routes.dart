import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A single source of truth describing every route in the app: its title,
/// subtitle, icon, and — critically — its logical *parent*.
///
/// Page headers, breadcrumbs and back buttons all read from here, so a screen
/// gets correct navigation just by declaring its path. No route paths are
/// changed; this only adds metadata about the routes that already exist.
class AppRoute {
  final String path;
  final String title;
  final String subtitle;
  final IconData icon;

  /// Logical parent. `null` means this is a root destination.
  final String? parent;

  const AppRoute({
    required this.path,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.parent,
  });
}

class AppRoutes {
  const AppRoutes._();

  static const home = '/';

  /// Every route in `main.dart`, annotated. Paths are unchanged.
  static const Map<String, AppRoute> all = {
    '/': AppRoute(
      path: '/',
      title: 'Dashboard',
      subtitle: 'Daily overview of collections and cash position',
      icon: Icons.dashboard_rounded,
    ),
    '/dashboard': AppRoute(
      path: '/dashboard',
      title: 'Daily Dashboard',
      subtitle: 'Collection entries and totals for a selected day',
      icon: Icons.today_rounded,
      parent: '/',
    ),
    '/weekly-dashboard': AppRoute(
      path: '/weekly-dashboard',
      title: 'Weekly Dashboard',
      subtitle: 'Week-on-week collection performance',
      icon: Icons.calendar_view_week_rounded,
      parent: '/',
    ),
    '/monthly-dashboard': AppRoute(
      path: '/monthly-dashboard',
      title: 'Monthly Dashboard',
      subtitle: 'Monthly totals and trends',
      icon: Icons.calendar_month_rounded,
      parent: '/',
    ),
    '/gpay-dashboard': AppRoute(
      path: '/gpay-dashboard',
      title: 'GPay Dashboard',
      subtitle: 'Digital payment reconciliation',
      icon: Icons.account_balance_wallet_rounded,
      parent: '/',
    ),
    '/daily-tracking': AppRoute(
      path: '/daily-tracking',
      title: 'Daily Tracking',
      subtitle: 'Track collection progress through the day',
      icon: Icons.track_changes_rounded,
      parent: '/',
    ),
    '/daily-entry': AppRoute(
      path: '/daily-entry',
      title: 'Daily Entry',
      subtitle: 'Record a daily collection entry',
      icon: Icons.edit_note_rounded,
      parent: '/dashboard',
    ),
    '/day-record-entry': AppRoute(
      path: '/day-record-entry',
      title: 'Day Record Entry',
      subtitle: 'Record cash movement for the day',
      icon: Icons.post_add_rounded,
      parent: '/',
    ),
    '/day-records': AppRoute(
      path: '/day-records',
      title: 'Day Records',
      subtitle: 'All recorded daily cash entries',
      icon: Icons.receipt_long_rounded,
      parent: '/',
    ),
    '/collection-history': AppRoute(
      path: '/collection-history',
      title: 'Collection History',
      subtitle: 'Past collection cycles and outcomes',
      icon: Icons.history_rounded,
      parent: '/',
    ),
    '/bag-history': AppRoute(
      path: '/bag-history',
      title: 'Bag History',
      subtitle: 'Lifecycle of each collection bag',
      icon: Icons.inventory_2_rounded,
      parent: '/',
    ),
    '/plan-notes': AppRoute(
      path: '/plan-notes',
      title: 'Plan Notes',
      subtitle: 'Notes and planning against collection days',
      icon: Icons.sticky_note_2_rounded,
      parent: '/',
    ),
    '/branches': AppRoute(
      path: '/branches',
      title: 'Branches',
      subtitle: 'Manage regions and branch locations',
      icon: Icons.location_city_rounded,
      parent: '/',
    ),
    '/models': AppRoute(
      path: '/models',
      title: 'Models',
      subtitle: 'Manage collection model types',
      icon: Icons.category_rounded,
      parent: '/',
    ),
    '/bags': AppRoute(
      path: '/bags',
      title: 'Bags',
      subtitle: 'Manage collection bags and configurations',
      icon: Icons.work_rounded,
      parent: '/',
    ),
    '/schedules': AppRoute(
      path: '/schedules',
      title: 'Schedules',
      subtitle: 'Day and branch scheduling',
      icon: Icons.schedule_rounded,
      parent: '/',
    ),
    '/reports': AppRoute(
      path: '/reports',
      title: 'Reports',
      subtitle: 'Financial summaries and exports',
      icon: Icons.analytics_rounded,
      parent: '/',
    ),
    '/settings': AppRoute(
      path: '/settings',
      title: 'Settings',
      subtitle: 'Appearance, display and data preferences',
      icon: Icons.settings_rounded,
      parent: '/',
    ),
    '/login': AppRoute(
      path: '/login',
      title: 'Sign In',
      subtitle: '',
      icon: Icons.login_rounded,
    ),
  };

  static AppRoute? meta(String path) {
    // Strip query string so '/day-record-entry?date=...' still resolves.
    final clean = path.split('?').first;
    return all[clean];
  }

  static AppRoute? metaOf(BuildContext context) =>
      meta(GoRouterState.of(context).uri.path);

  /// Breadcrumb trail from root to [path], e.g.
  /// `/daily-entry` → [Dashboard, Daily Dashboard, Daily Entry].
  static List<AppRoute> trail(String path) {
    final out = <AppRoute>[];
    var cursor = meta(path);
    final guard = <String>{}; // cycle protection
    while (cursor != null && guard.add(cursor.path)) {
      out.insert(0, cursor);
      cursor = cursor.parent == null ? null : meta(cursor.parent!);
    }
    return out;
  }

  /// Where a back action should land when there is nothing on the stack.
  static String parentOf(String path) => meta(path)?.parent ?? home;
}
