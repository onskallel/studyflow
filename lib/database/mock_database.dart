import '../models/matiere.dart';
import '../models/session.dart';
import '../models/objectif.dart';
import 'database_adapter.dart'; // IMPORT AJOUTÉ

// AJOUTE "implements StudyFlowDatabase"
class MockDatabase implements StudyFlowDatabase {
  // Données en mémoire
  List<Matiere> _matieres = [];
  List<SessionEtude> _sessions = [];
  ObjectifQuotidien _objectif = ObjectifQuotidien(id: 1, objectifMinutes: 120);
  int _nextMatiereId = 4;
  int _nextSessionId = 3;

  // Constructeur
  MockDatabase() {
    _initializeData();
  }

  void _initializeData() {
    _matieres = [
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

    _sessions = [
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

  // === CRUD Matières ===
  @override
  Future<List<Matiere>> getMatieres() async {
    print('📊 Mock: ${_matieres.length} matières récupérées');
    await Future.delayed(const Duration(milliseconds: 300));
    return [..._matieres]; // Retourne une copie
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
    print(
        '📊 Mock: Matière "${matiere.nom}" ajoutée (ID: ${nouvelleMatiere.id})');
    return nouvelleMatiere.id!;
  }

  @override
  Future<void> updateMatiere(Matiere matiere) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _matieres.indexWhere((m) => m.id == matiere.id);
    if (index != -1) {
      _matieres[index] = matiere;
      print('📊 Mock: Matière ID ${matiere.id} mise à jour');
    }
  }

  @override
  Future<void> deleteMatiere(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _matieres.removeWhere((m) => m.id == id);
    print('📊 Mock: Matière ID $id supprimée');
  }

  // === CRUD Sessions ===
  @override
  Future<List<SessionEtude>> getSessions() async {
    print('📊 Mock: ${_sessions.length} sessions récupérées');
    await Future.delayed(const Duration(milliseconds: 300));
    return [..._sessions]; // Retourne une copie
  }

  @override
  Future<List<SessionEtude>> getSessionsByMatiere(int matiereId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sessions = _sessions.where((s) => s.matiereId == matiereId).toList();
    print('📊 Mock: ${sessions.length} sessions pour matière $matiereId');
    return sessions;
  }

  @override
  Future<List<SessionEtude>> getSessionsByDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final dateString =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final sessions = _sessions.where((session) {
      final sessionDate =
          "${session.date.year}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}";
      return sessionDate == dateString;
    }).toList();
    print('📊 Mock: ${sessions.length} sessions pour la date $dateString');
    return sessions;
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
    print(
        '📊 Mock: Session de ${session.duree}min ajoutée (ID: ${nouvelleSession.id})');
    return nouvelleSession.id!;
  }

  @override
  Future<void> deleteSession(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sessions.removeWhere((s) => s.id == id);
    print('📊 Mock: Session ID $id supprimée');
  }

  // === Objectifs ===
  @override
  Future<ObjectifQuotidien> getObjectif() async {
    print('📊 Mock: Objectif récupéré - ${_objectif.objectifMinutes}min');
    await Future.delayed(const Duration(milliseconds: 200));
    return _objectif;
  }

  @override
  Future<void> updateObjectif(int objectifMinutes) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _objectif = ObjectifQuotidien(id: 1, objectifMinutes: objectifMinutes);
    print('📊 Mock: Objectif mis à jour - ${objectifMinutes}min');
  }

  // === Statistiques ===
  @override
  Future<int> getTempsEtudieAujourdhui() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final aujourdhui = DateTime.now();
    final total = _sessions
        .where((session) =>
            session.date.year == aujourdhui.year &&
            session.date.month == aujourdhui.month &&
            session.date.day == aujourdhui.day)
        .fold(0, (sum, session) => sum + session.duree);

    print('📊 Mock: Temps aujourd\'hui: ${total}min');
    return total;
  }

  @override
  Future<int> getTotalTempsEtudie() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final total = _sessions.fold(0, (sum, session) => sum + session.duree);
    print('📊 Mock: Temps total: ${total}min');
    return total;
  }

  @override
  Future<Map<String, int>> getTempsParMatiere() async {
    await Future.delayed(const Duration(milliseconds: 300));
    Map<String, int> result = {};

    for (var matiere in _matieres) {
      final temps = _sessions
          .where((session) => session.matiereId == matiere.id)
          .fold(0, (sum, session) => sum + session.duree);
      result[matiere.nom] = temps;
    }

    print('📊 Mock: Temps par matière calculé');
    return result;
  }

  @override
  Future<void> close() async {
    await Future.delayed(const Duration(milliseconds: 100));
    print('📊 Mock: Base de données fermée');
  }
}
