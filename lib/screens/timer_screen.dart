import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _secondsRemaining = 25 * 60; // 25 minutes
  bool _isRunning = false;
  String _selectedMatiere = 'Mathématiques';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏱️ Session d\'étude'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 600;
          
          return Padding(
            padding: EdgeInsets.all(isDesktop ? 40.0 : 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TIMER CIRCLE
                _buildTimerCircle(isDesktop),
                
                SizedBox(height: isDesktop ? 40 : 20),
                
                // SÉLECTION MATIÈRE
                _buildMatiereSelector(isDesktop),
                
                SizedBox(height: isDesktop ? 40 : 20),
                
                // BOUTONS CONTROL
                _buildControlButtons(isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerCircle(bool isDesktop) {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    
    return Container(
      width: isDesktop ? 300 : 200,
      height: isDesktop ? 300 : 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blue.shade300,
          width: 8,
        ),
      ),
      child: Center(
        child: Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: isDesktop ? 48 : 36,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildMatiereSelector(bool isDesktop) {
    final matieres = ['Mathématiques', 'Physique', 'Anglais', 'Histoire'];
    
    return Container(
      width: isDesktop ? 400 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedMatiere,
        isExpanded: true,
        underline: const SizedBox(),
        items: matieres.map((matiere) {
          return DropdownMenuItem(
            value: matiere,
            child: Text(matiere),
          );
        }).toList(),
        onChanged: _isRunning ? null : (value) {
          setState(() => _selectedMatiere = value!);
        },
      ),
    );
  }

  Widget _buildControlButtons(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isRunning) ...[
          ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow),
            label: Text(isDesktop ? 'Démarrer' : 'Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: isDesktop ? 16 : 12,
              ),
            ),
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: _pauseTimer,
            icon: const Icon(Icons.pause),
            label: Text(isDesktop ? 'Pause' : 'Pause'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: isDesktop ? 16 : 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _stopTimer,
            icon: const Icon(Icons.stop),
            label: Text(isDesktop ? 'Arrêter' : 'Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: isDesktop ? 16 : 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    // TODO: Logique timer
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    // TODO: Logique pause
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
      _secondsRemaining = 25 * 60;
    });
    // TODO: Sauvegarder session
  }
}