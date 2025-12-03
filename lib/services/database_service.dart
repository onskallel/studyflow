import 'package:flutter/material.dart';
import '../database/database_adapter.dart';
import '../models/matiere.dart';
import '../models/session.dart';
import '../models/objectif.dart';

class DatabaseService extends ChangeNotifier {
  final StudyFlowDatabase _db = getDatabase();

  // États
  List<Matiere> _matieres = [];
  List<SessionEtude> _sessions = [];
  ObjectifQuotidien? _objectif;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Matiere> get matieres => _matieres;
  List<SessionEtude> get sessions => _sessions;
  ObjectifQuotidien? get objectif => _objectif;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialisation
  DatabaseService() {
    _loadInitialData();
  }

  // Charger toutes les données initiales
  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadMatieres(),
        _loadSessions(),
        _loadObjectif(),
      ]);
      _error = null;
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      print('❌ Erreur DatabaseService: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // === CHARGEMENT DES DONNÉES ===
  Future<void> _loadMatieres() async {
    _matieres = await _db.getMatieres();
  }

  Future<void> _loadSessions() async {
    _sessions = await _db.getSessions();
  }

  Future<void> _loadObjectif() async {
    _objectif = await _db.getObjectif();
  }

  // === CRUD MATIÈRES ===
  Future<void> addMatiere(
      String nom, String couleur, int priorite, int objectifHebdo) async {
    _isLoading = true;
    notifyListeners();

    try {
      final nouvelleMatiere = Matiere(
        nom: nom,
        couleur: couleur,
        priorite: priorite,
        objectifHebdo: objectifHebdo,
      );

      await _db.insertMatiere(nouvelleMatiere);
      await _loadMatieres(); // Recharger la liste
      _error = null;
    } catch (e) {
      _error = 'Erreur d\'ajout: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMatiere(Matiere matiere) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.updateMatiere(matiere);
      await _loadMatieres();
      _error = null;
    } catch (e) {
      _error = 'Erreur de mise à jour: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMatiere(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.deleteMatiere(id);
      await _loadMatieres();
      _error = null;
    } catch (e) {
      _error = 'Erreur de suppression: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // === CRUD SESSIONS ===
  Future<void> addSession(
      int matiereId, int duree, DateTime date, String note) async {
    _isLoading = true;
    notifyListeners();

    try {
      final nouvelleSession = SessionEtude(
        matiereId: matiereId,
        duree: duree,
        date: date,
        note: note,
      );

      await _db.insertSession(nouvelleSession);
      await _loadSessions();
      _error = null;
    } catch (e) {
      _error = 'Erreur d\'ajout de session: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // === OBJECTIFS ===
  Future<void> updateObjectif(int objectifMinutes) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.updateObjectif(objectifMinutes);
      await _loadObjectif();
      _error = null;
    } catch (e) {
      _error = 'Erreur de mise à jour objectif: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // === STATISTIQUES ===
  Future<int> getTempsAujourdhui() async {
    return await _db.getTempsEtudieAujourdhui();
  }

  Future<int> getTempsTotal() async {
    return await _db.getTotalTempsEtudie();
  }

  Future<Map<String, int>> getStatsParMatiere() async {
    return await _db.getTempsParMatiere();
  }

  // Recharger toutes les données
  Future<void> refresh() async {
    await _loadInitialData();
  }
}
