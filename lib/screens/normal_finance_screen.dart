import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/region.dart';
import '../providers/app_providers.dart';
import '../services/supabase_service.dart';
import '../widgets/app_drawer.dart';

class NormalFinanceScreen extends ConsumerStatefulWidget {
  const NormalFinanceScreen({super.key});

  @override
  ConsumerState<NormalFinanceScreen> createState() => _NormalFinanceScreenState();
}

class _NormalFinanceScreenState extends ConsumerState<NormalFinanceScreen> {
  String? _autoSelectedBranchId;
  bool _autoLoaded = false;

  @override
  void initState() {
    super.initState();
    _applyTodayBranchIfNeeded();
  }

  Future<void> _applyTodayBranchIfNeeded() async {
    final manual = ref.read(manualBranchProvider);
    if (manual.isManualOverride && manual.selectedBranchId != null) return;
    if (_autoLoaded) return;

    final assignments = await ref.read(todayBranchesProvider.future);
    if (!mounted) return;
    if (assignments.isNotEmpty) {
      final first = assignments.first['branch_id'] as String;
      setState(() {
        _autoSelectedBranchId = first;
        _autoLoaded = true;
      });
      ref.read(manualBranchProvider.notifier).setManualBranch(first);
    } else {
      setState(() {
        _autoSelectedBranchId = null;
        _autoLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final manualBranch = ref.watch(manualBranchProvider);
    final todayBranchesAsync = ref.watch(todayBranchesProvider);
    final regionsAsync = ref.watch(regionsProvider);

    String? selectedBranchId = manualBranch.selectedBranchId ?? _autoSelectedBranchId;
    final todayBranches = todayBranchesAsync.value ?? const [];

    if (selectedBranchId == null && todayBranches.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_autoLoaded) {
          _applyTodayBranchIfNeeded();
        }
      });
    }

    List<Map<String, dynamic>> branchOptions = [];
    if (todayBranches.isNotEmpty) {
      branchOptions = todayBranches.map((a) {
        final regionData = a['region'] as Map<String, dynamic>?;
        return {
          'id': a['branch_id'] as String,
          'name': regionData?['name'] as String? ?? 'Unknown Branch',
        };
      }).toList();
    } else if (regionsAsync.value != null) {
      branchOptions = regionsAsync.value!.map((r) => {'id': r.id, 'name': r.name}).toList();
    }

    String? selectedBranchName;
    if (selectedBranchId != null && branchOptions.isNotEmpty) {
      try {
        selectedBranchName = branchOptions.firstWhere((b) => b['id'] == selectedBranchId)['name'] as String?;
      } catch (_) {
        selectedBranchName = branchOptions.isNotEmpty ? branchOptions.first['name'] as String? : null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Normal Finance'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          if (selectedBranchId != null)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    selectedBranchName ?? 'Branch',
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(todayBranchesProvider);
              ref.invalidate(regionsProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayBranchesProvider);
          ref.invalidate(regionsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedBranchId == null)
                _buildEmptyState(theme)
              else ...[
                _buildBranchChips(theme, branchOptions, selectedBranchId),
                const SizedBox(height: 18),
                _buildDashboard(theme, selectedBranchId, today),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.calendar_today_rounded, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              'No Branch Assigned Today',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Today has no branch assignment. You can pick any branch below to view its data.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildManualBranchPicker(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildManualBranchPicker(ThemeData theme) {
    final regionsAsync = ref.watch(regionsProvider);
    return regionsAsync.when(
      data: (regions) {
        if (regions.isEmpty) return const Text('No branches available');
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text('Select branch'),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down_rounded, color: theme.primaryColor),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF212121)),
                    items: regions.map((r) => DropdownMenuItem<String>(value: r.id, child: Text(r.name))).toList(),
                    onChanged: (value) {
                      if (value != null) ref.read(manualBranchProvider.notifier).setManualBranch(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildBranchChips(ThemeData theme, List<Map<String, dynamic>> branches, String selectedBranchId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, color: theme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedBranchId,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, color: theme.primaryColor),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
                items: branches.map((b) => DropdownMenuItem<String>(value: b['id'] as String, child: Text(b['name']))).toList(),
                onChanged: (value) {
                  if (value != null) ref.read(manualBranchProvider.notifier).setManualBranch(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme, String branchId, DateTime date) {
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Branch Dashboard', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(dateFormat.format(date), style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(DateFormat('EEEE').format(date), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _statCard(theme, 'Today\'s Collections', '₹0', Colors.green, Icons.trending_up_rounded),
            _statCard(theme, 'Total Entries', '0', Colors.blue, Icons.receipt_long_rounded),
            _statCard(theme, 'Active Lines', '0', Colors.purple, Icons.account_balance_rounded),
            _statCard(theme, 'Pending', '0', Colors.orange, Icons.pending_rounded),
          ],
        ),
        const SizedBox(height: 20),
        Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _actionCard(context, 'Daily Entry', Icons.edit_note_rounded, Colors.green, '/daily-entry'),
            _actionCard(context, 'Weekly Entry', Icons.calendar_view_week_rounded, Colors.blue, '/weekly-entry'),
            _actionCard(context, 'Monthly Entry', Icons.calendar_month_rounded, Colors.purple, '/monthly-entry'),
            _actionCard(context, 'Day-Branch Settings', Icons.calendar_today_rounded, Colors.teal, '/day-branch-settings'),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, String title, IconData icon, Color color, String route) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
