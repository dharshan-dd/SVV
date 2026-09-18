import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'premium_card.dart';
import 'states.dart';

/// One column definition, shared by the table and the mobile card renderer.
class PremiumColumn<T> {
  final String label;
  final Widget Function(T row) cell;

  /// Plain-text value used for the mobile card layout and for sorting.
  final String Function(T row)? text;
  final bool numeric;
  final double? width;

  /// Hidden on narrow screens when false — keeps mobile cards readable.
  final bool primary;

  const PremiumColumn({
    required this.label,
    required this.cell,
    this.text,
    this.numeric = false,
    this.width,
    this.primary = true,
  });
}

/// Table that reshapes itself for the viewport (Phase 11 / 18).
///
/// Wide screens get a real table with sticky-styled headers, hover states and
/// subtle row separators. Narrow screens get stacked cards instead, because a
/// squeezed six-column table is unreadable on a phone.
class PremiumDataTable<T> extends StatefulWidget {
  final List<PremiumColumn<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;
  final Widget? emptyState;
  final int? rowsPerPage;

  /// Optional leading title shown inside the card frame.
  final String? caption;

  const PremiumDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.emptyState,
    this.rowsPerPage,
    this.caption,
  });

  @override
  State<PremiumDataTable<T>> createState() => _PremiumDataTableState<T>();
}

class _PremiumDataTableState<T> extends State<PremiumDataTable<T>> {
  int _page = 0;
  int? _hoveredRow;

  @override
  void didUpdateWidget(covariant PremiumDataTable<T> old) {
    super.didUpdateWidget(old);
    if (old.rows.length != widget.rows.length) _page = 0;
  }

  List<T> get _visibleRows {
    final per = widget.rowsPerPage;
    if (per == null || widget.rows.length <= per) return widget.rows;
    final start = _page * per;
    return widget.rows.skip(start).take(per).toList();
  }

  int get _pageCount {
    final per = widget.rowsPerPage;
    if (per == null || per <= 0) return 1;
    return (widget.rows.length / per).ceil().clamp(1, 1 << 30);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return widget.emptyState ??
          const EmptyState(
            title: 'No records found',
            description: 'Try adjusting your search or filters.',
          );
    }

    final narrow = MediaQuery.sizeOf(context).width < 760;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (narrow) _mobileCards(context) else _wideTable(context),
        if (_pageCount > 1) ...[
          const SizedBox(height: AppTokens.space4),
          _pagination(context),
        ],
      ],
    );
  }

  // ── Wide ────────────────────────────────────────────────────────────────
  Widget _wideTable(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.caption != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(AppTokens.space5,
                  AppTokens.space4, AppTokens.space5, AppTokens.space3),
              child: Text(
                widget.caption!,
                style: TextStyle(
                  color: t.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          // Header
          Container(
            color: t.cardElevated,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space5, vertical: AppTokens.space3),
            child: Row(
              children: [
                for (final col in widget.columns)
                  _cellBox(
                    col,
                    Text(
                      col.label.toUpperCase(),
                      textAlign: col.numeric ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        color: t.mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          // Rows
          ..._visibleRows.asMap().entries.map((e) {
            final i = e.key;
            final row = e.value;
            final hovered = _hoveredRow == i;
            return MouseRegion(
              cursor: widget.onRowTap != null
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              onEnter: (_) => setState(() => _hoveredRow = i),
              onExit: (_) => setState(() => _hoveredRow = null),
              child: GestureDetector(
                onTap: widget.onRowTap == null
                    ? null
                    : () => widget.onRowTap!(row),
                child: Container(
                  color: hovered ? t.cardElevated : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space5, vertical: AppTokens.space4),
                  child: Row(
                    children: [
                      for (final col in widget.columns)
                        _cellBox(
                          col,
                          Align(
                            alignment: col.numeric
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: col.cell(row),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _cellBox(PremiumColumn<T> col, Widget child) {
    return col.width != null
        ? SizedBox(width: col.width, child: child)
        : Expanded(child: child);
  }

  // ── Narrow ──────────────────────────────────────────────────────────────
  Widget _mobileCards(BuildContext context) {
    final t = context.tokens;
    final cols = widget.columns.where((c) => c.primary).toList();
    final head = cols.isNotEmpty ? cols.first : widget.columns.first;
    final rest = cols.skip(1).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _visibleRows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space3),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              onTap: widget.onRowTap == null
                  ? null
                  : () => widget.onRowTap!(row),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: TextStyle(
                            color: t.foreground,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                          child: head.cell(row),
                        ),
                      ),
                      if (widget.onRowTap != null)
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: t.subtleForeground),
                    ],
                  ),
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.space3),
                    Divider(height: 1, color: t.divider),
                    const SizedBox(height: AppTokens.space3),
                    for (final col in rest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 118,
                              child: Text(
                                col.label,
                                style: TextStyle(
                                  color: t.subtleForeground,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: DefaultTextStyle.merge(
                                  style: TextStyle(
                                    color: t.foreground,
                                    fontSize: 13,
                                  ),
                                  child: col.cell(row),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _pagination(BuildContext context) {
    final t = context.tokens;
    final per = widget.rowsPerPage!;
    final from = _page * per + 1;
    final to = ((_page + 1) * per).clamp(0, widget.rows.length);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$from–$to of ${widget.rows.length}',
          style: TextStyle(color: t.mutedForeground, fontSize: 12.5),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous page',
              onPressed:
                  _page > 0 ? () => setState(() => _page -= 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              '${_page + 1} / $_pageCount',
              style: TextStyle(
                color: t.foreground,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: _page < _pageCount - 1
                  ? () => setState(() => _page += 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact search input sized for page headers.
class PremiumSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final double width;

  const PremiumSearchBar({
    super.key,
    this.hint = 'Search',
    required this.onChanged,
    this.controller,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final narrow = MediaQuery.sizeOf(context).width < 720;

    return SizedBox(
      width: narrow ? double.infinity : width,
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: t.foreground, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: t.subtleForeground),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }
}

/// Row of selectable filter chips.
class FilterBar extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const FilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.space2),
              child: GestureDetector(
                onTap: () => onSelect(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: o == selected
                        ? t.accent.withValues(alpha: 0.14)
                        : t.card,
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusPill),
                    border: Border.all(
                      color: o == selected ? t.accent : t.border,
                    ),
                  ),
                  child: Text(
                    o,
                    style: TextStyle(
                      color: o == selected ? t.accent : t.mutedForeground,
                      fontSize: 12.5,
                      fontWeight:
                          o == selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
