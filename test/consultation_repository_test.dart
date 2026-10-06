import 'package:flutter_test/flutter_test.dart';
import 'package:medhistory/core/database/database_helper.dart';
import 'package:medhistory/core/security/security_service.dart';
import 'package:medhistory/features/diseases/data/disease_repository.dart';
import 'package:medhistory/features/diseases/domain/disease.dart';
import 'package:medhistory/features/consultations/data/consultation_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('ConsultationRepository Tests', () {
    late DatabaseHelper dbHelper;
    late DiseaseRepository diseaseRepo;
    late ConsultationRepository consultationRepo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      dbHelper = DatabaseHelper(securityService: SecurityService());
      diseaseRepo = DiseaseRepository(dbHelper: dbHelper);
      consultationRepo = ConsultationRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('createConsultation links diseases and updates FTS5 index', () async {
      final disease = await diseaseRepo.createDisease(title: 'Diabète');

      final consultation = await consultationRepo.createConsultation(
        consultationDate: DateTime.now(),
        doctorName: 'Dr Martin',
        specialty: 'Endocrinologue',
        motive: 'Contrôle annuel glycémie',
        diagnosis: 'Équilibre glycémique satisfaisant',
        diseaseIds: [disease.id],
      );

      expect(consultation.id, isNotEmpty);
      expect(consultation.associatedDiseases.length, equals(1));
      expect(consultation.associatedDiseases.first.title, equals('Diabète'));

      // Vérification FTS5
      final db = await dbHelper.database;
      final ftsRes = await db.rawQuery(
        'SELECT * FROM medical_fts WHERE content_text MATCH ?',
        ['Endocrinologue'],
      );
      expect(ftsRes.length, equals(1));
      expect(ftsRes.first['entity_id'], equals(consultation.id));
    });
  });
}
