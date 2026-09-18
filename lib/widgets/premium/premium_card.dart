import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// The standard surface for grouped content. Replaces the ad-hoc
/// `Container(decoration: BoxDecoration(color: _kCard ...))` blocks that were
/// duplicated across nine screens.
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accentBorder;
  final bool elevated;
  final String? semanticLabel;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.space5),
    this.onTap,
    this.accentBorder,
    this.elevated = false,
    this.semanticLabel,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final interactive = widget.onTap != null;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final body = AnimatedContainer(
      duration: Duration(milliseconds: reduceMotion ? 0 : 160),
      curve: Curves.easeOut,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.elevated ? t.cardElevated : t.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: _hovered && interactive
              ? (widget.accentBorder ?? t.accent).withValues(alpha: 0.55)
              : (widget.accentBorder ?? t.border),
        ),
        boxShadow: _hovered && interactive
            ? [
                BoxShadow(
                  color: t.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    if (!interactive) {
      return widget.semanticLabel != null
          ? Semantics(label: widget.semanticLabel, child: body)
          : body;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// A single key figure. Used for the dashboard KPI row.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  /// Semantic tint. Defaults to the theme accent.
  final Color? tone;
  final String? caption;
  final bool loading;
  final VoidCallback? onTap;
  final bool compact;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
    this.caption,
    this.loading = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tint = tone ?? t.accent;

    return PremiumCard(
      onTap: onTap,
      semanticLabel: loading ? '$label, loading' : '$label: $value',
      padding: EdgeInsets.all(compact ? AppTokens.space3 : AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Icon(icon, color: tint, size: compact ? 15 : 17),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(Icons.arrow_outward_rounded,
                    size: 14, color: t.subtleForeground),
            ],
          ),
          SizedBox(height: compact ? AppTokens.space2 : AppTokens.space3),
          if (loading)
            _Bar(width: 78, height: compact ? 15 : 19)
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: t.foreground,
                  fontSize: compact ? 15 : 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.mutedForeground,
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (caption != null && !loading) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.subtleForeground, fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width, height;
  const _Bar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.tokens.skeleton,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

/// Section divider with the gold rule that anchors the visual hierarchy.
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: description == null ? 16 : 30,
            decoration: BoxDecoration(
              color: t.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: t.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style:
                        TextStyle(color: t.mutedForeground, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
