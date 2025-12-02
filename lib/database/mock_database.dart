import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/matiere.dart';
import '../models/session.dart';
import '../models/objectif.dart';
import 'database_adapter.dart';

class MockDatabase implements StudyFlowDatabase {
  // Singleton pattern
  static final MockDatabase _instance = MockDatabase._internal();

  // Factory constructor
  factory MockDatabase() {
    return _instance;
  }

  // Données en mémoire
  late List<Matiere> _matieres;
  late List<SessionEtude> _sessions;
  late ObjectifQuotidien _objectif;
  int _nextMatiereId = 1;
  int _nextSessionId = 1;

  // Constructeur privé
  MockDatabase._internal() {
    print('📊 Initialisation du MockDatabase (Singleton)');
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();

    // Essayer de charger les données sauvegardées
    final matieresSaved = prefs.getStringList('matieres');
    final sessionsSaved = prefs.getStringList('sessions');
    final objectifMinutes = prefs.getInt('objectifMinutes');

    if (matieresSaved != null && matieresSaved.isNotEmpty) {
      // Charger depuis SharedPreferences
      _matieres = matieresSaved
          .map((json) => Matiere.fromMap(_parseStringToMap(json)))
          .toList();
      _nextMatiereId = (_matieres.map((m) => m.id ?? 0).reduce(max)) + 1;
      print('📊 ${_matieres.length} matières chargées depuis le stockage');
    } else {
      // Données par défaut
      _matieres = _getDefaultMatieres();
      _nextMatiereId = 4;
      print('📊 Données par défaut chargées (3 matières)');
    }

    if (sessionsSaved != null && sessionsSaved.isNotEmpty) {
      _sessions = sessionsSaved
          .map((json) => SessionEtude.fromMap(_parseStringToMap(json)))
          .toList();
      _nextSessionId = (_sessions.map((s) => s.id ?? 0).reduce(max)) + 1;
      print('📊 ${_sessions.length} sessions chargées depuis le stockage');
    } else {
      _sessions = _getDefaultSessions();
      _nextSessionId = 3;
    }

    _objectif = ObjectifQuotidien(
      id: 1,
      objectifMinutes: objectifMinutes ?? 120,
    );

    print('✅ MockDatabase initialisé avec persistance');
  }

