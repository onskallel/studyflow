import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_adapter.dart';
import '../models/matiere.dart';
import '../models/session.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final StudyFlowDatabase _dbHelper = getDatabase();
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  int? _selectedMatiereId;
  List<Matiere> _matieres = [];
  Timer? _timer;
  int _totalSecondsStudied = 0;
  bool _isBreak = false;
  int _pomodoroCount = 0;
  final List<int> _pomodoroDurations = [25 * 60, 5 * 60]; // 25min travail, 5min pause
  bool _isLoading = true;
  double _objectifProgression = 0.0;
  bool _objectifAtteint = false;

  @override
  void initState() {
    super.initState();
    _chargerMatieres();
  }

  Future<void> _chargerMatieres() async {
    try {
      setState(() => _isLoading = true);
      final matieres = await _dbHelper.getMatieres();
      
      if (mounted) {
        setState(() {
          _matieres = matieres;
          if (matieres.isNotEmpty && _selectedMatiereId == null) {
            _selectedMatiereId = matieres.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement matières: $e');
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

  // FONCTION DE FORMATAGE
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

  String? get _selectedMatiereName {
    if (_selectedMatiereId == null) return null;
    try {
      final matiere = _matieres.firstWhere(
        (m) => m.id == _selectedMatiereId,
      );
      return matiere.nom;
    } catch (e) {
      return 'Inconnue';
    }
  }

  Color get _timerColor {
    if (!_isRunning) return Colors.blue;
    return _isBreak ? Colors.green : Colors.orange;
  }

  String get _timerTitle {
    if (_isBreak) return '⏳ Pause';
    return '🎯 Pomodoro';
  }

  // FONCTIONS POUR LES OBJECTIFS
  Future<int> _getTempsTotalMatiere(int matiereId) async {
    try {
      final sessions = await _dbHelper.getSessions();
      final sessionsMatiere = sessions.where((session) => session.matiereId == matiereId).toList();
      final tempsTotal = sessionsMatiere.fold(0, (sum, session) => sum + session.duree);
      return tempsTotal;
    } catch (e) {
      print('❌ Erreur calcul temps matière: $e');
      return 0;
    }
  }

  Future<void> _updateObjectifProgression() async {
    if (_selectedMatiereId == null) return;
    
    try {
      final matiere = _matieres.firstWhere((m) => m.id == _selectedMatiereId);
      
      if (matiere.objectifHebdo <= 0) {
        setState(() {
          _objectifProgression = 0.0;
          _objectifAtteint = false;
        });
        return;
      }
      
      final tempsTotal = await _getTempsTotalMatiere(_selectedMatiereId!);
      final tempsSession = _totalSecondsStudied ~/ 60;
      final tempsTotalAvecSession = tempsTotal + tempsSession;
      
      final progression = tempsTotalAvecSession / matiere.objectifHebdo;
      final objectifAtteint = progression >= 1.0;
      
      if (mounted) {
        setState(() {
          _objectifProgression = progression > 1.0 ? 1.0 : progression;
          _objectifAtteint = objectifAtteint;
        });
      }
    } catch (e) {
      print('❌ Erreur mise à jour progression: $e');
    }
  }

  Future<void> _verifierEtNotifierObjectif() async {
    if (_selectedMatiereId == null || !_objectifAtteint) return;
    
    try {
      final matiere = _matieres.firstWhere((m) => m.id == _selectedMatiereId);
      final tempsTotal = await _getTempsTotalMatiere(_selectedMatiereId!);
      
      if (tempsTotal >= matiere.objectifHebdo && !_isBreak) {
        _showGoalAchievedDialog();
      }
    } catch (e) {
      print('❌ Erreur vérification objectif: $e');
    }
  }

  // FONCTIONS UTILITAIRES POUR LES MATIÈRES
  String _getPriorityText(int priorite) {
    switch (priorite) {
      case 0: return 'Basse';
      case 1: return 'Moyenne';
      case 2: return 'Haute';
      default: return 'Inconnue';
    }
  }

  String _getPriorityIconText(int priorite) {
    switch (priorite) {
      case 0: return '⬇️';
      case 1: return '➡️';
      case 2: return '⬆️';
      default: return '❓';
    }
  }

  Color _getPriorityColor(int priorite) {
    switch (priorite) {
      case 0: return Colors.green;
      case 1: return Colors.orange;
      case 2: return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<Matiere?> _getSelectedMatiere() async {
    if (_selectedMatiereId == null) return null;
    try {
      return _matieres.firstWhere((m) => m.id == _selectedMatiereId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏱️ Session d\'étude'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_pomodoroCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.repeat, size: 16),
                  const SizedBox(width: 4),
                  Text('$_pomodoroCount'),
                ],
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 600;
          
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTimerCircle(isDesktop),
                  SizedBox(height: isDesktop ? 40.0 : 30.0),
                  _buildMatiereSelector(isDesktop),
                  SizedBox(height: isDesktop ? 40.0 : 30.0),
                  _buildControlButtons(isDesktop),
                  if (_totalSecondsStudied > 0 && !_isRunning)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Session: ${_formatMinutes(_totalSecondsStudied ~/ 60)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildPomodoroInfo(isDesktop),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerCircle(bool isDesktop) {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final circleSize = isDesktop ? 280.0 : 220.0;
    final fontSize = isDesktop ? 56.0 : 42.0;
    
    return Column(
      children: [
        Text(
          _timerTitle,
          style: TextStyle(
            fontSize: isDesktop ? 28.0 : 22.0,
            fontWeight: FontWeight.bold,
            color: _timerColor,
          ),
        ),
        const SizedBox(height: 10),
        
        
        
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _timerColor,
                  width: isDesktop ? 10.0 : 8.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _timerColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: _timerColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isBreak)
                      Text(
                        'Reposez-vous ! 😌',
                        style: TextStyle(
                          fontSize: isDesktop ? 18.0 : 14.0,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else if (_isRunning)
                      Text(
                        'Concentrez-vous ! 🔥',
                        style: TextStyle(
                          fontSize: isDesktop ? 18.0 : 14.0,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            
            // INDICATEUR DE PROGRESSION D'OBJECTIF
            if (_selectedMatiereId != null && _objectifProgression > 0 && !_isBreak)
              SizedBox(
                width: circleSize + 24,
                height: circleSize + 24,
                child: CircularProgressIndicator(
                  value: _objectifProgression,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _objectifAtteint ? Colors.green : Colors.blue,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatiereSelector(bool isDesktop) {
    return Container(
      width: isDesktop ? 400.0 : double.infinity,
      padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matieres.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 32),
                        const SizedBox(height: 12),
                        const Text(
                          'Ajoutez des matières d\'abord',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Retour aux matières'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '📚 Matière :',
                      style: TextStyle(
                        fontSize: isDesktop ? 16.0 : 14.0,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // LISTE DÉROULANTE DES MATIÈRES
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedMatiereId,
                          isExpanded: true,
                          icon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: isDesktop ? 16.0 : 14.0,
                            color: Colors.black,
                          ),
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text('Sélectionnez une matière'),
                          ),
                          items: _matieres.map((matiere) {
                            return DropdownMenuItem<int>(
                              value: matiere.id,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _parseColor(matiere.couleur),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            matiere.nom,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (matiere.objectifHebdo > 0)
                                            Text(
                                              '🎯 Objectif: ${_formatMinutes(matiere.objectifHebdo)}/semaine',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _getPriorityIconText(matiere.priorite),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getPriorityColor(matiere.priorite),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _isRunning ? null : (value) {
                            if (mounted) {
                              setState(() {
                                _selectedMatiereId = value;
                                _objectifProgression = 0.0;
                                _objectifAtteint = false;
                              });
                              _updateObjectifProgression();
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // MATIÈRE SÉLECTIONNÉE ET OBJECTIF
                    if (_selectedMatiereId != null)
                      FutureBuilder<Matiere?>(
                        future: _getSelectedMatiere(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final matiere = snapshot.data!;
                            
                            return FutureBuilder<int>(
                              future: _getTempsTotalMatiere(_selectedMatiereId!),
                              builder: (context, snapshotTemps) {
                                final tempsTotal = snapshotTemps.data ?? 0;
                                final tempsSession = _totalSecondsStudied ~/ 60;
                                final tempsTotalAvecSession = tempsTotal + tempsSession;
                                final objectifAtteint = matiere.objectifHebdo > 0 && 
                                                       tempsTotalAvecSession >= matiere.objectifHebdo;
                                final progression = matiere.objectifHebdo > 0 
                                    ? tempsTotalAvecSession / matiere.objectifHebdo 
                                    : 0.0;
                                
                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _parseColor(matiere.couleur).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _parseColor(matiere.couleur).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _parseColor(matiere.couleur),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '📖 ${matiere.nom}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '📊 Priorité: ${_getPriorityText(matiere.priorite)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 10),
                                    
                                    // PROGRESSION DE L'OBJECTIF
                                    if (matiere.objectifHebdo > 0)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      objectifAtteint ? '🎉' : '🎯',
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Objectif hebdomadaire',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${(progression * 100).toInt()}%',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: objectifAtteint ? Colors.green : Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 8),
                                            
                                            LinearProgressIndicator(
                                              value: progression,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                objectifAtteint ? Colors.green : Colors.blue,
                                              ),
                                              minHeight: 8,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            
                                            const SizedBox(height: 6),
                                            
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '⏱️ ${_formatMinutes(tempsTotalAvecSession)}/${_formatMinutes(matiere.objectifHebdo)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                
                                                if (objectifAtteint)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade50,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.green.shade100),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Text('✅', style: TextStyle(fontSize: 12)),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Objectif atteint!',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.green,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                  ],
                ),
    );
  }

  Widget _buildControlButtons(bool isDesktop) {
    final buttonPadding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 40, vertical: 20)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    
    return Wrap(
      spacing: isDesktop ? 20.0 : 12.0,
      runSpacing: isDesktop ? 16.0 : 12.0,
      alignment: WrapAlignment.center,
      children: [
        if (!_isRunning) ...[
          ElevatedButton.icon(
            onPressed: _selectedMatiereId == null || _matieres.isEmpty ? null : _startTimer,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              '▶️ Démarrer',
              style: TextStyle(fontSize: isDesktop ? 18.0 : 16.0),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_totalSecondsStudied > 0) ...[
            ElevatedButton.icon(
              onPressed: _stopAndSaveTimer,
              icon: const Icon(Icons.save),
              label: Text(
                '💾 Sauvegarder',
                style: TextStyle(fontSize: isDesktop ? 18.0 : 16.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _resetTimer,
              icon: const Icon(Icons.restart_alt),
              label: Text(
                '🔄 Réinitialiser',
                style: TextStyle(fontSize: isDesktop ? 18.0 : 16.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ] else ...[
          ElevatedButton.icon(
            onPressed: _pauseTimer,
            icon: const Icon(Icons.pause),
            label: Text(
              '⏸️ Pause',
              style: TextStyle(fontSize: isDesktop ? 18.0 : 16.0),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _stopAndSaveTimer,
            icon: const Icon(Icons.stop),
            label: Text(
              '⏹️ Arrêter',
              style: TextStyle(fontSize: isDesktop ? 18.0 : 16.0),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPomodoroInfo(bool isDesktop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔄 Cycle Pomodoro',
              style: TextStyle(
                fontSize: isDesktop ? 20.0 : 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPomodoroStep('🎯 Travail', '25 min', _isRunning && !_isBreak, isDesktop),
                _buildPomodoroStep('⏳ Pause', '5 min', _isRunning && _isBreak, isDesktop),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // COMPTEUR DE CYCLES
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Cycle: $_pomodoroCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('⏱️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    _formatMinutes(_totalSecondsStudied ~/ 60),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // DESCRIPTIF
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '📚 25 min de travail → ☕ 5 min de pause\n🔄 Répétez le cycle en continu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroStep(String title, String duration, bool isActive, bool isDesktop) {
    final circleSize = isDesktop ? 80.0 : 70.0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade50 : Colors.grey.shade50,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.blue : Colors.transparent,
              width: isActive ? 3 : 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  duration,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.blue : Colors.grey,
                    fontSize: isDesktop ? 18.0 : 16.0,
                  ),
                ),
                if (isActive)
                  const Text(
                    '✅',
                    style: TextStyle(fontSize: 24),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isDesktop ? 16.0 : 14.0,
            color: isActive ? Colors.blue : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _startTimer() {
    if (_selectedMatiereId == null && !_isBreak) return;
    
    if (mounted) {
      setState(() => _isRunning = true);
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
            if (!_isBreak) {
              _totalSecondsStudied++;
            }
          });
        }
      } else {
        _timer?.cancel();
        
        if (_isBreak) {
          // La pause est terminée, on repasse en mode travail
          _pomodoroCount++;
          _isBreak = false;
          _secondsRemaining = _pomodoroDurations[0]; // 25 min de travail
          
          _showBreakEndDialog();
        } else {
          // Le travail est terminé, on sauvegarde et on passe en pause
          if (_totalSecondsStudied > 0) {
            _sauvegarderSession();
          }
          _isBreak = true;
          _secondsRemaining = _pomodoroDurations[1]; // 5 min de pause
          
          _showSessionCompleteDialog();
        }
        
        if (mounted) {
          setState(() => _isRunning = false);
        }
      }
    });
  }

  void _pauseTimer() {
    if (mounted) {
      setState(() => _isRunning = false);
    }
    _timer?.cancel();
  }

  void _stopAndSaveTimer() async {
    _timer?.cancel();
    
    if (_totalSecondsStudied > 0 && !_isBreak) {
      await _sauvegarderSession();
    }
    
    if (mounted) {
      setState(() {
        _isRunning = false;
        _isBreak = false;
        _secondsRemaining = 25 * 60;
        _totalSecondsStudied = 0;
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isRunning = false;
        _isBreak = false;
        _secondsRemaining = 25 * 60;
        _totalSecondsStudied = 0;
        _pomodoroCount = 0;
      });
    }
  }

  Future<void> _sauvegarderSession() async {
    if (_selectedMatiereId == null || _totalSecondsStudied == 0) return;
    
    final minutes = (_totalSecondsStudied / 60).floor();
    if (minutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Durée trop courte pour sauvegarder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      final session = SessionEtude(
        matiereId: _selectedMatiereId!,
        duree: minutes,
        date: DateTime.now(),
        note: 'Session Pomodoro #${_pomodoroCount + 1}',
      );
      
      await _dbHelper.insertSession(session);
      
      // Mettre à jour la progression de l'objectif
      await _updateObjectifProgression();
      
      // Vérifier si l'objectif est atteint
      if (_objectifAtteint) {
        // NOTIFICATION SPÉCIALE POUR OBJECTIF ATTEINT
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Félicitations ! Objectif hebdomadaire atteint pour "$_selectedMatiereName" !',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Afficher un dialog de félicitations
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGoalAchievedDialog();
        });
      } else {
        // Notification normale
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Session de ${_formatMinutes(minutes)} sauvegardée pour "$_selectedMatiereName"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur sauvegarde session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NOUVELLE FONCTION POUR AFFICHER LE DIALOG DE FÉLICITATIONS
  void _showGoalAchievedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Objectif Atteint !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'Félicitations !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez atteint votre objectif hebdomadaire pour "$_selectedMatiereName" !',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Continuez comme ça ! Vous êtes sur la bonne voie pour exceller dans cette matière.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Session terminée !'),
          ],
        ),
        content: Text(
          'Vous avez étudié ${_formatMinutes(_totalSecondsStudied ~/ 60)}. Prenez une pause de 5 minutes ! ☕',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBreakEndDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('⏰', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Pause terminée !'),
          ],
        ),
        content: const Text('Prêt pour la prochaine session de travail ? 💪'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}