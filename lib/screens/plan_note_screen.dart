import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:microfinance_app/models/daily_cash_record.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/services/supabase_service.dart';
import 'package:microfinance_app/services/collection_calculation_service.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';

const _kBg      = Color(0xFF0A0E1A);
const _kSurface = Color(0xFF111827);
const _kCard    = Color(0xFF1C2333);
const _kBorder  = Color(0xFF2A3347);
const _kPrimary = Color(0xFF3B82F6);
const _kGold    = Color(0xFFF59E0B);
const _kGreen   = Color(0xFF10B981);
const _kRed     = Color(0xFFEF4444);
const _kOrange  = Color(0xFFF97316);
const _kText    = Color(0xFFF1F5F9);
const _kSubtext = Color(0xFF94A3B8);

class PlanNoteScreen extends ConsumerStatefulWidget {
  const PlanNoteScreen({super.key});

  @override
  ConsumerState<PlanNoteScreen> createState() => _PlanNoteScreenState();
}

class _PlanNoteScreenState extends ConsumerState<PlanNoteScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String? _selectedBagId;
  List<DailyCashRecord> _records = [];
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _load() {
    setState(() => _loading = true);
    final svc = ref.read(supabaseServiceProvider);
    svc.getDailyCashRecords(
      startDate: _selectedBagId != null ? null : _selectedDate,
      endDate: _selectedBagId != null ? null : _selectedDate,
      bagId: _selectedBagId,
    ).then((r) {
      if (!mounted) return;
      setState(() { _records = r; _loading = false; });
      _animCtrl.forward(from: 0);
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  void _changeDate(DateTime date) {
    setState(() => _selectedDate = date);
    _load();
  }

  Widget _buildBagDropdown() {
    final bagsAsync = ref.watch(collectionBagsProvider);
    return SizedBox(
      width: double.infinity,
      child: bagsAsync.when(
        data: (bags) => DropdownButtonFormField<String>(
          value: _selectedBagId,
          dropdownColor: _kCard,
          decoration: InputDecoration(
            labelText: 'Filter by Bag',
            labelStyle: const TextStyle(color: _kSubtext),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          style: const TextStyle(color: _kText),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Bags')),
            ...bags.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
          ],
          onChanged: (v) {
            setState(() => _selectedBagId = v);
            _load();
          },
        ),
        loading: () => const SizedBox(height: 48),
        error: (_, __) => const SizedBox(height: 48),
      ),
    );
  }

  Map<String, Map<String, List<DailyCashRecord>>> _groupByBranchAndBag() {
    final regionsAsync = ref.read(regionsProvider);
    final regions = regionsAsync.asData?.value ?? [];
    final regionMap = {for (var r in regions) r.id: r.name};

    final bagsAsync = ref.read(collectionBagsProvider);
    final bags = bagsAsync.asData?.value ?? [];
    final bagMap = {for (var b in bags) b.id: b.name};

    final Map<String, Map<String, List<DailyCashRecord>>> grouped = {};
    for (final r in _records) {
      final branch = regionMap[r.regionId] ?? 'Unknown Branch';
      final bagName = bagMap[r.bagId] ?? 'Bag ${r.bagId.substring(0, 8)}';
      grouped.putIfAbsent(branch, () => {});
      grouped[branch]!.putIfAbsent(bagName, () => []);
      grouped[branch]![bagName]!.add(r);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\u{20B9}', decimalDigits: 2);
    final grouped = _groupByBranchAndBag();

    return Scaffold(
      backgroundColor: _kBg,
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _kSurface,
            foregroundColor: _kText,
            elevation: 0,
            title: const Text('Plan Notes', style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: _kSubtext),
                onPressed: _load,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(primary: _kPrimary),
                            dialogBackgroundColor: _kSurface,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) _changeDate(picked);
                    },
                  icon: const Icon(Icons.calendar_today_rounded, color: _kPrimary, size: 18),
                  label: Text(
                    _selectedBagId != null
                      ? 'All dates (bag filter active)'
                      : DateFormat('EEE, d MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBagDropdown(),
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _loading
                ? _buildLoading()
                : grouped.isEmpty
                  ? _buildEmpty()
                  : _buildBranches(fmt, grouped),
          ),
        ]),
      ),
    );
  }

  Widget _buildLoading() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: List.generate(3, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(height: 120, decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14))),
    ))),
  );

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.note_rounded, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(_selectedBagId != null
          ? 'No records found for this bag'
          : 'No records for ${DateFormat('d MMMM yyyy').format(_selectedDate)}',
        style: TextStyle(color: Colors.grey.shade600)),
    ]),
  );

  Widget _buildBranches(NumberFormat fmt, Map<String, Map<String, List<DailyCashRecord>>> grouped) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final branchEntry in grouped.entries) ...[
          _branchSection(branchEntry.key, branchEntry.value, fmt),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }

  Widget _branchSection(String branchName, Map<String, List<DailyCashRecord>> bagsMap, NumberFormat fmt) {
    final allRecords = bagsMap.values.expand((r) => r).toList();
    allRecords.sort((a, b) {
      final cmp = a.entryDate.compareTo(b.entryDate);
      if (cmp != 0) return cmp;
      final cmp2 = a.createdAt.compareTo(b.createdAt);
      if (cmp2 != 0) return cmp2;
      return a.id.compareTo(b.id);
    });

    final totalCollected = allRecords.fold(0.0, (s, r) => s + r.collectedAmount);
    final totalAdditionalCollection = allRecords.fold(0.0, (s, r) => s + r.additionalCollection);
    final totalExpense = allRecords.fold(0.0, (s, r) => s + r.expense);
    final totalGiven = allRecords.fold(0.0, (s, r) => s + r.adapAmount);
    final totalFinal = allRecords.fold(0.0, (s, r) => s + r.finalAmount);

    final isBagMode = _selectedBagId != null;
    final title = isBagMode
        ? (bagsMap.keys.first)
        : '$branchName (${allRecords.length} records)';

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isBagMode ? _kGold.withValues(alpha: 0.08) : _kPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.vertical(top: Radius.circular(isBagMode ? 14 : 0)),
          border: Border.all(color: (isBagMode ? _kGold : _kPrimary).withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(isBagMode ? Icons.work_rounded : Icons.location_city_rounded, color: isBagMode ? _kGold : _kPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            title,
            style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 15),
          )),
          Text(fmt.format(totalFinal),
            style: TextStyle(color: totalFinal >= 0 ? _kGreen : _kRed, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(bottom: isBagMode ? Radius.circular(14) : Radius.zero),
          border: Border.all(color: _kBorder),
        ),
        child: Wrap(spacing: 16, runSpacing: 8, children: [
          _miniStat('Collected', fmt.format(totalCollected - totalAdditionalCollection), _kGreen),
          if (totalAdditionalCollection > 0)
            _miniStat('+ Additional', fmt.format(totalAdditionalCollection), _kGold),
          _miniStat('Expenses', fmt.format(totalExpense), _kRed),
          _miniStat('Amount Given', fmt.format(totalGiven), _kOrange),
        ]),
      ),
      if (isBagMode) ...[
        const SizedBox(height: 8),
        ..._buildRecordsWithWeekLabels(allRecords, fmt),
      ] else ...[
        for (final bagEntry in bagsMap.entries) ...[
          const SizedBox(height: 8),
          _bagSubSection(bagEntry.key, bagEntry.value, fmt),
        ],
      ],
    ]);
  }

  Widget _bagSubSection(String bagName, List<DailyCashRecord> records, NumberFormat fmt) {
    records.sort((a, b) {
      final cmp = a.entryDate.compareTo(b.entryDate);
      if (cmp != 0) return cmp;
      final cmp2 = a.createdAt.compareTo(b.createdAt);
      if (cmp2 != 0) return cmp2;
      return a.id.compareTo(b.id);
    });

    final bagCollected = records.fold(0.0, (s, r) => s + r.collectedAmount);
    final bagExpense = records.fold(0.0, (s, r) => s + r.expense);
    final bagGiven = records.fold(0.0, (s, r) => s + r.adapAmount);
    final bagFinal = records.fold(0.0, (s, r) => s + r.finalAmount);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          const Icon(Icons.work_rounded, color: _kGold, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(
            '$bagName (${records.length})',
            style: const TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 13),
          )),
          Text(fmt.format(bagFinal),
            style: TextStyle(color: bagFinal >= 0 ? _kGreen : _kRed, fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 8),
      ..._buildRecordsWithWeekLabels(records, fmt),
    ]);
  }

  List<Widget> _buildRecordsWithWeekLabels(List<DailyCashRecord> records, NumberFormat fmt) {
    final widgets = <Widget>[];
    String? currentWeekStart;
    for (final r in records) {
      final weekStart = _weekStartString(r.entryDate);
      if (weekStart != currentWeekStart) {
        currentWeekStart = weekStart;
        widgets.add(_weekLabel(r.entryDate, fmt));
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(_RecordDetail(record: r, fmt: fmt));
      widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }

  String _weekStartString(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return '${monday.year}-${monday.month}-${monday.day}';
  }

  Widget _weekLabel(DateTime date, NumberFormat fmt) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final label = DateFormat('d MMM').format(monday) + ' - ' + DateFormat('d MMM').format(sunday);
    final weekTotal = _records
        .where((r) => r.entryDate.isAfter(monday.subtract(const Duration(seconds: 1))) && r.entryDate.isBefore(sunday.add(const Duration(days: 1))))
        .fold(0.0, (s, r) => s + r.finalAmount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        const Icon(Icons.date_range_rounded, color: _kPrimary, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _kText, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text(fmt.format(weekTotal), style: TextStyle(color: weekTotal >= 0 ? _kGreen : _kRed, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: _kSubtext, fontSize: 10)),
    Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}

class _RecordDetail extends StatelessWidget {
  final DailyCashRecord record;
  final NumberFormat fmt;
  const _RecordDetail({required this.record, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final calc = CollectionCalculationService().calculateDayRecordTrail(
      previousFinalAmount: record.previousFinalAmount,
      netAmountInHand: record.netAmountInHand,
      collectedAmount: record.collectedAmount,
      remainingAmount: record.remainingAmount,
      documentFees: record.documentFees,
      adapAmount: record.adapAmount,
      rrGpayAmount: record.rrGpayAmount,
      expense: record.expense,
    );

    final isPos = (calc['finalAmount'] as double) >= 0;
    final color = isPos ? _kGreen : _kRed;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payment_rounded, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bag: ${record.bagId.substring(0, 8)}...',
                  style: TextStyle(color: _kSubtext, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(DateFormat('EEE, d MMM yyyy').format(record.entryDate),
                  style: TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
             Text(fmt.format(calc['finalAmount']),
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: _kSubtext, size: 18),
              onPressed: () {
                final dateStr = DateFormat('yyyy-MM-dd').format(record.entryDate);
                context.go('/day-record-entry?date=$dateStr&regionId=${record.regionId}&modelId=${record.modelId}&bagId=${record.bagId}');
              },
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _calcRow('Previous Final', fmt.format(calc['previousFinalAmount']), _kGold),
            _calcRow('Net in Hand', fmt.format(calc['netAmountInHand']), _kText),
            _calcRow('Collected', fmt.format(record.collectedAmount - record.additionalCollection), _kGreen),
            if (record.additionalCollection > 0)
              _calcRow('+ Additional Collection', fmt.format(record.additionalCollection), _kGold),
            _calcRow('Amount Given', fmt.format(calc['adapAmount']), _kOrange),
            _calcRow('Remaining', fmt.format(calc['remainingAmount']), _kPrimary),
            _calcRow('Document Fees', fmt.format(calc['documentFees']), _kText),
            _divider(),
            _calcTotal('Total Amount', fmt.format(calc['totalAmount']), _kText),
            _calcTotal('After ADAP', fmt.format(calc['amountAfterAdap']), _kOrange),
            _calcTotal('After GPay', fmt.format(calc['amountAfterGpay']), _kPrimary),
            _divider(),
            _calcRow('- RR GPay', '- ${fmt.format(calc['rrGpayAmount'])}', _kRed),
            _calcRow('- Expense', '- ${fmt.format(calc['expense'])}', _kRed),
            _divider(),
            _calcTotal('Final Amount', fmt.format(calc['finalAmount']), isPos ? _kGreen : _kRed),
          ]),
        ),
      ]),
    );
  }

  Widget _calcRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: _kSubtext, fontSize: 12)),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _calcTotal(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: _kSubtext, fontSize: 11, fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 5),
    child: Divider(height: 1, color: _kBorder),
  );
}
