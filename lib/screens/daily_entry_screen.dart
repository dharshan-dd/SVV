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
import '../models/daily_collection_entry.dart';
import '../providers/app_providers.dart';
import '../services/supabase_service.dart';
import '../services/collection_calculation_service.dart';
import '../widgets/index.dart';
import '../widgets/app_drawer.dart';

class DailyEntryScreen extends ConsumerStatefulWidget {
  const DailyEntryScreen({super.key});

  @override
  ConsumerState<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends ConsumerState<DailyEntryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    ref.invalidate(regionsProvider);
    ref.invalidate(modelsProvider);
    ref.invalidate(collectionBagsProvider);
    ref.invalidate(todayEntriesProvider);
  }

  void _loadCycleInfo() {
    final formState = ref.read(dailyEntryFormProvider);
    if (formState.bagId == null || formState.entryDate == null) return;

    final calcService = CollectionCalculationService();
    final service = ref.read(supabaseServiceProvider);
    final bagId = formState.bagId!;
    final entryDate = formState.entryDate!;

    Future<Map<String, dynamic>> futureResult;
    if (formState.bagConfigurationId != null && formState.bagConfigurationId!.isNotEmpty) {
      futureResult = calcService.calculateCollectionDue(
        bagConfigurationId: formState.bagConfigurationId!,
        bagId: bagId,
        date: entryDate,
      );
    } else {
      futureResult = service.getBagConfigurations().then((configs) {
        final config = configs.firstWhere(
          (c) => c.bagId == bagId,
          orElse: () => configs.isEmpty
              ? BagConfiguration(id: '', entity: '', regionId: '', modelId: '', bagId: bagId, frequency: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), startDate: DateTime.now(), endDate: DateTime.now())
              : configs.first,
        );
        return calcService.calculateCollectionDue(
          bagConfigurationId: config.id,
          bagId: bagId,
          date: entryDate,
        );
      });
    }

    futureResult.then((result) {
      if (!mounted) return;
      final cycle = result['cycle'] as CollectionCycle?;
      final notifier = ref.read(dailyEntryFormProvider.notifier);
      
      if (cycle != null) {
        notifier.setCollectionCycle(cycle.id);
      }
      notifier.setExpectedAmount(result['currentDue'] as double);
      notifier.setPreviousPending(result['previousPending'] as double);
      notifier.setTotalDue(result['totalDue'] as double);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(dailyEntryFormProvider);
    final regionsAsync = ref.watch(regionsProvider);
    final modelsAsync = ref.watch(modelsProvider);
    final bagsAsync = ref.watch(collectionBagsProvider);
    final formStatus = ref.watch(formSubmissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Collection Entry'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (formStatus.isSuccess)
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              onPressed: () {
                ref.read(formSubmissionProvider.notifier).state =
                    FormSubmissionState();
                ref.read(dailyEntryFormProvider.notifier).reset();
                ref.invalidate(todayEntriesProvider);
              },
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Selection Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: DatePickerField(
                    label: 'Entry Date',
                    date: formState.entryDate,
                    onDateSelected: (date) {
                      ref
                          .read(dailyEntryFormProvider.notifier)
                          .setEntryDate(date);
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Cascading Dropdowns Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      regionsAsync.when(
                        data: (regions) => CustomDropdownField(
                          label: 'Region',
                          hint: 'Select region',
                          value: formState.regionId != null
                              ? regions
                                  .firstWhere(
                                    (r) => r.id == formState.regionId,
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
                            ref
                                .read(dailyEntryFormProvider.notifier)
                                .setRegion(region.id);
                          },
                        ),
                        loading: () => const LinearProgressIndicator(minHeight: 48),
                        error: (e, _) => Text('Error loading regions: $e'),
                      ),

                      const SizedBox(height: 12),

                      modelsAsync.when(
                        data: (models) => CustomDropdownField(
                          label: 'Type / Model',
                          hint: 'Select type',
                          value: formState.modelId != null
                              ? models
                                  .firstWhere(
                                    (m) => m.id == formState.modelId,
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
                            ref
                                .read(dailyEntryFormProvider.notifier)
                                .setModel(model.id);
                          },
                        ),
                        loading: () => const LinearProgressIndicator(minHeight: 48),
                        error: (e, _) => Text('Error loading models: $e'),
                      ),

                      const SizedBox(height: 12),

                       bagsAsync.when(
                         data: (bags) => CustomDropdownField(
                           label: 'Area / Bag',
                           hint: 'Select bag',
                           value: formState.bagId != null
                               ? bags
                                   .firstWhere(
                                     (b) => b.id == formState.bagId,
                                     orElse: () => bags.first,
                                   )
                                   .name
                               : null,
                           items: bags.map((b) => b.name).toList(),
                           onChanged: (value) {
                             if (value == null) return;
                             final bag = bags.firstWhere(
                               (b) => b.name == value,
                               orElse: () => bags.first,
                             );
                             ref
                                 .read(dailyEntryFormProvider.notifier)
                                 .setBag(bag.id);
                             WidgetsBinding.instance.addPostFrameCallback((_) {
                               if (mounted) _loadCycleInfo();
                             });
                           },
                         ),
                         loading: () => const LinearProgressIndicator(minHeight: 48),
                         error: (e, _) => Text('Error loading bags: $e'),
                       ),
                     ],
                   ),
                 ),

                 if (formState.expectedAmount > 0 || formState.previousPending > 0) ...[
                   const SizedBox(height: 16),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.purple.shade50,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: Colors.purple.shade200),
                     ),
                     child: Column(
                       children: [
                         Row(
                           children: [
                             Icon(Icons.calendar_today_rounded, color: Colors.purple.shade700, size: 20),
                             const SizedBox(width: 10),
                             Text(
                               'Collection Cycle Info',
                               style: TextStyle(
                                 fontSize: 15,
                                 fontWeight: FontWeight.w600,
                                 color: Colors.purple.shade700,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),
                         Row(
                           children: [
                             Expanded(
                               child: _InfoTile(
                                 label: 'Expected',
                                 value: NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(formState.expectedAmount),
                                 color: Colors.blue,
                               ),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                               child: _InfoTile(
                                 label: 'Previous Pending',
                                 value: NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(formState.previousPending),
                                 color: formState.previousPending > 0 ? Colors.orange : Colors.grey,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),
                         Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: Colors.purple.shade100,
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: Colors.purple.shade300),
                           ),
                           child: Row(
                             children: [
                               const Icon(Icons.calculate_rounded, color: Colors.purple, size: 20),
                               const SizedBox(width: 10),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       'Total Due',
                                       style: TextStyle(
                                         fontSize: 12,
                                         color: Colors.purple.shade700,
                                         fontWeight: FontWeight.w500,
                                       ),
                                     ),
                                     Text(
                                       NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(formState.totalDue),
                                       style: TextStyle(
                                         fontSize: 18,
                                         fontWeight: FontWeight.bold,
                                         color: Colors.purple.shade800,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                 ],

                const SizedBox(height: 20),

                // Credit Section
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade50,
                        Colors.green.shade50.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'CREDIT (Income)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            NumericInputField(
                              label: 'Opening Balance',
                              hint: 'Enter opening balance',
                              value: formState.openingBalance,
                              onChanged: (value) {
                                ref
                                    .read(dailyEntryFormProvider.notifier)
                                    .setOpeningBalance(value);
                              },
                              prefixIcon: Icons.account_balance_wallet_rounded,
                              color: Colors.green,
                            ),
                            NumericInputField(
                              label: 'Collection (Cash)',
                              hint: 'Cash collection',
                              value: formState.collectionCash,
                              onChanged: (value) {
                                ref
                                    .read(dailyEntryFormProvider.notifier)
                                    .setCollectionCash(value);
                              },
                              prefixIcon: Icons.money_rounded,
                              color: Colors.green,
                            ),
                            NumericInputField(
                              label: 'Collection (UPI)',
                              hint: 'UPI collection',
                              value: formState.collectionUpi,
                              onChanged: (value) {
                                ref
                                    .read(dailyEntryFormProvider.notifier)
                                    .setCollectionUpi(value);
                              },
                              prefixIcon: Icons.qr_code_rounded,
                              color: Colors.green,
                            ),
                            NumericInputField(
                              label: 'Document Charges',
                              hint: 'Document charges',
                              value: formState.documentCharges,
                              onChanged: (value) {
                                ref
                                    .read(dailyEntryFormProvider.notifier)
                                    .setDocumentCharges(value);
                              },
                              prefixIcon: Icons.description_rounded,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_circle_rounded, color: Colors.green, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Credit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(formState.totalCredit),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Debit Section
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade50,
                        Colors.orange.shade50.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'DEBIT (Expenses)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            NumericInputField(
                              label: 'New Loan (Cash)',
                              hint: 'New loan cash',
                              value: formState.newLoanCash,
                              onChanged: (value) {
                                ref
                                    .read(dailyEntryFormProvider.notifier)
                                    .setNewLoanCash(value);
                              },
                              prefixIcon: Icons.money_rounded,
                              color: Colors.orange,
                            ),
                            NumericInputField(
                              label: 'New Loan (UPI)',
                              hint: 'New loan UPI',
                              value: formState.newLoanUpi,
                              onChanged: (value) {
                                ref
                                    .read(dailyEntryFormProvider.notifier)
                                    .setNewLoanUpi(value);
                              },
                              prefixIcon: Icons.qr_code_rounded,
                              color: Colors.orange,
                            ),
                            NumericInputField(
                              label: 'Chit Payment',
                              hint: 'Chit payment',
                              value: formState.chitPayment,
                              onChanged: (value) {
                                ref
                                    .read(dailyEntryFormProvider.notifier)
                                    .setChitPayment(value);
                              },
                              prefixIcon: Icons.payments_rounded,
                              color: Colors.orange,
                            ),
                            NumericInputField(
                              label: 'Misc Expenses',
                              hint: 'Miscellaneous expenses',
                              value: formState.miscExpenses,
                              onChanged: (value) {
                                ref
                                    .read(dailyEntryFormProvider.notifier)
                                    .setMiscExpenses(value);
                              },
                              prefixIcon: Icons.miscellaneous_services_rounded,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.remove_circle_rounded, color: Colors.orange, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Debit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(formState.totalDebit),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Net Closing Balance
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: formState.netClosingBalance >= 0
                        ? Colors.blue.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: formState.netClosingBalance >= 0
                          ? Colors.blue.shade300
                          : Colors.red.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (formState.netClosingBalance >= 0 ? Colors.blue : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          formState.netClosingBalance >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 28,
                          color: formState.netClosingBalance >= 0
                              ? Colors.blue.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Closing Balance',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(
                                symbol: '₹',
                                decimalDigits: 2,
                              ).format(formState.netClosingBalance),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: formState.netClosingBalance >= 0
                                    ? Colors.blue.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                if (formStatus.isLoading)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  )
                else if (formStatus.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formStatus.error!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                ElevatedButton(
                  onPressed: formState.isValid && !formStatus.isLoading
                      ? _submitEntry
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: const Text(
                    'Submit Entry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitEntry() async {
    final formState = ref.read(dailyEntryFormProvider);
    final service = ref.read(supabaseServiceProvider);
    final calcService = CollectionCalculationService();

    final success = await ref
        .read(formSubmissionProvider.notifier)
        .submitEntry(service, formState);

    if (success && mounted) {
      if (formState.collectionCycleId != null) {
        await calcService.recordCollection(
          collectionCycleId: formState.collectionCycleId!,
          cashCollected: formState.collectionCash,
          upiCollected: formState.collectionUpi,
        );
      }

      // Reset form and submission state for next entry
      ref.read(dailyEntryFormProvider.notifier).reset();
      ref.read(formSubmissionProvider.notifier).state = FormSubmissionState();
      ref.invalidate(todayEntriesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry submitted successfully!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Go back to tracking screen
      if (mounted) context.go('/daily-tracking');
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
