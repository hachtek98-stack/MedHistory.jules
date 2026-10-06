import 'package:flutter_test/flutter_test.dart';
import 'package:medhistory/core/database/database_helper.dart';
import 'package:medhistory/core/security/security_service.dart';
import 'package:medhistory/features/diseases/data/disease_repository.dart';
import 'package:medhistory/features/diseases/domain/disease.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('DiseaseRepository Tests', () {
    late DatabaseHelper dbHelper;
    late DiseaseRepository repository;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      dbHelper = DatabaseHelper(securityService: SecurityService());
      repository = DiseaseRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('createDisease inserts disease and syncs FTS5', () async {
      final disease = await repository.createDisease(
        title: 'Hypertension',
        description: 'Tension élevée',
        status: DiseaseStatus.active,
      );

      expect(disease.id, isNotEmpty);
      expect(disease.title, equals('Hypertension'));

      final list = await repository.getAllDiseases();
      expect(list.length, equals(1));
      expect(list.first.title, equals('Hypertension'));

      // Vérification FTS5
      final db = await dbHelper.database;
      final ftsRes = await db.rawQuery(
        'SELECT * FROM medical_fts WHERE content_text MATCH ?',
        ['Hypertension'],
      );
      expect(ftsRes.length, equals(1));
    });

    test('updateDisease updates status and description', () async {
      final created = await repository.createDisease(
        title: 'Asthme',
        status: DiseaseStatus.active,
      );

      final updated = created.copyWith(status: DiseaseStatus.remission);
      await repository.updateDisease(updated);

      final list = await repository.getAllDiseases();
      expect(list.first.status, equals(DiseaseStatus.remission));
    });
  });
}
