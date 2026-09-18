import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:microfinance_app/models/daily_cash_record.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/services/collection_calculation_service.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';

const _kPrimary = Color(0xFF1A237E);
const _kAccent = Color(0xFF3949AB);
const _kGold = Color(0xFFFFC107);
const _kSurface = Color(0xFFF5F7FF);
const _kGreen = Color(0xFF00897B);
const _kRed = Color(0xFFE53935);
const _kRadius = 16.0;

class DayRecordEntryScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final String? initialRegionId;
  final String? initialModelId;
  final String? initialBagId;

  const DayRecordEntryScreen({
    super.key,
    this.initialDate,
    this.initialRegionId,
    this.initialModelId,
    this.initialBagId,
  });
  @override
  ConsumerState<DayRecordEntryScreen> createState() => _DayRecordEntryScreenState();
}

class _DayRecordEntryScreenState extends ConsumerState<DayRecordEntryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  DateTime _entryDate = DateTime.now();
  String? _selectedRegionId;
  String? _selectedModelId;
  String? _selectedBagId;

  final _netCtrl = TextEditingController();
  final _collectedCtrl = TextEditingController();
  final _remainingCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _docFeesCtrl = TextEditingController();
  final _adapCtrl = TextEditingController();
  final _gpayCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _extraNetCtrl = TextEditingController();

  final List<Map<String, dynamic>> _extraCollections = [];
  final List<Map<String, dynamic>> _extraExpenses = [];

  bool _submitting = false;
  DailyCashRecord? _existingRecord;
  double get _prevFinal => _d(_netCtrl);
  bool _isEditMode = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    for (final c in [_netCtrl, _collectedCtrl, _remainingCtrl, _docFeesCtrl, _adapCtrl, _gpayCtrl, _expenseCtrl, _otherCtrl, _extraNetCtrl]) {
      c.addListener(() => setState(() {}));
    }
    _entryDate = widget.initialDate ?? DateTime.now();
    _selectedRegionId = widget.initialRegionId;
    _selectedModelId = widget.initialModelId;
    _selectedBagId = widget.initialBagId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedBagId != null) {
        _loadContext();
      }
    });
  }

  void _addExtraCollection() {
    final lc = TextEditingController();
    final ac = TextEditingController();
    final rc = TextEditingController();
    ac.addListener(() => setState(() {}));
    setState(() => _extraCollections.add({'label': lc, 'amount': ac, 'reason': rc}));
  }

  void _removeExtraCollection(int i) {
    (_extraCollections[i]['label'] as TextEditingController).dispose();
    (_extraCollections[i]['amount'] as TextEditingController).dispose();
    (_extraCollections[i]['reason'] as TextEditingController).dispose();
    setState(() => _extraCollections.removeAt(i));
  }

  void _addExtraExpense() {
    final lc = TextEditingController();
    final ac = TextEditingController();
    final rc = TextEditingController();
    ac.addListener(() => setState(() {}));
    setState(() => _extraExpenses.add({'label': lc, 'amount': ac, 'reason': rc}));
  }

  void _removeExtraExpense(int i) {
    (_extraExpenses[i]['label'] as TextEditingController).dispose();
    (_extraExpenses[i]['amount'] as TextEditingController).dispose();
    (_extraExpenses[i]['reason'] as TextEditingController).dispose();
    setState(() => _extraExpenses.removeAt(i));
  }

  void _clearDynamicRows() {
    for (final e in _extraCollections) {
      (e['label'] as TextEditingController).dispose();
      (e['amount'] as TextEditingController).dispose();
      (e['reason'] as TextEditingController).dispose();
    }
    for (final e in _extraExpenses) {
      (e['label'] as TextEditingController).dispose();
      (e['amount'] as TextEditingController).dispose();
      (e['reason'] as TextEditingController).dispose();
    }
    _extraCollections.clear();
    _extraExpenses.clear();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [_netCtrl, _collectedCtrl, _remainingCtrl, _reasonCtrl,
        _docFeesCtrl, _adapCtrl, _gpayCtrl, _expenseCtrl, _otherCtrl, _extraNetCtrl]) {
      c.dispose();
    }
    for (final e in _extraCollections) {
      (e['label'] as TextEditingController).dispose();
      (e['amount'] as TextEditingController).dispose();
      (e['reason'] as TextEditingController).dispose();
    }
    for (final e in _extraExpenses) {
      (e['label'] as TextEditingController).dispose();
      (e['amount'] as TextEditingController).dispose();
      (e['reason'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

  double get _extraCollectionTotal => _extraCollections.fold(0.0, (s, e) => s + _d(e['amount'] as TextEditingController));
  double get _extraExpenseTotal => _extraExpenses.fold(0.0, (s, e) => s + _d(e['amount'] as TextEditingController));

  Map<String, dynamic> get _trail => CollectionCalculationService().calculateDayRecordTrail(
    previousFinalAmount: _prevFinal,
    netAmountInHand: _d(_netCtrl),
    collectedAmount: _d(_collectedCtrl) + _extraCollectionTotal,
    remainingAmount: _d(_remainingCtrl),
    documentFees: _d(_docFeesCtrl),
    adapAmount: _d(_adapCtrl),
    rrGpayAmount: _d(_gpayCtrl),
    expense: _d(_expenseCtrl) + _extraExpenseTotal,
    otherAmount: _d(_otherCtrl),
    extraNetAmount: _d(_extraNetCtrl),
  );

  bool get _ready => _selectedBagId != null;

  Future<void> _loadContext() async {
    if (!_ready) return;
    // For existing record: use stored previous_final_amount (already correct)
    // For new record: get the latest final_amount from previous records
    final svc = ref.read(supabaseServiceProvider);
    DailyCashRecord? existing;
    if (_selectedRegionId != null && _selectedModelId != null) {
      existing = await svc.getDailyCashRecordByDate(
        date: _entryDate, regionId: _selectedRegionId!,
        modelId: _selectedModelId!, bagId: _selectedBagId!,
      );
    }
    double opening = 0.0;
    if (existing != null) {
      opening = existing.previousFinalAmount;
    } else {
      try {
        final records = await svc.getDailyCashRecords(
          startDate: DateTime(2000),
          endDate: _entryDate,
          bagIds: [_selectedBagId!],
        );
        if (records.isNotEmpty) {
          final sorted = [...records]
            ..sort((a, b) {
              final dc = b.entryDate.compareTo(a.entryDate);
              if (dc != 0) return dc;
              return b.updatedAt.compareTo(a.updatedAt);
            });
          opening = sorted.first.finalAmount;
        }
      } catch (_) {
        opening = 0.0;
      }
    }
    if (!mounted) return;
    setState(() {
      _existingRecord = existing;
      _isEditMode = existing != null;
      for (final c in [_netCtrl, _collectedCtrl, _remainingCtrl, _reasonCtrl,
          _docFeesCtrl, _adapCtrl, _gpayCtrl, _expenseCtrl, _otherCtrl, _extraNetCtrl]) {
        c.clear();
      }
      _netCtrl.text = opening > 0 ? opening.toStringAsFixed(2) : '';
      _clearDynamicRows();
      if (existing != null) {
        _collectedCtrl.text = existing.collectedAmount > 0 ? existing.collectedAmount.toStringAsFixed(2) : '';
        _remainingCtrl.text = existing.remainingAmount > 0 ? existing.remainingAmount.toStringAsFixed(2) : '';
        _reasonCtrl.text = existing.remainingReason;
        _docFeesCtrl.text = existing.documentFees > 0 ? existing.documentFees.toStringAsFixed(2) : '';
        _adapCtrl.text = existing.adapAmount > 0 ? existing.adapAmount.toStringAsFixed(2) : '';
        _gpayCtrl.text = existing.rrGpayAmount > 0 ? existing.rrGpayAmount.toStringAsFixed(2) : '';
        _expenseCtrl.text = existing.expense > 0 ? existing.expense.toStringAsFixed(2) : '';
        _otherCtrl.text = existing.otherAmount > 0 ? existing.otherAmount.toStringAsFixed(2) : '';
        _extraNetCtrl.text = existing.extraNetAmount > 0 ? existing.extraNetAmount.toStringAsFixed(2) : '';
      }
    });
  }

  DateTime _weekStart(DateTime d) {
    final m = d.subtract(Duration(days: d.weekday - 1));
    return DateTime(m.year, m.month, m.day);
  }

  Future<void> _submit() async {
    if (!_ready || _selectedRegionId == null || _selectedModelId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Select Region, Model, and Bag first', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final svc = ref.read(supabaseServiceProvider);
    try {
      // Always upsert: re-check for existing record at submit time
      final existing = _existingRecord ?? await svc.getDailyCashRecordByDate(
        date: _entryDate, regionId: _selectedRegionId!,
        modelId: _selectedModelId!, bagId: _selectedBagId!,
      );
      final saved = existing != null
          ? await svc.updateDailyCashRecord(
              id: existing.id, entryDate: _entryDate,
              regionId: _selectedRegionId!, modelId: _selectedModelId!, bagId: _selectedBagId!,
              weekStartDate: _weekStart(_entryDate), dayOfWeek: _entryDate.weekday % 7,
              netAmountInHand: _d(_netCtrl), collectedAmount: _d(_collectedCtrl) + _extraCollectionTotal,
              remainingAmount: _d(_remainingCtrl), remainingReason: _reasonCtrl.text.trim(),
              documentFees: _d(_docFeesCtrl), adapAmount: _d(_adapCtrl),
              rrGpayAmount: _d(_gpayCtrl), expense: _d(_expenseCtrl) + _extraExpenseTotal,
              otherAmount: _d(_otherCtrl), previousFinalAmount: _prevFinal,
               additionalCollection: _extraCollectionTotal,
               extraNetAmount: _d(_extraNetCtrl),
             )
             : await svc.createDailyCashRecord(
                 entryDate: _entryDate, regionId: _selectedRegionId!,
                 modelId: _selectedModelId!, bagId: _selectedBagId!,
                 weekStartDate: _weekStart(_entryDate), dayOfWeek: _entryDate.weekday % 7,
                 netAmountInHand: _d(_netCtrl), collectedAmount: _d(_collectedCtrl) + _extraCollectionTotal,
                 remainingAmount: _d(_remainingCtrl), remainingReason: _reasonCtrl.text.trim(),
                 documentFees: _d(_docFeesCtrl), adapAmount: _d(_adapCtrl),
                 rrGpayAmount: _d(_gpayCtrl), expense: _d(_expenseCtrl) + _extraExpenseTotal,
                 otherAmount: _d(_otherCtrl), previousFinalAmount: _prevFinal,
                 additionalCollection: _extraCollectionTotal,
                 extraNetAmount: _d(_extraNetCtrl),
             );

      if (!mounted) return;
      final calc = CollectionCalculationService();
      final newOpening = await calc.getLatestFinalAmount(
        bagId: _selectedBagId!, onOrBeforeDate: _entryDate,
      );
      if (!mounted) return;
      setState(() {
        _existingRecord = saved;
        _isEditMode = true;
    for (final c in [_netCtrl, _collectedCtrl, _remainingCtrl, _reasonCtrl,
        _docFeesCtrl, _adapCtrl, _gpayCtrl, _expenseCtrl, _otherCtrl]) {
      c.clear();
    }
        _clearDynamicRows();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(existing != null ? 'Record updated' : 'Record saved',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Error: $e')),
          ]),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2);
    final trail = _trail;
    return Scaffold(
      backgroundColor: _kSurface,
      drawer: const AppDrawer(),
      body: CustomScrollView(slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 20),
                  _selectionCard(),
                  if (_ready) ...[
                    const SizedBox(height: 16),
                    _openingCard(fmt),
                    const SizedBox(height: 16),
                    _liveBanner(trail, fmt),
                    const SizedBox(height: 16),
                    _inputsCard(),
                    const SizedBox(height: 16),
                    _deductionsCard(trail, fmt),
                    const SizedBox(height: 16),
                    _analyticsCard(trail, fmt),
                    const SizedBox(height: 16),
                    _trailCard(trail, fmt),
                    const SizedBox(height: 24),
                    _submitBtn(),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: _kPrimary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
        title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEditMode ? 'Edit Day Record' : 'New Day Record',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(DateFormat('EEEE, d MMM yyyy').format(_entryDate),
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_kPrimary, _kAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Icon(Icons.receipt_long_rounded, size: 72, color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionCard() {
    final regionsAsync = ref.watch(regionsProvider);
    final modelsAsync = ref.watch(modelsProvider);
    final bagsAsync = ref.watch(collectionBagsProvider);
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Label(icon: Icons.tune_rounded, text: 'Select Context', color: _kAccent),
      const SizedBox(height: 16),
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final p = await showDatePicker(
            context: context, initialDate: _entryDate,
            firstDate: DateTime(2020), lastDate: DateTime(2100),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kPrimary)),
              child: child!,
            ),
          );
          if (p != null) { setState(() => _entryDate = p); _loadContext(); }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: _kAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(DateFormat('EEEE, d MMMM yyyy').format(_entryDate),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade500),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      regionsAsync.when(
        data: (regions) => _Drop(
          label: 'Branch', icon: Icons.location_city_rounded,
          value: _selectedRegionId != null ? regions.firstWhere((r) => r.id == _selectedRegionId, orElse: () => regions.first).name : null,
          items: regions.map((r) => r.name).toList(),
          onChanged: (v) { if (v == null) return; final r = regions.firstWhere((x) => x.name == v); setState(() => _selectedRegionId = r.id); _loadContext(); },
        ),
        loading: () => const _Skel(), error: (e, _) => Text('$e'),
      ),
      const SizedBox(height: 12),
      modelsAsync.when(
        data: (models) => _Drop(
          label: 'Model', icon: Icons.category_rounded,
          value: _selectedModelId != null ? models.firstWhere((m) => m.id == _selectedModelId, orElse: () => models.first).name : null,
          items: models.map((m) => m.name).toList(),
          onChanged: (v) { if (v == null) return; final m = models.firstWhere((x) => x.name == v); setState(() => _selectedModelId = m.id); _loadContext(); },
        ),
        loading: () => const _Skel(), error: (e, _) => Text('$e'),
      ),
      const SizedBox(height: 12),
      bagsAsync.when(
        data: (bags) => _Drop(
          label: 'Bag', icon: Icons.work_rounded,
          value: _selectedBagId != null ? bags.firstWhere((b) => b.id == _selectedBagId, orElse: () => bags.first).name : null,
          items: bags.map((b) => b.name).toList(),
          onChanged: (v) { if (v == null) return; final b = bags.firstWhere((x) => x.name == v); setState(() => _selectedBagId = b.id); _loadContext(); },
        ),
        loading: () => const _Skel(), error: (e, _) => Text('$e'),
      ),
    ]));
  }

  Widget _openingCard(NumberFormat fmt) {
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Label(icon: Icons.account_balance_wallet_rounded, text: 'Opening Balance', color: _kGreen),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_kGreen.withValues(alpha: 0.08), _kGreen.withValues(alpha: 0.02)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
        ),
         child: Row(children: [
           Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.12), shape: BoxShape.circle),
             child: const Icon(Icons.arrow_forward_rounded, color: _kGreen, size: 20),
           ),
           const SizedBox(width: 14),
           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             const Text('Opening Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
             Text(fmt.format(_d(_netCtrl)),
                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kGreen)),
             ]),
          ]),
        ),
      ]));
  }

  Widget _liveBanner(Map<String, dynamic> trail, NumberFormat fmt) {
    final final_ = (trail['finalAmount'] as double?) ?? 0.0;
    final total = (trail['totalAmount'] as double?) ?? 0.0;
    final isPos = final_ >= 0;
    final color = isPos ? _kGreen : _kRed;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(_kRadius),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Icon(isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 32),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Live Final Amount', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(fmt.format(final_), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('Total In', style: TextStyle(color: Colors.white60, fontSize: 11)),
          Text(fmt.format(total), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _inputsCard() {
    final fmt = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2);
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const _Label(icon: Icons.add_circle_rounded, text: 'Collections', color: _kAccent),
        TextButton.icon(
          onPressed: _addExtraCollection,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: _kAccent, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
        ),
      ]),
      const SizedBox(height: 4),
      _Field(ctrl: _netCtrl, label: 'Opening Balance (Net in Hand)', icon: Icons.account_balance_rounded),
      const SizedBox(height: 12),
      _Field(ctrl: _collectedCtrl, label: 'Collected Amount', icon: Icons.payments_rounded),
      const SizedBox(height: 12),
      _ExtraNetRow(extraNetCtrl: _extraNetCtrl, onNetAdd: _showExtraNetDialog),
      const SizedBox(height: 12),
      _Field(ctrl: _remainingCtrl, label: 'Remaining Amount', icon: Icons.pending_rounded),
      const SizedBox(height: 12),
      TextFormField(
        controller: _reasonCtrl,
        decoration: InputDecoration(
          labelText: 'Remaining Reason',
          prefixIcon: const Icon(Icons.notes_rounded, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      const SizedBox(height: 12),
      _Field(ctrl: _docFeesCtrl, label: 'Document Fees', icon: Icons.description_rounded),
      for (int i = 0; i < _extraCollections.length; i++) ...[
        const SizedBox(height: 12),
        _ExtraRow(
          labelCtrl: _extraCollections[i]['label'] as TextEditingController,
          amountCtrl: _extraCollections[i]['amount'] as TextEditingController,
          reasonCtrl: _extraCollections[i]['reason'] as TextEditingController,
          hint: 'Collection label',
          icon: Icons.payments_rounded,
          color: _kAccent,
          onRemove: () => _removeExtraCollection(i),
        ),
      ],
      if (_extraCollections.isNotEmpty) ...[
        const SizedBox(height: 8),
        _ResultRow(label: 'Extra Collections Total', value: fmt.format(_extraCollectionTotal), color: _kAccent),
      ],
    ]));
  }

  Widget _deductionsCard(Map<String, dynamic> trail, NumberFormat fmt) {
    final afterAdap = (trail['amountAfterAdap'] as double?) ?? 0.0;
    final afterGpay = (trail['amountAfterGpay'] as double?) ?? 0.0;
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const _Label(icon: Icons.remove_circle_rounded, text: 'Deductions', color: _kRed),
        TextButton.icon(
          onPressed: _addExtraExpense,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: _kRed, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
        ),
      ]),
      const SizedBox(height: 4),
      _Field(ctrl: _adapCtrl, label: 'ADAP Amount', icon: Icons.swap_horiz_rounded),
      const SizedBox(height: 6),
      _ResultRow(label: 'After ADAP', value: fmt.format(afterAdap), color: _kAccent),
      const SizedBox(height: 12),
      _Field(ctrl: _gpayCtrl, label: 'RR GPay Amount', icon: Icons.phone_android_rounded),
      const SizedBox(height: 6),
      _ResultRow(label: 'After GPay', value: fmt.format(afterGpay), color: _kAccent),
      const SizedBox(height: 12),
      _Field(ctrl: _expenseCtrl, label: 'Expense', icon: Icons.receipt_rounded),
      for (int i = 0; i < _extraExpenses.length; i++) ...[
        const SizedBox(height: 12),
        _ExtraRow(
          labelCtrl: _extraExpenses[i]['label'] as TextEditingController,
          amountCtrl: _extraExpenses[i]['amount'] as TextEditingController,
          reasonCtrl: _extraExpenses[i]['reason'] as TextEditingController,
          hint: 'Expense label',
          icon: Icons.receipt_rounded,
          color: _kRed,
          onRemove: () => _removeExtraExpense(i),
        ),
      ],
      if (_extraExpenses.isNotEmpty) ...[
        const SizedBox(height: 8),
        _ResultRow(label: 'Extra Expenses Total', value: fmt.format(_extraExpenseTotal), color: _kRed),
      ],
    ]));
  }

  Widget _analyticsCard(Map<String, dynamic> trail, NumberFormat fmt) {
    final total = (trail['totalAmount'] as double?) ?? 0.0;
    final final_ = (trail['finalAmount'] as double?) ?? 0.0;
    final adap = _d(_adapCtrl);
    final gpay = _d(_gpayCtrl);
    final exp = _d(_expenseCtrl);
    final totalDeductions = adap + gpay + exp;
    final collectionRate = total > 0 ? ((total - totalDeductions) / total * 100).clamp(0, 100) : 0.0;
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Label(icon: Icons.analytics_rounded, text: 'Analytics', color: _kGold),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _StatBox(label: 'Collection Rate', value: '${collectionRate.toStringAsFixed(1)}%',
            color: collectionRate >= 80 ? _kGreen : collectionRate >= 50 ? _kGold : _kRed)),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Total Deductions', value: fmt.format(totalDeductions), color: _kRed)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _StatBox(label: 'Total In', value: fmt.format(total), color: _kAccent)),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Net Final', value: fmt.format(final_),
            color: final_ >= 0 ? _kGreen : _kRed)),
      ]),
    ]));
  }

  Widget _trailCard(Map<String, dynamic> trail, NumberFormat fmt) {
    final totalAmt = (trail['totalAmount'] as double?) ?? 0.0;
    final afterAdap = (trail['amountAfterAdap'] as double?) ?? 0.0;
    final afterGpay = (trail['amountAfterGpay'] as double?) ?? 0.0;
    final finalAmt = (trail['finalAmount'] as double?) ?? 0.0;
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Label(icon: Icons.account_tree_rounded, text: 'Calculation Trail', color: _kPrimary),
      const SizedBox(height: 16),
      _Field(ctrl: _otherCtrl, label: 'Other Amount', icon: Icons.more_horiz_rounded),
      const SizedBox(height: 16),
      _TrailStep(step: '1', label: 'Previous Final', value: fmt.format(_prevFinal), color: _kGreen),
      _TrailStep(step: '2', label: 'Total Amount', value: fmt.format(totalAmt), color: _kAccent),
      _TrailStep(step: '3', label: '− ADAP', value: '− ${fmt.format(_d(_adapCtrl))}', color: _kRed),
      _TrailStep(step: '4', label: 'After ADAP', value: fmt.format(afterAdap), color: _kAccent),
      _TrailStep(step: '5', label: '− GPay', value: '− ${fmt.format(_d(_gpayCtrl))}', color: _kRed),
      _TrailStep(step: '6', label: 'After GPay', value: fmt.format(afterGpay), color: _kAccent),
      _TrailStep(step: '7', label: '− Expense', value: '− ${fmt.format(_d(_expenseCtrl))}', color: _kRed),
      const Divider(height: 24),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (finalAmt >= 0 ? _kGreen : _kRed).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (finalAmt >= 0 ? _kGreen : _kRed).withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Final Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text(fmt.format(finalAmt),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18,
                  color: finalAmt >= 0 ? _kGreen : _kRed)),
        ]),
      ),
    ]));
  }

  Widget _submitBtn() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
          elevation: 4,
        ),
        child: _submitting
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_isEditMode ? Icons.save_rounded : Icons.check_circle_rounded, size: 20),
                const SizedBox(width: 10),
                Text(_isEditMode ? 'Update Record' : 'Save Record',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
      ),
    );
  }

  void _showExtraNetDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        title: Text('Add Extra Net', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add extra cash to net in hand',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Amount to Add',
              labelStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: _kGreen),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: _kSurface,
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text.trim()) ?? 0.0;
              if (amount <= 0) return;
              Navigator.pop(ctx);
              setState(() {
                _extraNetCtrl.text = (_d(_extraNetCtrl) + amount).toStringAsFixed(2);
              });
            },
            child: Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Private widget classes ──────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_kRadius),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: child,
  );
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Label({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: color),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
  ]);
}

