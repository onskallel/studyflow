import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/matiere.dart';
import '../models/session.dart';
import '../models/objectif.dart';
import 'database_adapter.dart';

class SupabaseDatabase implements StudyFlowDatabase {
  final SupabaseClient _supabase;

  SupabaseDatabase() : _supabase = Supabase.instance.client {
    print('☁️ SupabaseDatabase créé');
  }

  // ========== CRUD MATIÈRES ==========
  @override
  Future<List<Matiere>> getMatieres() async {
    try {
      final response = await _supabase
          .from('matieres')
          .select()
          .order('id', ascending: true);

      final List<Matiere> matieres = [];

      for (final row in response) {
        matieres.add(Matiere(
          id: row['id'],
          nom: row['nom'],
          couleur: row['couleur'],
          priorite: row['priorite'],
          objectifHebdo: row['objectif_hebdo'] ?? 0,
        ));
      }

      print('📊 ${matieres.length} matières chargées depuis Supabase');
      return matieres;
    } catch (e) {
      print('❌ Erreur Supabase getMatieres: $e');
      return [];
    }
  }

  @override
  Future<Matiere?> getMatiereById(int id) async {
    try {
      final response =
          await _supabase.from('matieres').select().eq('id', id).single();

      return Matiere(
        id: response['id'],
        nom: response['nom'],
        couleur: response['couleur'],
        priorite: response['priorite'],
        objectifHebdo: response['objectif_hebdo'] ?? 0,
      );
    } catch (e) {
      print('❌ Erreur getMatiereById: $e');
      return null;
    }
  }

