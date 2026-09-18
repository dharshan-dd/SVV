import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:microfinance_app/models/bag_configuration.dart';
import 'package:microfinance_app/models/collection_bag.dart';
import 'package:microfinance_app/models/daily_cash_record.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/theme/app_tokens.dart';

const _kPrimary = Color(0xFF3B82F6);
const _kGold    = Color(0xFFF59E0B);
const _kGreen   = Color(0xFF10B981);
const _kRed     = Color(0xFFEF4444);
const _kPurple  = Color(0xFF8B5CF6);

/// Resolves the screen's palette from the active [AppTokens] so that theme
/// changes (light / dark / navy / high-contrast) flow through instantly.
class _ThemeColors {
  final Color bg;
  final Color surface;
  final Color card;
  final Color border;
  final Color primary;
  final Color gold;
  final Color green;
  final Color red;
  final Color purple;
  final Color text;
  final Color subtext;

  const _ThemeColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.primary,
    required this.gold,
    required this.green,
    required this.red,
    required this.purple,
    required this.text,
    required this.subtext,
  });

  factory _ThemeColors.of(BuildContext context) {
    final t = context.tokens;
    return _ThemeColors(
      bg: t.background,
      surface: t.surface,
      card: t.card,
      border: t.border,
      primary: t.primary,
      gold: t.accent,
      green: t.success,
      red: t.danger,
      purple: t.info,
      text: t.foreground,
      subtext: t.mutedForeground,
    );
  }
}

class WeeklyDashboardScreen extends ConsumerStatefulWidget {
  const WeeklyDashboardScreen({super.key});
  @override
  ConsumerState<WeeklyDashboardScreen> createState() => _WeeklyDashboardScreenState();
}

