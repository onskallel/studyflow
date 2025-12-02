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
  bool _modeSombre = false;
  bool _notifications = true;
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
        const SnackBar(
          content: Text('✅ Objectif mis à jour'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
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

  Future<void> _reinitialiserDonnees() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Réinitialiser toutes les données ?'),
        content: const Text('Cette action supprimera toutes vos sessions, matières et réinitialisera les objectifs. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // TODO: Implémenter la méthode resetAllData dans votre MockDatabase
                // await _dbHelper.resetAllData();
                
                // Réinitialiser l'objectif à la valeur par défaut
                await _dbHelper.updateObjectif(120);
                await _chargerPreferences();
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Données réinitialisées avec succès'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                print('❌ Erreur réinitialisation: $e');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
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
          : LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth > 600;
                
                return Padding(
                  padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDesktop ? 'Paramètres de l\'Application' : 'Paramètres',
                        style: TextStyle(
                          fontSize: isDesktop ? 28.0 : 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Expanded(
                        child: isDesktop ? _buildDesktopSettings() : _buildMobileSettings(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMobileSettings() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSettingSection('Objectifs', Icons.flag, [
            _buildSettingItem('Objectif quotidien', '', Icons.flag, 'objectif'),
            _buildSettingItem('Durée Pomodoro', '25 min', Icons.timer, 'normal'),
          ]),
          const SizedBox(height: 20),
          _buildSettingSection('Apparence', Icons.palette, [
            _buildSettingItem('Mode sombre', _modeSombre ? 'Activé' : 'Désactivé', Icons.dark_mode, 'switch'),
            _buildSettingItem('Couleur principale', 'Bleu', Icons.palette, 'normal'),
          ]),
          const SizedBox(height: 20),
          _buildSettingSection('Notifications', Icons.notifications, [
            _buildSettingItem('Rappels d\'étude', _notifications ? 'Activées' : 'Désactivées', Icons.notifications, 'switch'),
            _buildSettingItem('Heure des rappels', '18:00', Icons.access_time, 'normal'),
          ]),
          const SizedBox(height: 20),
          _buildSettingSection('Données', Icons.backup, [
            _buildSettingItem('Exporter données', 'CSV', Icons.backup, 'normal'),
            _buildSettingItem('Réinitialiser données', '', Icons.restore, 'danger'),
          ]),
          const SizedBox(height: 20),
          _buildSettingSection('À propos', Icons.info, [
            _buildSettingItem('Version', '1.0.0', Icons.info, 'normal'),
            _buildSettingItem('Contact support', '', Icons.email, 'normal'),
            _buildSettingItem('Évaluer l\'app', '', Icons.star, 'normal'),
          ]),
        ],
      ),
    );
  }

  Widget _buildDesktopSettings() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 220,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView(
              children: [
                _buildSettingsMenuItem('Objectifs', Icons.flag, true),
                _buildSettingsMenuItem('Apparence', Icons.palette, false),
                _buildSettingsMenuItem('Notifications', Icons.notifications, false),
                _buildSettingsMenuItem('Données', Icons.backup, false),
                _buildSettingsMenuItem('À propos', Icons.info, false),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flag, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Objectifs',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Définissez vos objectifs d\'étude personnalisés pour rester motivé et suivre votre progression.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  _buildDesktopGoalSettings(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSection(String titre, IconData icon, List<Widget> enfants) {
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
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  titre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...enfants,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String titre, String valeur, IconData icone, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icone, color: Colors.blue),
        title: Text(titre),
        trailing: type == 'objectif'
            ? SizedBox(
                width: 140,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () {
                        final nouveau = _objectifMinutes - 30;
                        if (nouveau >= 30) {
                          _mettreAJourObjectif(nouveau);
                        }
                      },
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${_objectifMinutes ~/ 60}h',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () {
                        _mettreAJourObjectif(_objectifMinutes + 30);
                      },
                    ),
                  ],
                ),
              )
            : type == 'switch'
                ? Switch(
                    value: titre == 'Mode sombre' ? _modeSombre : _notifications,
                    onChanged: (value) {
                      setState(() {
                        if (titre == 'Mode sombre') _modeSombre = value;
                        if (titre == 'Rappels d\'étude') _notifications = value;
                      });
                    },
                  )
                : type == 'danger'
                    ? IconButton(
                        icon: const Icon(Icons.warning, color: Colors.red),
                        onPressed: _reinitialiserDonnees,
                      )
                    : Text(
                        valeur,
                        style: const TextStyle(color: Colors.grey),
                      ),
        onTap: type == 'normal' ? () => print('$titre tapped') : null,
      ),
    );
  }

  Widget _buildDesktopGoalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectif quotidien actuel:',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_objectifMinutes / 60).toStringAsFixed(0)} heures (${_objectifMinutes} minutes)',
          style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        
        const SizedBox(height: 30),
        
        // Réglage de l'objectif avec slider
        const Text(
          'Ajuster l\'objectif:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _objectifMinutes.toDouble(),
                min: 30,
                max: 480,
                divisions: 15,
                label: '${(_objectifMinutes / 60).toStringAsFixed(0)}h',
                onChanged: (value) {
                  setState(() {
                    _objectifMinutes = value.toInt();
                  });
                },
                onChangeEnd: (value) {
                  _mettreAJourObjectif(value.toInt());
                },
              ),
            ),
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(_objectifMinutes / 60).toStringAsFixed(0)}h',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Boutons prédéfinis
        const Text(
          'Objectifs prédéfinis:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildGoalButton('30min', 30),
            _buildGoalButton('1h', 60),
            _buildGoalButton('2h', 120),
            _buildGoalButton('3h', 180),
            _buildGoalButton('4h', 240),
            _buildGoalButton('5h', 300),
          ],
        ),
        
        const SizedBox(height: 30),
        
        // Informations supplémentaires
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Conseil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Commencez avec un objectif réaliste (1-2h par jour) et augmentez progressivement.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalButton(String label, int minutes) {
    return ElevatedButton(
      onPressed: () => _mettreAJourObjectif(minutes),
      style: ElevatedButton.styleFrom(
        backgroundColor: _objectifMinutes == minutes ? Colors.blue : Colors.grey.shade200,
        foregroundColor: _objectifMinutes == minutes ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildSettingsMenuItem(String titre, IconData icone, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.blue : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icone, color: isActive ? Colors.blue : Colors.grey),
        title: Text(
          titre,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue : Colors.grey.shade700,
          ),
        ),
        onTap: () => print('$titre menu tapped'),
      ),
    );
  }
}