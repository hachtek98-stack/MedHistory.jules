import '../../diseases/domain/disease.dart';

class Consultation {
  final String id;
  final DateTime consultationDate;
  final String? doctorName;
  final String? specialty;
  final String? facility;
  final String? motive;
  final String? diagnosis;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Disease> associatedDiseases;

  Consultation({
    required this.id,
    required this.consultationDate,
    this.doctorName,
    this.specialty,
    this.facility,
    this.motive,
    this.diagnosis,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.associatedDiseases = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consultation_date': consultationDate.millisecondsSinceEpoch,
      'doctor_name': doctorName,
      'specialty': specialty,
      'facility': facility,
      'motive': motive,
      'diagnosis': diagnosis,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Consultation.fromMap(Map<String, dynamic> map, {List<Disease> associatedDiseases = const []}) {
    return Consultation(
      id: map['id'] as String,
      consultationDate: DateTime.fromMillisecondsSinceEpoch(map['consultation_date'] as int),
      doctorName: map['doctor_name'] as String?,
      specialty: map['specialty'] as String?,
      facility: map['facility'] as String?,
      motive: map['motive'] as String?,
      diagnosis: map['diagnosis'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      associatedDiseases: associatedDiseases,
    );
  }

  Consultation copyWith({
    String? id,
    DateTime? consultationDate,
    String? doctorName,
    String? specialty,
    String? facility,
    String? motive,
    String? diagnosis,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Disease>? associatedDiseases,
  }) {
    return Consultation(
      id: id ?? this.id,
      consultationDate: consultationDate ?? this.consultationDate,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      facility: facility ?? this.facility,
      motive: motive ?? this.motive,
      diagnosis: diagnosis ?? this.diagnosis,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      associatedDiseases: associatedDiseases ?? this.associatedDiseases,
    );
  }
}
