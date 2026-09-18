import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:microfinance_app/models/collection_bag.dart';
import 'package:microfinance_app/models/daily_cash_record.dart';
import 'package:microfinance_app/models/region.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/services/supabase_service.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';

const _gBg = Color(0xFF0A0E1A);
const _gSurface = Color(0xFF111827);
const _gCard = Color(0xFF1C2333);
const _gBorder = Color(0xFF2A3347);
const _gPrimary = Color(0xFF3B82F6);
const _gGold = Color(0xFFF59E0B);
const _gGreen = Color(0xFF10B981);
const _gRed = Color(0xFFEF4444);
const _gText = Color(0xFFF1F5F9);
const _gPurple = Color(0xFF8B5CF6);
const _gSubtext = Color(0xFF94A3B8);

class GPayDashboardScreen extends ConsumerStatefulWidget {
  const GPayDashboardScreen({super.key});

  @override
  ConsumerState<GPayDashboardScreen> createState() => _GPayDashboardScreenState();
}

class _GPayDashboardScreenState extends ConsumerState<GPayDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0);
    final bagsAsync = ref.watch(collectionBagsProvider);
    final recordsAsync = ref.watch(dailyCashRecordsProvider);
    final regionsAsync = ref.watch(regionsProvider);
    final configsAsync = ref.watch(bagConfigurationsProvider);

    return Scaffold(
      backgroundColor: _gBg,
      appBar: AppBar(
        title: const Text('GPay Dashboard', style: TextStyle(color: _gText, fontWeight: FontWeight.w700)),
        backgroundColor: _gSurface,
        foregroundColor: _gText,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(collectionBagsProvider);
          ref.invalidate(dailyCashRecordsProvider);
        },
        child: bagsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _gRed))),
              data: (bags) {
                return regionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _gRed))),
                  data: (regions) {
                    return configsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _gRed))),
                      data: (configs) {
                        final activeBagIds = configs
                            .where((c) => c.isActive && c.regionId.isNotEmpty)
                            .map((c) => c.bagId)
                            .toSet();
                        final filteredBags = bags
                            .where((b) => activeBagIds.contains(b.id))
                            .toList();
                        return recordsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _gRed))),
                          data: (allRecords) {
                        final regionMap = <String, String>{};
                        for (final r in regions) {
                          regionMap[r.id] = r.name;
                        }

                final today = DateTime.now();
                final weekStart = DateTime(today.year, today.month, today.day - ((today.weekday - DateTime.thursday + 7) % 7));
                final weekEnd = weekStart.add(const Duration(days: 6));

                final bagData = <BagGPayData>[];
                for (final bag in filteredBags) {
                  final bagRecords = allRecords.where((r) => r.bagId == bag.id).toList();
                  final weekRecords = bagRecords
                      .where((r) =>
                          r.rrGpayAmount! > 0 &&
                          !r.entryDate!.isBefore(weekStart) &&
                          !r.entryDate!.isAfter(weekEnd))
                      .toList();

                  final weekGPay = weekRecords.fold(0.0, (s, r) => s + r.rrGpayAmount!);
                  final totalGPay = bagRecords.fold(0.0, (s, r) => s + r.rrGpayAmount!);
                  final weekCount = weekRecords.length;
                  final totalCount = bagRecords.length;

                  DateTime? lastUpdated;
                  if (bagRecords.isNotEmpty) {
                    lastUpdated = bagRecords.map((r) => r.updatedAt!).reduce((a, b) => a.isAfter(b) ? a : b);
                  }

                  String regionName = '';
                  if (bagRecords.isNotEmpty && bagRecords.first.regionId != null) {
                    regionName = regionMap[bagRecords.first.regionId!] ?? bagRecords.first.regionId ?? '';
                  }

                  bagData.add(BagGPayData(
                    bagId: bag.id,
                    bagName: bag.name,
                    regionName: regionName,
                    weekGPay: weekGPay,
                    totalGPay: totalGPay,
                    weekCount: weekCount,
                    totalCount: totalCount,
                    lastUpdated: lastUpdated,
                  ));
                }

                bagData.sort((a, b) => b.totalGPay.compareTo(a.totalGPay));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(child: _SummaryTile(
                            label: 'Total GPay (Week)',
                            value: fmt.format(bagData.fold(0.0, (s, d) => s + d.weekGPay)),
                            color: _gGold,
                            icon: Icons.swap_horiz_rounded,
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _SummaryTile(
                            label: 'Total GPay (All Time)',
                            value: fmt.format(bagData.fold(0.0, (s, d) => s + d.totalGPay)),
                            color: _gPrimary,
                            icon: Icons.account_balance_rounded,
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _SummaryTile(
                            label: 'Total Bags',
                            value: '${bagData.length}',
                            color: _gGreen,
                            icon: Icons.inventory_2_rounded,
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: bagData.length,
                        itemBuilder: (context, index) {
                          return _GPayBagCard(
                            data: bagData[index],
                            fmt: fmt,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        );
      },
    );
  },
)
)
);
}
}

class BagGPayData {
  final String bagId;
  final String bagName;
  final String regionName;
  final double weekGPay;
  final double totalGPay;
  final int weekCount;
  final int totalCount;
  final DateTime? lastUpdated;

  const BagGPayData({
    required this.bagId,
    required this.bagName,
    required this.regionName,
    required this.weekGPay,
    required this.totalGPay,
    required this.weekCount,
    required this.totalCount,
    required this.lastUpdated,
  });
}

class _GPayBagCard extends ConsumerStatefulWidget {
  final BagGPayData data;
  final NumberFormat fmt;

  const _GPayBagCard({required this.data, required this.fmt});

  @override
  ConsumerState<_GPayBagCard> createState() => _GPayBagCardState();
}

class _GPayBagCardState extends ConsumerState<_GPayBagCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Card(
      color: _gCard,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _gBorder, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _gGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.swap_horiz_rounded, color: _gGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.regionName.isNotEmpty ? '${d.regionName} - ${d.bagName}' : d.bagName,
                          style: const TextStyle(color: _gText, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Week: ${widget.fmt.format(d.weekGPay)} • All Time: ${widget.fmt.format(d.totalGPay)} • ${d.weekCount} txns this week',
                          style: const TextStyle(color: _gSubtext, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: _gSubtext,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: _gBorder),
                  const SizedBox(height: 10),
                  _statRow('This Week GPay', widget.fmt.format(d.weekGPay), _gGold),
                  _statRow('All Time GPay', widget.fmt.format(d.totalGPay), _gPrimary),
                  _statRow('This Week Txns', '${d.weekCount}', _gGreen),
                  _statRow('All Time Txns', '${d.totalCount}', _gPurple),
                  _statRow('Last Updated', d.lastUpdated != null
                      ? DateFormat('EEE, d MMM yyyy hh:mm a').format(d.lastUpdated!)
                      : 'Never',
                      _gSubtext),
                  const SizedBox(height: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Widget _statRow(String label, String value, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _gSubtext, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

Widget _SummaryTile({
  required String label,
  required String value,
  required Color color,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(
      color: _gCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _gBorder),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: _gSubtext, fontSize: 10)),
            ],
          ),
        ),
      ],
    ),
  );
}
