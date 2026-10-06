enum DiseaseStatus {
  active('ACTIVE'),
  remission('REMISSION'),
  cured('CURED');

  final String value;
  const DiseaseStatus(this.value);

  static DiseaseStatus fromString(String val) {
    return DiseaseStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DiseaseStatus.active,
    );
  }
}

class Disease {
  final String id;
  final String title;
  final String? description;
  final DiseaseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Disease({
    required this.id,
    required this.title,
    this.description,
    this.status = DiseaseStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.value,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Disease.fromMap(Map<String, dynamic> map) {
    return Disease(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: DiseaseStatus.fromString(map['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Disease copyWith({
    String? id,
    String? title,
    String? description,
    DiseaseStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Disease(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
