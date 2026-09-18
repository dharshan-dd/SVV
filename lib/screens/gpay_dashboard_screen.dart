import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:microfinance_app/models/daily_cash_record.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/theme/app_tokens.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';

/// GPay Tracking dashboard.
///
/// This screen enters NO data of its own. Every figure here is derived,
/// automatically, from the GPay amount already captured on each Weekly /
/// Day Record (`rrGpayAmount`). Editing or adding a day record invalidates
/// `dailyCashRecordsProvider` (see day_record_entry_screen._submit), so the
/// totals below recompute the next time this screen is built — no manual
/// re-entry, no separate ledger to keep in sync.
enum _GPayPeriod { thisWeek, thisMonth, thisYear, allTime }

extension on _GPayPeriod {
  String get label => switch (this) {
        _GPayPeriod.thisWeek => 'This Week',
        _GPayPeriod.thisMonth => 'This Month',
        _GPayPeriod.thisYear => 'This Year',
        _GPayPeriod.allTime => 'All Time',
      };
}

/// Thursday-start week, matching WeeklyDashboardScreen so "Week 1/2/3…"
/// means the same thing everywhere in the app.
DateTime _weekStartOf(DateTime d) {
  final offset = (d.weekday - DateTime.thursday + 7) % 7;
  return DateTime(d.year, d.month, d.day - offset);
}

class GPayDashboardScreen extends ConsumerStatefulWidget {
  const GPayDashboardScreen({super.key});

  @override
  ConsumerState<GPayDashboardScreen> createState() => _GPayDashboardScreenState();
}

