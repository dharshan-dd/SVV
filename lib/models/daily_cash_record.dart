import 'package:microfinance_app/models/region.dart';
import 'package:microfinance_app/models/model_type.dart';
import 'package:microfinance_app/models/collection_bag.dart';

class DailyCashRecord {
  final String id;
  final DateTime entryDate;
  final String regionId;
  final String modelId;
  final String bagId;
  final DateTime weekStartDate;
  final int dayOfWeek;

  final double netAmountInHand;
  final double collectedAmount;
  final double remainingAmount;
  final String remainingReason;
  final double documentFees;
  final double totalAmount;

  final double adapAmount;
  final double amountAfterAdap;

  final double rrGpayAmount;
  final double amountAfterGpay;

  final double expense;
  final double finalAmount;

  final double additionalCollection;
  final double additionalDeduction;
  final double otherAmount;
  final double extraNetAmount;

  final double previousFinalAmount;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyCashRecord({
    required this.id,
    required this.entryDate,
    required this.regionId,
    required this.modelId,
    required this.bagId,
    required this.weekStartDate,
    required this.dayOfWeek,
    this.netAmountInHand = 0.0,
    this.collectedAmount = 0.0,
    this.remainingAmount = 0.0,
    this.remainingReason = '',
    this.documentFees = 0.0,
    this.totalAmount = 0.0,
    this.adapAmount = 0.0,
    this.amountAfterAdap = 0.0,
    this.rrGpayAmount = 0.0,
    this.amountAfterGpay = 0.0,
    this.expense = 0.0,
    this.finalAmount = 0.0,
     this.additionalCollection = 0.0,
     this.additionalDeduction = 0.0,
     this.otherAmount = 0.0,
     this.extraNetAmount = 0.0,
     this.previousFinalAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyCashRecord.fromJson(Map<String, dynamic> json) {
    return DailyCashRecord(
      id: json['id'] as String,
      entryDate: DateTime.parse(json['entry_date'] as String),
      regionId: json['region_id'] as String,
      modelId: json['model_id'] as String,
      bagId: json['bag_id'] as String,
      weekStartDate: DateTime.parse(json['week_start_date'] as String),
      dayOfWeek: json['day_of_week'] as int,
      netAmountInHand: (json['net_amount_in_hand'] as num?)?.toDouble() ?? 0.0,
      collectedAmount: (json['collected_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      remainingReason: json['remaining_reason'] as String? ?? '',
      documentFees: (json['document_fees'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      adapAmount: (json['adap_amount'] as num?)?.toDouble() ?? 0.0,
      amountAfterAdap: (json['amount_after_adap'] as num?)?.toDouble() ?? 0.0,
      rrGpayAmount: (json['rr_gpay_amount'] as num?)?.toDouble() ?? 0.0,
      amountAfterGpay: (json['amount_after_gpay'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      finalAmount: ((json['final_amount'] as num?)?.toDouble() ?? 0.0) + ((json['extra_net_amount'] as num?)?.toDouble() ?? 0.0) + ((json['other_amount'] as num?)?.toDouble() ?? 0.0),
       additionalCollection: (json['additional_collection'] as num?)?.toDouble() ?? 0.0,
       additionalDeduction: (json['additional_deduction'] as num?)?.toDouble() ?? 0.0,
       otherAmount: (json['other_amount'] as num?)?.toDouble() ?? 0.0,
       extraNetAmount: (json['extra_net_amount'] as num?)?.toDouble() ?? 0.0,
       previousFinalAmount: (json['previous_final_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
  }

  DailyCashRecord copyWith({
    String? id,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyCashRecord(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      regionId: regionId ?? this.regionId,
      modelId: modelId ?? this.modelId,
      bagId: bagId ?? this.bagId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      netAmountInHand: netAmountInHand ?? this.netAmountInHand,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      remainingReason: remainingReason ?? this.remainingReason,
      documentFees: documentFees ?? this.documentFees,
      totalAmount: totalAmount,
      adapAmount: adapAmount ?? this.adapAmount,
      amountAfterAdap: amountAfterAdap,
      rrGpayAmount: rrGpayAmount ?? this.rrGpayAmount,
      amountAfterGpay: amountAfterGpay,
      expense: expense ?? this.expense,
      finalAmount: finalAmount,
       additionalCollection: additionalCollection ?? this.additionalCollection,
       additionalDeduction: additionalDeduction ?? this.additionalDeduction,
       otherAmount: otherAmount ?? this.otherAmount,
       extraNetAmount: extraNetAmount ?? this.extraNetAmount,
       previousFinalAmount: previousFinalAmount ?? this.previousFinalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
