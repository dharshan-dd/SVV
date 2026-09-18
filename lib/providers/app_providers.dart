import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/region.dart';
import '../models/model_type.dart';
import '../models/collection_bag.dart';
import '../models/bag_configuration.dart';
import '../models/collection_cycle.dart';
import '../models/daily_cash_record.dart';
import '../models/daily_collection_entry.dart';
import '../services/supabase_service.dart';
import '../services/collection_calculation_service.dart';

// ============================================
// SERVICE PROVIDERS
// ============================================

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final collectionCalculationServiceProvider = Provider<CollectionCalculationService>((ref) {
  return CollectionCalculationService();
});

// ============================================
// REGION PROVIDERS
// ============================================

final regionsProvider = FutureProvider<List<Region>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getRegions();
});

// ============================================
// MODEL TYPE PROVIDERS
// ============================================

final modelsProvider = FutureProvider<List<ModelType>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getModels();
});

// ============================================
// COLLECTION BAG PROVIDERS
// ============================================

final collectionBagsProvider = FutureProvider<List<CollectionBag>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getCollectionBags();
});

// ============================================
// BAG CONFIGURATION PROVIDERS
// ============================================

final bagConfigurationsProvider = FutureProvider<List<BagConfiguration>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getBagConfigurations();
});

// ============================================
// DAILY COLLECTION ENTRY PROVIDERS
// ============================================

final dailyEntriesProvider =
    FutureProvider.family<List<DailyCollectionEntry>, Map<String, dynamic>>((
  ref,
  filters,
) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getDailyCollectionEntries(
    startDate: filters['startDate'] as DateTime?,
    endDate: filters['endDate'] as DateTime?,
    regionId: filters['regionId'] as String?,
    modelId: filters['modelId'] as String?,
    bagId: filters['bagId'] as String?,
  );
});

final todayEntriesProvider = FutureProvider<List<DailyCollectionEntry>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  final today = DateTime.now();
  return service.getDailyCollectionEntries(startDate: today, endDate: today);
});

final dailyCashRecordsProvider = FutureProvider<List<DailyCashRecord>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getDailyCashRecords();
});

// ============================================
// DASHBOARD PROVIDERS
// ============================================

final dailySummaryProvider =
    FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getDailySummary(date);
});

final weeklySummaryProvider =
    FutureProvider.family<Map<String, double>, DateTime>((ref, weekStart) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getWeeklySummary(weekStart);
});

final monthlySummaryProvider =
    FutureProvider.family<Map<String, double>, DateTime>((ref, monthStart) async {
  final service = ref.read(supabaseServiceProvider);
  final entries = await service.getDailyCollectionEntries(
    startDate: monthStart,
    endDate: DateTime(monthStart.year, monthStart.month + 1, 0),
  );

  double totalCollectionCash = 0;
  double totalCollectionUpi = 0;
  double totalDocumentCharges = 0;
  double totalNewLoanCash = 0;
  double totalNewLoanUpi = 0;
  double totalChitPayment = 0;
  double totalMiscExpenses = 0;

  for (final entry in entries) {
    totalCollectionCash += entry.collectionCash;
    totalCollectionUpi += entry.collectionUpi;
    totalDocumentCharges += entry.documentCharges;
    totalNewLoanCash += entry.newLoanCash;
    totalNewLoanUpi += entry.newLoanUpi;
    totalChitPayment += entry.chitPayment;
    totalMiscExpenses += entry.miscExpenses;
  }

  final totalCredit = totalCollectionCash + totalCollectionUpi + totalDocumentCharges;
  final totalDebit = totalNewLoanCash + totalNewLoanUpi + totalChitPayment + totalMiscExpenses;

  return {
    'totalCollectionCash': totalCollectionCash,
    'totalCollectionUpi': totalCollectionUpi,
    'totalDocumentCharges': totalDocumentCharges,
    'totalNewLoanCash': totalNewLoanCash,
    'totalNewLoanUpi': totalNewLoanUpi,
    'totalChitPayment': totalChitPayment,
    'totalMiscExpenses': totalMiscExpenses,
    'totalCredit': totalCredit,
    'totalDebit': totalDebit,
    'netProfit': totalCredit - totalDebit,
  };
});

// ============================================
// FILTER STATE PROVIDER
// ============================================

class FilterState {
  final DateTime? selectedDate;
  final String? selectedRegionId;
  final String? selectedModelId;
  final String? selectedBagId;

  FilterState({
    this.selectedDate,
    this.selectedRegionId,
    this.selectedModelId,
    this.selectedBagId,
  });

  FilterState copyWith({
    DateTime? selectedDate,
    String? selectedRegionId,
    String? selectedModelId,
    String? selectedBagId,
  }) {
    return FilterState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedRegionId: selectedRegionId ?? this.selectedRegionId,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      selectedBagId: selectedBagId ?? this.selectedBagId,
    );
  }
}

