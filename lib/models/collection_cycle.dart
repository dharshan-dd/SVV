class CollectionCycle {
  final String id;
  final String bagConfigurationId;
  final String bagId;
  final DateTime scheduledDate;
  final double expectedAmount;
  final double collectedAmount;
  final double pendingAmount;
  final String status;
  final String? previousCycleId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectionCycle({
    required this.id,
    required this.bagConfigurationId,
    required this.bagId,
    required this.scheduledDate,
    this.expectedAmount = 0.0,
    this.collectedAmount = 0.0,
    this.pendingAmount = 0.0,
    this.status = 'pending',
    this.previousCycleId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectionCycle.fromJson(Map<String, dynamic> json) {
    return CollectionCycle(
      id: json['id'] as String,
      bagConfigurationId: json['bag_configuration_id'] as String,
      bagId: json['bag_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      expectedAmount: _toDouble(json['expected_amount']),
      collectedAmount: _toDouble(json['collected_amount']),
      pendingAmount: _toDouble(json['pending_amount']),
      status: json['status'] as String? ?? 'pending',
      previousCycleId: json['previous_cycle_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bag_configuration_id': bagConfigurationId,
      'bag_id': bagId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'expected_amount': expectedAmount,
      'collected_amount': collectedAmount,
      'pending_amount': pendingAmount,
      'status': status,
      'previous_cycle_id': previousCycleId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isPartiallyCollected => status == 'partially_collected';
  bool get isCollected => status == 'collected';
  bool get isMissed => status == 'missed';
  bool get isCancelled => status == 'cancelled';

  double get remainingAmount => expectedAmount - collectedAmount;
}