class _WeeklyDashboardScreenState extends ConsumerState<WeeklyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late DateTime weekStart;
  late DateTime weekEnd;
  late Future<List<DailyCashRecord>> _recordsFuture;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final Set<String> _selectedBagIds = {};

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _recalcWeek();
    _loadRecords();
  }

  void _recalcWeek() {
    final today = DateTime.now();
    final offset = (today.weekday - DateTime.thursday + 7) % 7;
    weekStart = DateTime(today.year, today.month, today.day - offset);
    weekEnd = weekStart.add(const Duration(days: 6));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _loadRecords() {
    final svc = ref.read(supabaseServiceProvider);
    _recordsFuture = svc.getDailyCashRecords(
      startDate: weekStart.subtract(const Duration(days: 7)),
      endDate: weekEnd,
      bagIds: _selectedBagIds.isNotEmpty ? _selectedBagIds.toList() : null,
    );
  }

  void _changeWeek(int delta) {
    setState(() {
      weekStart = weekStart.add(Duration(days: delta * 7));
      weekEnd = weekStart.add(const Duration(days: 6));
      _loadRecords();
    });
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2);
    return Scaffold(
      backgroundColor: c.bg,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: FutureBuilder<List<DailyCashRecord>>(
                  future: _recordsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return _buildLoading();
                    }
                    if (snap.hasError) return _buildError(snap.error);

                    final records = snap.data ?? [];

                    // 1. Latest record per (bagId, entryDate) — deduplicates rows that share the same bag+date
                    final latestPerBagDate = <String, DailyCashRecord>{};
                    for (final r in records) {
                      final key = '${r.bagId}|${DateFormat('yyyy-MM-dd').format(r.entryDate)}';
                      final ex = latestPerBagDate[key];
                      if (ex == null || r.updatedAt.isAfter(ex.updatedAt)) {
                        latestPerBagDate[key] = r;
                      }
                    }
                    final deduped = latestPerBagDate.values.toList();

                    // 2. Records belonging to the current week
                    final currentWeekRecords = deduped
                        .where((r) =>
                            !r.entryDate.isBefore(weekStart) &&
                            !r.entryDate.isAfter(weekEnd))
                        .toList();

                    // 3. Running total = latest finalAmount per bag across ALL fetched records (before week)
                    //    (ordered by updatedAt so the newest record wins)
                    final latestPerBag = <String, DailyCashRecord>{};
                    for (final r in deduped) {
                      final ex = latestPerBag[r.bagId];
                      if (ex == null || r.updatedAt.isAfter(ex.updatedAt)) {
                        latestPerBag[r.bagId] = r;
                      }
                    }
                    final runningTotal = latestPerBag.values.fold(
                      0.0,
                      (s, r) => s + r.finalAmount,
                    );

                    // 4. Week Final = sum of the latest record per bag within the current week
                    final latestPerBagInWeek = <String, DailyCashRecord>{};
                    for (final r in currentWeekRecords) {
                      final ex = latestPerBagInWeek[r.bagId];
                      if (ex == null || r.updatedAt.isAfter(ex.updatedAt)) {
                        latestPerBagInWeek[r.bagId] = r;
                      }
                    }
                    final weekFinal = latestPerBagInWeek.values.fold(
                      0.0,
                      (s, r) => s + r.finalAmount,
                    );

                    final totalCollected = currentWeekRecords.fold(0.0, (s, r) => s + r.collectedAmount);
                    final totalExpense = currentWeekRecords.fold(0.0, (s, r) => s + r.expense);
                    final totalGiven = currentWeekRecords.fold(0.0, (s, r) => s + r.adapAmount);
                    final totalGpay = currentWeekRecords.fold(0.0, (s, r) => s + r.rrGpayAmount);

                    // Build lookup of all deduped records by date
                    final dedupedByDate = <String, List<DailyCashRecord>>{};
                    for (final r in deduped) {
                      final key = DateFormat('yyyy-MM-dd').format(r.entryDate);
                      dedupedByDate.putIfAbsent(key, () => []).add(r);
                    }

                    final currentWeekDates = <String>{};
                    final recordsByDate = <String, List<DailyCashRecord>>{};
                    for (final r in currentWeekRecords) {
                      final key = DateFormat('yyyy-MM-dd').format(r.entryDate);
                      currentWeekDates.add(key);
                      recordsByDate.putIfAbsent(key, () => []).add(r);
                    }

                    // For days without current week records, show same day's data from last week
                    for (int i = 0; i < 7; i++) {
                      final date = weekStart.add(Duration(days: i));
                      final key = DateFormat('yyyy-MM-dd').format(date);
                      if (!currentWeekDates.contains(key)) {
                        final prevDate = date.subtract(const Duration(days: 7));
                        final prevKey = DateFormat('yyyy-MM-dd').format(prevDate);
                        final prevRecords = dedupedByDate[prevKey];
                        if (prevRecords != null && prevRecords.isNotEmpty) {
                          recordsByDate[key] = prevRecords;
                        }
                      }
                    }

                    final daysRecorded = currentWeekDates.length;

                    // Carryover not shown — days without records show last week's
                    // same-day data above (if available) or "Add" button
                    final carryoverByDate = <String, double>{};

return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const SizedBox(height: 16),
                          _weekNav(c),
                          const SizedBox(height: 16),
                          _buildBagFilter(c, fmt),
                          const SizedBox(height: 16),
                          _summaryRow(fmt, weekFinal, totalCollected, totalExpense, totalGiven, totalGpay, daysRecorded, c),
                          if (_selectedBagIds.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _perBagAnalysis(currentWeekRecords, fmt, c),
                          ],
                          const SizedBox(height: 24),
                          _sectionLabel('Day Records', c),
                          const SizedBox(height: 12),
                          for (int i = 0; i < 7; i++) ...[
                            Builder(builder: (_) {
                              final date = weekStart.add(Duration(days: i));
                              final key = DateFormat('yyyy-MM-dd').format(date);
                              return _DayCard(
                                date: date,
                                records: recordsByDate[key] ?? const [],
                                carryover: carryoverByDate[key],
                                fmt: fmt,
                                c: c,
                                onTap: () async {
                                  final dateStr = DateFormat('yyyy-MM-dd').format(date);
                                  await context.push('/day-record-entry?date=$dateStr');
                                  if (mounted) setState(() => _loadRecords());
                                },
                              );
                            }),
                          ],
                        ]),
                    );
                    }
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'addWeeklyRecord',
              onPressed: _showAddRecordDialog,
              icon: const Icon(Icons.add_rounded, color: c.text),
              label: const Text('Record', style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
              backgroundColor: c.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBagFilter(_ThemeColors c, NumberFormat fmt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showBagSelector(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Row(children: [
                const Icon(Icons.filter_alt_rounded, color: c.subtext, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedBagIds.isEmpty
                        ? 'Select bags for analysis'
                        : '${_selectedBagIds.length} bag(s) selected',
                    style: const TextStyle(color: c.text, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: c.subtext, size: 18),
                ]),
                )),
                          ),
        if (_selectedBagIds.isNotEmpty)
          TextButton(
            onPressed: () => setState(() { _selectedBagIds.clear(); _loadRecords(); }),
            child: const Text('Clear', style: TextStyle(color: c.subtext, fontSize: 12)),
          ),
      ]),
    if (_selectedBagIds.isNotEmpty)
      Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (final bagId in _selectedBagIds)
              FutureBuilder<String>(
                future: _getBagName(bagId),
                builder: (context, snap) {
                  final name = snap.data ?? bagId.substring(0, 8);
                  return Chip(
                    label: Text(name, style: const TextStyle(color: c.text, fontSize: 11)),
                    backgroundColor: c.primary.withValues(alpha: 0.12),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    onDeleted: () => setState(() { _selectedBagIds.remove(bagId); _loadRecords(); }),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14, color: c.text),
                  );
                },
              ),
          ]),
        ),
    ]);
  }

  Future<String> _getBagName(String bagId) async {
    try {
      final svc = ref.read(supabaseServiceProvider);
      final bags = await svc.getCollectionBags();
      final bag = bags.firstWhere((b) => b.id == bagId, orElse: () => CollectionBag(id: bagId, name: bagId, createdAt: DateTime.now(), updatedAt: DateTime.now()));
      return bag.name;
    } catch (e) {
      return bagId;
    }
  }

  void _showBagSelector(_ThemeColors c) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: c.card,
              title: const Text('Select Bags', style: TextStyle(color: c.text)),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Consumer(
                  builder: (context, ref, _) {
                    final bagsAsync = ref.watch(collectionBagsProvider);
                    return bagsAsync.when(
                      data: (bags) => Scrollable(
                        viewportBuilder: (ctx, _) => ListView(
                          children: bags.map((b) => CheckboxListTile(
                            title: Text(b.name, style: const TextStyle(color: c.text, fontSize: 13)),
                            value: _selectedBagIds.contains(b.id),
                            onChanged: (v) => setDialogState(() {
                              if (v != null && v) {
                                _selectedBagIds.add(b.id);
                              } else {
                                _selectedBagIds.remove(b.id);
                              }
          }),
                            fillColor: WidgetStateProperty.all(c.primary),
                            side: const BorderSide(color: c.border),
                          )).toList(),
                        ),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e', style: TextStyle(color: c.red)),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: c.subtext))),
                ElevatedButton(onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _loadRecords());
                }, child: const Text('Apply')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _perBagAnalysis(List<DailyCashRecord> records, NumberFormat fmt, _ThemeColors c) {
    final bagIds = _selectedBagIds.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sectionLabel('Per-Bag Analysis'),
      const SizedBox(height: 12),
      for (final bagId in bagIds)
        FutureBuilder<String>(
          future: _getBagName(bagId),
          builder: (context, nameSnap) {
            final bagName = nameSnap.data ?? 'Bag';
            final bagRecords = records.where((r) => r.bagId == bagId).toList();
            if (bagRecords.isEmpty) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                child: Text('$bagName: No records', style: TextStyle(color: c.subtext, fontSize: 12)),
              );
            }
            // Deduplicate: keep the latest record per entryDate for this bag
            final byDate = <String, DailyCashRecord>{};
            for (final r in bagRecords) {
              final key = DateFormat('yyyy-MM-dd').format(r.entryDate);
              final ex = byDate[key];
              if (ex == null || r.updatedAt.isAfter(ex.updatedAt)) byDate[key] = r;
            }
            final sortedBag = byDate.values.toList()
              ..sort((a, b) => a.entryDate.compareTo(b.entryDate));

            // Week Final = latest finalAmount across all fetched records for this bag
            double bagFinal = 0.0;
            if (sortedBag.isNotEmpty) bagFinal = sortedBag.last.finalAmount;

            // Count only distinct dates that fall within the current week
            final daysInWeek = sortedBag
                .where((r) =>
                    !r.entryDate.isBefore(weekStart) &&
                    !r.entryDate.isAfter(weekEnd))
                .length;

            final bagCollected = bagRecords.fold(0.0, (s, r) => s + r.collectedAmount);
            final bagExpense = bagRecords.fold(0.0, (s, r) => s + r.expense);
            final bagGiven = bagRecords.fold(0.0, (s, r) => s + r.adapAmount);
            final bagGpay = bagRecords.fold(0.0, (s, r) => s + r.rrGpayAmount);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(bagName, style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _summaryRow(fmt, bagFinal, bagCollected, bagExpense, bagGiven, bagGpay, daysInWeek),
              ]),
            );
          },
        ),
    ]);
  }

  Widget _buildAppBar(_ThemeColors c) => SliverAppBar(
    pinned: true,
    backgroundColor: c.surface,
    foregroundColor: c.text,
    elevation: 0,
    title: const Text('Weekly Dashboard', style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 18)),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh_rounded, color: c.subtext),
        onPressed: () => setState(() { _loadRecords(); _animCtrl.forward(from: 0); }),
      ),
    ],
  );

  Widget _weekNav(_ThemeColors c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
    child: Row(children: [
      _NavBtn(icon: Icons.chevron_left_rounded, onTap: () => _changeWeek(-1)),
      Expanded(child: Column(children: [
        Text(
          '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM yyyy').format(weekEnd)}',
          style: const TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text('Week ${_weekNumber(weekStart)}', style: const TextStyle(color: c.subtext, fontSize: 11)),
      ])),
      _NavBtn(icon: Icons.chevron_right_rounded, onTap: () => _changeWeek(1)),
    ]),
  );

  int _weekNumber(DateTime d) {
    final startOfYear = DateTime(d.year, 1, 1);
    return ((d.difference(startOfYear).inDays + startOfYear.weekday) / 7).ceil();
  }

  Widget _summaryRow(NumberFormat fmt, double weekFinal, double collected, double expense, double given, double gpay, int days, _ThemeColors c) {
    return Column(children: [
      Row(children: [
        Expanded(child: _SummaryTile(label: 'Week Final', value: fmt.format(weekFinal), color: weekFinal >= 0 ? c.green : c.red, icon: Icons.account_balance_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryTile(label: 'Collected', value: fmt.format(collected), color: c.primary, icon: Icons.payments_rounded)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _SummaryTile(label: 'Amount Given', value: fmt.format(given), color: c.gold, icon: Icons.account_balance_wallet_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryTile(label: 'Expenses', value: fmt.format(expense), color: c.red, icon: Icons.receipt_rounded)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _SummaryTile(label: 'Days Recorded', value: '$days / 7', color: c.gold, icon: Icons.calendar_today_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryTile(label: 'GPay', value: fmt.format(gpay), color: c.purple, icon: Icons.swap_horiz_rounded)),
      ]),
    ]);
  }

  Widget _sectionLabel(String text, _ThemeColors c) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);

  Widget _buildLoading(_ThemeColors c) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: List.generate(4, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(height: 80, decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14))),
    ))),
  );

  Widget _buildError(Object? error, _ThemeColors c) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: c.red),
      const SizedBox(height: 16),
      const Text('Failed to load records', style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('$error', style: const TextStyle(color: c.subtext, fontSize: 12), textAlign: TextAlign.center),
    ]),
  );

  void _showAddRecordDialog(_ThemeColors c) async {
    final svc = ref.read(supabaseServiceProvider);
    final List<CollectionBag> bags;
    try {
      bags = await svc.getCollectionBags();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: c.red),
        );
      }
      return;
    }
    if (bags.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No bags available'), backgroundColor: c.red),
        );
      }
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final pick = ValueNotifier<String?>(null);
        return ValueListenableBuilder<String?>(
          valueListenable: pick,
          builder: (dialogCtx, picked, child) {
            return AlertDialog(
              backgroundColor: c.card,
              title: const Text('Select Bag', style: TextStyle(color: c.text)),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView(
                  children: bags.map((bag) {
                    final isSelected = picked == bag.id;
                    return Card(
                      color: isSelected ? c.primary.withValues(alpha: 0.15) : c.surface,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(bag.name, style: const TextStyle(color: c.text)),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? c.primary : c.border,
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: c.text, size: 16)
                              : null,
                        ),
                        onTap: () => pick.value = bag.id,
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, ''),
                  child: const Text('Cancel', style: TextStyle(color: c.subtext)),
                ),
                ElevatedButton(
                  onPressed: picked != null
                      ? () {
                          Navigator.pop(ctx, picked);
                        }
                      : null,
                  child: const Text('Next', style: TextStyle(color: c.text)),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null && selected.isNotEmpty) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String regionId = '';
      String modelId = '';
      try {
        final svc = ref.read(supabaseServiceProvider);
        final configs = await svc.getBagConfigurations();
        final config = configs.firstWhere((c) => c.bagId == selected, orElse: () => BagConfiguration(
          id: '', entity: '', regionId: '', modelId: '', bagId: '', frequency: '', isActive: true,
          createdAt: DateTime.now(), updatedAt: DateTime.now(), startDate: DateTime.now(), endDate: DateTime(2099),
        ));
        regionId = config.regionId;
        modelId = config.modelId;
      } catch (_) {}
      final query = {
        'date': today,
        if (regionId.isNotEmpty) 'regionId': regionId,
        if (modelId.isNotEmpty) 'modelId': modelId,
        'bagId': selected,
      };
      final queryString = query.entries.map((e) => '${e.key}=${e.value}').join('&');
      await context.push('/day-record-entry?$queryString');
      if (mounted) setState(() => _loadRecords());
    }
  }
}

