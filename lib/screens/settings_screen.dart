import 'package:flutter/material.dart';
import '../database/database_adapter.dart';
import '../models/objectif.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StudyFlowDatabase _dbHelper = getDatabase();
  int _objectifMinutes = 120;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerPreferences();
  }

  Future<void> _chargerPreferences() async {
    setState(() => _isLoading = true);
    try {
      final objectif = await _dbHelper.getObjectif();
      if (mounted) {
        setState(() {
          _objectifMinutes = objectif.objectifMinutes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement préférences: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _mettreAJourObjectif(int nouvellesMinutes) async {
    try {
      await _dbHelper.updateObjectif(nouvellesMinutes);
      if (mounted) {
        setState(() {
          _objectifMinutes = nouvellesMinutes;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Objectif mis à jour: ${_formatMinutes(nouvellesMinutes)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Erreur mise à jour objectif: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final heures = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$heures h';
      } else {
        return '$heures h $mins min';
      }
    }
  }

  Future<void> _reinitialiserDonnees() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Réinitialiser toutes les données ?'),
        content: const Text('Cette action supprimera toutes vos sessions, matières et réinitialisera les objectifs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Réinitialiser l'objectif à la valeur par défaut
        await _dbHelper.updateObjectif(120);
        await _chargerPreferences();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Données réinitialisées avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print('❌ Erreur réinitialisation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _afficherInfoVersion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('À propos'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('StudyFlow v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Application de suivi des révisions'),
            SizedBox(height: 5),
            Text('Développée avec ❤️ en Flutter'),
            SizedBox(height: 10),
            Text('Fonctionnalités :'),
            SizedBox(height: 5),
            Text('• Gestion des matières'),
            Text('• Timer Pomodoro intégré'),
            Text('• Suivi des objectifs'),
            Text('• Statistiques détaillées'),
            SizedBox(height: 10),
            Text('© 2024 Tous droits réservés'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Paramètres'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // SECTION OBJECTIFS
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flag, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Objectifs',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            // Objectif quotidien actuel
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.timer, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Objectif actuel: ${_formatMinutes(_objectifMinutes)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // Réglage de l'objectif
                            const Text(
                              'Ajuster l\'objectif :',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(Icons.remove, color: Colors.white),
                                  ),
                                  onPressed: () {
                                    final nouveau = _objectifMinutes - 30;
                                    if (nouveau >= 30) {
                                      _mettreAJourObjectif(nouveau);
                                    }
                                  },
                                ),
                                
                                Container(
                                  width: 100,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Text(
                                    _formatMinutes(_objectifMinutes),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                
                                IconButton(
                                  icon: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(Icons.add, color: Colors.white),
                                  ),
                                  onPressed: () {
                                    _mettreAJourObjectif(_objectifMinutes + 30);
                                  },
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // Boutons d'objectif rapides
                            const Text(
                              'Objectifs prédéfinis :',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildGoalButton('30 min', 30),
                                _buildGoalButton('1 heure', 60),
                                _buildGoalButton('2 heures', 120),
                                _buildGoalButton('3 heures', 180),
                                _buildGoalButton('4 heures', 240),
                              ],
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // Conseil
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lightbulb, color: Colors.green),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Conseil : Commencez avec 1-2 heures par jour et augmentez progressivement.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // SECTION DONNÉES
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.storage, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Données',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            // Réinitialisation
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.restore, color: Colors.red),
                                title: const Text(
                                  'Réinitialiser toutes les données',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Supprime toutes les sessions et matières',
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                                onTap: _reinitialiserDonnees,
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // Message d'avertissement
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Attention : Cette action est irréversible',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // SECTION À PROPOS
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'À propos',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            // Version
                            ListTile(
                              leading: const Icon(Icons.phone_android, color: Colors.blue),
                              title: const Text('Version'),
                              trailing: const Text('1.0.0'),
                              onTap: _afficherInfoVersion,
                            ),
                            
                            
                            
                            // Crédits
                            ListTile(
                              leading: const Icon(Icons.code, color: Colors.blue),
                              title: const Text('Développeurs'),
                              subtitle: const Text('Nour elhouda Ayachi / Ons Kallel'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _afficherInfoVersion,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGoalButton(String label, int minutes) {
    return ElevatedButton(
      onPressed: () => _mettreAJourObjectif(minutes),
      style: ElevatedButton.styleFrom(
        backgroundColor: _objectifMinutes == minutes ? Colors.blue : Colors.grey.shade200,
        foregroundColor: _objectifMinutes == minutes ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: _objectifMinutes == minutes ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}