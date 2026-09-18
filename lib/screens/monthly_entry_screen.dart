import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/region.dart';
import '../models/model_type.dart';
import '../models/collection_bag.dart';
import '../models/daily_collection_entry.dart';
import '../providers/app_providers.dart';
import '../services/supabase_service.dart';
import '../widgets/index.dart';
import '../widgets/app_drawer.dart';

class MonthlyEntryScreen extends ConsumerStatefulWidget {
  const MonthlyEntryScreen({super.key});

  @override
  ConsumerState<MonthlyEntryScreen> createState() => _MonthlyEntryScreenState();
}

class _MonthlyEntryScreenState extends ConsumerState<MonthlyEntryScreen> {
  final _scrollController = ScrollController();
  DateTime? _monthStartDate;

  // Form fields
  final _netAmountController = TextEditingController();
  final _collectedAmountController = TextEditingController();
  final _remainingAmountController = TextEditingController(text: '0');
  final _remainingReasonController = TextEditingController();
  final _documentFeesController = TextEditingController();
  final _adapAmountController = TextEditingController();
  final _rrGpayAmountController = TextEditingController();
  final _expenseController = TextEditingController();
  final _additionalCollectionController = TextEditingController();
  final _additionalDeductionController = TextEditingController();
  final _otherAmountController = TextEditingController();

  String? _selectedRegionId;
  String? _selectedModelId;
  String? _selectedBagId;

