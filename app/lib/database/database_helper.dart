import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/inspection.dart';
import '../models/insurance.dart';
import '../models/maintenance_task.dart';
import '../models/tire_set.dart';
import '../models/vehicle.dart';
import '../models/vehicle_document.dart';
import '../models/vignette.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'fuhrparkmeister.db';
  static const _dbVersion = 3;

  static const _createMaintenanceTasksTable = '''
    CREATE TABLE maintenance_tasks (
      id TEXT PRIMARY KEY,
      vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
      titel TEXT NOT NULL,
      notizen TEXT,
      erledigt INTEGER NOT NULL DEFAULT 0,
      erstellt_am TEXT NOT NULL,
      erledigt_am TEXT
    )
  ''';
  static const _createMaintenanceTasksIndex =
      'CREATE INDEX idx_maintenance_tasks_vehicle ON maintenance_tasks(vehicle_id)';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vehicles (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            marke TEXT,
            modell TEXT,
            kennzeichen TEXT,
            fahrgestellnummer TEXT,
            baujahr INTEGER,
            farbe TEXT,
            kaufdatum TEXT,
            kilometerstand_bei_ankauf INTEGER,
            anzahl_vorbesitzer INTEGER,
            soll_reifendimension TEXT,
            notizen TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tire_sets (
            id TEXT PRIMARY KEY,
            vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
            season TEXT NOT NULL,
            dimension TEXT NOT NULL,
            hersteller TEXT,
            profiltiefe_mm REAL,
            montiert INTEGER NOT NULL DEFAULT 0,
            kaufdatum TEXT,
            wechsel_faellig_am TEXT,
            notizen TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE inspections (
            id TEXT PRIMARY KEY,
            vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
            type TEXT NOT NULL,
            faellig_am TEXT NOT NULL,
            letzte_pruefung_am TEXT,
            erinnerung_tage_vorher INTEGER NOT NULL DEFAULT 30,
            erledigt INTEGER NOT NULL DEFAULT 0,
            notizen TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE vignettes (
            id TEXT PRIMARY KEY,
            vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
            jahr INTEGER NOT NULL,
            gueltig_von TEXT NOT NULL,
            gueltig_bis TEXT NOT NULL,
            kaufdatum TEXT,
            preis_euro REAL,
            digital INTEGER NOT NULL DEFAULT 1,
            notizen TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE insurances (
            id TEXT PRIMARY KEY,
            vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
            gesellschaft TEXT NOT NULL,
            polizzennummer TEXT NOT NULL,
            type TEXT NOT NULL,
            gueltig_ab TEXT,
            faelligkeit_jaehrlich_am TEXT,
            praemie_euro REAL,
            notizen TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
            kategorie TEXT NOT NULL,
            dateipfad TEXT NOT NULL,
            titel TEXT NOT NULL,
            erstellt_am TEXT NOT NULL,
            notizen TEXT
          )
        ''');
        await db.execute(_createMaintenanceTasksTable);
        await db.execute(
          'CREATE INDEX idx_tire_sets_vehicle ON tire_sets(vehicle_id)',
        );
        await db.execute(
          'CREATE INDEX idx_inspections_vehicle ON inspections(vehicle_id)',
        );
        await db.execute(
          'CREATE INDEX idx_vignettes_vehicle ON vignettes(vehicle_id)',
        );
        await db.execute(
          'CREATE INDEX idx_insurances_vehicle ON insurances(vehicle_id)',
        );
        await db.execute(
          'CREATE INDEX idx_documents_vehicle ON documents(vehicle_id)',
        );
        await db.execute(_createMaintenanceTasksIndex);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(_createMaintenanceTasksTable);
          await db.execute(_createMaintenanceTasksIndex);
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE vehicles ADD COLUMN kilometerstand_bei_ankauf INTEGER',
          );
          await db.execute(
            'ALTER TABLE vehicles ADD COLUMN anzahl_vorbesitzer INTEGER',
          );
        }
      },
    );
  }

  // ---------------- Vehicles ----------------

  Future<void> insertVehicle(Vehicle v) async {
    final db = await database;
    await db.insert(
      'vehicles',
      v.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateVehicle(Vehicle v) async {
    final db = await database;
    await db.update(
      'vehicles',
      v.toMap(),
      where: 'id = ?',
      whereArgs: [v.id],
    );
  }

  Future<void> deleteVehicle(String id) async {
    final db = await database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final rows = await db.query('vehicles', orderBy: 'name COLLATE NOCASE');
    return rows.map(Vehicle.fromMap).toList();
  }

  // ---------------- Tire sets ----------------

  Future<void> insertTireSet(TireSet t) async {
    final db = await database;
    await db.insert(
      'tire_sets',
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTireSet(TireSet t) async {
    final db = await database;
    await db.update('tire_sets', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTireSet(String id) async {
    final db = await database;
    await db.delete('tire_sets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TireSet>> getTireSetsForVehicle(String vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'tire_sets',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'season',
    );
    return rows.map(TireSet.fromMap).toList();
  }

  // ---------------- Inspections ----------------

  Future<void> insertInspection(Inspection i) async {
    final db = await database;
    await db.insert(
      'inspections',
      i.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateInspection(Inspection i) async {
    final db = await database;
    await db.update(
      'inspections',
      i.toMap(),
      where: 'id = ?',
      whereArgs: [i.id],
    );
  }

  Future<void> deleteInspection(String id) async {
    final db = await database;
    await db.delete('inspections', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Inspection>> getInspectionsForVehicle(String vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'inspections',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'faellig_am',
    );
    return rows.map(Inspection.fromMap).toList();
  }

  Future<List<Inspection>> getAllOpenInspections() async {
    final db = await database;
    final rows = await db.query(
      'inspections',
      where: 'erledigt = 0',
      orderBy: 'faellig_am',
    );
    return rows.map(Inspection.fromMap).toList();
  }

  // ---------------- Vignettes ----------------

  Future<void> insertVignette(Vignette v) async {
    final db = await database;
    await db.insert(
      'vignettes',
      v.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateVignette(Vignette v) async {
    final db = await database;
    await db.update('vignettes', v.toMap(), where: 'id = ?', whereArgs: [v.id]);
  }

  Future<void> deleteVignette(String id) async {
    final db = await database;
    await db.delete('vignettes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Vignette>> getVignettesForVehicle(String vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'vignettes',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'gueltig_bis DESC',
    );
    return rows.map(Vignette.fromMap).toList();
  }

  Future<List<Vignette>> getAllVignettes() async {
    final db = await database;
    final rows = await db.query('vignettes', orderBy: 'gueltig_bis');
    return rows.map(Vignette.fromMap).toList();
  }

  // ---------------- Insurances ----------------

  Future<void> insertInsurance(Insurance i) async {
    final db = await database;
    await db.insert(
      'insurances',
      i.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateInsurance(Insurance i) async {
    final db = await database;
    await db.update(
      'insurances',
      i.toMap(),
      where: 'id = ?',
      whereArgs: [i.id],
    );
  }

  Future<void> deleteInsurance(String id) async {
    final db = await database;
    await db.delete('insurances', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Insurance>> getInsurancesForVehicle(String vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'insurances',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
    );
    return rows.map(Insurance.fromMap).toList();
  }

  Future<List<Insurance>> getAllInsurances() async {
    final db = await database;
    final rows = await db.query('insurances');
    return rows.map(Insurance.fromMap).toList();
  }

  // ---------------- Documents ----------------

  Future<void> insertDocument(VehicleDocument d) async {
    final db = await database;
    await db.insert(
      'documents',
      d.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<VehicleDocument>> getDocumentsForVehicle(
    String vehicleId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'documents',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'erstellt_am DESC',
    );
    return rows.map(VehicleDocument.fromMap).toList();
  }

  // ---------------- Maintenance-To-Dos ----------------

  Future<void> insertMaintenanceTask(MaintenanceTask t) async {
    final db = await database;
    await db.insert(
      'maintenance_tasks',
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMaintenanceTask(MaintenanceTask t) async {
    final db = await database;
    await db.update(
      'maintenance_tasks',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<void> deleteMaintenanceTask(String id) async {
    final db = await database;
    await db.delete('maintenance_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MaintenanceTask>> getMaintenanceTasksForVehicle(
    String vehicleId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'maintenance_tasks',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'erledigt ASC, erstellt_am DESC',
    );
    return rows.map(MaintenanceTask.fromMap).toList();
  }

  // ---------------- Export / Import (Backup & Sync) ----------------

  static const backupTables = [
    'vehicles',
    'tire_sets',
    'inspections',
    'vignettes',
    'insurances',
    'documents',
    'maintenance_tasks',
  ];

  /// Liefert den kompletten Inhalt aller Tabellen als Rohdaten - direkt
  /// JSON-serialisierbar, da alle Modelle bereits primitive Typen in
  /// toMap() liefern.
  Future<Map<String, List<Map<String, Object?>>>> exportAllRaw() async {
    final db = await database;
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in backupTables) {
      result[table] = await db.query(table);
    }
    return result;
  }

  /// Ersetzt den kompletten lokalen Datenbestand durch [data]. Das Löschen
  /// von `vehicles` genügt, da alle Kind-Tabellen per ON DELETE CASCADE
  /// automatisch mitgeräumt werden. Reihenfolge beim Einfügen: Eltern
  /// (vehicles) vor Kindern wegen Foreign-Key-Constraints.
  Future<void> replaceAllRaw(
    Map<String, List<Map<String, Object?>>> data,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('vehicles');
      final batch = txn.batch();
      for (final row in data['vehicles'] ?? const []) {
        batch.insert('vehicles', row);
      }
      for (final table in backupTables.where((t) => t != 'vehicles')) {
        for (final row in data[table] ?? const []) {
          batch.insert(table, row);
        }
      }
      await batch.commit(noResult: true);
    });
  }
}
