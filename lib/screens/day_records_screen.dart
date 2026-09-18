import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:microfinance_app/models/collection_bag.dart';
import 'package:microfinance_app/models/daily_cash_record.dart';
import 'package:microfinance_app/models/region.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/services/supabase_service.dart';
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

class DayRecordsScreen extends ConsumerStatefulWidget {
  const DayRecordsScreen({super.key});

  @override
  ConsumerState<DayRecordsScreen> createState() => _DayRecordsScreenState();
}

class _DayRecordsScreenState extends ConsumerState<DayRecordsScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRegionId;
  String? _selectedBagId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
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
      startDate: _startDate,
      endDate: _endDate,
      regionId: _selectedRegionId,
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

  BoxDecoration _cardDecor({Color? border}) => BoxDecoration(
    color: _kCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border ?? _kBorder),
  );

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\u{20B9}', decimalDigits: 2);
    final regionsAsync = ref.watch(regionsProvider);

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
            title: const Text(
              'Day Records',
              style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: _kSubtext),
                onPressed: _load,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 16),
                _buildFilters(regionsAsync),
                const SizedBox(height: 16),
                _loading
                    ? _buildLoading()
                    : _records.isEmpty
                      ? _buildEmpty()
                      : _buildContent(fmt),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFilters(AsyncValue<List<Region>> regionsAsync) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      regionsAsync.when(
        data: (regions) => DropdownButtonFormField<String>(
          value: _selectedRegionId,
          dropdownColor: _kCard,
          decoration: InputDecoration(
            labelText: 'Branch',
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
              borderSide: const BorderSide(color: _kPrimary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          style: const TextStyle(color: _kText),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Branches')),
            ...regions.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
          ],
          onChanged: (v) {
            setState(() => _selectedRegionId = v);
            _load();
          },
        ),
        loading: () => const LinearProgressIndicator(minHeight: 48),
        error: (e, _) => Text('Error: $e', style: const TextStyle(color: _kRed)),
      ),
      const SizedBox(height: 12),
      Builder(builder: (_) {
        final bagsAsync = ref.watch(collectionBagsProvider);
        return bagsAsync.when(
          data: (bags) => DropdownButtonFormField<String>(
            value: _selectedBagId,
            dropdownColor: _kCard,
            decoration: InputDecoration(
              labelText: 'Bag',
              labelStyle: const TextStyle(color: _kSubtext),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
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
          error: (e, _) => const SizedBox(height: 48),
        );
      }),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(primary: _kPrimary),
                dialogBackgroundColor: _kSurface,
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            setState(() { _startDate = picked.start; _endDate = picked.end; });
            _load();
          }
        },
        icon: const Icon(Icons.calendar_today_rounded, color: _kPrimary),
        label: Text(
          '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
          style: const TextStyle(color: _kText),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    ]);
  }

  Widget _buildLoading() => Column(children: List.generate(4, (_) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      height: 80,
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14)),
    ),
  )));

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('No day records found', style: TextStyle(color: Colors.grey.shade600)),
    ]),
  );

  Widget _buildContent(NumberFormat fmt) {
    final totalCollected = _records.fold(0.0, (s, r) => s + r.collectedAmount);
    final totalExpense = _records.fold(0.0, (s, r) => s + r.expense);
    final totalGiven = _records.fold(0.0, (s, r) => s + r.adapAmount);
    final netFinal = _records.fold(0.0, (s, r) => s + r.finalAmount);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _summarySection(fmt, totalCollected, totalExpense, totalGiven, netFinal),
      const SizedBox(height: 28),
      _sectionLabel('Records (${_records.length})'),
      const SizedBox(height: 12),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final r = _records[i];
          final isNeg = r.finalAmount < 0;
          return _RecordCard(record: r, fmt: fmt, isNeg: isNeg);
        },
      ),
    ]);
  }

  Widget _sectionLabel(String text) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
  ]);

  Widget _summarySection(NumberFormat fmt, double collected, double expense, double given, double netFinal) {
    return Column(children: [
      Row(children: [
        Expanded(child: _SummaryTile(label: 'Collected', value: fmt.format(collected), color: _kGreen, icon: Icons.payments_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryTile(label: 'Expenses', value: fmt.format(expense), color: _kRed, icon: Icons.receipt_rounded)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _SummaryTile(label: 'Amount Given', value: fmt.format(given), color: _kGold, icon: Icons.account_balance_wallet_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryTile(label: 'Net Final', value: fmt.format(netFinal), color: netFinal >= 0 ? _kGreen : _kRed, icon: Icons.account_balance_rounded)),
      ]),
    ]);
  }
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
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _kSubtext, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      ])),
    ]),
  );
}

class _RecordCard extends StatelessWidget {
  final DailyCashRecord record;
  final NumberFormat fmt;
  final bool isNeg;
  const _RecordCard({required this.record, required this.fmt, required this.isNeg});

  @override
  Widget build(BuildContext context) {
    final color = isNeg ? _kRed : _kGreen;
    return Material(
      color: _kCard,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Text(
          DateFormat('EEE, d MMM yyyy').format(record.entryDate),
          style: const TextStyle(color: _kText, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Final: ${fmt.format(record.finalAmount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        iconColor: _kSubtext,
        collapsedIconColor: _kSubtext,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _DetailRow('Opening Balance', fmt.format(record.previousFinalAmount), _kGold),
              _DetailRow('Net in Hand', fmt.format(record.netAmountInHand), _kText),
              _DetailRow('Collected', fmt.format(record.collectedAmount), _kGreen),
              _DetailRow('Amount Given', fmt.format(record.adapAmount), _kOrange),
              _DetailRow('Doc Fees', fmt.format(record.documentFees), _kPrimary),
              const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: _kBorder)),
              _DetailRow('RR GPay', '- ${fmt.format(record.rrGpayAmount)}', _kRed),
              _DetailRow('Expense', '- ${fmt.format(record.expense)}', _kRed),
              const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: _kBorder)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Final Amount', style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(fmt.format(record.finalAmount),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final dateStr = DateFormat('yyyy-MM-dd').format(record.entryDate);
                    context.go('/day-record-entry?date=$dateStr&regionId=${record.regionId}&modelId=${record.modelId}&bagId=${record.bagId}');
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
            ]),
          ),
        ],
      ),
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