  @override
  Future<int> insertMatiere(Matiere matiere) async {
    try {
      final response = await _supabase
          .from('matieres')
          .insert({
            'nom': matiere.nom,
            'couleur': matiere.couleur,
            'priorite': matiere.priorite,
            'objectif_hebdo': matiere.objectifHebdo,
          })
          .select('id')
          .single();

      final newId = response['id'] as int;
      print('✅ Matière "${matiere.nom}" ajoutée (ID: $newId)');
      return newId;
    } catch (e) {
      print('❌ Erreur insertMatiere: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMatiere(Matiere matiere) async {
    try {
      await _supabase.from('matieres').update({
        'nom': matiere.nom,
        'couleur': matiere.couleur,
        'priorite': matiere.priorite,
        'objectif_hebdo': matiere.objectifHebdo,
      }).eq('id', matiere.id!);

      print('✅ Matière ${matiere.id} mise à jour');
    } catch (e) {
      print('❌ Erreur updateMatiere: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMatiere(int id) async {
    try {
      await _supabase.from('matieres').delete().eq('id', id);

      print('✅ Matière $id supprimée');
    } catch (e) {
      print('❌ Erreur deleteMatiere: $e');
      rethrow;
    }
  }

  // ========== CRUD SESSIONS ==========
  @override
  Future<List<SessionEtude>> getSessions() async {
    try {
      final response = await _supabase
          .from('sessions')
          .select()
          .order('date', ascending: false);

      final List<SessionEtude> sessions = [];

      for (final row in response) {
        sessions.add(SessionEtude(
          id: row['id'],
          matiereId: row['matiere_id'],
          duree: row['duree'],
          date: DateTime.parse(row['date']),
          note: row['note'] ?? '',
        ));
      }

      print('📊 ${sessions.length} sessions chargées depuis Supabase');
      return sessions;
    } catch (e) {
      print('❌ Erreur getSessions: $e');
      return [];
    }
  }

  @override
  Future<int> insertSession(SessionEtude session) async {
    try {
      final response = await _supabase
          .from('sessions')
          .insert({
            'matiere_id': session.matiereId,
            'duree': session.duree,
            'date': session.date.toIso8601String(),
            'note': session.note,
          })
          .select('id')
          .single();

      final newId = response['id'] as int;
      print('✅ Session ajoutée (ID: $newId)');
      return newId;
    } catch (e) {
      print('❌ Erreur insertSession: $e');
      rethrow;
    }
  }

  // ========== OBJECTIFS ==========
  @override
  Future<ObjectifQuotidien> getObjectif() async {
    try {
      final response =
          await _supabase.from('objectifs').select().eq('id', 1).maybeSingle();

      if (response != null) {
        return ObjectifQuotidien(
          id: response['id'],
          objectifMinutes: response['objectif_minutes'] ?? 120,
        );
      } else {
        // Créer l'objectif par défaut
        await _supabase
            .from('objectifs')
            .insert({'id': 1, 'objectif_minutes': 120});

        return ObjectifQuotidien(id: 1, objectifMinutes: 120);
      }
    } catch (e) {
      print('❌ Erreur getObjectif: $e');
      return ObjectifQuotidien(id: 1, objectifMinutes: 120);
    }
  }

  @override
  Future<void> updateObjectif(int objectifMinutes) async {
    try {
      await _supabase.from('objectifs').upsert({
        'id': 1,
        'objectif_minutes': objectifMinutes,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Objectif mis à jour: $objectifMinutes minutes');
    } catch (e) {
      print('❌ Erreur updateObjectif: $e');
      rethrow;
    }
  }

  // ========== AUTRES MÉTHODES ==========
  @override
  Future<List<SessionEtude>> getSessionsByMatiere(int matiereId) async {
    try {
      final response = await _supabase
          .from('sessions')
          .select()
          .eq('matiere_id', matiereId)
          .order('date', ascending: false);

      return response
          .map((row) => SessionEtude(
                id: row['id'],
                matiereId: row['matiere_id'],
                duree: row['duree'],
                date: DateTime.parse(row['date']),
                note: row['note'] ?? '',
              ))
          .toList();
    } catch (e) {
      print('❌ Erreur getSessionsByMatiere: $e');
      return [];
    }
  }

  @override
  Future<List<SessionEtude>> getSessionsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('sessions')
          .select()
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String());

      return response
          .map((row) => SessionEtude(
                id: row['id'],
                matiereId: row['matiere_id'],
                duree: row['duree'],
                date: DateTime.parse(row['date']),
                note: row['note'] ?? '',
              ))
          .toList();
    } catch (e) {
      print('❌ Erreur getSessionsByDate: $e');
      return [];
    }
  }

  @override
  Future<int> getTempsEtudieAujourdhui() async {
    try {
      final aujourdhui = DateTime.now();
      final startOfDay =
          DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('sessions')
          .select('duree')
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String());

      int total = 0;
      for (final row in response) {
        total += row['duree'] as int;
      }

      return total;
    } catch (e) {
      print('❌ Erreur getTempsEtudieAujourdhui: $e');
      return 0;
    }
  }

  @override
  Future<int> getTotalTempsEtudie() async {
    try {
      final response = await _supabase.from('sessions').select('duree');

      int total = 0;
      for (final row in response) {
        total += row['duree'] as int;
      }

      return total;
    } catch (e) {
      print('❌ Erreur getTotalTempsEtudie: $e');
      return 0;
    }
  }

  @override
  Future<Map<String, int>> getTempsParMatiere() async {
    try {
      final response = await _supabase.rpc('get_temps_par_matiere');

      final Map<String, int> result = {};
      for (final row in response) {
        result[row['nom']] = row['total_duree'] as int;
      }

      return result;
    } catch (e) {
      // Si la fonction RPC n'existe pas, faire manuellement
      print('⚠️  Création manuelle des stats...');

      final matieres = await getMatieres();
      final sessions = await getSessions();

      final Map<String, int> result = {};

      for (final matiere in matieres) {
        int total = 0;
        for (final session in sessions) {
          if (session.matiereId == matiere.id) {
            total += session.duree;
          }
        }
        result[matiere.nom] = total;
      }

      return result;
    }
  }

  @override
  Future<void> deleteSession(int id) async {
    try {
      await _supabase.from('sessions').delete().eq('id', id);

      print('✅ Session $id supprimée');
    } catch (e) {
      print('❌ Erreur deleteSession: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    print('☁️ SupabaseDatabase fermé');
    // Supabase gère sa propre connexion
  }

  // Méthode pour initialiser les données par défaut
  Future<void> initializeDefaultData() async {
    try {
      final matieres = await getMatieres();
      if (matieres.isEmpty) {
        print('➕ Initialisation des données par défaut...');

        await insertMatiere(Matiere(
          nom: "Mathématiques",
          couleur: "#2196F3",
          priorite: 2,
          objectifHebdo: 300,
        ));

        await insertMatiere(Matiere(
          nom: "Physique",
          couleur: "#FF5722",
          priorite: 1,
          objectifHebdo: 180,
        ));

        await insertMatiere(Matiere(
          nom: "Anglais",
          couleur: "#4CAF50",
          priorite: 2,
          objectifHebdo: 240,
        ));

        print('✅ Données par défaut créées');
      }
    } catch (e) {
      print('❌ Erreur initialisation: $e');
    }
  }
}
