content = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:microfinance_app/models/daily_cash_record.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/services/supabase_service.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';

const _kPrimary = Color(0xFF1B5E20);
const _kGreen = Color(0xFF2E7D32);
const _kRed = Color(0xFFC62828);

class DayRecordsScreen extends ConsumerState StatefulWidget {
  const DayRecordsScreen({super.key});

  @override
  ConsumerState<DayRecordsScreen> createState() => _DayRecordsScreenState();
}

class _DayRecordsScreenState extends ConsumerState<DayRecordsScreen> {
  String? _selectedRegionId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<DailyCashRecord> _records = [];
  bool _loading = false;

  void _load() {
    setState(() => _loading = true);
    final svc = ref.read(supabaseServiceProvider);
    svc.getDailyCashRecords(
      startDate: _startDate,
      endDate: _endDate,
      regionId: _selectedRegionId,
    ).then((r) {
      if (!mounted) return;
      setState(() { _records = r; _loading = false; });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\\u{20B9}', decimalDigits: 2);
    final regionsAsync = ref.watch(regionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Records'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  regionsAsync.when(
                    data: (regions) => DropdownButtonFormField<String>(
                      value: _selectedRegionId,
                      decoration: const/inputDecoration(labelText: 'Branch', border: BorderRadius.all(Radius.circular(8))),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Branches')),
                        ...regions.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
                      ],
                      onChanged: (v) => setState(() => _selectedRegionId = v),
                    ),
                    loading: () => const LinearProgressIndicator(minHeight: 48),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                          );
                          if (picked != null) {
                            setState(() { _startDate = picked.start; _endDate = picked.end; });
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: Text(
                          '${DateFormat('dd MMM yyyy').format(_startDate)} - '
                          '${DateFormat('dd MMM yyyy').format(_endDate)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
                  ]),
                ],
              ),
            ),
          ),
        ),
        if (_records.isNotEmpty) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _Stat(label: 'Total Records', value: '${_records.length}', color: _kPrimary),
            _Stat(label: 'Total Collected', value: fmt.format(_records.fold(0.0, (s, r) => s + r.collectedAmount)), color: _kGreen),
            _Stat(label: 'Total Expense', value: fmt.format(_records.fold(0.0, (s, r) => s + r.expense)), color: _kRed),
            _Stat(label: 'Net Final', value: fmt.format(_records.fold(0.0, (s, r) => s + r.finalAmount)), color: _kPrimary),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxis
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No day records found', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _records.length,
                      itemBuilder: (ctx, i) {
                        final r = _records[i];
                        final isNeg = r.finalAmount < 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              DateFormat('dd MMM yyyy').format(r.entryDate),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Opening: ${fmt.format(r.previousFinalAmount)}'),
                                Text('Collected: ${fmt.format(r.collectedAmount)}'),
                                Text('Expense: ${fmt.format(r.expense)}'),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isNeg ? _kRed : _kGreen).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: (isNeg ? _kRed : _kGreen).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Final: ${fmt.format(r.finalAmount)}',
                                style: TextStyle(
                                  color: isNeg ? _kRed : _kGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    ));
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
"""
content = content.replace('mainAxis\n', 'mainAxis: MainAxisSize.min,\n')
with open('lib/screens/day_records_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('written')