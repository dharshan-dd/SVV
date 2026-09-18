import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/region.dart';
import '../models/model_type.dart';
import '../models/collection_bag.dart';
import '../models/bag_configuration.dart';
import '../models/collection_cycle.dart';
import '../providers/app_providers.dart';
import '../services/supabase_service.dart';
import '../services/collection_calculation_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/index.dart';
import '../widgets/app_drawer.dart';

class DailyTrackingScreen extends ConsumerStatefulWidget {
  const DailyTrackingScreen({super.key});

  @override
  ConsumerState<DailyTrackingScreen> createState() => _DailyTrackingScreenState();
}

class _DailyTrackingScreenState extends ConsumerState<DailyTrackingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedRegionId;
  String? _selectedModelId;
  String? _selectedBagId;

  List<BagConfiguration> _configs = [];
  List<CollectionCycle> _cycles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    setState(() => _isLoading = true);
    final service = ref.read(supabaseServiceProvider);
    final configs = await service.getBagConfigurations();
    if (!mounted) return;
    setState(() {
      _configs = configs;
      _isLoading = false;
    });
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    if (_selectedRegionId == null ||
        _selectedModelId == null ||
        _selectedBagId == null) {
      setState(() => _cycles = []);
      return;
    }

    final calcService = CollectionCalculationService();
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    
    final cycles = await calcService.getCollectionHistory(
      bagId: _selectedBagId,
      startDate: _selectedDate.subtract(const Duration(days: 30)),
      endDate: _selectedDate.add(const Duration(days: 30)),
    );

    if (!mounted) return;
    setState(() {
      _cycles = cycles.where((c) => c.scheduledDate.isBefore(_selectedDate) || c.scheduledDate.isAtSameMomentAs(_selectedDate)).toList();
    });
  }

  void _proceedToEntry() {
    if (_selectedRegionId == null ||
        _selectedModelId == null ||
        _selectedBagId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date, branch, model, and bag'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final config = _configs.firstWhere(
      (c) => c.bagId == _selectedBagId && c.regionId == _selectedRegionId && c.modelId == _selectedModelId,
      orElse: () => _configs.first,
    );

    final formNotifier = ref.read(dailyEntryFormProvider.notifier);
    formNotifier.setSelections(
      entryDate: _selectedDate,
      regionId: _selectedRegionId!,
      modelId: _selectedModelId!,
      bagId: _selectedBagId!,
      bagConfigurationId: config.id,
    );

    context.go('/daily-entry');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regionsAsync = ref.watch(regionsProvider);
    final modelsAsync = ref.watch(modelsProvider);
    final bagsAsync = ref.watch(collectionBagsProvider);

    final filteredConfigs = _configs.where((c) {
      if (_selectedRegionId != null && c.regionId != _selectedRegionId) return false;
      if (_selectedModelId != null && c.modelId != _selectedModelId) return false;
      return true;
    }).toList();

    final availableBagIds = filteredConfigs.map((c) => c.bagId).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Collection Tracking'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadContext,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.tokens.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.tokens.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    DatePickerField(
                      label: 'Collection Date',
                      date: _selectedDate,
                      onDateSelected: (date) {
                        setState(() => _selectedDate = date);
                        _loadCycles();
                      },
                    ),
                    const SizedBox(height: 16),
                    regionsAsync.when(
                      data: (regions) => CustomDropdownField(
                        label: 'Branch',
                        hint: 'Select branch',
                        value: _selectedRegionId != null
                            ? regions
                                .firstWhere(
                                  (r) => r.id == _selectedRegionId,
                                  orElse: () => regions.first,
                                )
                                .name
                            : null,
                        items: regions.map((r) => r.name).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final region = regions.firstWhere(
                            (r) => r.name == value,
                            orElse: () => regions.first,
                          );
                          setState(() => _selectedRegionId = region.id);
                          _loadCycles();
                        },
                      ),
                      loading: () => const LinearProgressIndicator(minHeight: 48),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 12),
                    modelsAsync.when(
                      data: (models) => CustomDropdownField(
                        label: 'Type / Model',
                        hint: 'Select model',
                        value: _selectedModelId != null
                            ? models
                                .firstWhere(
                                  (m) => m.id == _selectedModelId,
                                  orElse: () => models.first,
                                )
                                .name
                            : null,
                        items: models.map((m) => m.name).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final model = models.firstWhere(
                            (m) => m.name == value,
                            orElse: () => models.first,
                          );
                          setState(() => _selectedModelId = model.id);
                          _loadCycles();
                        },
                      ),
                      loading: () => const LinearProgressIndicator(minHeight: 48),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 12),
                    bagsAsync.when(
                      data: (bags) {
                        final availableBags = availableBagIds.isEmpty
                            ? bags
                            : bags.where((b) => availableBagIds.contains(b.id)).toList();
                        return CustomDropdownField(
                          label: 'Collection Bag',
                          hint: 'Select bag',
                          value: _selectedBagId != null
                              ? availableBags
                                  .firstWhere(
                                    (b) => b.id == _selectedBagId,
                                    orElse: () => availableBags.first,
                                  )
                                  .name
                              : null,
                          items: availableBags.map((b) => b.name).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final bag = availableBags.firstWhere(
                              (b) => b.name == value,
                              orElse: () => availableBags.first,
                            );
                            setState(() => _selectedBagId = bag.id);
                            _loadCycles();
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(minHeight: 48),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_selectedRegionId != null &&
                  _selectedModelId != null &&
                  _selectedBagId != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.tokens.info.withValues(alpha: 0.10),
                        context.tokens.info.withValues(alpha: 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.tokens.info.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_rounded, color: context.tokens.info, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Collection Context',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.tokens.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _cycles.isNotEmpty
                          ? Column(
                              children: _cycles.map((cycle) {
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
                                  color: context.tokens.card,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: context.tokens.border, width: 0.5),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    title: Text(
                                      dateStr,
                                      style: TextStyle(fontWeight: FontWeight.w600, color: context.tokens.foreground),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Expected: ₹${cycle.expectedAmount.toStringAsFixed(2)}', style: TextStyle(color: context.tokens.mutedForeground)),
                                        Text('Collected: ₹${cycle.collectedAmount.toStringAsFixed(2)}', style: TextStyle(color: context.tokens.mutedForeground)),
                                        Text('Pending: ₹${cycle.pendingAmount.toStringAsFixed(2)}', style: TextStyle(color: context.tokens.mutedForeground)),
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
                              }).toList(),
                            )
                          : Text(
                              'No collection history found for this bag',
                              style: TextStyle(color: context.tokens.mutedForeground),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              ElevatedButton(
                onPressed: _proceedToEntry,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: const Text(
                  'Proceed to Collection Entry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