class _GPayDashboardScreenState extends ConsumerState<GPayDashboardScreen> {
  _GPayPeriod _period = _GPayPeriod.thisMonth;
  String? _selectedBagId; // null = All Bags

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fmt = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0);
    final bagsAsync = ref.watch(collectionBagsProvider);
    final recordsAsync = ref.watch(dailyCashRecordsProvider);
    final configsAsync = ref.watch(bagConfigurationsProvider);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        title: Text('GPay Tracking',
            style: TextStyle(color: t.foreground, fontWeight: FontWeight.w700)),
        backgroundColor: t.surface,
        foregroundColor: t.foreground,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: t.accent,
        backgroundColor: t.card,
        onRefresh: () async {
          ref.invalidate(collectionBagsProvider);
          ref.invalidate(bagConfigurationsProvider);
          ref.invalidate(dailyCashRecordsProvider);
        },
        child: bagsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _errorView(t, e),
          data: (bags) => configsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _errorView(t, e),
            data: (configs) => recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _errorView(t, e),
              data: (allRecords) {
                final activeBagIds = configs
                    .where((c) => c.isActive && c.regionId.isNotEmpty)
                    .map((c) => c.bagId)
                    .toSet();
                final bagNames = {for (final b in bags) b.id: b.name};
                final activeBags = bags.where((b) => activeBagIds.contains(b.id)).toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                // Only one row per (bag, day) — if a day was edited more than
                // once, count its GPay amount once, using the latest save.
                final dedupKeyed = <String, DailyCashRecord>{};
                for (final r in allRecords) {
                  final key = '${r.bagId}_${DateFormat('yyyy-MM-dd').format(r.entryDate)}';
                  final existing = dedupKeyed[key];
                  if (existing == null || r.updatedAt.isAfter(existing.updatedAt)) {
                    dedupKeyed[key] = r;
                  }
                }
                final gpayRecords =
                    dedupKeyed.values.where((r) => r.rrGpayAmount > 0).toList();

                final now = DateTime.now();
                final weekStart = _weekStartOf(now);
                final weekEnd = weekStart.add(const Duration(days: 6));
                final monthStart = DateTime(now.year, now.month, 1);

                double sumWhere(bool Function(DailyCashRecord) test) =>
                    gpayRecords.where(test).fold(0.0, (s, r) => s + r.rrGpayAmount);

                final totalAllTime = sumWhere((_) => true);
                final totalThisWeek = sumWhere((r) =>
                    !r.entryDate.isBefore(weekStart) && !r.entryDate.isAfter(weekEnd));
                final totalThisMonth = sumWhere((r) => !r.entryDate.isBefore(monthStart));

                bool inPeriod(DailyCashRecord r) => switch (_period) {
                      _GPayPeriod.thisWeek => !r.entryDate.isBefore(weekStart) &&
                          !r.entryDate.isAfter(weekEnd),
                      _GPayPeriod.thisMonth => !r.entryDate.isBefore(monthStart),
                      _GPayPeriod.thisYear => r.entryDate.year == now.year,
                      _GPayPeriod.allTime => true,
                    };

                final periodRecords = gpayRecords
                    .where(inPeriod)
                    .where((r) => _selectedBagId == null || r.bagId == _selectedBagId)
                    .toList();

                // Bag-wise totals for the selected period.
                final bagTotals = <String, double>{};
                final bagWeekly = <String, Map<DateTime, double>>{};
                for (final r in periodRecords) {
                  bagTotals.update(r.bagId, (v) => v + r.rrGpayAmount,
                      ifAbsent: () => r.rrGpayAmount);
                  final ws = _weekStartOf(r.entryDate);
                  final weekMapForBag = bagWeekly.putIfAbsent(r.bagId, () => {});
                  weekMapForBag.update(ws, (v) => v + r.rrGpayAmount,
                      ifAbsent: () => r.rrGpayAmount);
                }
                final bagTotalsSorted = bagTotals.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                // Week -> bag -> amount, for the "Weekly GPay Records" list.
                final weekMap = <DateTime, Map<String, double>>{};
                for (final r in periodRecords) {
                  final ws = _weekStartOf(r.entryDate);
                  final bagsForWeek = weekMap.putIfAbsent(ws, () => {});
                  bagsForWeek.update(r.bagId, (v) => v + r.rrGpayAmount,
                      ifAbsent: () => r.rrGpayAmount);
                }
                final weeksSorted = weekMap.keys.toList()..sort((a, b) => b.compareTo(a));
                final periodTotal = periodRecords.fold(0.0, (s, r) => s + r.rrGpayAmount);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    Text(
                      'Automatically tracked from Weekly / Day Collection Records',
                      style: TextStyle(color: t.mutedForeground, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // ── Fixed headline figures ──────────────────────────
                    Row(children: [
                      Expanded(
                          child: _StatTile(
                              label: 'Total GPay (All Time)',
                              value: fmt.format(totalAllTime),
                              color: t.accent,
                              icon: Icons.account_balance_rounded)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatTile(
                              label: 'This Week',
                              value: fmt.format(totalThisWeek),
                              color: t.success,
                              icon: Icons.calendar_view_week_rounded)),
                    ]),
                    const SizedBox(height: 10),
                    _StatTile(
                        label: 'This Month',
                        value: fmt.format(totalThisMonth),
                        color: t.info,
                        icon: Icons.calendar_month_rounded,
                        wide: true),

                    const SizedBox(height: 20),

                    // ── Filters ──────────────────────────────────────────
                    Row(children: [
                      Expanded(
                        child: _FilterDropdown<_GPayPeriod>(
                          value: _period,
                          items: _GPayPeriod.values,
                          labelOf: (p) => p.label,
                          onChanged: (v) => setState(() => _period = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterDropdown<String?>(
                          value: _selectedBagId,
                          items: [null, ...activeBags.map((b) => b.id)],
                          labelOf: (id) => id == null ? 'All Bags' : (bagNames[id] ?? id),
                          onChanged: (v) => setState(() => _selectedBagId = v),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _sectionLabel(t, 'GPay by Collection Bag'),
                    const SizedBox(height: 4),
                    Text(
                      '${_period.label} · ${fmt.format(periodTotal)} total',
                      style: TextStyle(color: t.mutedForeground, fontSize: 11.5),
                    ),
                    const SizedBox(height: 12),

                    if (bagTotalsSorted.isEmpty)
                      _emptyNote(t, 'No GPay recorded for this period yet.')
                    else
                      for (final e in bagTotalsSorted)
                        _BagGPayCard(
                          bagName: bagNames[e.key] ?? e.key,
                          total: e.value,
                          weekly: bagWeekly[e.key] ?? const {},
                          fmt: fmt,
                        ),

                    const SizedBox(height: 24),
                    _sectionLabel(t, 'Weekly GPay Records'),
                    const SizedBox(height: 12),

                    if (weeksSorted.isEmpty)
                      _emptyNote(t, 'No weekly GPay activity for this period yet.')
                    else
                      for (final ws in weeksSorted)
                        _WeekGPayCard(
                          weekStart: ws,
                          bagAmounts: weekMap[ws]!,
                          bagNames: bagNames,
                          fmt: fmt,
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorView(AppTokens t, Object? e) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e',
              style: TextStyle(color: t.danger), textAlign: TextAlign.center),
        ),
      );

  Widget _sectionLabel(AppTokens t, String text) => Row(children: [
        Container(
            width: 3,
            height: 16,
            decoration:
                BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(color: t.foreground, fontSize: 14, fontWeight: FontWeight.w700)),
      ]);

  Widget _emptyNote(AppTokens t, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Text(text, style: TextStyle(color: t.mutedForeground, fontSize: 12.5)),
      );
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final bool wide;
  const _StatTile(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon,
      this.wide = false});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style:
                      TextStyle(color: t.foreground, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.mutedForeground, fontSize: 10.5)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  const _FilterDropdown(
      {required this.value,
      required this.items,
      required this.labelOf,
      required this.onChanged,
      super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: t.card,
          iconEnabledColor: t.mutedForeground,
          style: TextStyle(color: t.foreground, fontSize: 13),
          items: items
              .map((v) => DropdownMenuItem<T>(
                    value: v,
                    child: Text(labelOf(v),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.foreground, fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) {
            onChanged(v as T);
          },
        ),
      ),
    );
  }
}

class _BagGPayCard extends StatefulWidget {
  final String bagName;
  final double total;
  final Map<DateTime, double> weekly; // weekStart -> amount
  final NumberFormat fmt;
  const _BagGPayCard(
      {required this.bagName, required this.total, required this.weekly, required this.fmt});

  @override
  State<_BagGPayCard> createState() => _BagGPayCardState();
}

class _BagGPayCardState extends State<_BagGPayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final weeksDesc = widget.weekly.keys.toList()..sort((a, b) => b.compareTo(a));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.swap_horiz_rounded, color: t.accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.bagName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Text(widget.fmt.format(widget.total),
                  style: TextStyle(color: t.accent, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: t.subtleForeground,
                  size: 20),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Divider(height: 1, color: t.divider),
              const SizedBox(height: 8),
              Text('Weekly History',
                  style: TextStyle(
                      color: t.mutedForeground, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (final ws in weeksDesc)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                        '${DateFormat('d MMM').format(ws)} – ${DateFormat('d MMM').format(ws.add(const Duration(days: 6)))}',
                        style: TextStyle(color: t.mutedForeground, fontSize: 12)),
                    Text(widget.fmt.format(widget.weekly[ws]),
                        style: TextStyle(
                            color: t.foreground, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ]),
                ),
              Divider(height: 16, color: t.divider),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total',
                    style: TextStyle(
                        color: t.mutedForeground, fontSize: 12.5, fontWeight: FontWeight.w700)),
                Text(widget.fmt.format(widget.total),
                    style:
                        TextStyle(color: t.accent, fontSize: 14, fontWeight: FontWeight.w900)),
              ]),
            ]),
          ),
      ]),
    );
  }
}

class _WeekGPayCard extends StatelessWidget {
  final DateTime weekStart;
  final Map<String, double> bagAmounts; // bagId -> amount
  final Map<String, String> bagNames;
  final NumberFormat fmt;
  const _WeekGPayCard(
      {required this.weekStart,
      required this.bagAmounts,
      required this.bagNames,
      required this.fmt});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final rows = bagAmounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = bagAmounts.values.fold(0.0, (s, v) => s + v);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM yyyy').format(weekEnd)}',
          style: TextStyle(color: t.foreground, fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final e in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(bagNames[e.key] ?? e.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.mutedForeground, fontSize: 12.5)),
              Text(fmt.format(e.value),
                  style: TextStyle(
                      color: t.foreground, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(height: 1, color: t.divider),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Week Total',
              style: TextStyle(color: t.foreground, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(fmt.format(total),
              style: TextStyle(color: t.accent, fontSize: 15, fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }
}