final filterStateProvider = StateProvider<FilterState>((ref) {
  return FilterState(selectedDate: DateTime.now());
});

// ============================================
// FORM STATE PROVIDER FOR DAILY ENTRY
// ============================================

class DailyEntryFormState {
  final DateTime entryDate;
  final String? regionId;
  final String? modelId;
  final String? bagId;

  // Collection Cycle Fields
  final String? bagConfigurationId;
  final String? collectionCycleId;
  final double expectedAmount;
  final double previousPending;
  final double totalDue;

  // Credit fields
  final double openingBalance;
  final double collectionCash;
  final double collectionUpi;
  final double documentCharges;

  // Debit fields
  final double newLoanCash;
  final double newLoanUpi;
  final double chitPayment;
  final double miscExpenses;

  DailyEntryFormState({
    required this.entryDate,
    this.regionId,
    this.modelId,
    this.bagId,
    this.bagConfigurationId,
    this.collectionCycleId,
    this.expectedAmount = 0.0,
    this.previousPending = 0.0,
    this.totalDue = 0.0,
    this.openingBalance = 0.0,
    this.collectionCash = 0.0,
    this.collectionUpi = 0.0,
    this.documentCharges = 0.0,
    this.newLoanCash = 0.0,
    this.newLoanUpi = 0.0,
    this.chitPayment = 0.0,
    this.miscExpenses = 0.0,
  });

  double get totalCredit =>
      openingBalance + collectionCash + collectionUpi + documentCharges;

  double get totalDebit =>
      newLoanCash + newLoanUpi + chitPayment + miscExpenses;

  double get netClosingBalance => totalCredit - totalDebit;

  bool get isValid =>
      regionId != null && modelId != null && bagId != null;

  DailyEntryFormState copyWith({
    DateTime? entryDate,
    String? regionId,
    String? modelId,
    String? bagId,
    String? bagConfigurationId,
    String? collectionCycleId,
    double? expectedAmount,
    double? previousPending,
    double? totalDue,
    double? openingBalance,
    double? collectionCash,
    double? collectionUpi,
    double? documentCharges,
    double? newLoanCash,
    double? newLoanUpi,
    double? chitPayment,
    double? miscExpenses,
  }) {
    return DailyEntryFormState(
      entryDate: entryDate ?? this.entryDate,
      regionId: regionId ?? this.regionId,
      modelId: modelId ?? this.modelId,
      bagId: bagId ?? this.bagId,
      bagConfigurationId: bagConfigurationId ?? this.bagConfigurationId,
      collectionCycleId: collectionCycleId ?? this.collectionCycleId,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      previousPending: previousPending ?? this.previousPending,
      totalDue: totalDue ?? this.totalDue,
      openingBalance: openingBalance ?? this.openingBalance,
      collectionCash: collectionCash ?? this.collectionCash,
      collectionUpi: collectionUpi ?? this.collectionUpi,
      documentCharges: documentCharges ?? this.documentCharges,
      newLoanCash: newLoanCash ?? this.newLoanCash,
      newLoanUpi: newLoanUpi ?? this.newLoanUpi,
      chitPayment: chitPayment ?? this.chitPayment,
      miscExpenses: miscExpenses ?? this.miscExpenses,
    );
  }
}

final dailyEntryFormProvider =
    StateNotifierProvider<DailyEntryFormNotifier, DailyEntryFormState>((ref) {
  return DailyEntryFormNotifier();
});

class DailyEntryFormNotifier extends StateNotifier<DailyEntryFormState> {
  DailyEntryFormNotifier()
      : super(DailyEntryFormState(entryDate: DateTime.now()));

  void setEntryDate(DateTime date) {
    state = state.copyWith(entryDate: date);
  }

  void setRegion(String? regionId) {
    state = state.copyWith(regionId: regionId, modelId: null, bagId: null);
  }

  void setModel(String? modelId) {
    state = state.copyWith(modelId: modelId, bagId: null);
  }

  void setSelections({
    required String regionId,
    required String modelId,
    required String bagId,
    String? bagConfigurationId,
    DateTime? entryDate,
  }) {
    state = DailyEntryFormState(
      entryDate: entryDate ?? state.entryDate,
      regionId: regionId,
      modelId: modelId,
      bagId: bagId,
      bagConfigurationId: bagConfigurationId,
    );
  }

  void setBag(String? bagId) {
    state = state.copyWith(bagId: bagId);
  }

  void setBagConfiguration(String? bagConfigurationId) {
    state = state.copyWith(bagConfigurationId: bagConfigurationId);
  }

