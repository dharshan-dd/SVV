import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'premium_card.dart';

/// Shimmering placeholder block. Respects reduced-motion by falling back to a
/// static fill rather than animating.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? radius;

  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = widget.radius ?? BorderRadius.circular(6);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: t.skeleton, borderRadius: radius),
      );
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            t.skeleton,
            t.skeleton.withValues(alpha: 0.45),
            _c.value,
          ),
          borderRadius: radius,
        ),
      ),
    );
  }
}

/// Skeleton arranged to match a list of cards — shown instead of a blank
/// screen while data loads.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SkeletonList({super.key, this.count = 5, this.itemHeight = 72});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTokens.space5),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space3),
      itemBuilder: (_, __) => Skeleton(
        height: itemHeight,
        radius: BorderRadius.circular(AppTokens.radiusLg),
      ),
    );
  }
}

/// Centred spinner with an optional message.
class LoadingState extends StatelessWidget {
  final String? message;
  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: t.accent),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTokens.space4),
            Text(
              message!,
              style: TextStyle(color: t.mutedForeground, fontSize: 13.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown when a query legitimately returns nothing.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 27, color: t.accent),
              ),
              const SizedBox(height: AppTokens.space5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.foreground,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: AppTokens.space2),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.mutedForeground,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppTokens.space6),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// User-facing error surface.
///
/// Raw exception text is shown only in debug builds — in release the user sees
/// a plain-language message while the detail still goes to the console via
/// [debugPrint], preserving debuggability without leaking internals.
class ErrorStateView extends StatelessWidget {
  final Object? error;
  final String title;
  final String? description;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    this.error,
    this.title = 'Something went wrong',
    this.description,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (error != null) {
      debugPrint('[SVV] ErrorStateView: $error');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: PremiumCard(
            accentBorder: t.danger.withValues(alpha: 0.35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: t.danger.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline_rounded,
                      color: t.danger, size: 25),
                ),
                const SizedBox(height: AppTokens.space4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  description ??
                      'We could not load this information. Please check your '
                          'connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.mutedForeground,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                if (kDebugMode && error != null) ...[
                  const SizedBox(height: AppTokens.space4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTokens.space3),
                    decoration: BoxDecoration(
                      color: t.cardElevated,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusSm),
                      border: Border.all(color: t.border),
                    ),
                    child: Text(
                      '$error',
                      style: TextStyle(
                        color: t.subtleForeground,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: AppTokens.space5),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Try again'),
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

/// Wraps a [Future] so every screen gets loading, error and empty handling
/// with one widget instead of hand-rolled `FutureBuilder` branches.
class AsyncBoundary<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final Widget? loading;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;

  const AsyncBoundary({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.isEmpty,
    this.empty,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return loading ?? const SkeletonList();
        }
        if (snap.hasError) {
          return ErrorStateView(error: snap.error, onRetry: onRetry);
        }
        final data = snap.data;
        if (data == null) {
          return empty ??
              const EmptyState(title: 'No data available');
        }
        if (isEmpty?.call(data) ?? false) {
          return empty ??
              const EmptyState(
                title: 'Nothing here yet',
                description: 'Records you add will appear in this list.',
              );
        }
        return builder(data);
      },
    );
  }
}
