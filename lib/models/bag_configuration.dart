class BagConfiguration {
  final String id;
  final String entity;
  final String regionId;
  final String modelId;
  final String bagId;
  final String frequency;
  bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enhanced schedule fields
  final String frequencyType;
  final List<int> daysOfWeek;
  final String monthlyRule;
  final double expectedAmount;
  final double sundayAmount;
  final double mondayAmount;
  final double tuesdayAmount;
  final double wednesdayAmount;
  final double thursdayAmount;
  final double fridayAmount;
  final double saturdayAmount;
  final DateTime startDate;
  final DateTime endDate;

  BagConfiguration({
    required this.id,
    required this.entity,
    required this.regionId,
    required this.modelId,
    required this.bagId,
    required this.frequency,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.frequencyType = 'weekly',
    this.daysOfWeek = const [],
    this.monthlyRule = '',
    this.expectedAmount = 0.0,
    this.sundayAmount = 0.0,
    this.mondayAmount = 0.0,
    this.tuesdayAmount = 0.0,
    this.wednesdayAmount = 0.0,
    this.thursdayAmount = 0.0,
    this.fridayAmount = 0.0,
    this.saturdayAmount = 0.0,
    required this.startDate,
    required this.endDate,
  });

  factory BagConfiguration.fromJson(Map<String, dynamic> json) {
    return BagConfiguration(
      id: json['id'] as String,
      entity: json['entity'] as String? ?? 'Line',
      regionId: json['region_id'] as String,
      modelId: json['model_id'] as String,
      bagId: json['bag_id'] as String,
      frequency: json['frequency'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      frequencyType: json['frequency_type'] as String? ?? 'weekly',
      daysOfWeek: json['days_of_week'] != null
          ? List<int>.from(json['days_of_week'] as List)
          : [],
      monthlyRule: json['monthly_rule'] as String? ?? '',
      expectedAmount: _toDouble(json['expected_amount']),
      sundayAmount: _toDouble(json['sunday_amount']),
      mondayAmount: _toDouble(json['monday_amount']),
      tuesdayAmount: _toDouble(json['tuesday_amount']),
      wednesdayAmount: _toDouble(json['wednesday_amount']),
      thursdayAmount: _toDouble(json['thursday_amount']),
      fridayAmount: _toDouble(json['friday_amount']),
      saturdayAmount: _toDouble(json['saturday_amount']),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : DateTime(2099, 12, 31),
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
      'entity': entity,
      'region_id': regionId,
      'model_id': modelId,
      'bag_id': bagId,
      'frequency': frequency,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    };
  }

  double getAmountForDay(int dayOfWeek) {
    switch (dayOfWeek) {
      case 0:
        return sundayAmount;
      case 1:
        return mondayAmount;
      case 2:
        return tuesdayAmount;
      case 3:
        return wednesdayAmount;
      case 4:
        return thursdayAmount;
      case 5:
        return fridayAmount;
      case 6:
        return saturdayAmount;
      default:
        return 0.0;
    }
  }

  List<String> getDaysDisplay() {
    final days = <String>[];
    if (daysOfWeek.contains(0)) days.add('Sunday');
    if (daysOfWeek.contains(1)) days.add('Monday');
    if (daysOfWeek.contains(2)) days.add('Tuesday');
    if (daysOfWeek.contains(3)) days.add('Wednesday');
    if (daysOfWeek.contains(4)) days.add('Thursday');
    if (daysOfWeek.contains(5)) days.add('Friday');
    if (daysOfWeek.contains(6)) days.add('Saturday');
    return days;
  }
}