class _Drop extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Drop({required this.label, required this.icon, required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
    onChanged: onChanged,
  );
}

class _Skel extends StatelessWidget {
  const _Skel();
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

class _ExtraNetRow extends StatelessWidget {
  final TextEditingController extraNetCtrl;
  final VoidCallback onNetAdd;
  const _ExtraNetRow({required this.extraNetCtrl, required this.onNetAdd});
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2);
    final amount = double.tryParse(extraNetCtrl.text.trim()) ?? 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _kGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Extra Net', style: TextStyle(fontSize: 11, color: _kGreen)),
              Text(fmt.format(amount),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kGreen)),
            ]),
          ),
          GestureDetector(
            onTap: onNetAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: _kGreen, size: 14),
                SizedBox(width: 4),
                Text('Net+', style: TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  const _Field({required this.ctrl, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultRow({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
    ]),
  );
}

class _TrailStep extends StatelessWidget {
  final String step;
  final String label;
  final String value;
  final Color color;
  const _TrailStep({required this.step, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(
        width: 22, height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Text(step, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _ExtraRow extends StatelessWidget {
  final TextEditingController labelCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController? reasonCtrl;
  final String hint;
  final IconData icon;
  final Color color;
  final VoidCallback onRemove;
  const _ExtraRow({required this.labelCtrl, required this.amountCtrl, required this.hint, required this.icon, required this.color, required this.onRemove, this.reasonCtrl});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [
      Expanded(
        flex: 2,
        child: TextFormField(
          controller: labelCtrl,
          decoration: InputDecoration(
            labelText: hint,
            prefixIcon: Icon(icon, size: 18, color: color),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 2,
        child: TextFormField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          decoration: InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
      const SizedBox(width: 4),
      IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.remove_circle_rounded, color: _kRed, size: 22),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ]),
    if (reasonCtrl != null) ...[
      const SizedBox(height: 6),
      TextFormField(
        controller: reasonCtrl,
        decoration: InputDecoration(
          labelText: 'Reason (optional)',
          prefixIcon: const Icon(Icons.notes_rounded, size: 18, color: _kRed),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    ],
  ]);
}
