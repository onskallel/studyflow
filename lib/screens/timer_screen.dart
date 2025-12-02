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
  final List<int> _pomodoroDurations = [25 * 60, 5 * 60, 25 * 60, 5 * 60, 25 * 60, 5 * 60, 25 * 60, 15 * 60];
  bool _isLoading = true;

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
          // Sélectionner la première matière si disponible
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimerCircle(),
              const SizedBox(height: 30),
              _buildMatiereSelector(),
              const SizedBox(height: 30),
              _buildControlButtons(),
              if (_totalSecondsStudied > 0 && !_isRunning)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'Session: ${(_totalSecondsStudied / 60).toStringAsFixed(1)} min',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 20),
              _buildPomodoroInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCircle() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    
    return Column(
      children: [
        Text(
          _timerTitle,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _timerColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _timerColor,
              width: 8,
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
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _timerColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isBreak)
                  const Text(
                    'Reposez-vous !',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  )
                else if (_isRunning)
                  const Text(
                    'Concentrez-vous !',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatiereSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matieres.isEmpty
              ? const Center(
                  child: Column(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 24),
                      SizedBox(height: 8),
                      Text(
                        'Ajoutez des matières d\'abord',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Matière :',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<int>(
                      value: _selectedMatiereId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      hint: const Text('Sélectionnez une matière'),
                      items: _matieres.map((matiere) {
                        return DropdownMenuItem<int>(
                          value: matiere.id,
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  matiere.nom,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (matiere.objectifHebdo > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    '(${matiere.objectifHebdo} min)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _isRunning ? null : (value) {
                        if (mounted) {
                          setState(() => _selectedMatiereId = value);
                        }
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildControlButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (!_isRunning) ...[
          ElevatedButton.icon(
            onPressed: _selectedMatiereId == null || _matieres.isEmpty ? null : _startTimer,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Démarrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_totalSecondsStudied > 0) ...[
            ElevatedButton.icon(
              onPressed: _stopAndSaveTimer,
              icon: const Icon(Icons.save),
              label: const Text('Sauvegarder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _resetTimer,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Réinitialiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _stopAndSaveTimer,
            icon: const Icon(Icons.stop),
            label: const Text('Arrêter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPomodoroInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cycle Pomodoro',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPomodoroStep('🎯 Travail', '25 min', _isRunning && !_isBreak),
                _buildPomodoroStep('⏳ Pause', '5 min', _isRunning && _isBreak),
                _buildPomodoroStep('🔥 Longue', '15 min', false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroStep(String title, String duration, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade50 : Colors.grey.shade50,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              duration,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.blue : Colors.grey,
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
          // Fin de pause
          _pomodoroCount++;
          _isBreak = false;
          _secondsRemaining = _pomodoroDurations[(_pomodoroCount * 2) % _pomodoroDurations.length];
          
          _showBreakEndDialog();
        } else {
          // Fin de session pomodoro
          if (_totalSecondsStudied > 0) {
            _sauvegarderSession();
          }
          _isBreak = true;
          _secondsRemaining = _pomodoroDurations[(_pomodoroCount * 2 + 1) % _pomodoroDurations.length];
          
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
    
    // CORRECTION: Assurer que la durée est > 0 et convertir correctement
    final minutes = (_totalSecondsStudied / 60).floor();
    if (minutes < 1) {
      print('⚠️ Durée trop courte: $_totalSecondsStudied secondes = $minutes minutes');
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Session de $minutes min sauvegardée pour $_selectedMatiereName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Session terminée !'),
        content: Text('Vous avez étudié ${(_totalSecondsStudied / 60).toStringAsFixed(1)} minutes. Prenez une pause de 5 minutes !'),
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
        title: const Text('⏰ Pause terminée !'),
        content: const Text('Prêt pour la prochaine session de travail ?'),
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