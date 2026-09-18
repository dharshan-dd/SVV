import 'package:intl/intl.dart';

class DailyCollectionEntry {
  final String id;
  final DateTime entryDate;
  final String regionId;
  final String modelId;
  final String bagId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Collection Cycle Fields
  final String? bagConfigurationId;
  final String? collectionCycleId;
  final double expectedAmount;
  final double previousPending;
  final double totalDue;
  final bool isDeleted;
  final DateTime? deletedAt;

  // Credit Breakdown
  final double openingBalance;
  final double collectionCash;
  final double collectionUpi;
  final double documentCharges;

  // Debit Breakdown
  final double newLoanCash;
  final double newLoanUpi;
  final double chitPayment;
  final double miscExpenses;

  // Calculated Fields
  final double totalCredit;
  final double totalDebit;
  final double netClosingBalance;

  DailyCollectionEntry({
    required this.id,
    required this.entryDate,
    required this.regionId,
    required this.modelId,
    required this.bagId,
    required this.createdAt,
    required this.updatedAt,
    this.bagConfigurationId,
    this.collectionCycleId,
    this.expectedAmount = 0.0,
    this.previousPending = 0.0,
    this.totalDue = 0.0,
    this.isDeleted = false,
    this.deletedAt,
    this.openingBalance = 0.0,
    this.collectionCash = 0.0,
    this.collectionUpi = 0.0,
    this.documentCharges = 0.0,
    this.newLoanCash = 0.0,
    this.newLoanUpi = 0.0,
    this.chitPayment = 0.0,
    this.miscExpenses = 0.0,
    this.totalCredit = 0.0,
    this.totalDebit = 0.0,
    this.netClosingBalance = 0.0,
  });

  factory DailyCollectionEntry.fromJson(Map<String, dynamic> json) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return DailyCollectionEntry(
      id: json['id'] as String,
      entryDate: dateFormat.parse(json['entry_date'] as String),
      regionId: json['region_id'] as String,
      modelId: json['model_id'] as String,
      bagId: json['bag_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      bagConfigurationId: json['bag_configuration_id'] as String?,
      collectionCycleId: json['collection_cycle_id'] as String?,
      expectedAmount: _toDouble(json['expected_amount']),
      previousPending: _toDouble(json['previous_pending']),
      totalDue: _toDouble(json['total_due']),
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      openingBalance: _toDouble(json['opening_balance']),
      collectionCash: _toDouble(json['collection_cash']),
      collectionUpi: _toDouble(json['collection_upi']),
      documentCharges: _toDouble(json['document_charges']),
      newLoanCash: _toDouble(json['new_loan_cash']),
      newLoanUpi: _toDouble(json['new_loan_upi']),
      chitPayment: _toDouble(json['chit_payment']),
      miscExpenses: _toDouble(json['misc_expenses']),
      totalCredit: _toDouble(json['total_credit']),
      totalDebit: _toDouble(json['total_debit']),
      netClosingBalance: _toDouble(json['net_closing_balance']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return {
      'id': id,
      'entry_date': dateFormat.format(entryDate),
      'region_id': regionId,
      'model_id': modelId,
      'bag_id': bagId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bag_configuration_id': bagConfigurationId,
      'collection_cycle_id': collectionCycleId,
      'expected_amount': expectedAmount,
      'previous_pending': previousPending,
      'total_due': totalDue,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'opening_balance': openingBalance,
      'collection_cash': collectionCash,
      'collection_upi': collectionUpi,
      'document_charges': documentCharges,
      'new_loan_cash': newLoanCash,
      'new_loan_upi': newLoanUpi,
      'chit_payment': chitPayment,
      'misc_expenses': miscExpenses,
    };
  }

  DailyCollectionEntry copyWith({
    String? id,
    DateTime? entryDate,
    String? regionId,
    String? modelId,
    String? bagId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bagConfigurationId,
    String? collectionCycleId,
    double? expectedAmount,
    double? previousPending,
    double? totalDue,
    bool? isDeleted,
    DateTime? deletedAt,
    double? openingBalance,
    double? collectionCash,
    double? collectionUpi,
    double? documentCharges,
    double? newLoanCash,
    double? newLoanUpi,
    double? chitPayment,
    double? miscExpenses,
    double? totalCredit,
    double? totalDebit,
    double? netClosingBalance,
  }) {
    return DailyCollectionEntry(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      regionId: regionId ?? this.regionId,
      modelId: modelId ?? this.modelId,
      bagId: bagId ?? this.bagId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bagConfigurationId: bagConfigurationId ?? this.bagConfigurationId,
      collectionCycleId: collectionCycleId ?? this.collectionCycleId,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      previousPending: previousPending ?? this.previousPending,
      totalDue: totalDue ?? this.totalDue,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
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

  double get calculatedTotalCredit =>
      openingBalance + collectionCash + collectionUpi + documentCharges;

  double get calculatedTotalDebit =>
      newLoanCash + newLoanUpi + chitPayment + miscExpenses;

  double get calculatedNetClosingBalance =>
      calculatedTotalCredit - calculatedTotalDebit;
}
