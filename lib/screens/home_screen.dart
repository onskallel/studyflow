import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_adapter.dart';
import '../models/session.dart';
import '../models/matiere.dart';
import 'timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StudyFlowDatabase _dbHelper = getDatabase();
  List<SessionEtude> _sessionsAujourdhui = [];
  List<Matiere> _matieres = [];
  double _tempsEtudieAujourdhui = 0;
  double _objectifQuotidien = 120;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
    
    // Rafraîchir automatiquement toutes les 5 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _chargerDonnees();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    if (!mounted) return;
    
    try {
      // Charger toutes les sessions
      final toutesSessions = await _dbHelper.getSessions();
      
      // Charger les matières
      final matieres = await _dbHelper.getMatieres();
      
      // Filtrer les sessions d'aujourd'hui
      final aujourdhui = DateTime.now();
      final sessionsAujourdhui = toutesSessions.where((session) {
        return session.date.year == aujourdhui.year &&
               session.date.month == aujourdhui.month &&
               session.date.day == aujourdhui.day;
      }).toList();
      
      // Calculer le temps total d'aujourd'hui
      final tempsAujourdhui = sessionsAujourdhui.fold(
        0.0, 
        (sum, session) => sum + session.duree / 60
      );
      
      // Récupérer l'objectif quotidien
      final objectif = await _dbHelper.getObjectif();
      
      if (mounted) {
        setState(() {
          _sessionsAujourdhui = sessionsAujourdhui;
          _matieres = matieres;
          _tempsEtudieAujourdhui = tempsAujourdhui;
          _objectifQuotidien = objectif.objectifMinutes / 60.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement accueil: $e');
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
      return Colors.blue;
    }
  }

  double get _progression {
    return _objectifQuotidien > 0 
        ? (_tempsEtudieAujourdhui / _objectifQuotidien).clamp(0, 1)
        : 0;
  }

  String _getMatiereName(int matiereId) {
    try {
      return _matieres.firstWhere((m) => m.id == matiereId).nom;
    } catch (e) {
      return 'Inconnue';
    }
  }

  Color _getMatiereColor(int matiereId) {
    try {
      final matiere = _matieres.firstWhere((m) => m.id == matiereId);
      return _parseColor(matiere.couleur);
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏠 StudyFlow'),
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
          : LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth > 600;
                final double screenHeight = constraints.maxHeight;
                
                return SingleChildScrollView( // AJOUTÉ: Permet le scroll
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDesktop ? 'Tableau de Bord' : 'Aujourd\'hui',
                          style: TextStyle(
                            fontSize: isDesktop ? 28.0 : 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: TextStyle(
                            fontSize: isDesktop ? 16.0 : 14.0,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildDailyGoalCard(),
        const SizedBox(height: 20),
        _buildQuickSessionButton(context),
        const SizedBox(height: 20),
        _buildTodayStats(),
        const SizedBox(height: 20),
        _buildRecentSessions(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildDailyGoalCard(),
                  const SizedBox(height: 20),
                  _buildQuickSessionButton(context),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _buildRecentSessions(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTodayStats(),
      ],
    );
  }

  Widget _buildDailyGoalCard() {
    final progressionColor = _progression >= 1 
        ? Colors.green 
        : _progression >= 0.5 
          ? Colors.orange 
          : Colors.blue;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Objectif Quotidien',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Cercle de progression
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _progression,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(progressionColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_progression * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'complété',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Détails
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Objectif:',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_objectifQuotidien.toStringAsFixed(0)} heures',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Accompli:',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_tempsEtudieAujourdhui.toStringAsFixed(1)} heures',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Message de motivation
            if (_progression >= 1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎉 Objectif atteint ! Excellent travail !',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_progression >= 0.75)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💪 Presque là ! Continue comme ça !',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSessionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TimerScreen()),
          ).then((_) {
            // Rafraîchir après retour du timer
            _chargerDonnees();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.blue.shade200,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 24),
            SizedBox(width: 12),
            Text(
              'DÉMARRER UNE SESSION',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    final sessionsCount = _sessionsAujourdhui.length;
    final tempsTotal = _sessionsAujourdhui.fold(0, (sum, session) => sum + session.duree);
    final moyenne = sessionsCount > 0 ? tempsTotal / sessionsCount : 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.today, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  '📊 Aujourd\'hui',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (_sessionsAujourdhui.isEmpty)
              Column(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune session aujourd\'hui',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Commencez votre première session !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            else ...[
              // Statistiques principales
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    Icons.list,
                    'Sessions',
                    '$sessionsCount',
                    Colors.blue,
                  ),
                  _buildStatCard(
                    Icons.timer,
                    'Temps total',
                    '${(tempsTotal / 60).toStringAsFixed(1)}h',
                    Colors.green,
                  ),
                  _buildStatCard(
                    Icons.timeline,
                    'Moyenne/session',
                    '${moyenne.toStringAsFixed(0)} min',
                    Colors.orange,
                  ),
                  _buildStatCard(
                    Icons.flag,
                    'Progression',
                    '${(_progression * 100).toInt()}%',
                    Colors.purple,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Dernière session
              if (_sessionsAujourdhui.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.update, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dernière session:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatDerniereSession(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions() {
    return FutureBuilder<List<SessionEtude>>(
      future: _dbHelper.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune session',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        final sessions = snapshot.data!.take(5).toList(); // 5 dernières
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '📋 Sessions récentes',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: ${snapshot.data!.length} sessions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Liste limitée à 3 sessions pour éviter l'overflow
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.take(3).length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final matiereName = _getMatiereName(session.matiereId);
                    final matiereColor = _getMatiereColor(session.matiereId);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 40,
                            decoration: BoxDecoration(
                              color: matiereColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  matiereName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.timer, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${session.duree} min',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(session.date),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                if (snapshot.data!.length > 3)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () {
                        // Naviguer vers les statistiques
                        // Navigator.push(...)
                      },
                      icon: const Icon(Icons.more_horiz),
                      label: Text('+ ${snapshot.data!.length - 3} autres sessions'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDerniereSession() {
    if (_sessionsAujourdhui.isEmpty) return '--';
    
    final derniere = _sessionsAujourdhui.reduce(
      (a, b) => a.date.isAfter(b.date) ? a : b,
    );
    
    final heures = derniere.date.hour.toString().padLeft(2, '0');
    final minutes = derniere.date.minute.toString().padLeft(2, '0');
    final matiereName = _getMatiereName(derniere.matiereId);
    
    return '$matiereName à $heures:$minutes (${derniere.duree} min)';
  }

  String _formatDate(DateTime date) {
    final aujourdhui = DateTime.now();
    final hier = aujourdhui.subtract(const Duration(days: 1));
    
    if (date.year == aujourdhui.year && 
        date.month == aujourdhui.month && 
        date.day == aujourdhui.day) {
      return 'Aujourd\'hui';
    } else if (date.year == hier.year && 
               date.month == hier.month && 
               date.day == hier.day) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
    }
  }
}