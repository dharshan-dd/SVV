import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:microfinance_app/models/collection_bag.dart';
import 'package:microfinance_app/models/collection_cycle.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/services/collection_calculation_service.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';

class BagHistoryScreen extends ConsumerStatefulWidget {
  const BagHistoryScreen({super.key});

  @override
  ConsumerState<BagHistoryScreen> createState() => _BagHistoryScreenState();
}

class _BagHistoryScreenState extends ConsumerState<BagHistoryScreen> {
  String? _selectedBagId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.read(supabaseServiceProvider);
    final bagsAsync = ref.watch(collectionBagsProvider);
    final calcService = CollectionCalculationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bag History'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: bagsAsync.when(
                            data: (bags) {
                              return DropdownButtonFormField<String>(
                                value: _selectedBagId,
                                decoration: const InputDecoration(
                                  labelText: 'Collection Bag',
                                  border: OutlineInputBorder(),
                                ),
                                items: bags.map((bag) {
                                  return DropdownMenuItem<String>(
                                    value: bag.id,
                                    child: Text(bag.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedBagId = value);
                                },
                              );
                            },
                            loading: () => const LinearProgressIndicator(minHeight: 48),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.calendar_today_rounded),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                            );
                            if (picked != null) {
                              setState(() {
                                _startDate = picked.start;
                                _endDate = picked.end;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CollectionCycle>>(
              future: _selectedBagId == null
                  ? Future.value([])
                  : calcService.getBagHistory(
                      bagId: _selectedBagId!,
                      startDate: _startDate,
                      endDate: _endDate,
                    ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No bag history found',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final totalExpected = history.fold<double>(0, (sum, c) => sum + c.expectedAmount);
                final totalCollected = history.fold<double>(0, (sum, c) => sum + c.collectedAmount);
                final totalPending = history.fold<double>(0, (sum, c) => sum + c.pendingAmount);
                final lastCollection = history.isNotEmpty ? history.first : null;
                final nextScheduled = history.isNotEmpty ? history.last : null;

                return Column(
                  children: [
                    if (history.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryTile(
                                    label: 'Total Expected',
                                    value: NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(totalExpected),
                                  ),
                                ),
                                Expanded(
                                  child: _SummaryTile(
                                    label: 'Total Collected',
                                    value: NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(totalCollected),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryTile(
                                    label: 'Total Pending',
                                    value: NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(totalPending),
                                  ),
                                ),
                                Expanded(
                                  child: _SummaryTile(
                                    label: 'Last Collection',
                                    value: lastCollection != null
                                        ? DateFormat('dd MMM yyyy').format(lastCollection.scheduledDate)
                                        : 'N/A',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final cycle = history[index];
                          final dateStr = DateFormat('dd MMM yyyy').format(cycle.scheduledDate);
                          Color statusColor;
                          switch (cycle.status) {
                            case 'collected':
                              statusColor = Colors.green;
                              break;
                            case 'partially_collected':
                              statusColor = Colors.orange;
                              break;
                            case 'missed':
                              statusColor = Colors.red;
                              break;
                            default:
                              statusColor = Colors.grey;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              title: Text(
                                dateStr,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Expected: ₹${cycle.expectedAmount.toStringAsFixed(2)}'),
                                  Text('Collected: ₹${cycle.collectedAmount.toStringAsFixed(2)}'),
                                  Text('Pending: ₹${cycle.pendingAmount.toStringAsFixed(2)}'),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  cycle.status.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
