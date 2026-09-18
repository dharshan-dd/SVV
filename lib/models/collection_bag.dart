class CollectionBag {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectionBag({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectionBag.fromJson(Map<String, dynamic> json) {
    return CollectionBag(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CollectionBag copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CollectionBag(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
