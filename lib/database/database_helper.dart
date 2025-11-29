import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/matiere.dart';
import '../models/session.dart';
import '../models/objectif.dart';

class DatabaseHelper {
  // Singleton pattern - une seule instance de la base
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'studyflow.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Table des matières
    await db.execute('''
      CREATE TABLE matieres(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        couleur TEXT,
        priorite INTEGER DEFAULT 1,
        objectifHebdo INTEGER DEFAULT 0
      )
    ''');

    // Table des sessions d'étude
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matiereId INTEGER,
        duree INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY(matiereId) REFERENCES matieres(id)
      )
    ''');

    // Table des objectifs
    await db.execute('''
      CREATE TABLE objectifs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        objectifMinutes INTEGER DEFAULT 120
      )
    ''');

    // Objectif par défaut : 2 heures
    await db.insert('objectifs', {'objectifMinutes': 120});
  }

  // CRUD pour Matieres
  Future<int> insertMatiere(Matiere matiere) async {
    final db = await database;
    return await db.insert('matieres', matiere.toMap());
  }

  Future<List<Matiere>> getMatieres() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('matieres');
    return List.generate(maps.length, (i) => Matiere.fromMap(maps[i]));
  }

  Future<Matiere?> getMatiereById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'matieres',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Matiere.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateMatiere(Matiere matiere) async {
    final db = await database;
    return await db.update(
      'matieres',
      matiere.toMap(),
      where: 'id = ?',
      whereArgs: [matiere.id],
    );
  }

  Future<int> deleteMatiere(int id) async {
    final db = await database;
    return await db.delete(
      'matieres',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD pour Sessions
  Future<int> insertSession(SessionEtude session) async {
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<List<SessionEtude>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sessions');
    return List.generate(maps.length, (i) => SessionEtude.fromMap(maps[i]));
  }

  Future<List<SessionEtude>> getSessionsByMatiere(int matiereId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'matiereId = ?',
      whereArgs: [matiereId],
    );
    return List.generate(maps.length, (i) => SessionEtude.fromMap(maps[i]));
  }

  Future<List<SessionEtude>> getSessionsByDate(DateTime date) async {
    final db = await database;
    final dateString = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'date LIKE ?',
      whereArgs: ['$dateString%'],
    );
    return List.generate(maps.length, (i) => SessionEtude.fromMap(maps[i]));
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Objectifs
  Future<ObjectifQuotidien> getObjectif() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('objectifs');
    return ObjectifQuotidien.fromMap(maps.first);
  }

  Future<int> updateObjectif(int objectifMinutes) async {
    final db = await database;
    return await db.update(
      'objectifs',
      {'objectifMinutes': objectifMinutes},
    );
  }

  // Méthodes utilitaires - VERSION CORRIGÉE
  Future<int> getTotalTempsEtudie() async {
    final sessions = await getSessions();
    int total = 0;
    for (var session in sessions) {
      total += session.duree;
    }
    return total;
  }

  Future<int> getTempsEtudieAujourdhui() async {
    final aujourdhui = DateTime.now();
    final sessionsAujourdhui = await getSessionsByDate(aujourdhui);
    int total = 0;
    for (var session in sessionsAujourdhui) {
      total += session.duree;
    }
    return total;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
