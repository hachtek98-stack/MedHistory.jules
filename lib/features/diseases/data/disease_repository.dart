import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../domain/disease.dart';

class DiseaseRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid;

  DiseaseRepository({DatabaseHelper? dbHelper, Uuid? uuid})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _uuid = uuid ?? const Uuid();

  Future<List<Disease>> getAllDiseases() async {
    final db = await _dbHelper.database;
    final maps = await db.query('diseases', orderBy: 'title ASC');
    return maps.map((m) => Disease.fromMap(m)).toList();
  }

  Future<List<Disease>> getActiveDiseases() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'diseases',
      where: 'status = ?',
      whereArgs: [DiseaseStatus.active.value],
      orderBy: 'title ASC',
    );
    return maps.map((m) => Disease.fromMap(m)).toList();
  }

  Future<Disease> createDisease({
    required String title,
    String? description,
    DiseaseStatus status = DiseaseStatus.active,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final disease = Disease(
      id: _uuid.v4(),
      title: title,
      description: description,
      status: status,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('diseases', disease.toMap());

    // Synchronisation FTS5
    await db.insert('medical_fts', {
      'entity_id': disease.id,
      'entity_type': 'DISEASE',
      'content_text': '${disease.title} ${disease.description ?? ''}',
    });

    return disease;
  }

  Future<void> updateDisease(Disease disease) async {
    final db = await _dbHelper.database;
    final updated = disease.copyWith(updatedAt: DateTime.now());

    await db.update(
      'diseases',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [disease.id],
    );

    // Mettre à jour FTS5
    await db.delete('medical_fts', where: 'entity_id = ?', whereArgs: [disease.id]);
    await db.insert('medical_fts', {
      'entity_id': updated.id,
      'entity_type': 'DISEASE',
      'content_text': '${updated.title} ${updated.description ?? ''}',
    });
  }

  Future<void> deleteDisease(String id) async {
    final db = await _dbHelper.database;
    await db.delete('diseases', where: 'id = ?', whereArgs: [id]);
    await db.delete('medical_fts', where: 'entity_id = ?', whereArgs: [id]);
  }
}
