import 'package:flutter/material.dart';
import '../database/database_adapter.dart';
import '../models/session.dart';
import '../models/matiere.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StudyFlowDatabase _dbHelper = getDatabase();
  List<SessionEtude> _sessions = [];
  List<Matiere> _matieres = [];
  bool _isLoading = true;
  int _selectedTimeRange = 0; // 0: semaine, 1: mois, 2: total

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _dbHelper.getSessions();
      final matieres = await _dbHelper.getMatieres();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _matieres = matieres;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceFirst('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  // FONCTIONS DE FORMATAGE
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

  String _formatHeures(double heures) {
    if (heures < 1) {
      final minutes = (heures * 60).round();
      return '$minutes min';
    } else if (heures == heures.toInt()) {
      return '${heures.toInt()} h';
    } else {
      final heuresEntieres = heures.floor();
      final minutes = ((heures - heuresEntieres) * 60).round();
      if (minutes == 0) {
        return '$heuresEntieres h';
      } else if (heuresEntieres == 0) {
        return '$minutes min';
      } else {
        return '$heuresEntieres h $minutes min';
      }
    }
  }

  // Filtrer les sessions selon la période sélectionnée
  List<SessionEtude> get _sessionsFiltrees {
    final maintenant = DateTime.now();
    
    switch (_selectedTimeRange) {
      case 0: // Cette semaine
        final debutSemaine = maintenant.subtract(Duration(days: maintenant.weekday - 1));
        return _sessions.where((session) => session.date.isAfter(debutSemaine)).toList();
      case 1: // Ce mois
        final debutMois = DateTime(maintenant.year, maintenant.month, 1);
        return _sessions.where((session) => session.date.isAfter(debutMois)).toList();
      case 2: // Total
        return _sessions;
      default:
        return _sessions;
    }
  }

  double get _tempsTotal {
    return _sessionsFiltrees.fold(0.0, (sum, session) => sum + session.duree / 60);
  }

  int get _nombreSessions => _sessionsFiltrees.length;

  double get _moyenneParSession {
    return _sessionsFiltrees.isEmpty ? 0 : _tempsTotal / _nombreSessions;
  }

  Map<String, double> get _tempsParMatiere {
    final Map<String, double> result = {};
    
    for (final session in _sessionsFiltrees) {
      final matiere = _matieres.firstWhere(
        (m) => m.id == session.matiereId,
        orElse: () => Matiere(
          nom: 'Inconnue',
          couleur: '#CCCCCC',
          priorite: 1,
          objectifHebdo: 0,
        ),
      );
      
      final heures = session.duree / 60;
      result[matiere.nom] = (result[matiere.nom] ?? 0) + heures;
    }
    
    return result;
  }

  List<double> get _tempsParJourSemaine {
    final List<double> result = List.filled(7, 0);
    
    for (final session in _sessionsFiltrees) {
      final jour = session.date.weekday - 1;
      if (jour >= 0 && jour < 7) {
        result[jour] += session.duree / 60;
      }
    }
    
    return result;
  }

  String get _matierePreferee {
    if (_tempsParMatiere.isEmpty) return 'Aucune';
    
    final entree = _tempsParMatiere.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    
    return entree.key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statistiques'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerDonnees,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // SÉLECTION PÉRIODE
                  _buildTimeRangeSelector(),
                  const SizedBox(height: 20),
                  
                  // STATISTIQUES
                  _sessionsFiltrees.isEmpty 
                      ? _buildEmptyState() 
                      : Column(
                          children: [
                            _buildStatsSummary(),
                            const SizedBox(height: 20),
                            _buildTempsParMatiereCard(),
                            const SizedBox(height: 20),
                            _buildTempsParJourCard(),
                            const SizedBox(height: 20),
                            _buildProductivityCard(),
                          ],
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildTimeRangeOption('Cette semaine', 0),
              const SizedBox(width: 8),
              _buildTimeRangeOption('Ce mois', 1),
              const SizedBox(width: 8),
              _buildTimeRangeOption('Total', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeOption(String text, int value) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeRange = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _selectedTimeRange == value ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedTimeRange == value ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedTimeRange == value ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: _selectedTimeRange == value ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: _selectedTimeRange == value ? Colors.blue : Colors.grey.shade600,
                fontWeight: _selectedTimeRange == value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune donnée disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilisez le timer pour générer des statistiques',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Navigation vers le timer
              },
              icon: const Icon(Icons.timer),
              label: const Text('Démarrer une session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.summarize, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Résumé des Études',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatItem('⏱️', _formatHeures(_tempsTotal), 'Temps total'),
                _buildStatItem('📚', '$_nombreSessions', 'Sessions'),
                _buildStatItem('⚡', _formatHeures(_moyenneParSession), 'Moyenne/session'),
                _buildStatItem('🏆', _matierePreferee, 'Matière préférée'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String valeur, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            valeur,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTempsParMatiereCard() {
    final data = _tempsParMatiere;
    final total = _tempsTotal;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '⏱️ Répartition par Matière',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (data.isEmpty)
              const Center(
                child: Text(
                  'Aucune donnée de session',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: data.entries.map((entry) {
                  final matiere = _matieres.firstWhere(
                    (m) => m.nom == entry.key,
                    orElse: () => Matiere(
                      nom: entry.key,
                      couleur: '#CCCCCC',
                      priorite: 1,
                      objectifHebdo: 0,
                    ),
                  );
                  
                  final couleur = _parseColor(matiere.couleur);
                  final pourcentage = total > 0 ? (entry.value / total * 100).toInt() : 0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: couleur,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: total > 0 ? (entry.value / total) : 0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(couleur),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$pourcentage%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatHeures(entry.value),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempsParJourCard() {
    final data = _tempsParJourSemaine;
    final jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '📅 Temps par Jour',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (data.isEmpty)
              const Center(
                child: Text(
                  'Aucune donnée de session',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: data.asMap().entries.map((entry) {
                    final maxValue = _tempsParJourSemaine.reduce((a, b) => a > b ? a : b);
                    final hauteur = maxValue > 0 ? (entry.value / maxValue * 100) : 0;
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatHeures(entry.value),
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: hauteur.toDouble(),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          jours[entry.key],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityCard() {
    final meilleureSession = _getBestSession();
    final jourProductif = _getMostProductiveDay();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '🚀 Productivité',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProductivityItem('📊 Jour le plus productif', jourProductif),
            const Divider(height: 20),
            _buildProductivityItem('⭐ Meilleure session', _formatMinutes(meilleureSession)),
            const Divider(height: 20),
            _buildProductivityItem('📈 Tendance', _getTrend()),
            const Divider(height: 20),
            _buildProductivityItem('🎯 Progression globale', '${_getGoalProgress()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MÉTHODES UTILITAIRES
  String _getMostProductiveDay() {
    if (_sessionsFiltrees.isEmpty) return '--';
    
    final jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeu', 'Vendredi', 'Samedi', 'Dimanche'];
    final data = _tempsParJourSemaine;
    
    if (data.isEmpty) return '--';
    
    final maxIndex = data.indexWhere((value) => value == data.reduce((a, b) => a > b ? a : b));
    return maxIndex >= 0 ? jours[maxIndex] : '--';
  }

  int _getBestSession() {
    if (_sessionsFiltrees.isEmpty) return 0;
    
    final maxDuree = _sessionsFiltrees.map((s) => s.duree).reduce((a, b) => a > b ? a : b);
    return maxDuree;
  }

  String _getTrend() {
    if (_sessionsFiltrees.length < 2) return 'Stable';
    
    final maintenant = DateTime.now();
    final derniereSemaine = maintenant.subtract(const Duration(days: 7));
    final sessionsDerniereSemaine = _sessions.where((s) => s.date.isAfter(derniereSemaine)).toList();
    final sessionsAvant = _sessions.length - sessionsDerniereSemaine.length;
    
    if (sessionsDerniereSemaine.length > sessionsAvant) {
      return '↗️ En hausse';
    } else if (sessionsDerniereSemaine.length < sessionsAvant) {
      return '↘️ En baisse';
    } else {
      return '➡️ Stable';
    }
  }

  int _getGoalProgress() {
    const objectifMensuel = 40.0; // 40 heures par mois
    final progression = (_tempsTotal / objectifMensuel * 100).clamp(0, 100);
    return progression.toInt();
  }
}