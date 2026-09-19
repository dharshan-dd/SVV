import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:microfinance_app/models/bag_configuration.dart';
import 'package:microfinance_app/models/collection_bag.dart';
import 'package:microfinance_app/models/daily_cash_record.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';

const _kBg      = Color(0xFF0A0E1A);
const _kSurface = Color(0xFF111827);
const _kCard    = Color(0xFF1C2333);
const _kBorder  = Color(0xFF2A3347);
const _kPrimary = Color(0xFF3B82F6);
const _kGold    = Color(0xFFF59E0B);
const _kGreen   = Color(0xFF10B981);
const _kRed     = Color(0xFFEF4444);
const _kPurple  = Color(0xFF8B5CF6);
const _kText    = Color(0xFFF1F5F9);
const _kSubtext = Color(0xFF94A3B8);

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
      backgroundColor: _kBg,
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
                    final sortedByUpdated = [...records]
                      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

                    final currentWeekRecords = sortedByUpdated.where((r) =>
                        !r.entryDate.isBefore(weekStart) && !r.entryDate.isAfter(weekEnd)
                    ).toList();

                    final latestPerBag = <String, DailyCashRecord>{};
                    for (final r in sortedByUpdated) {
                      if (!r.entryDate.isBefore(weekStart) && !r.entryDate.isAfter(weekEnd)) {
                        latestPerBag[r.bagId] = r;
                      }
                    }
                    final weekFinal = latestPerBag.values.fold(
                      0.0,
                      (s, r) => s + r.finalAmount,
                    );

                    final totalCollected = currentWeekRecords.fold(0.0, (s, r) => s + r.collectedAmount);
                    final totalAdditionalCollection = currentWeekRecords.fold(0.0, (s, r) => s + r.additionalCollection);
                    final totalExpense = currentWeekRecords.fold(0.0, (s, r) => s + r.expense);
                    final totalGiven = currentWeekRecords.fold(0.0, (s, r) => s + r.adapAmount);
                    final totalGpay = currentWeekRecords.fold(0.0, (s, r) => s + r.rrGpayAmount);
                    final totalExtraNet = currentWeekRecords.fold(0.0, (s, r) => s + r.extraNetAmount);

                    final currentWeekDates = <String>{};
                    final recordsByDate = <String, List<DailyCashRecord>>{};
                    for (final r in currentWeekRecords) {
                      final key = DateFormat('yyyy-MM-dd').format(r.entryDate);
                      currentWeekDates.add(key);
                      recordsByDate.putIfAbsent(key, () => []).add(r);
                    }
                    final daysRecorded = currentWeekDates.length;

                    final lastWeekByDate = <String, List<DailyCashRecord>>{};
                    for (int i = 0; i < 7; i++) {
                      final date = weekStart.add(Duration(days: i));
                      final key = DateFormat('yyyy-MM-dd').format(date);
                      if (!currentWeekDates.contains(key)) {
                        final lastWeekDate = date.subtract(const Duration(days: 7));
                        final lastKey = DateFormat('yyyy-MM-dd').format(lastWeekDate);
                        final lastWeekRecordsForDay = sortedByUpdated.where((r) =>
                          DateFormat('yyyy-MM-dd').format(r.entryDate) == lastKey
                        ).toList();
                        if (lastWeekRecordsForDay.isNotEmpty) {
                          lastWeekByDate[key] = lastWeekRecordsForDay;
                        }
                      }
                    }

                     return Padding(
                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                       child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                         const SizedBox(height: 16),
                         _weekNav(),
                         const SizedBox(height: 16),
                         _buildBagFilter(fmt),
                         const SizedBox(height: 16),
                           _summaryRow(fmt, weekFinal, totalCollected, totalAdditionalCollection, totalExpense, totalGiven, totalGpay, totalExtraNet, daysRecorded),
                         if (_selectedBagIds.isNotEmpty) ...[
                           const SizedBox(height: 24),
                           _perBagAnalysis(currentWeekRecords, fmt),
                         ],
                        const SizedBox(height: 24),
                        _sectionLabel('Day Records'),
                        const SizedBox(height: 12),
                        for (int i = 0; i < 7; i++) ...[
                          Builder(builder: (_) {
                            final date = weekStart.add(Duration(days: i));
                            final key = DateFormat('yyyy-MM-dd').format(date);
                            final dayRecords = lastWeekByDate[key] ?? recordsByDate[key] ?? const [];
                            return _DayCard(
                              date: date,
                              records: dayRecords,
                              isLastWeek: lastWeekByDate.containsKey(key),
                              fmt: fmt,
                               onTap: () async {
                                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                                final recs = dayRecords;
                                if (recs.isNotEmpty) {
                                  final r0 = recs.first;
                                  await context.push('/day-record-entry?date=$dateStr&regionId=${r0.regionId}&modelId=${r0.modelId}&bagId=${r0.bagId}');
                                } else {
                                  await context.push('/day-record-entry?date=$dateStr');
                                }
                                if (mounted) setState(() => _loadRecords());
                              },
                            );
                          }),
                        ],
                      ]),
                    );
                  })),
            ]),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'addWeeklyRecord',
              onPressed: _showAddRecordDialog,
              icon: const Icon(Icons.add_rounded, color: _kText),
              label: const Text('Record', style: TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBagFilter(NumberFormat fmt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showBagSelector(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Row(children: [
                const Icon(Icons.filter_alt_rounded, color: _kSubtext, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedBagIds.isEmpty
                        ? 'Select bags for analysis'
                        : '${_selectedBagIds.length} bag(s) selected',
                    style: const TextStyle(color: _kText, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: _kSubtext, size: 18),
                ]),
                )),
                          ),
        if (_selectedBagIds.isNotEmpty)
          TextButton(
            onPressed: () => setState(() { _selectedBagIds.clear(); _loadRecords(); }),
            child: const Text('Clear', style: TextStyle(color: _kSubtext, fontSize: 12)),
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
                    label: Text(name, style: const TextStyle(color: _kText, fontSize: 11)),
                    backgroundColor: _kPrimary.withValues(alpha: 0.12),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    onDeleted: () => setState(() { _selectedBagIds.remove(bagId); _loadRecords(); }),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14, color: _kText),
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

  void _showBagSelector() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: _kCard,
              title: const Text('Select Bags', style: TextStyle(color: _kText)),
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
                            title: Text(b.name, style: const TextStyle(color: _kText, fontSize: 13)),
                            value: _selectedBagIds.contains(b.id),
                            onChanged: (v) => setDialogState(() {
                              if (v != null && v) {
                                _selectedBagIds.add(b.id);
                              } else {
                                _selectedBagIds.remove(b.id);
                              }
          }),
                            fillColor: WidgetStateProperty.all(_kPrimary),
                            side: const BorderSide(color: _kBorder),
                          )).toList(),
                        ),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e', style: TextStyle(color: _kRed)),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: _kSubtext))),
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

  Widget _perBagAnalysis(List<DailyCashRecord> records, NumberFormat fmt) {
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
                decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                child: Text('$bagName: No records', style: TextStyle(color: _kSubtext, fontSize: 12)),
              );
            }
            final bagMap = <String, DailyCashRecord>{};
            for (final r in bagRecords) {
              final key = DateFormat('yyyy-MM-dd').format(r.entryDate);
              final ex = bagMap[key];
              if (ex == null || r.updatedAt.isAfter(ex.updatedAt)) bagMap[key] = r;
            }
            final sortedBag = bagMap.values.toList()
              ..sort((a, b) => a.entryDate.compareTo(b.entryDate));

            final allByDateBag = <String, DailyCashRecord>{};
            for (final r in bagRecords) {
              final key = DateFormat('yyyy-MM-dd').format(r.entryDate);
              final ex = allByDateBag[key];
              if (ex == null || r.updatedAt.isAfter(ex.updatedAt)) allByDateBag[key] = r;
            }
            final sortedAllBag = allByDateBag.values.toList()
              ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
            final bagWeekFinal = sortedBag.isNotEmpty
                ? sortedBag.last.finalAmount
                : 0.0;
            double bagRunning = 0.0;
            for (final r in sortedAllBag) {
              bagRunning = r.finalAmount;
            }
            final bagFinal = sortedBag.isNotEmpty ? bagWeekFinal : bagRunning;

            final bagCollected = bagRecords.fold(0.0, (s, r) => s + r.collectedAmount);
            final bagAdditionalCollection = bagRecords.fold(0.0, (s, r) => s + r.additionalCollection);
            final bagExpense = bagRecords.fold(0.0, (s, r) => s + r.expense);
            final bagGiven = bagRecords.fold(0.0, (s, r) => s + r.adapAmount);
            final bagGpay = bagRecords.fold(0.0, (s, r) => s + r.rrGpayAmount);
            final bagExtraNet = bagRecords.fold(0.0, (s, r) => s + r.extraNetAmount);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(bagName, style: TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _summaryRow(fmt, bagFinal, bagCollected, bagAdditionalCollection, bagExpense, bagGiven, bagGpay, bagExtraNet, sortedBag.length),
              ]),
            );
          },
        ),
    ]);
  }

  Widget _buildAppBar() => SliverAppBar(
    pinned: true,
    backgroundColor: _kSurface,
    foregroundColor: _kText,
    elevation: 0,
    title: const Text('Weekly Dashboard', style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 18)),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh_rounded, color: _kSubtext),
        onPressed: () => setState(() { _loadRecords(); _animCtrl.forward(from: 0); }),
      ),
    ],
  );

  Widget _weekNav() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
    child: Row(children: [
      _NavBtn(icon: Icons.chevron_left_rounded, onTap: () => _changeWeek(-1)),
      Expanded(child: Column(children: [
        Text(
          '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM yyyy').format(weekEnd)}',
          style: const TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text('Week ${_weekNumber(weekStart)}', style: const TextStyle(color: _kSubtext, fontSize: 11)),
      ])),
      _NavBtn(icon: Icons.chevron_right_rounded, onTap: () => _changeWeek(1)),
    ]),
  );

  int _weekNumber(DateTime d) {
    final startOfYear = DateTime(d.year, 1, 1);
    return ((d.difference(startOfYear).inDays + startOfYear.weekday) / 7).ceil();
  }

  Widget _summaryRow(NumberFormat fmt, double weekFinal, double collected, double additionalCollection, double expense, double given, double gpay, double extraNet, int days) {
    return Column(children: [
      Row(children: [
        Expanded(child: _SummaryTile(label: 'Week Final', value: fmt.format(weekFinal), color: weekFinal >= 0 ? _kGreen : _kRed, icon: Icons.account_balance_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryTile(label: 'Collected', value: fmt.format(collected - additionalCollection), color: _kPrimary, icon: Icons.payments_rounded)),
        const SizedBox(width: 10),
        if (additionalCollection > 0)
          Expanded(child: _SummaryTile(label: '+ Additional', value: fmt.format(additionalCollection), color: _kGold, icon: Icons.account_balance_wallet_rounded)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _SummaryTile(label: 'Amount Given', value: fmt.format(given), color: _kGold, icon: Icons.account_balance_wallet_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryTile(label: 'Expenses', value: fmt.format(expense), color: _kRed, icon: Icons.receipt_rounded)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        if (extraNet > 0)
          Expanded(child: _SummaryTile(label: 'Extra Net', value: fmt.format(extraNet), color: _kGreen, icon: Icons.account_balance_wallet_rounded)),
        Expanded(child: _SummaryTile(label: 'Days Recorded', value: '$days / 7', color: _kGold, icon: Icons.calendar_today_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryTile(label: 'GPay', value: fmt.format(gpay), color: _kPurple, icon: Icons.swap_horiz_rounded)),
      ]),
    ]);
  }

  Widget _sectionLabel(String text) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);

  Widget _buildLoading() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: List.generate(4, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(height: 80, decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14))),
    ))),
  );

  Widget _buildError(Object? error) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: _kRed),
      const SizedBox(height: 16),
      const Text('Failed to load records', style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('$error', style: const TextStyle(color: _kSubtext, fontSize: 12), textAlign: TextAlign.center),
    ]),
  );

  void _showAddRecordDialog() async {
    final svc = ref.read(supabaseServiceProvider);
    final List<CollectionBag> bags;
    try {
      bags = await svc.getCollectionBags();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _kRed),
        );
      }
      return;
    }
    if (bags.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No bags available'), backgroundColor: _kRed),
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
              backgroundColor: _kCard,
              title: const Text('Select Bag', style: TextStyle(color: _kText)),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView(
                  children: bags.map((bag) {
                    final isSelected = picked == bag.id;
                    return Card(
                      color: isSelected ? _kPrimary.withValues(alpha: 0.15) : _kSurface,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(bag.name, style: const TextStyle(color: _kText)),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? _kPrimary : _kBorder,
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: _kText, size: 16)
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
                  child: const Text('Cancel', style: TextStyle(color: _kSubtext)),
                ),
                ElevatedButton(
                  onPressed: picked != null
                      ? () {
                          Navigator.pop(ctx, picked);
                        }
                      : null,
                  child: const Text('Next', style: TextStyle(color: _kText)),
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
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: _kText, size: 20),
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SummaryTile({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _kCard,
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
        Text(label, style: const TextStyle(color: _kSubtext, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
      ])),
    ]),
  );
}

