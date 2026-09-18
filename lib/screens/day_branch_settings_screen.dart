import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/region.dart';
import '../providers/app_providers.dart';
import '../services/supabase_service.dart';
import '../widgets/app_drawer.dart';

class DayBranchSettingsScreen extends ConsumerStatefulWidget {
  const DayBranchSettingsScreen({super.key});

  @override
  ConsumerState<DayBranchSettingsScreen> createState() => _DayBranchSettingsScreenState();
}

class _DayBranchSettingsScreenState extends ConsumerState<DayBranchSettingsScreen> {
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final Map<int, List<Map<String, dynamic>>> _selectedBranches = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final assignmentsAsync = await ref.read(dayBranchAssignmentsProvider.future);
    for (final assignment in assignmentsAsync) {
      final day = assignment['day_of_week'] as int;
      final branchId = assignment['branch_id'] as String;
      final branchName = assignment['region']?['name'] as String? ?? 'Unknown';
      _selectedBranches.putIfAbsent(day, () => []).add({
        'id': assignment['id'] as String,
        'branch_id': branchId,
        'name': branchName,
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveAssignment(int dayOfWeek, String branchId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(supabaseServiceProvider).createDayBranchAssignment(
            dayOfWeek: dayOfWeek,
            branchId: branchId,
          );
      await _loadAssignments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(supabaseServiceProvider).deleteDayBranchAssignment(assignmentId);
      await _loadAssignments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment deleted successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regionsAsync = ref.watch(regionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day-Branch Assignment'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAssignments,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Configure Branch Assignments',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Assign branches to specific days of the week. The app will automatically open the assigned branch on that day.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(7, (index) {
                      final dayOfWeek = index + 1;
                      final dayName = _days[index];
                      final assignedBranches = _selectedBranches[dayOfWeek] ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    dayName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    assignedBranches.isEmpty
                                        ? 'No branch assigned'
                                        : '${assignedBranches.length} branch${assignedBranches.length > 1 ? "es" : ""} assigned',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: assignedBranches.isEmpty
                                          ? Colors.grey.shade600
                                          : Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (assignedBranches.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...assignedBranches.map((branch) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 18, color: Colors.green),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          branch['name'],
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_rounded, color: Colors.red.shade600, size: 20),
                                        onPressed: () => _deleteAssignment(branch['id']),
                                        tooltip: 'Remove assignment',
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            const SizedBox(height: 12),
                            regionsAsync.when(
                              data: (regions) {
                                if (regions.isEmpty) {
                                  return const Text('No branches available');
                                }
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            hint: const Text('Add branch to this day'),
                                            isExpanded: true,
                                            style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
                                            items: regions.map((region) {
                                              final isAssigned = assignedBranches.any((b) => b['branch_id'] == region.id);
                                              return DropdownMenuItem<String>(
                                                value: region.id,
                                                enabled: !isAssigned,
                                                child: Text(
                                                  region.name + (isAssigned ? ' (assigned)' : ''),
                                                  style: TextStyle(
                                                    color: isAssigned ? Colors.grey : null,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              if (value != null) {
                                                final isAssigned = assignedBranches.any((b) => b['branch_id'] == value);
                                                if (!isAssigned) {
                                                  _saveAssignment(dayOfWeek, value);
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const LinearProgressIndicator(minHeight: 36),
                              error: (e, _) => Text('Error: $e'),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}