  @override
  void initState() {
    super.initState();
    _monthStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  Future<void> _selectMonthStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _monthStartDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _monthStartDate = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  double _parseAmount(String text) {
    return double.tryParse(text.replaceAll(',', '')) ?? 0.0;
  }

  double get _totalAmount {
    final netAmount = _parseAmount(_netAmountController.text);
    final collectedAmount = _parseAmount(_collectedAmountController.text);
    final remainingAmount = _parseAmount(_remainingAmountController.text);
    final documentFees = _parseAmount(_documentFeesController.text);
    final otherAmount = _parseAmount(_otherAmountController.text);
    final additionalCollection = _parseAmount(_additionalCollectionController.text);
    return netAmount + collectedAmount + remainingAmount + documentFees + otherAmount + additionalCollection;
  }

  double get _amountAfterAdap {
    final totalAmount = _totalAmount;
    final adapAmount = _parseAmount(_adapAmountController.text);
    return totalAmount - adapAmount;
  }

  double get _amountAfterGpay {
    final amountAfterAdap = _amountAfterAdap;
    final rrGpayAmount = _parseAmount(_rrGpayAmountController.text);
    return amountAfterAdap - rrGpayAmount;
  }

  double get _finalBalance {
    final amountAfterGpay = _amountAfterGpay;
    final expense = _parseAmount(_expenseController.text);
    final additionalDeduction = _parseAmount(_additionalDeductionController.text);
    return amountAfterGpay - expense - additionalDeduction;
  }

  bool get _isFormValid {
    return _selectedRegionId != null &&
        _selectedModelId != null &&
        _selectedBagId != null &&
        _monthStartDate != null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _netAmountController.dispose();
    _collectedAmountController.dispose();
    _remainingAmountController.dispose();
    _remainingReasonController.dispose();
    _documentFeesController.dispose();
    _adapAmountController.dispose();
    _rrGpayAmountController.dispose();
    _expenseController.dispose();
    _additionalCollectionController.dispose();
    _additionalDeductionController.dispose();
    _otherAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regionsAsync = ref.watch(regionsProvider);
    final modelsAsync = ref.watch(modelsProvider);
    final bagsAsync = ref.watch(collectionBagsProvider);
    final formStatus = ref.watch(formSubmissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Collection Entry'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(regionsProvider);
          ref.invalidate(modelsProvider);
          ref.invalidate(collectionBagsProvider);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Month Start Date
                InkWell(
                  onTap: _selectMonthStart,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Month Starting',
                      hintText: 'Select month start date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    child: Text(
                      _monthStartDate != null
                          ? DateFormat('MMMM yyyy').format(_monthStartDate!)
                          : 'Select month start date',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cascading Dropdowns
                regionsAsync.when(
                  data: (regions) {
                    return CustomDropdownField(
                      label: 'Region',
                      hint: 'Select region',
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
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 48),
                  error: (e, _) => Text('Error loading regions: $e'),
                ),

                const SizedBox(height: 12),

                modelsAsync.when(
                  data: (models) {
                    return CustomDropdownField(
                      label: 'Type / Model',
                      hint: 'Select type',
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
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 48),
                  error: (e, _) => Text('Error loading models: $e'),
                ),

                const SizedBox(height: 12),

                bagsAsync.when(
                  data: (bags) {
                    return CustomDropdownField(
                      label: 'Area / Bag',
                      hint: 'Select bag',
                      value: _selectedBagId != null
                          ? bags
                              .firstWhere(
                                (b) => b.id == _selectedBagId,
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
                        setState(() => _selectedBagId = bag.id);
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 48),
                  error: (e, _) => Text('Error loading bags: $e'),
                ),

                const SizedBox(height: 24),

                // Section 1: Amounts in Hand / Starting
                const SectionHeader(
                  title: '1. AMOUNTS IN HAND / STARTING',
                  color: Colors.blue,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _netAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Net Amount in Hand',
                          hintText: 'Enter net amount in hand',
                          prefixIcon: Icon(Icons.money_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _collectedAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Collected Amount on That Day',
                          hintText: 'Enter collected amount',
                          prefixIcon: Icon(Icons.collections_bookmark_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: Additional Amounts
                const SectionHeader(
                  title: '2. ADDITIONAL AMOUNTS',
                  color: Colors.purple,
                  icon: Icons.add_circle_rounded,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _remainingAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Remaining Amount (Editable)',
                          hintText: 'Enter remaining amount with reason',
                          prefixIcon: Icon(Icons.pending_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _remainingReasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Remaining Amount',
                          hintText: 'Enter reason',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _documentFeesController,
                        decoration: const InputDecoration(
                          labelText: 'Document Fees',
                          hintText: 'Enter document fees',
                          prefixIcon: Icon(Icons.description_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otherAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Other Amount',
                          hintText: 'Enter other amount',
                          prefixIcon: Icon(Icons.more_horiz_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 3: Total Amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_rounded, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(_totalAmount),
                              style: TextStyle(
                                fontSize: 22,
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

                const SizedBox(height: 24),

                // Section 4: ADAP / Customer Return
                const SectionHeader(
                  title: '3. ADAP / CUSTOMER RETURN',
                  color: Colors.red,
                  icon: Icons.arrow_back_rounded,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _adapAmountController,
                        decoration: const InputDecoration(
                          labelText: 'ADAP / Amount Given Back to Customer',
                          hintText: 'Enter ADAP amount',
                          prefixIcon: Icon(Icons.money_off_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Amount After ADAP: ${NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(_amountAfterAdap)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 5: R.R. / GPay
                const SectionHeader(
                  title: '4. R.R. / GPAY AMOUNT RECEIVED',
                  color: Colors.teal,
                  icon: Icons.payment_rounded,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _rrGpayAmountController,
                        decoration: const InputDecoration(
                          labelText: 'R.R. / GPay Amount Received',
                          hintText: 'Enter GPay amount',
                          prefixIcon: Icon(Icons.qr_code_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_rounded, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Amount After GPay: ${NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(_amountAfterGpay)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 6: Expenses / Deductions
                const SectionHeader(
                  title: '5. EXPENSES / DEDUCTIONS',
                  color: Colors.orange,
                  icon: Icons.remove_circle_rounded,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _expenseController,
                        decoration: const InputDecoration(
                          labelText: 'Expense / Next Deduction',
                          hintText: 'Enter expense amount',
                          prefixIcon: Icon(Icons.money_off_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _additionalDeductionController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Deduction',
                          hintText: 'Enter additional deduction',
                          prefixIcon: Icon(Icons.remove_circle_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Final Balance Display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _finalBalance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _finalBalance >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_rounded,
                            size: 32,
                            color: _finalBalance >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FINAL BALANCE',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(_finalBalance),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: _finalBalance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(_totalAmount),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'After ADAP:',
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(_amountAfterAdap),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'After GPay:',
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(_amountAfterGpay),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                if (formStatus.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (formStatus.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      formStatus.error!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ElevatedButton(
                  onPressed: _isFormValid && !formStatus.isLoading
                      ? _submitEntry
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Submit Monthly Entry',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    if (_monthStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a month start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final service = ref.read(supabaseServiceProvider);

    try {
      await service.createMonthlyEntry(
        monthStartDate: _monthStartDate!,
        regionId: _selectedRegionId!,
        modelId: _selectedModelId!,
        bagId: _selectedBagId!,
        netAmount: _parseAmount(_netAmountController.text),
        collectedAmount: _parseAmount(_collectedAmountController.text),
        remainingAmount: _parseAmount(_remainingAmountController.text),
        remainingReason: _remainingReasonController.text,
        documentFees: _parseAmount(_documentFeesController.text),
        adapAmount: _parseAmount(_adapAmountController.text),
        rrGpayAmount: _parseAmount(_rrGpayAmountController.text),
        expense: _parseAmount(_expenseController.text),
        additionalCollection: _parseAmount(_additionalCollectionController.text),
        additionalDeduction: _parseAmount(_additionalDeductionController.text),
        otherAmount: _parseAmount(_otherAmountController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monthly entry submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _netAmountController.clear();
        _collectedAmountController.clear();
        _remainingAmountController.text = '0';
        _remainingReasonController.clear();
        _documentFeesController.clear();
        _adapAmountController.clear();
        _rrGpayAmountController.clear();
        _expenseController.clear();
        _additionalCollectionController.clear();
        _additionalDeductionController.clear();
        _otherAmountController.clear();
        setState(() {
          _selectedRegionId = null;
          _selectedModelId = null;
          _selectedBagId = null;
        });
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
    }
  }
}