  // Helper pour parser les chaînes en Map
  Map<String, dynamic> _parseStringToMap(String str) {
    final entries = str.split(',');
    final map = <String, dynamic>{};

    for (var entry in entries) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim();
        var value = parts[1].trim();

        // Convertir les valeurs selon leur type
        if (value == 'null') {
          map[key] = null;
        } else if (int.tryParse(value) != null) {
          map[key] = int.parse(value);
        } else {
          map[key] = value;
        }
      }
    }

    return map;
  }

  // Helper pour convertir Map en String simple
  String _mapToString(Map<String, dynamic> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  List<Matiere> _getDefaultMatieres() {
    return [
      Matiere(
        id: 1,
        nom: "Mathématiques",
        couleur: "#2196F3",
        priorite: 2,
        objectifHebdo: 300,
      ),
      Matiere(
        id: 2,
        nom: "Physique",
        couleur: "#FF5722",
        priorite: 1,
        objectifHebdo: 180,
      ),
      Matiere(
        id: 3,
        nom: "Anglais",
        couleur: "#4CAF50",
        priorite: 2,
        objectifHebdo: 240,
      ),
    ];
  }

  List<SessionEtude> _getDefaultSessions() {
    return [
      SessionEtude(
        id: 1,
        matiereId: 1,
        duree: 45,
        date: DateTime.now().subtract(const Duration(days: 1)),
        note: "Chapitre 3 - Algèbre",
      ),
      SessionEtude(
        id: 2,
        matiereId: 2,
        duree: 30,
        date: DateTime.now(),
        note: "Mécanique",
      ),
    ];
  }

  // Sauvegarder les données dans SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Convertir les listes en chaînes simples
    final matieresStrings =
        _matieres.map((matiere) => _mapToString(matiere.toMap())).toList();

    final sessionsStrings =
        _sessions.map((session) => _mapToString(session.toMap())).toList();

    // Sauvegarder
    await prefs.setStringList('matieres', matieresStrings);
    await prefs.setStringList('sessions', sessionsStrings);
    await prefs.setInt('objectifMinutes', _objectif.objectifMinutes);

    print(
        '💾 Données sauvegardées (${_matieres.length} matières, ${_sessions.length} sessions)');
  }

  // === CRUD Matières ===
  @override
  Future<List<Matiere>> getMatieres() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [..._matieres];
  }

  @override
  Future<Matiere?> getMatiereById(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _matieres.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> insertMatiere(Matiere matiere) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final nouvelleMatiere = Matiere(
      id: _nextMatiereId++,
      nom: matiere.nom,
      couleur: matiere.couleur,
      priorite: matiere.priorite,
      objectifHebdo: matiere.objectifHebdo,
    );
    _matieres.add(nouvelleMatiere);
    await _saveData();
    return nouvelleMatiere.id!;
  }

  @override
  Future<void> updateMatiere(Matiere matiere) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _matieres.indexWhere((m) => m.id == matiere.id);
    if (index != -1) {
      _matieres[index] = matiere;
      await _saveData();
    }
  }

  @override
  Future<void> deleteMatiere(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _matieres.removeWhere((m) => m.id == id);
    await _saveData();
  }

  // === CRUD Sessions ===
  @override
  Future<List<SessionEtude>> getSessions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [..._sessions];
  }

  @override
  Future<List<SessionEtude>> getSessionsByMatiere(int matiereId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _sessions.where((s) => s.matiereId == matiereId).toList();
  }

  @override
  Future<List<SessionEtude>> getSessionsByDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _sessions
        .where((session) =>
            session.date.year == date.year &&
            session.date.month == date.month &&
            session.date.day == date.day)
        .toList();
  }

  @override
  Future<int> insertSession(SessionEtude session) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final nouvelleSession = SessionEtude(
      id: _nextSessionId++,
      matiereId: session.matiereId,
      duree: session.duree,
      date: session.date,
      note: session.note,
    );
    _sessions.add(nouvelleSession);
    await _saveData();
    return nouvelleSession.id!;
  }

  @override
  Future<void> deleteSession(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sessions.removeWhere((s) => s.id == id);
    await _saveData();
  }

  // === Objectifs ===
  @override
  Future<ObjectifQuotidien> getObjectif() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _objectif;
  }

  @override
  Future<void> updateObjectif(int objectifMinutes) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _objectif = ObjectifQuotidien(id: 1, objectifMinutes: objectifMinutes);
    await _saveData();
  }

  // === Statistiques ===
  @override
  Future<int> getTempsEtudieAujourdhui() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final aujourdhui = DateTime.now();

    int total = 0;
    for (var session in _sessions) {
      if (session.date.year == aujourdhui.year &&
          session.date.month == aujourdhui.month &&
          session.date.day == aujourdhui.day) {
        total += session.duree; // duree doit être int
      }
    }
    return total;
  }

  @override
  Future<int> getTotalTempsEtudie() async {
    await Future.delayed(const Duration(milliseconds: 300));

    int total = 0;
    for (var session in _sessions) {
      total += session.duree; // duree doit être int
    }
    return total;
  }

  @override
  Future<Map<String, int>> getTempsParMatiere() async {
    await Future.delayed(const Duration(milliseconds: 300));
    Map<String, int> result = {};

    for (var matiere in _matieres) {
      int total = 0;
      for (var session in _sessions) {
        if (session.matiereId == matiere.id) {
          total += session.duree;
        }
      }
      result[matiere.nom] = total;
    }

    return result;
  }

  @override
  Future<void> close() async {
    await _saveData(); // Sauvegarde avant fermeture
    print('📊 MockDatabase fermé et sauvegardé');
  }

  // Méthode utilitaire pour réinitialiser les données (debug)
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('matieres');
    await prefs.remove('sessions');
    await prefs.remove('objectifMinutes');

    _matieres = _getDefaultMatieres();
    _sessions = _getDefaultSessions();
    _objectif = ObjectifQuotidien(id: 1, objectifMinutes: 120);
    _nextMatiereId = 4;
    _nextSessionId = 3;

    print('🔄 Données réinitialisées aux valeurs par défaut');
  }
}
