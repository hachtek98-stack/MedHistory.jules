import 'package:flutter_test/flutter_test.dart';
import 'package:medhistory/core/database/database_helper.dart';
import 'package:medhistory/core/security/security_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('DatabaseHelper DDL & Integrity Tests', () {
    late DatabaseHelper databaseHelper;
    late SecurityService securityService;
    const uuid = Uuid();

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      securityService = SecurityService();
      databaseHelper = DatabaseHelper(securityService: securityService);
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    test('Database opens with foreign_keys ON and creates all tables', () async {
      final db = await databaseHelper.database;
      expect(db.isOpen, isTrue);

      final pragmaRes = await db.rawQuery('PRAGMA foreign_keys;');
      expect(pragmaRes.first['foreign_keys'], equals(1));

      // Vérification des tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
      final tableNames = tables.map((t) => t['name'] as String).toList();

      expect(tableNames, contains('diseases'));
      expect(tableNames, contains('consultations'));
      expect(tableNames, contains('consultation_diseases'));
      expect(tableNames, contains('prescriptions'));
      expect(tableNames, contains('attachments'));
      expect(tableNames, contains('medications'));
      expect(tableNames, contains('medical_fts'));
    });

    test('Enforces Foreign Key constraint on consultation_diseases and medications', () async {
      final db = await databaseHelper.database;

      final diseaseId = uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('diseases', {
        'id': diseaseId,
        'title': 'Diabète de type 2',
        'status': 'ACTIVE',
        'created_at': now,
        'updated_at': now,
      });

      // Tentative d'insertion avec une consultation_id non existante
      expect(
        () async => await db.insert('consultation_diseases', {
          'consultation_id': uuid.v4(),
          'disease_id': diseaseId,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('FTS5 Virtual Table insert and search works as intended', () async {
      final db = await databaseHelper.database;

      final docId = uuid.v4();
      await db.insert('medical_fts', {
        'entity_id': docId,
        'entity_type': 'CONSULTATION',
        'content_text': 'Dr Dupont Cardiologue Consultation hypertension artérielle sévère',
      });

      final results = await db.rawQuery(
        'SELECT * FROM medical_fts WHERE content_text MATCH ?',
        ['hypertension'],
      );

      expect(results.length, equals(1));
      expect(results.first['entity_id'], equals(docId));
      expect(results.first['entity_type'], equals('CONSULTATION'));
    });
  });
}
