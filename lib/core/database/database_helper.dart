import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import '../security/security_service.dart';

/// Gestionnaire SQLite chiffré SQLCipher (AES-256) pour l'architecture Offline-First.
class DatabaseHelper {
  static const String _dbName = 'medhistory_vault.db';
  static const int _dbVersion = 1;

  final SecurityService _securityService;
  Database? _database;

  DatabaseHelper({SecurityService? securityService})
      : _securityService = securityService ?? SecurityService();

  /// Fournit l'instance active de la base de données déverrouillée.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données chiffrée avec SQLCipher et la clé cryptographique 256 bits.
  Future<Database> _initDatabase({String? customPath, DatabaseFactory? customFactory}) async {
    final encryptionKey = await _securityService.getOrCreateDatabaseKey();

    String dbPath;
    if (customPath != null) {
      dbPath = customPath;
    } else {
      if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        ffi.sqfliteFfiInit();
        databaseFactory = ffi.databaseFactoryFfi;
      }
      final dbDir = await getDatabasesPath();
      dbPath = join(dbDir, _dbName);
    }

    final factory = customFactory ?? databaseFactory;

    return await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        password: encryptionKey,
        onConfigure: (db) async {
          // Activation impérative des contraintes de clés étrangères
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Logique de migration de schéma si besoin futur
        },
      ),
    );
  }

  /// Exécute les requêtes de création du schéma complet.
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diseases (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'REMISSION', 'CURED')),
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_diseases_status ON diseases(status);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS consultations (
          id TEXT PRIMARY KEY,
          consultation_date INTEGER NOT NULL,
          doctor_name TEXT,
          specialty TEXT,
          facility TEXT,
          motive TEXT,
          diagnosis TEXT,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_consultations_date ON consultations(consultation_date DESC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_consultations_doctor ON consultations(doctor_name);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS consultation_diseases (
          consultation_id TEXT NOT NULL,
          disease_id TEXT NOT NULL,
          PRIMARY KEY (consultation_id, disease_id),
          FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
          FOREIGN KEY (disease_id) REFERENCES diseases(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_assoc_disease ON consultation_diseases(disease_id);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS prescriptions (
          id TEXT PRIMARY KEY,
          consultation_id TEXT,
          prescription_date INTEGER NOT NULL,
          notes TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prescriptions_consultation ON prescriptions(consultation_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prescriptions_date ON prescriptions(prescription_date DESC);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attachments (
          id TEXT PRIMARY KEY,
          prescription_id TEXT,
          consultation_id TEXT,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL CHECK (file_type IN ('PRESCRIPTION_PHOTO', 'LAB_RESULT', 'RADIOLOGY', 'OTHER')),
          created_at INTEGER NOT NULL,
          FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE,
          FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attachments_prescription ON attachments(prescription_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attachments_consultation ON attachments(consultation_id);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS medications (
          id TEXT PRIMARY KEY,
          prescription_id TEXT NOT NULL,
          name TEXT NOT NULL,
          dosage TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'ONGOING' CHECK (status IN ('ONGOING', 'COMPLETED', 'STOPPED')),
          start_date INTEGER NOT NULL,
          end_date INTEGER,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_prescription ON medications(prescription_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_status ON medications(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_name ON medications(name);');

    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS medical_fts USING fts5(
          entity_id UNINDEXED,
          entity_type UNINDEXED,
          content_text
      );
    ''');
  }

  /// Ferme la connexion active à la base de données.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