class _DayCard extends StatefulWidget {
  final DateTime date;
  final List<DailyCashRecord> records;
  final NumberFormat fmt;
  final VoidCallback onTap;
  final bool isLastWeek;
  const _DayCard({required this.date, required this.records, required this.fmt, required this.onTap, this.isLastWeek = false});

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  @override
  Widget build(BuildContext context) {
    final hasRecord = widget.records.isNotEmpty;
    return Card(
      color: _kCard,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 18, color: _kSubtext),
          const SizedBox(width: 8),
          Expanded(child: Text(DateFormat('EEE, d MMM').format(widget.date), style: const TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 14))),
          const SizedBox(width: 4),
          Text(hasRecord ? '${widget.records.length} record${widget.records.length > 1 ? 's' : ''}' : 'No record', style: TextStyle(color: hasRecord ? _kGreen : _kSubtext, fontSize: 12, fontWeight: FontWeight.w600)),
          if (hasRecord && widget.isLastWeek)
            const Padding(padding: EdgeInsets.only(left: 4), child: Text('Last Week', style: TextStyle(color: _kGold, fontSize: 10, fontWeight: FontWeight.w600))),
          if (!hasRecord) ...[
            const SizedBox(width: 8),
            _AddBtn(onTap: widget.onTap),
          ],
        ]),
        children: [
          Container(
            color: _kCard,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: [
              for (final r in widget.records) ...[
                _DetailRow('Collected', widget.fmt.format(r.collectedAmount - r.additionalCollection), _kGreen),
                if (r.additionalCollection > 0)
                  _DetailRow('+ Additional Collection', widget.fmt.format(r.additionalCollection), _kGold),
                _DetailRow('Net in Hand', widget.fmt.format(r.netAmountInHand), _kGreen),
                if (r.extraNetAmount > 0)
                  _DetailRow('+ Extra Net', widget.fmt.format(r.extraNetAmount), _kGreen),
                _DetailRow('Expense', '− ${widget.fmt.format(r.expense)}', _kRed),
                _DetailRow('GPay', '− ${widget.fmt.format(r.rrGpayAmount)}', _kRed),
                _DetailRow('Adap', widget.fmt.format(r.adapAmount), _kGold),
                _DetailRow('Other', widget.fmt.format(r.otherAmount), _kSubtext),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: _kBorder)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  Text('Final', style: TextStyle(color: _kSubtext, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(widget.fmt.format(r.finalAmount), style: TextStyle(color: r.finalAmount >= 0 ? _kGreen : _kRed, fontWeight: FontWeight.w900, fontSize: 16)),
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
                      backgroundColor: _kPrimary.withValues(alpha: 0.15),
                      foregroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (widget.records.length > 1) const Divider(height: 16, color: _kBorder),
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
      Text(label, style: const TextStyle(color: _kSubtext, fontSize: 12)),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add_rounded, color: _kPrimary, size: 14),
        SizedBox(width: 4),
        Text('Add', style: TextStyle(color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