class _NavBtn extends StatelessWidget {
  final _ThemeColors icon;
  final VoidCallback onTap;
  final _ThemeColors c;
  const _NavBtn({required this.icon, required this.onTap, required this.c});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: c.text, size: 20),
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final _ThemeColors c;
  const _SummaryTile({required this.label, required this.value, required this.color, required this.icon, required this.c});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: c.subtext, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
      ])),
    ]),
  );
}

class _DayCard extends StatefulWidget {
  final DateTime date;
  final List<DailyCashRecord> records;
  final double? carryover;
  final NumberFormat fmt;
  final VoidCallback onTap;
  final _ThemeColors c;
  const _DayCard({required this.date, required this.records, required this.carryover, required this.fmt, required this.onTap, required this.c});

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  @override
  Widget build(BuildContext context) {
    final hasRecord = widget.records.isNotEmpty;
    return Card(
      color: widget.c.card,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 18, color: widget.c.subtext),
          const SizedBox(width: 8),
          Expanded(child: Text(DateFormat('EEE, d MMM').format(widget.date), style: const TextStyle(color: widget.c.text, fontWeight: FontWeight.w600, fontSize: 14))),
          const SizedBox(width: 4),
          Text(hasRecord ? '${widget.records.length} record${widget.records.length > 1 ? 's' : ''}' : 'No record', style: TextStyle(color: hasRecord ? widget.c.green : widget.c.subtext, fontSize: 12, fontWeight: FontWeight.w600)),
          if (!hasRecord) ...[
            const SizedBox(width: 8),
            _CarryoverOrAddBtn(carryover: widget.carryover, fmt: widget.fmt, onTap: widget.onTap),
          ],
        ]),
        children: [
          Container(
            color: widget.c.card,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: [
              for (final r in widget.records) ...[
                _DetailRow('Collected', widget.fmt.format(r.collectedAmount), widget.c.green),
                _DetailRow('Net in Hand', widget.fmt.format(r.netAmountInHand), widget.c.green),
                _DetailRow('Expense', '− ${widget.fmt.format(r.expense)}', widget.c.red),
                _DetailRow('GPay', '− ${widget.fmt.format(r.rrGpayAmount)}', widget.c.red),
                _DetailRow('Adap', widget.fmt.format(r.adapAmount), widget.c.gold),
                _DetailRow('Other', widget.fmt.format(r.otherAmount), widget.c.subtext),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: widget.c.border)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  Text('Final', style: TextStyle(color: widget.c.subtext, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(widget.fmt.format(r.finalAmount), style: TextStyle(color: r.finalAmount >= 0 ? widget.c.green : widget.c.red, fontWeight: FontWeight.w900, fontSize: 16)),
                ]),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final dateStr = DateFormat('yyyy-MM-dd').format(r.entryDate);
                      context.push('/day-record-entry?date=$dateStr&regionId=${r.regionId}&modelId=${r.modelId}&bagId=${r.bagId}');
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.c.primary.withValues(alpha: 0.15),
                      foregroundColor: widget.c.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (widget.records.length > 1) const Divider(height: 16, color: widget.c.border),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DetailRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: c.subtext, fontSize: 12)),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _CarryoverOrAddBtn extends StatelessWidget {
  final double? carryover;
  final NumberFormat fmt;
  final VoidCallback onTap;
  const _CarryoverOrAddBtn({this.carryover, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (carryover != null && carryover! > 0.005) {
      return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(fmt.format(carryover!)),
        const Text('Last Week', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
      ]);
    }
    return _AddBtn(onTap: onTap);
  }
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  final _ThemeColors c;
  const _AddBtn({required this.onTap, required this.c});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add_rounded, color: c.primary, size: 14),
        SizedBox(width: 4),
        Text('Add', style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

