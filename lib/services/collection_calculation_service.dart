import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collection_cycle.dart';
import '../models/index.dart';

class CollectionCalculationService {
  static final CollectionCalculationService _instance = CollectionCalculationService._internal();
  factory CollectionCalculationService() => _instance;
  CollectionCalculationService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<CollectionCycle?> getPreviousCycle({
    required String bagId,
    required DateTime beforeDate,
  }) async {
    try {
      final response = await _client
          .from('collection_cycles')
          .select()
          .eq('bag_id', bagId)
          .lt('scheduled_date', beforeDate.toIso8601String().split('T')[0])
          .eq('is_active', true)
          .order('scheduled_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return CollectionCycle.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<CollectionCycle?> getCurrentCycle({
    required String bagConfigurationId,
    required String bagId,
    required DateTime date,
  }) async {
    try {
      final response = await _client
          .rpc('get_or_create_current_cycle', params: {
        'p_bag_configuration_id': bagConfigurationId,
        'p_bag_id': bagId,
        'p_scheduled_date': date.toIso8601String().split('T')[0],
      });

      if (response == null) return null;
      return CollectionCycle.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<double> calculatePreviousPending({
    required String bagId,
    required DateTime beforeDate,
  }) async {
    try {
      final response = await _client
          .rpc('calculate_pending_from_previous', params: {
        'p_bag_id': bagId,
        'p_scheduled_date': beforeDate.toIso8601String().split('T')[0],
      });

      return (response as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> calculateCollectionDue({
    required String bagConfigurationId,
    required String bagId,
    required DateTime date,
  }) async {
    final previousPending = await calculatePreviousPending(
      bagId: bagId,
      beforeDate: date,
    );

    final currentCycle = await getCurrentCycle(
      bagConfigurationId: bagConfigurationId,
      bagId: bagId,
      date: date,
    );

    if (currentCycle == null) {
      return {
        'previousPending': previousPending,
        'currentDue': 0.0,
        'totalDue': previousPending,
        'cycle': null,
      };
    }

    final currentDue = currentCycle.expectedAmount;
    final totalDue = previousPending + currentDue;

    return {
      'previousPending': previousPending,
      'currentDue': currentDue,
      'totalDue': totalDue,
      'cycle': currentCycle,
    };
  }

  Future<void> recordCollection({
    required String collectionCycleId,
    required double cashCollected,
    required double upiCollected,
  }) async {
    final totalCollected = cashCollected + upiCollected;

    final cycleResponse = await _client
        .from('collection_cycles')
        .select()
        .eq('id', collectionCycleId)
        .single();

    final cycle = CollectionCycle.fromJson(cycleResponse as Map<String, dynamic>);
    final newPending = cycle.expectedAmount - totalCollected;

    String newStatus = 'pending';
    if (totalCollected >= cycle.expectedAmount) {
      newStatus = 'collected';
    } else if (totalCollected > 0) {
      newStatus = 'partially_collected';
    } else {
      newStatus = 'missed';
    }

    await _client.from('collection_cycles').update({
      'collected_amount': totalCollected,
      'pending_amount': newPending > 0 ? newPending : 0.0,
      'status': newStatus,
    }).eq('id', collectionCycleId);

    await _client.rpc('recalculate_future_pendings', params: {
      'p_cycle_id': collectionCycleId,
    });
  }

  Future<void> updateCollection({
    required String collectionCycleId,
    required double cashCollected,
    required double upiCollected,
  }) async {
    await recordCollection(
      collectionCycleId: collectionCycleId,
      cashCollected: cashCollected,
      upiCollected: upiCollected,
    );
  }

  Future<void> cancelCollection(String collectionCycleId) async {
    await _client.from('collection_cycles').update({
      'status': 'cancelled',
      'collected_amount': 0.0,
      'pending_amount': 0.0,
    }).eq('id', collectionCycleId);

    await _client.rpc('recalculate_future_pendings', params: {
      'p_cycle_id': collectionCycleId,
    });
  }

  Future<List<CollectionCycle>> getBagHistory({
    required String bagId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('collection_cycles')
        .select()
        .eq('bag_id', bagId)
        .eq('is_active', true);

    if (startDate != null) {
      query = query.gte('scheduled_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('scheduled_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('scheduled_date', ascending: false);
    return (response as List)
        .map((json) => CollectionCycle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CollectionCycle>> getCollectionHistory({
    String? bagId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('collection_cycles')
        .select()
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
    return (response as List)
        .map((json) => CollectionCycle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<double> getPreviousDayFinalAmount({
    required String bagId,
    required DateTime beforeDate,
  }) async {
    try {
      final response = await _client
          .rpc('get_previous_day_final_amount', params: {
        'p_bag_id': bagId,
        'p_entry_date': beforeDate.toIso8601String().split('T')[0],
      });
      return (response as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Returns the final_amount of the latest record for a bag on or before the given date.
  // This is used as the opening balance when adding a new record for the same bag.
  Future<double> getLatestFinalAmount({
    required String bagId,
    required DateTime onOrBeforeDate,
  }) async {
    try {
      final dateStr = onOrBeforeDate.toIso8601String().split('T')[0];
      final response = await _client
          .from('daily_cash_records')
          .select('previous_final_amount!inner,final_amount!inner')
          .eq('bag_id', bagId)
          .lte('entry_date', dateStr)
          .order('entry_date', ascending: false)
          .limit(1);
      final list = response as List;
      if (list.isEmpty) return 0.0;
      final row = list.first as Map<String, dynamic>;
      final finalAmount = (row['final_amount'] as num?)?.toDouble() ?? 0.0;
      return finalAmount;
    } catch (e) {
      return 0.0;
    }
  }

  Map<String, dynamic> calculateDayRecordTrail({
    required double previousFinalAmount,
    required double netAmountInHand,
    required double collectedAmount,
    required double remainingAmount,
    required double documentFees,
    required double adapAmount,
    required double rrGpayAmount,
    required double expense,
    double otherAmount = 0.0,
    double extraNetAmount = 0.0,
  }) {
    final totalAmount = netAmountInHand + collectedAmount + remainingAmount + documentFees + extraNetAmount;
    final amountAfterAdap = totalAmount - adapAmount;
    final amountAfterGpay = amountAfterAdap - rrGpayAmount;
    final finalAmount = amountAfterGpay - expense;

    return {
      'previousFinalAmount': previousFinalAmount,
      'netAmountInHand': netAmountInHand,
      'collectedAmount': collectedAmount,
      'remainingAmount': remainingAmount,
      'documentFees': documentFees,
      'totalAmount': totalAmount,
      'adapAmount': adapAmount,
      'amountAfterAdap': amountAfterAdap,
      'rrGpayAmount': rrGpayAmount,
      'amountAfterGpay': amountAfterGpay,
      'expense': expense,
      'finalAmount': finalAmount,
      'otherAmount': otherAmount,
      'extraNetAmount': extraNetAmount,
    };
  }
}
