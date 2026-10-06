import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../diseases/domain/disease.dart';
import '../domain/consultation.dart';

class ConsultationRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid;

  ConsultationRepository({DatabaseHelper? dbHelper, Uuid? uuid})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _uuid = uuid ?? const Uuid();

  Future<List<Consultation>> getAllConsultations() async {
    final db = await _dbHelper.database;
    final maps = await db.query('consultations', orderBy: 'consultation_date DESC');

    List<Consultation> list = [];
    for (var map in maps) {
      final id = map['id'] as String;
      final associatedDiseases = await _getDiseasesForConsultation(db, id);
      list.add(Consultation.fromMap(map, associatedDiseases: associatedDiseases));
    }
    return list;
  }

  Future<Consultation> createConsultation({
    required DateTime consultationDate,
    String? doctorName,
    String? specialty,
    String? facility,
    String? motive,
    String? diagnosis,
    String? notes,
    List<String> diseaseIds = const [],
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final id = _uuid.v4();

    final consultation = Consultation(
      id: id,
      consultationDate: consultationDate,
      doctorName: doctorName,
      specialty: specialty,
      facility: facility,
      motive: motive,
      diagnosis: diagnosis,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('consultations', consultation.toMap());

      for (var diseaseId in diseaseIds) {
        await txn.insert('consultation_diseases', {
          'consultation_id': id,
          'disease_id': diseaseId,
        });
      }

      // Concaténation pour la recherche globale FTS5
      final contentText = [
        doctorName ?? '',
        specialty ?? '',
        facility ?? '',
        motive ?? '',
        diagnosis ?? '',
        notes ?? '',
      ].where((s) => s.isNotEmpty).join(' ');

      await txn.insert('medical_fts', {
        'entity_id': id,
        'entity_type': 'CONSULTATION',
        'content_text': contentText,
      });
    });

    final associatedDiseases = await _getDiseasesForConsultation(db, id);
    return consultation.copyWith(associatedDiseases: associatedDiseases);
  }

  Future<List<Disease>> _getDiseasesForConsultation(Database db, String consultationId) async {
    final maps = await db.rawQuery('''
      SELECT d.* FROM diseases d
      INNER JOIN consultation_diseases cd ON cd.disease_id = d.id
      WHERE cd.consultation_id = ?
    ''', [consultationId]);

    return maps.map((m) => Disease.fromMap(m)).toList();
  }
}
