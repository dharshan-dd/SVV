import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/index.dart';
import '../../theme/app_tokens.dart';

/// Tappable trail: `Dashboard › Branches › Branch`.
///
/// Every crumb except the last navigates. This is what guarantees a route home
/// even when the back stack is empty (drawer navigation, deep link, web
/// refresh), so the user is never stranded inside a page.
class Breadcrumb extends StatelessWidget {
  /// Extra leaf appended for detail views, e.g. a customer's name.
  final String? leaf;

  const Breadcrumb({super.key, this.leaf});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final path = GoRouterState.of(context).uri.path;
    final trail = AppRoutes.trail(path);

    if (trail.isEmpty) return const SizedBox.shrink();

    final labels = <_Crumb>[
      for (final r in trail) _Crumb(r.title, r.path),
      if (leaf != null) _Crumb(leaf!, null),
    ];

    // A single crumb is just the page title — no trail worth showing.
    if (labels.length < 2) return const SizedBox.shrink();

    return Semantics(
      label: 'Breadcrumb navigation',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTokens.space1),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 14, color: t.subtleForeground),
                ),
              if (i == labels.length - 1 || labels[i].path == null)
                Text(
                  labels[i].label,
                  style: TextStyle(
                    color: t.mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                _CrumbLink(crumb: labels[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Crumb {
  final String label;
  final String? path;
  const _Crumb(this.label, this.path);
}

class _CrumbLink extends StatefulWidget {
  final _Crumb crumb;
  const _CrumbLink({required this.crumb});

  @override
  State<_CrumbLink> createState() => _CrumbLinkState();
}

class _CrumbLinkState extends State<_CrumbLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.goTop(widget.crumb.path!),
        child: Text(
          widget.crumb.label,
          style: TextStyle(
            color: _hover ? t.accent : t.subtleForeground,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            decoration: _hover ? TextDecoration.underline : null,
            decorationColor: t.accent,
          ),
        ),
      ),
    );
  }
}

/// Back control that degrades gracefully: pops the stack when one exists,
/// otherwise navigates to the route's declared parent.
class PremiumBackButton extends StatelessWidget {
  final String? label;
  const PremiumBackButton({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: 'Back',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.backOrHome(),
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? 8 : 12,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 18, color: t.foreground),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: TextStyle(
                      color: t.foreground,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Consistent page heading: breadcrumb, title, description, and actions.
/// Used identically on every major screen (Phase 10).
class PageHeader extends StatelessWidget {
  final String title;
  final String? description;

  /// Search field, filter chips, primary action — laid out to the right on
  /// wide screens and wrapped underneath on narrow ones.
  final List<Widget> actions;
  final String? breadcrumbLeaf;
  final bool showBreadcrumb;

  const PageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
    this.breadcrumbLeaf,
    this.showBreadcrumb = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final narrow = MediaQuery.sizeOf(context).width < 720;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBreadcrumb) ...[
          Breadcrumb(leaf: breadcrumbLeaf),
          const SizedBox(height: AppTokens.space2),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(
              color: t.foreground,
              fontSize: narrow ? 21 : 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(
            description!,
            style: TextStyle(
              color: t.mutedForeground,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ],
    );

    if (actions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.space5, AppTokens.space5, AppTokens.space5, 0),
        child: heading,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.space5, AppTokens.space5, AppTokens.space5, 0),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                const SizedBox(height: AppTokens.space4),
                Wrap(
                  spacing: AppTokens.space2,
                  runSpacing: AppTokens.space2,
                  children: actions,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: heading),
                const SizedBox(width: AppTokens.space4),
                Wrap(
                  spacing: AppTokens.space2,
                  runSpacing: AppTokens.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ],
            ),
    );
  }
}

/// App shell used by every screen. Supplies the themed background, the drawer,
/// a compact app bar, and the [PageHeader] — so an individual screen only
/// supplies its body.
///
/// Leading control follows a deliberate rule rather than being added blindly:
/// a back arrow appears when there is a real back stack; otherwise the drawer
/// menu button appears, and the breadcrumb carries the route home.
class PremiumScaffold extends StatelessWidget {
  final String title;
  final String? description;
  final Widget body;
  final List<Widget> headerActions;
  final List<Widget> appBarActions;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final String? breadcrumbLeaf;
  final bool showHeader;
  final Future<void> Function()? onRefresh;

  const PremiumScaffold({
    super.key,
    required this.title,
    required this.body,
    this.description,
    this.headerActions = const [],
    this.appBarActions = const [],
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.breadcrumbLeaf,
    this.showHeader = true,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final canPop = context.hasBackStack;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          PageHeader(
            title: title,
            description: description,
            actions: headerActions,
            breadcrumbLeaf: breadcrumbLeaf,
          ),
        Expanded(child: body),
      ],
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: t.accent,
        backgroundColor: t.card,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: t.background,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      appBar: AppBar(
        backgroundColor: t.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 52,
        titleSpacing: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: () => context.backOrHome(),
              )
            : null,
        title: canPop
            ? Text(
                title,
                style: TextStyle(
                  color: t.foreground,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        actions: [
          ...appBarActions,
          if (!context.isAtHome)
            IconButton(
              icon: const Icon(Icons.home_rounded),
              tooltip: 'Go to Dashboard',
              onPressed: () => context.goTop(AppRoutes.home),
            ),
          const SizedBox(width: AppTokens.space2),
        ],
      ),
      body: SafeArea(top: false, child: content),
    );
  }
}
