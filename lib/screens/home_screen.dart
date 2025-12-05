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
      final toutesSessions = await _dbHelper.getSessions();
      final matieres = await _dbHelper.getMatieres();
      final objectif = await _dbHelper.getObjectif();
      
      final aujourdhui = DateTime.now();
      final sessionsAujourdhui = toutesSessions.where((session) {
        return session.date.year == aujourdhui.year &&
               session.date.month == aujourdhui.month &&
               session.date.day == aujourdhui.day;
      }).toList();
      
      final tempsAujourdhui = sessionsAujourdhui.fold(
        0.0, 
        (sum, session) => sum + session.duree / 60
      );
      
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Aujourd\'hui',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildDailyGoalCard(),
                    const SizedBox(height: 20),
                    _buildQuickSessionButton(context),
                    const SizedBox(height: 20),
                    _buildTodayStats(),
                    const SizedBox(height: 20),
                    _buildAllSessionsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDailyGoalCard() {
    final progressionColor = _progression >= 1 
        ? Colors.green 
        : _progression >= 0.5 
          ? Colors.orange 
          : Colors.blue;
    
    return Container(
      constraints: const BoxConstraints(
        minHeight: 320,
      ),
      child: Card(
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
                  Icon(Icons.flag, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Objectif Quotidien',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
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
                        _formatHeures(_objectifQuotidien),
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
                        _formatHeures(_tempsEtudieAujourdhui),
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
                          maxLines: 2,
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
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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
    
    return Container(
      constraints: const BoxConstraints(
        minHeight: 300,
      ),
      child: Card(
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
                  mainAxisSize: MainAxisSize.min,
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
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Commencez votre première session !',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else ...[
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
                      _formatHeures(tempsTotal / 60),
                      Colors.green,
                    ),
                    _buildStatCard(
                      Icons.timeline,
                      'Moyenne/session',
                      _formatMinutes(moyenne.toInt()),
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
                            mainAxisSize: MainAxisSize.min,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 100,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSessionsCard() {
    return FutureBuilder<List<SessionEtude>>(
      future: _dbHelper.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            constraints: const BoxConstraints(
              minHeight: 200,
            ),
            child: const Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            constraints: const BoxConstraints(
              minHeight: 200,
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    SizedBox(height: 8),
                    Text(
                      'Vos sessions apparaîtront ici',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        final sessions = snapshot.data!;
        final sessionsTriees = List.from(sessions)
          ..sort((a, b) => b.date.compareTo(a.date));
        
        // Limiter le nombre de sessions affichées à 5 maximum
        final sessionsAffichees = sessionsTriees.length > 5 
            ? sessionsTriees.sublist(0, 5) 
            : sessionsTriees;
        
        return Container(
          constraints: const BoxConstraints(
            minHeight: 200,
          ),
          child: Card(
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
                        '📋 Sessions Récentes',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      _buildMiniStat('Total', '${sessions.length}'),
                      const SizedBox(width: 16),
                      _buildMiniStat('Temps total', _formatHeures(_calculerTempsTotal(sessions))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Liste des sessions limitée en hauteur
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 300, // Hauteur maximale fixe
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessionsAffichees.length,
                      itemBuilder: (context, index) {
                        final session = sessionsAffichees[index];
                        final matiereName = _getMatiereName(session.matiereId);
                        final matiereColor = _getMatiereColor(session.matiereId);
                        final isToday = _isToday(session.date);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _buildSessionTile(session, matiereName, matiereColor, isToday),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (sessions.length > 5)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${sessions.length} sessions enregistrées (${sessions.length - 5} de plus)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionTile(SessionEtude session, String matiereName, Color matiereColor, bool isToday) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? Colors.blue.shade100 : Colors.grey.shade200,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 40, // Hauteur réduite
            decoration: BoxDecoration(
              color: matiereColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        matiereName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.blue.shade800 : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Auj.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatMinutes(session.duree),
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday ? Colors.blue.shade600 : Colors.grey,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatDateCompact(session.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday ? Colors.blue.shade600 : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                if (session.note != null && session.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _truncateNote(session.note!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _truncateNote(String note) {
    if (note.length > 25) {
      return '${note.substring(0, 25)}...';
    }
    return note;
  }

  String _formatDateCompact(DateTime date) {
    final aujourdhui = DateTime.now();
    
    if (date.year == aujourdhui.year && 
        date.month == aujourdhui.month && 
        date.day == aujourdhui.day) {
      final heures = date.hour.toString().padLeft(2, '0');
      final minutes = date.minute.toString().padLeft(2, '0');
      return '$heures:$minutes';
    } else {
      return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
    }
  }

  Widget _buildMiniStat(String title, String value) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
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
    
    return '$matiereName à $heures:$minutes (${_formatMinutes(derniere.duree)})';
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

  String _formatDateComplete(DateTime date) {
    final aujourdhui = DateTime.now();
    
    if (date.year == aujourdhui.year && 
        date.month == aujourdhui.month && 
        date.day == aujourdhui.day) {
      final heures = date.hour.toString().padLeft(2, '0');
      final minutes = date.minute.toString().padLeft(2, '0');
      return 'Aujourd\'hui $heures:$minutes';
    } else {
      return '${date.day}/${date.month}/${date.year.toString().substring(2)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  bool _isToday(DateTime date) {
    final aujourdhui = DateTime.now();
    return date.year == aujourdhui.year && 
           date.month == aujourdhui.month && 
           date.day == aujourdhui.day;
  }

  double _calculerTempsTotal(List<SessionEtude> sessions) {
    final totalMinutes = sessions.fold(0, (sum, session) => sum + session.duree);
    return totalMinutes / 60;
  }
}