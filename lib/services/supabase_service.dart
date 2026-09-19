import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/index.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  SupabaseClient get client => _client;

  // ============================================
  // OPERATIONS
  // ============================================

  // Auth removed for daily operations mode

  // ============================================

  Future<List<Region>> getRegions() async {
    final response = await _client
        .from('regions')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((json) => Region.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Region> createRegion({required String name}) async {
    final response = await _client
        .from('regions')
        .insert({'name': name})
        .select()
        .single();

    return Region.fromJson(response as Map<String, dynamic>);
  }

  Future<Region> updateRegion({required String id, required String name}) async {
    final response = await _client
        .from('regions')
        .update({'name': name})
        .eq('id', id)
        .select()
        .single();

    return Region.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteRegion(String id) async {
    await _client.from('regions').delete().eq('id', id);
  }

  // ============================================
  // MODELS (TYPES)
  // ============================================

  Future<List<ModelType>> getModels() async {
    final response = await _client
        .from('models')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((json) => ModelType.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ModelType> createModel({required String name}) async {
    final response = await _client
        .from('models')
        .insert({'name': name})
        .select()
        .single();

    return ModelType.fromJson(response as Map<String, dynamic>);
  }

  Future<ModelType> updateModel({required String id, required String name}) async {
    final response = await _client
        .from('models')
        .update({'name': name})
        .eq('id', id)
        .select()
        .single();

    return ModelType.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteModel(String id) async {
    await _client.from('models').delete().eq('id', id);
  }

  // ============================================
  // COLLECTION BAGS (AREAS)
  // ============================================

  Future<List<CollectionBag>> getCollectionBags() async {
    final response = await _client
        .from('collection_bags')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((json) => CollectionBag.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CollectionBag> createCollectionBag({required String name}) async {
    final response = await _client
        .from('collection_bags')
        .insert({'name': name})
        .select()
        .single();

    return CollectionBag.fromJson(response as Map<String, dynamic>);
  }

  Future<CollectionBag> updateCollectionBag({
    required String id,
    required String name,
  }) async {
    final response = await _client
        .from('collection_bags')
        .update({'name': name})
        .eq('id', id)
        .select()
        .single();

    return CollectionBag.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteCollectionBag(String id) async {
    await _client.from('collection_bags').delete().eq('id', id);
  }

  // ============================================
  // BAG CONFIGURATIONS
  // ============================================

  Future<List<BagConfiguration>> getBagConfigurations() async {
    final response = await _client
        .from('bag_configurations')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BagConfiguration.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BagConfiguration> createBagConfiguration({
    required String regionId,
    required String modelId,
    required String bagId,
    required String frequency,
    String entity = 'Line',
    String frequencyType = 'weekly',
    List<int> daysOfWeek = const [],
    String monthlyRule = '',
    double expectedAmount = 0.0,
    double sundayAmount = 0.0,
    double mondayAmount = 0.0,
    double tuesdayAmount = 0.0,
    double wednesdayAmount = 0.0,
    double thursdayAmount = 0.0,
    double fridayAmount = 0.0,
    double saturdayAmount = 0.0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = {
      'entity': entity,
      'region_id': regionId,
      'model_id': modelId,
      'bag_id': bagId,
      'frequency': frequency,
      'frequency_type': frequencyType,
      'days_of_week': daysOfWeek,
      'monthly_rule': monthlyRule,
      'expected_amount': expectedAmount,
      'sunday_amount': sundayAmount,
      'monday_amount': mondayAmount,
      'tuesday_amount': tuesdayAmount,
      'wednesday_amount': wednesdayAmount,
      'thursday_amount': thursdayAmount,
      'friday_amount': fridayAmount,
      'saturday_amount': saturdayAmount,
      'start_date': (startDate ?? DateTime.now()).toIso8601String().split('T')[0],
      'end_date': (endDate ?? DateTime(2099, 12, 31)).toIso8601String().split('T')[0],
    };

    final response = await _client
        .from('bag_configurations')
        .insert(data)
        .select()
        .single();

    return BagConfiguration.fromJson(response as Map<String, dynamic>);
  }

  Future<BagConfiguration> updateBagConfiguration({
    required String id,
    String? entity,
    String? regionId,
    String? modelId,
    String? bagId,
    String? frequency,
    bool? isActive,
    String? frequencyType,
    List<int>? daysOfWeek,
    String? monthlyRule,
    double? expectedAmount,
    double? sundayAmount,
    double? mondayAmount,
    double? tuesdayAmount,
    double? wednesdayAmount,
    double? thursdayAmount,
    double? fridayAmount,
    double? saturdayAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{};
    if (entity != null) data['entity'] = entity;
    if (regionId != null) data['region_id'] = regionId;
    if (modelId != null) data['model_id'] = modelId;
    if (bagId != null) data['bag_id'] = bagId;
    if (frequency != null) data['frequency'] = frequency;
    if (isActive != null) data['is_active'] = isActive;
    if (frequencyType != null) data['frequency_type'] = frequencyType;
    if (daysOfWeek != null) data['days_of_week'] = daysOfWeek;
    if (monthlyRule != null) data['monthly_rule'] = monthlyRule;
    if (expectedAmount != null) data['expected_amount'] = expectedAmount;
    if (sundayAmount != null) data['sunday_amount'] = sundayAmount;
    if (mondayAmount != null) data['monday_amount'] = mondayAmount;
    if (tuesdayAmount != null) data['tuesday_amount'] = tuesdayAmount;
    if (wednesdayAmount != null) data['wednesday_amount'] = wednesdayAmount;
    if (thursdayAmount != null) data['thursday_amount'] = thursdayAmount;
    if (fridayAmount != null) data['friday_amount'] = fridayAmount;
    if (saturdayAmount != null) data['saturday_amount'] = saturdayAmount;
    if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T')[0];

    final response = await _client
        .from('bag_configurations')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return BagConfiguration.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteBagConfiguration(String id) async {
    await _client.from('bag_configurations').delete().eq('id', id);
  }

  // ============================================
  // COLLECTION CYCLES
  // ============================================

  Future<List<CollectionCycle>> getCollectionCycles({
    String? bagConfigurationId,
    String? bagId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    var query = _client
        .from('collection_cycles')
        .select();

    if (bagConfigurationId != null) {
      query = query.eq('bag_configuration_id', bagConfigurationId);
    }
    if (bagId != null) {
      query = query.eq('bag_id', bagId);
    }
    if (startDate != null) {
      query = query.gte('scheduled_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('scheduled_date', endDate.toIso8601String().split('T')[0]);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('scheduled_date', ascending: false);

    return (response as List)
        .map((json) => CollectionCycle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CollectionCycle> createCollectionCycle({
    required String bagConfigurationId,
    required String bagId,
    required DateTime scheduledDate,
    double expectedAmount = 0.0,
    String? previousCycleId,
  }) async {
    final data = {
      'bag_configuration_id': bagConfigurationId,
      'bag_id': bagId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'expected_amount': expectedAmount,
      'previous_cycle_id': previousCycleId,
    };

    final response = await _client
        .from('collection_cycles')
        .insert(data)
        .select()
        .single();

    return CollectionCycle.fromJson(response as Map<String, dynamic>);
  }

  Future<CollectionCycle> updateCollectionCycle({
    required String id,
    double? collectedAmount,
    double? pendingAmount,
    String? status,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (collectedAmount != null) data['collected_amount'] = collectedAmount;
    if (pendingAmount != null) data['pending_amount'] = pendingAmount;
    if (status != null) data['status'] = status;
    if (isActive != null) data['is_active'] = isActive;

    final response = await _client
        .from('collection_cycles')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return CollectionCycle.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteCollectionCycle(String id) async {
    await _client.from('collection_cycles').delete().eq('id', id);
  }

  Future<void> generateCyclesForConfiguration({
    required String bagConfigurationId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _client.rpc(
      'generate_collection_cycles',
      params: {
        'p_bag_configuration_id': bagConfigurationId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      },
    );
  }

  // ============================================
  // COLLECTION HISTORY
  // ============================================

  Future<List<Map<String, dynamic>>> getCollectionHistory({
    String? bagId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('collection_cycles')
        .select('*, bag_configuration:bag_configurations(*)')
        .eq('is_active', true);

    if (bagId != null) {
      query = query.eq('bag_id', bagId);
    }
    if (startDate != null) {
      query = query.gte('scheduled_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('scheduled_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('scheduled_date', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ============================================
  // DASHBOARD / ANALYTICS
  // ============================================

  Future<List<DailyCollectionEntry>> getDailyCollectionEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? regionId,
    String? modelId,
    String? bagId,
  }) async {
    var query = _client
        .from('daily_collection_entries')
        .select();

    if (startDate != null) {
      query = query.gte('entry_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('entry_date', endDate.toIso8601String().split('T')[0]);
    }
    if (regionId != null) {
      query = query.eq('region_id', regionId);
    }
    if (modelId != null) {
      query = query.eq('model_id', modelId);
    }
    if (bagId != null) {
      query = query.eq('bag_id', bagId);
    }

    final response = await query.order('entry_date', ascending: false);

    return (response as List)
        .map((json) => DailyCollectionEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DailyCollectionEntry> createDailyCollectionEntry({
    required DateTime entryDate,
    required String regionId,
    required String modelId,
    required String bagId,
    String? bagConfigurationId,
    String? collectionCycleId,
    double expectedAmount = 0.0,
    double previousPending = 0.0,
    double totalDue = 0.0,
    double openingBalance = 0.0,
    double collectionCash = 0.0,
    double collectionUpi = 0.0,
    double documentCharges = 0.0,
    double newLoanCash = 0.0,
    double newLoanUpi = 0.0,
    double chitPayment = 0.0,
    double miscExpenses = 0.0,
  }) async {
    final data = <String, dynamic>{
      'entry_date': entryDate.toIso8601String().split('T')[0],
      'region_id': regionId,
      'model_id': modelId,
      'bag_id': bagId,
      'opening_balance': openingBalance,
      'collection_cash': collectionCash,
      'collection_upi': collectionUpi,
      'document_charges': documentCharges,
      'new_loan_cash': newLoanCash,
      'new_loan_upi': newLoanUpi,
      'chit_payment': chitPayment,
      'misc_expenses': miscExpenses,
    };

    // Only include optional columns if they have values (they may not exist in older schemas)
    if (bagConfigurationId != null) data['bag_configuration_id'] = bagConfigurationId;
    if (collectionCycleId != null) data['collection_cycle_id'] = collectionCycleId;
    if (expectedAmount != 0.0) data['expected_amount'] = expectedAmount;
    if (previousPending != 0.0) data['previous_pending'] = previousPending;
    if (totalDue != 0.0) data['total_due'] = totalDue;

    try {
      final response = await _client
          .from('daily_collection_entries')
          .insert(data)
          .select()
          .single();
      return DailyCollectionEntry.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Retry without optional columns if schema doesn't have them
      if (e.toString().contains('bag_configuration_id') ||
          e.toString().contains('collection_cycle_id') ||
          e.toString().contains('expected_amount') ||
          e.toString().contains('previous_pending') ||
          e.toString().contains('total_due')) {
        data.remove('bag_configuration_id');
        data.remove('collection_cycle_id');
        data.remove('expected_amount');
        data.remove('previous_pending');
        data.remove('total_due');
        final response = await _client
            .from('daily_collection_entries')
            .insert(data)
            .select()
            .single();
        return DailyCollectionEntry.fromJson(response as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  Future<DailyCollectionEntry> updateDailyCollectionEntry({
    required String id,
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
    bool? isDeleted,
  }) async {
    final data = <String, dynamic>{};
    if (entryDate != null) data['entry_date'] = entryDate.toIso8601String().split('T')[0];
    if (regionId != null) data['region_id'] = regionId;
    if (modelId != null) data['model_id'] = modelId;
    if (bagId != null) data['bag_id'] = bagId;
    if (bagConfigurationId != null) data['bag_configuration_id'] = bagConfigurationId;
    if (collectionCycleId != null) data['collection_cycle_id'] = collectionCycleId;
    if (expectedAmount != null) data['expected_amount'] = expectedAmount;
    if (previousPending != null) data['previous_pending'] = previousPending;
    if (totalDue != null) data['total_due'] = totalDue;
    if (openingBalance != null) data['opening_balance'] = openingBalance;
    if (collectionCash != null) data['collection_cash'] = collectionCash;
    if (collectionUpi != null) data['collection_upi'] = collectionUpi;
    if (documentCharges != null) data['document_charges'] = documentCharges;
    if (newLoanCash != null) data['new_loan_cash'] = newLoanCash;
    if (newLoanUpi != null) data['new_loan_upi'] = newLoanUpi;
    if (chitPayment != null) data['chit_payment'] = chitPayment;
    if (miscExpenses != null) data['misc_expenses'] = miscExpenses;
    if (isDeleted != null) data['is_deleted'] = isDeleted;

    final response = await _client
        .from('daily_collection_entries')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return DailyCollectionEntry.fromJson(response as Map<String, dynamic>);
  }

  Future<void> softDeleteDailyCollectionEntry(String id) async {
    await _client
        .from('daily_collection_entries')
        .update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteDailyCollectionEntry(String id) async {
    await _client.from('daily_collection_entries').delete().eq('id', id);
  }

  // ============================================
  // DASHBOARD / ANALYTICS
  // ============================================

  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];

    try {
      final response = await _client
          .from('daily_cash_records')
          .select('final_amount, collected_amount, expense, adap_amount, document_fees, remaining_amount, total_amount')
          .eq('entry_date', dateStr);

      if (response.isEmpty) {
        return {
          'total_final_amount': 0.0,
          'total_collected': 0.0,
          'total_expense': 0.0,
          'total_adap_amount': 0.0,
          'total_document_fees': 0.0,
          'total_remaining': 0.0,
          'total_amount': 0.0,
          'entry_count': 0,
        };
      }

      double sumFinal = 0;
      double sumCollected = 0;
      double sumExpense = 0;
      double sumAdap = 0;
      double sumDocFees = 0;
      double sumRemaining = 0;
      double sumTotal = 0;

      for (final row in response) {
        sumFinal += (row['final_amount'] as num?)?.toDouble() ?? 0.0;
        sumCollected += (row['collected_amount'] as num?)?.toDouble() ?? 0.0;
        sumExpense += (row['expense'] as num?)?.toDouble() ?? 0.0;
        sumAdap += (row['adap_amount'] as num?)?.toDouble() ?? 0.0;
        sumDocFees += (row['document_fees'] as num?)?.toDouble() ?? 0.0;
        sumRemaining += (row['remaining_amount'] as num?)?.toDouble() ?? 0.0;
        sumTotal += (row['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      return {
        'total_final_amount': sumFinal,
        'total_collected': sumCollected,
        'total_expense': sumExpense,
        'total_adap_amount': sumAdap,
        'total_document_fees': sumDocFees,
        'total_remaining': sumRemaining,
        'total_amount': sumTotal,
        'entry_count': response.length,
      };
    } catch (_) {
      try {
        final response = await _client
            .rpc('get_daily_summary', params: {'p_date': dateStr})
            .single();
        return response as Map<String, dynamic>;
      } catch (e) {
        return <String, dynamic>{};
      }
    }
  }

  Future<Map<String, double>> getWeeklySummary(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final entries = await getDailyCollectionEntries(
      startDate: weekStart,
      endDate: weekEnd,
    );

    double totalCollectionCash = 0;
    double totalCollectionUpi = 0;
    double totalNewLoanCash = 0;
    double totalNewLoanUpi = 0;

    for (final entry in entries) {
      totalCollectionCash += entry.collectionCash;
      totalCollectionUpi += entry.collectionUpi;
      totalNewLoanCash += entry.newLoanCash;
      totalNewLoanUpi += entry.newLoanUpi;
    }

    return {
      'totalCollectionCash': totalCollectionCash,
      'totalCollectionUpi': totalCollectionUpi,
      'totalNewLoanCash': totalNewLoanCash,
      'totalNewLoanUpi': totalNewLoanUpi,
      'netCashFlow': (totalCollectionCash + totalCollectionUpi) -
          (totalNewLoanCash + totalNewLoanUpi),
    };
  }

  Future<Map<String, dynamic>> createWeeklyEntry({
    required DateTime weekStartDate,
    required String regionId,
    required String modelId,
    required String bagId,
    double netAmount = 0.0,
    double collectedAmount = 0.0,
    double remainingAmount = 0.0,
    String remainingReason = '',
    double documentFees = 0.0,
    double adapAmount = 0.0,
    double rrGpayAmount = 0.0,
    double expense = 0.0,
    double additionalCollection = 0.0,
    double additionalDeduction = 0.0,
    double otherAmount = 0.0,
  }) async {
    final data = {
      'week_start_date': weekStartDate.toIso8601String().split('T')[0],
      'region_id': regionId,
      'model_id': modelId,
      'bag_id': bagId,
      'opening_balance': netAmount,
      'collection_cash': collectedAmount,
      'remaining_amount': remainingAmount,
      'remaining_reason': remainingReason,
      'document_charges': documentFees,
      'adap_amount': adapAmount,
      'rr_gpay_amount': rrGpayAmount,
      'misc_expenses': expense,
      'additional_collection': additionalCollection,
      'additional_deduction': additionalDeduction,
      'other_amount': otherAmount,
    };

    final response = await _client
        .from('weekly_collection_entries')
        .insert(data)
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getWeeklyEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? regionId,
    String? modelId,
    String? bagId,
  }) async {
    var query = _client
        .from('weekly_collection_entries')
        .select();

    if (startDate != null) {
      query = query.gte('week_start_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('week_start_date', endDate.toIso8601String().split('T')[0]);
    }
    if (regionId != null) {
      query = query.eq('region_id', regionId);
    }
    if (modelId != null) {
      query = query.eq('model_id', modelId);
    }
    if (bagId != null) {
      query = query.eq('bag_id', bagId);
    }

    final response = await query.order('week_start_date', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ============================================
  // MONTHLY COLLECTION ENTRIES
  // ============================================

  Future<Map<String, dynamic>> createMonthlyEntry({
    required DateTime monthStartDate,
    required String regionId,
    required String modelId,
    required String bagId,
    double netAmount = 0.0,
    double collectedAmount = 0.0,
    double remainingAmount = 0.0,
    String remainingReason = '',
    double documentFees = 0.0,
    double adapAmount = 0.0,
    double rrGpayAmount = 0.0,
    double expense = 0.0,
    double additionalCollection = 0.0,
    double additionalDeduction = 0.0,
    double otherAmount = 0.0,
  }) async {
    final data = {
      'month_start_date': monthStartDate.toIso8601String().split('T')[0],
      'region_id': regionId,
      'model_id': modelId,
      'bag_id': bagId,
      'opening_balance': netAmount,
      'collection_cash': collectedAmount,
      'remaining_amount': remainingAmount,
      'remaining_reason': remainingReason,
      'document_charges': documentFees,
      'adap_amount': adapAmount,
      'rr_gpay_amount': rrGpayAmount,
      'misc_expenses': expense,
      'additional_collection': additionalCollection,
      'additional_deduction': additionalDeduction,
      'other_amount': otherAmount,
    };

    final response = await _client
        .from('monthly_collection_entries')
        .insert(data)
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMonthlyEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? regionId,
    String? modelId,
    String? bagId,
  }) async {
    var query = _client
        .from('monthly_collection_entries')
        .select();

    if (startDate != null) {
      query = query.gte('month_start_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('month_start_date', endDate.toIso8601String().split('T')[0]);
    }
    if (regionId != null) {
      query = query.eq('region_id', regionId);
    }
    if (modelId != null) {
      query = query.eq('model_id', modelId);
    }
    if (bagId != null) {
      query = query.eq('bag_id', bagId);
    }

    final response = await query.order('month_start_date', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ============================================
  // DAY BRANCH ASSIGNMENTS
  // ============================================

  Future<List<Map<String, dynamic>>> getDayBranchAssignments() async {
    try {
      final response = await _client
          .from('day_branch_assignments')
          .select('*, region:regions(name)')
          .order('day_of_week', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAssignmentsByDay(int dayOfWeek) async {
    try {
      final response = await _client
          .from('day_branch_assignments')
          .select('*, region:regions(name)')
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createDayBranchAssignment({
    required int dayOfWeek,
    required String branchId,
    bool isActive = true,
  }) async {
    final data = {
      'day_of_week': dayOfWeek,
      'branch_id': branchId,
      'is_active': isActive,
    };

    final response = await _client
        .from('day_branch_assignments')
        .insert(data)
        .select('*, region:regions(name)')
        .single();

    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDayBranchAssignment({
    required String id,
    int? dayOfWeek,
    String? branchId,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (dayOfWeek != null) data['day_of_week'] = dayOfWeek;
    if (branchId != null) data['branch_id'] = branchId;
    if (isActive != null) data['is_active'] = isActive;

    final response = await _client
        .from('day_branch_assignments')
        .update(data)
        .eq('id', id)
        .select('*, region:regions(name)')
        .single();

    return response as Map<String, dynamic>;
  }

  Future<void> deleteDayBranchAssignment(String id) async {
    try {
      await _client.from('day_branch_assignments').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete assignment: $e');
    }
  }

  // ============================================
  // DAILY CASH RECORDS
  // ============================================

  Future<List<DailyCashRecord>> getDailyCashRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? regionId,
    String? modelId,
    String? bagId,
    List<String>? bagIds,
  }) async {
    var query = _client
        .from('daily_cash_records')
        .select();

    if (startDate != null) query = query.gte('entry_date', startDate.toIso8601String().split('T')[0]);
    if (endDate != null) query = query.lte('entry_date', endDate.toIso8601String().split('T')[0]);
    if (regionId != null) query = query.eq('region_id', regionId);
    if (modelId != null) query = query.eq('model_id', modelId);
    if (bagId != null) query = query.eq('bag_id', bagId);
    if (bagIds != null && bagIds.isNotEmpty) {
      final bagIdsCopy = List<String>.from(bagIds);
      query = query.filter('bag_id', 'in', bagIdsCopy);
    }

    final response = await query
        .order('entry_date', ascending: true)
        .order('created_at', ascending: true);
    return (response as List)
        .map((json) => DailyCashRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DailyCashRecord?> getDailyCashRecordByDate({
    required DateTime date,
    required String regionId,
    required String modelId,
    required String bagId,
  }) async {
    try {
      final response = await _client
          .from('daily_cash_records')
          .select()
          .eq('entry_date', date.toIso8601String().split('T')[0])
          .eq('region_id', regionId)
          .eq('model_id', modelId)
          .eq('bag_id', bagId)
          .maybeSingle();

      if (response == null) return null;
      return DailyCashRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<DailyCashRecord> createDailyCashRecord({
    required DateTime entryDate,
    required String regionId,
    required String modelId,
    required String bagId,
    required DateTime weekStartDate,
    required int dayOfWeek,
    double netAmountInHand = 0.0,
    double collectedAmount = 0.0,
    double remainingAmount = 0.0,
    String remainingReason = '',
    double documentFees = 0.0,
    double adapAmount = 0.0,
    double rrGpayAmount = 0.0,
    double expense = 0.0,
     double additionalCollection = 0.0,
     double additionalDeduction = 0.0,
     double otherAmount = 0.0,
     double extraNetAmount = 0.0,
     double previousFinalAmount = 0.0,
     double totalAmount = 0.0,
     double finalAmount = 0.0,
   }) async {
     final data = {
       'entry_date': entryDate.toIso8601String().split('T')[0],
       'region_id': regionId,
       'model_id': modelId,
       'bag_id': bagId,
       'week_start_date': weekStartDate.toIso8601String().split('T')[0],
       'day_of_week': dayOfWeek,
       'net_amount_in_hand': netAmountInHand,
       'collected_amount': collectedAmount,
       'remaining_amount': remainingAmount,
       'remaining_reason': remainingReason,
       'document_fees': documentFees,
       'adap_amount': adapAmount,
       'rr_gpay_amount': rrGpayAmount,
       'expense': expense,
       'additional_collection': additionalCollection,
       'additional_deduction': additionalDeduction,
        'other_amount': otherAmount,
        'extra_net_amount': extraNetAmount,
        'previous_final_amount': previousFinalAmount,
      };

    try {
      final response = await _client
          .from('daily_cash_records')
          .insert(data)
          .select()
          .single();

      return DailyCashRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
       final errStr = e.toString();
       final optionalCols = [
         'extra_net_amount', 'total_amount', 'final_amount',
         'additional_collection', 'additional_deduction', 'other_amount',
         'previous_final_amount',
       ];
       bool hasSchemaError = false;
       for (final col in optionalCols) {
         if (errStr.contains(col)) {
           hasSchemaError = true;
           data.remove(col);
         }
       }
       if (!hasSchemaError) rethrow;
       final response = await _client
           .from('daily_cash_records')
           .insert(data)
           .select()
           .single();
        return DailyCashRecord.fromJson(response as Map<String, dynamic>);
      }
    }

  Future<DailyCashRecord> updateDailyCashRecord({
    required String id,
    DateTime? entryDate,
    String? regionId,
    String? modelId,
    String? bagId,
    DateTime? weekStartDate,
    int? dayOfWeek,
    double? netAmountInHand,
    double? collectedAmount,
    double? remainingAmount,
    String? remainingReason,
    double? documentFees,
    double? adapAmount,
    double? rrGpayAmount,
    double? expense,
     double? additionalCollection,
     double? additionalDeduction,
     double? otherAmount,
     double? extraNetAmount,
     double? previousFinalAmount,
     double? totalAmount,
     double? finalAmount,
   }) async {
    final data = <String, dynamic>{};
    if (entryDate != null) data['entry_date'] = entryDate.toIso8601String().split('T')[0];
    if (regionId != null) data['region_id'] = regionId;
    if (modelId != null) data['model_id'] = modelId;
    if (bagId != null) data['bag_id'] = bagId;
    if (weekStartDate != null) data['week_start_date'] = weekStartDate.toIso8601String().split('T')[0];
    if (dayOfWeek != null) data['day_of_week'] = dayOfWeek;
    if (netAmountInHand != null) data['net_amount_in_hand'] = netAmountInHand;
    if (collectedAmount != null) data['collected_amount'] = collectedAmount;
    if (remainingAmount != null) data['remaining_amount'] = remainingAmount;
    if (remainingReason != null) data['remaining_reason'] = remainingReason;
    if (documentFees != null) data['document_fees'] = documentFees;
    if (adapAmount != null) data['adap_amount'] = adapAmount;
    if (rrGpayAmount != null) data['rr_gpay_amount'] = rrGpayAmount;
    if (expense != null) data['expense'] = expense;
    if (additionalCollection != null) data['additional_collection'] = additionalCollection;
    if (additionalDeduction != null) data['additional_deduction'] = additionalDeduction;
    if (otherAmount != null) data['other_amount'] = otherAmount;
     if (extraNetAmount != null) data['extra_net_amount'] = extraNetAmount;
     if (previousFinalAmount != null) data['previous_final_amount'] = previousFinalAmount;
     if (totalAmount != null) data['total_amount'] = totalAmount;
     if (finalAmount != null) data['final_amount'] = finalAmount;

     if (data.isEmpty) {
       throw Exception('No fields to update');
     }

     try {
       final response = await _client
           .from('daily_cash_records')
           .update(data)
           .eq('id', id)
           .select()
           .single();
       return DailyCashRecord.fromJson(response as Map<String, dynamic>);
     } catch (e) {
       final errStr = e.toString();
       final optionalCols = [
         'extra_net_amount', 'total_amount', 'final_amount',
         'additional_collection', 'additional_deduction', 'other_amount',
         'previous_final_amount',
       ];
       bool hasSchemaError = false;
       for (final col in optionalCols) {
         if (errStr.contains(col)) {
           hasSchemaError = true;
           data.remove(col);
         }
       }
       if (!hasSchemaError) rethrow;
       final response = await _client
           .from('daily_cash_records')
           .update(data)
           .eq('id', id)
           .select()
           .single();
       return DailyCashRecord.fromJson(response as Map<String, dynamic>);
     }
   }

   Future<void> deleteDailyCashRecord(String id) async {
    await _client.from('daily_cash_records').delete().eq('id', id);
  }

  Future<void> upsertBagNetAmount({
    required String bagId,
    required DateTime entryDate,
    required double amount,
  }) async {
    final dateStr = entryDate.toIso8601String().split('T')[0];
    try {
      await _client
          .from('bag_net_amounts')
          .upsert({
            'bag_id': bagId,
            'entry_date': dateStr,
            'amount': amount,
          });
    } catch (e) {
      // Fallback: use other_amount column on daily_cash_records
      final records = await _client.from('daily_cash_records').select('id').eq('bag_id', bagId).eq('entry_date', dateStr);
      final list = records as List;
      if (list.isNotEmpty) {
        final recordId = (list.first as Map<String, dynamic>)['id'];
        await _client.from('daily_cash_records').update({'other_amount': amount}).eq('id', recordId);
      }
    }
  }

   Future<double> getBagNetAmount({
    required String bagId,
    required DateTime onOrBeforeDate,
  }) async {
    final dateStr = onOrBeforeDate.toIso8601String().split('T')[0];
    double total = 0.0;

    // Get the net amount from the latest record on or before the date
    try {
      final response = await _client
          .from('daily_cash_records')
          .select('other_amount,extra_net_amount')
          .eq('bag_id', bagId)
          .lte('entry_date', dateStr)
          .order('entry_date', ascending: false)
          .order('updated_at', ascending: false)
          .limit(1);
      final list = response as List;
      if (list.isNotEmpty) {
        final row = list.first as Map<String, dynamic>;
        total = ((row['other_amount'] as num?)?.toDouble() ?? 0.0);
        if (total == 0.0) {
          total = (row['extra_net_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    } catch (e) {
      // Fallback: try bag_net_amounts table
      try {
        final response = await _client
            .from('bag_net_amounts')
            .select('amount')
            .eq('bag_id', bagId)
            .lte('entry_date', dateStr)
            .order('entry_date', ascending: false)
            .limit(1);
        final list = response as List;
        if (list.isNotEmpty) {
          total = ((list.first as Map<String, dynamic>)['amount'] as num?)?.toDouble() ?? 0.0;
        }
        return total;
      } catch (e2) {
        return 0.0;
      }
    }
  }

  Future<List<Map<String, dynamic>>> getBagNetAmountHistory({
    required String bagId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];
    try {
      final response = await _client
          .from('bag_net_amounts')
          .select('entry_date,amount,created_at,updated_at')
          .eq('bag_id', bagId)
          .gte('entry_date', startStr)
          .lte('entry_date', endStr)
          .order('entry_date', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Fallback: use other_amount column from daily_cash_records
      final response = await _client
          .from('daily_cash_records')
          .select('entry_date,other_amount,updated_at')
          .eq('bag_id', bagId)
          .gte('entry_date', startStr)
          .lte('entry_date', endStr)
          .order('entry_date', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    }
  }
}
