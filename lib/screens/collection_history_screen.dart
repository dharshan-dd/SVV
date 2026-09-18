import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../services/supabase_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';

class CollectionHistoryScreen extends ConsumerStatefulWidget {
  const CollectionHistoryScreen({super.key});

  @override
  ConsumerState<CollectionHistoryScreen> createState() => _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState extends ConsumerState<CollectionHistoryScreen> {
  String? _selectedBagId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.read(supabaseServiceProvider);
    final bagsAsync = ref.watch(collectionBagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection History'),
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
                                  labelText: 'Bag',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Bags'),
                                  ),
                                  ...bags.map((bag) {
                                    return DropdownMenuItem<String>(
                                      value: bag.id,
                                      child: Text(bag.name),
                                    );
                                  }),
                                ],
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                              Text('To: ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
                            ],
                          ),
                        ),
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: service.getCollectionHistory(
                bagId: _selectedBagId,
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
                        Icon(Icons.history_rounded, size: 64, color: context.tokens.mutedForeground),
                        const SizedBox(height: 16),
                        Text(
                          'No collection history found',
                          style: TextStyle(fontSize: 16, color: context.tokens.mutedForeground),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final scheduledDate = DateTime.parse(item['scheduled_date'] as String);
                    final expectedAmount = (item['expected_amount'] as num?)?.toDouble() ?? 0.0;
                    final collectedAmount = (item['collected_amount'] as num?)?.toDouble() ?? 0.0;
                    final pendingAmount = (item['pending_amount'] as num?)?.toDouble() ?? 0.0;
                    final status = item['status'] as String? ?? 'pending';
                    final bagConfig = item['bag_configuration'] as Map<String, dynamic>?;

                    Color statusColor;
                    switch (status) {
                      case 'collected':
                        statusColor = Colors.green;
                        break;
                      case 'partially_collected':
                        statusColor = Colors.orange;
                        break;
                      case 'missed':
                        statusColor = Colors.red;
                        break;
                      case 'pending':
                        statusColor = Colors.grey;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: context.tokens.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.tokens.border, width: 0.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Text(
                          DateFormat('dd MMM yyyy').format(scheduledDate),
                          style: TextStyle(fontWeight: FontWeight.w600, color: context.tokens.foreground),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bagConfig != null ? 'Bag: ${bagConfig['bag_id'] ?? ''}' : 'Bag: ${item['bag_id']}',
                              style: TextStyle(fontSize: 12, color: context.tokens.mutedForeground),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Expected: ₹${expectedAmount.toStringAsFixed(2)}', style: TextStyle(color: context.tokens.foreground)),
                                const SizedBox(width: 16),
                                Text('Collected: ₹${collectedAmount.toStringAsFixed(2)}', style: TextStyle(color: context.tokens.foreground)),
                                const SizedBox(width: 16),
                                Text('Pending: ₹${pendingAmount.toStringAsFixed(2)}', style: TextStyle(color: context.tokens.foreground)),
                              ],
                            ),
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
                            status.replaceAll('_', ' ').toUpperCase(),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}