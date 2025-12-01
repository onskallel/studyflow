import 'mock_database.dart';
import '../models/matiere.dart';
import '../models/session.dart';
import '../models/objectif.dart';

abstract class StudyFlowDatabase {
  // Matières
  Future<List<Matiere>> getMatieres();
  Future<Matiere?> getMatiereById(int id);
  Future<int> insertMatiere(Matiere matiere);
  Future<void> updateMatiere(Matiere matiere);
  Future<void> deleteMatiere(int id);

  // Sessions
  Future<List<SessionEtude>> getSessions();
  Future<List<SessionEtude>> getSessionsByMatiere(int matiereId);
  Future<List<SessionEtude>> getSessionsByDate(DateTime date);
  Future<int> insertSession(SessionEtude session);
  Future<void> deleteSession(int id);

  // Objectifs
  Future<ObjectifQuotidien> getObjectif();
  Future<void> updateObjectif(int objectifMinutes);

  // Statistiques
  Future<int> getTempsEtudieAujourdhui();
  Future<int> getTotalTempsEtudie();
  Future<Map<String, int>> getTempsParMatiere();

  // Fermer la base (pour interface commune)
  Future<void> close();
}

// Factory qui retourne TOUJOURS le mock pour le moment
StudyFlowDatabase getDatabase() {
  print('🔄 Utilisation de MockDatabase (pour développement)');
  return MockDatabase();
}

// Tu peux supprimer complètement _SqliteAdapter pour l'instant