  void setCollectionCycle(String? collectionCycleId) {
    state = state.copyWith(collectionCycleId: collectionCycleId);
  }

  void setExpectedAmount(double value) {
    state = state.copyWith(expectedAmount: value);
  }

  void setPreviousPending(double value) {
    state = state.copyWith(previousPending: value);
  }

  void setTotalDue(double value) {
    state = state.copyWith(totalDue: value);
  }

  void setOpeningBalance(double value) {
    state = state.copyWith(openingBalance: value);
  }

  void setCollectionCash(double value) {
    state = state.copyWith(collectionCash: value);
  }

  void setCollectionUpi(double value) {
    state = state.copyWith(collectionUpi: value);
  }

  void setDocumentCharges(double value) {
    state = state.copyWith(documentCharges: value);
  }

  void setNewLoanCash(double value) {
    state = state.copyWith(newLoanCash: value);
  }

  void setNewLoanUpi(double value) {
    state = state.copyWith(newLoanUpi: value);
  }

  void setChitPayment(double value) {
    state = state.copyWith(chitPayment: value);
  }

  void setMiscExpenses(double value) {
    state = state.copyWith(miscExpenses: value);
  }

  void reset() {
    state = DailyEntryFormState(entryDate: DateTime.now());
  }

  void loadEntry(DailyCollectionEntry entry) {
    state = DailyEntryFormState(
      entryDate: entry.entryDate,
      regionId: entry.regionId,
      modelId: entry.modelId,
      bagId: entry.bagId,
      bagConfigurationId: entry.bagConfigurationId,
      collectionCycleId: entry.collectionCycleId,
      expectedAmount: entry.expectedAmount,
      previousPending: entry.previousPending,
      totalDue: entry.totalDue,
      openingBalance: entry.openingBalance,
      collectionCash: entry.collectionCash,
      collectionUpi: entry.collectionUpi,
      documentCharges: entry.documentCharges,
      newLoanCash: entry.newLoanCash,
      newLoanUpi: entry.newLoanUpi,
      chitPayment: entry.chitPayment,
      miscExpenses: entry.miscExpenses,
    );
  }
}

// ============================================
// FORM SUBMISSION STATE PROVIDER
// ============================================

class FormSubmissionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  FormSubmissionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  FormSubmissionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return FormSubmissionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final formSubmissionProvider =
    StateNotifierProvider<FormSubmissionNotifier, FormSubmissionState>((ref) {
  return FormSubmissionNotifier();
});

class FormSubmissionNotifier extends StateNotifier<FormSubmissionState> {
  FormSubmissionNotifier() : super(FormSubmissionState());

  Future<bool> submitEntry(
    SupabaseService service,
    DailyEntryFormState formState,
  ) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await service.createDailyCollectionEntry(
        entryDate: formState.entryDate,
        regionId: formState.regionId!,
        modelId: formState.modelId!,
        bagId: formState.bagId!,
        bagConfigurationId: formState.bagConfigurationId,
        collectionCycleId: formState.collectionCycleId,
        expectedAmount: formState.expectedAmount,
        previousPending: formState.previousPending,
        totalDue: formState.totalDue,
        openingBalance: formState.openingBalance,
        collectionCash: formState.collectionCash,
        collectionUpi: formState.collectionUpi,
        documentCharges: formState.documentCharges,
        newLoanCash: formState.newLoanCash,
        newLoanUpi: formState.newLoanUpi,
        chitPayment: formState.chitPayment,
        miscExpenses: formState.miscExpenses,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
      return false;
    }
  }
}

// ============================================
// DAY BRANCH ASSIGNMENT PROVIDERS
// ============================================

final dayBranchAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getDayBranchAssignments();
});

final todayBranchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  final today = DateTime.now();
  final dayOfWeek = today.weekday;
  return service.getAssignmentsByDay(dayOfWeek);
});

class ManualBranchState {
  final String? selectedBranchId;
  final bool isManualOverride;

  ManualBranchState({
    this.selectedBranchId,
    this.isManualOverride = false,
  });

  ManualBranchState copyWith({
    String? selectedBranchId,
    bool? isManualOverride,
  }) {
    return ManualBranchState(
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      isManualOverride: isManualOverride ?? this.isManualOverride,
    );
  }
}

final manualBranchProvider = StateNotifierProvider<ManualBranchNotifier, ManualBranchState>((ref) {
  return ManualBranchNotifier();
});

class ManualBranchNotifier extends StateNotifier<ManualBranchState> {
  ManualBranchNotifier() : super(ManualBranchState());

  void setManualBranch(String? branchId) {
    state = state.copyWith(
      selectedBranchId: branchId,
      isManualOverride: branchId != null,
    );
  }

  void clearManualOverride() {
    state = ManualBranchState();
  }
}
