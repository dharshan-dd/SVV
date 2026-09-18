import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Navigation helpers built on the existing `go_router` instance.
///
/// Background: almost every screen previously called `context.go()`, which
/// *replaces* the navigation stack rather than pushing onto it. That is why
/// there was never anything to go "back" to. These helpers distinguish the two
/// intents explicitly:
///
///   * [goTop]   — switching top-level destination (drawer taps). Replaces.
///   * [drillTo] — opening a child of the current page. Pushes, so back works.
///   * [backOrHome] — pops if possible, otherwise falls back to the logical
///     parent from [AppRoutes]. The user can never get stranded.
extension AppNavX on BuildContext {
  /// Switch top-level destination. Clears the stack by design.
  void goTop(String path) => GoRouter.of(this).go(path);

  /// Drill into a child page, preserving the back stack.
  Future<T?> drillTo<T>(String path) => GoRouter.of(this).push<T>(path);

  /// Return to the previous page, or to this route's logical parent if the
  /// stack is empty (e.g. after a deep link or a hard refresh on web).
  void backOrHome() {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final current = GoRouterState.of(this).uri.path;
    router.go(AppRoutes.parentOf(current));
  }

  /// True when a real back-stack entry exists.
  bool get hasBackStack => GoRouter.of(this).canPop();

  /// Whether the current route is the home dashboard.
  bool get isAtHome => GoRouterState.of(this).uri.path == AppRoutes.home;
}
