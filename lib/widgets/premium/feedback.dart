import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

enum StatusTone { neutral, success, warning, danger, info, accent }

/// Pill label for record state — used in tables and detail headers.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dense;

  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  Color _color(AppTokens t) => switch (tone) {
        StatusTone.success => t.success,
        StatusTone.warning => t.warning,
        StatusTone.danger => t.danger,
        StatusTone.info => t.info,
        StatusTone.accent => t.accent,
        StatusTone.neutral => t.mutedForeground,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = _color(t);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: c.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: c),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

enum ToastKind { success, error, warning, info }

/// The single notification channel for the app (Phase 15).
///
/// Built on the existing `ScaffoldMessenger` so it does not introduce a second
/// notification system alongside Flutter's.
class AppToast {
  const AppToast._();

  static void success(BuildContext context, String message) =>
      _show(context, message, ToastKind.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, ToastKind.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message, ToastKind.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message, ToastKind.info);

  static void _show(BuildContext context, String message, ToastKind kind) {
    final t = context.tokens;
    final (color, icon) = switch (kind) {
      ToastKind.success => (t.success, Icons.check_circle_rounded),
      ToastKind.error => (t.danger, Icons.error_rounded),
      ToastKind.warning => (t.warning, Icons.warning_rounded),
      ToastKind.info => (t.info, Icons.info_rounded),
    };

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: Duration(seconds: kind == ToastKind.error ? 5 : 3),
          backgroundColor: t.cardElevated,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          margin: const EdgeInsets.all(AppTokens.space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
          content: Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: t.foreground,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Confirmation for destructive actions (Phase 13). Returns `true` only on
/// explicit confirmation.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    this.icon,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: context.tokens.overlay,
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  /// Convenience wrapper for delete flows.
  static Future<bool> confirmDelete(
    BuildContext context, {
    required String entity,
    String? detail,
  }) {
    return show(
      context,
      title: 'Delete $entity?',
      message: detail ??
          'This will permanently remove this $entity. This action cannot be '
              'undone.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = destructive ? t.danger : t.accent;

    return AlertDialog(
      backgroundColor: t.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        side: BorderSide(color: t.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
          AppTokens.space6, AppTokens.space6, AppTokens.space6, 0),
      contentPadding: const EdgeInsets.fromLTRB(
          AppTokens.space6, AppTokens.space3, AppTokens.space6, 0),
      actionsPadding: const EdgeInsets.all(AppTokens.space5),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Icon(
              icon ?? (destructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
              color: tone,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: t.foreground,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          color: t.mutedForeground,
          fontSize: 13.5,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: t.mutedForeground),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? t.danger : t.primary,
            foregroundColor: destructive ? Colors.white : t.onPrimary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
