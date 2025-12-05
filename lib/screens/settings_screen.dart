import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/objectif.dart';
import '../models/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _modeSombre = false;
  bool _notifications = true;
  bool _isLoading = true;
  TimeOfDay _heureRappel = const TimeOfDay(hour: 18, minute: 0);
  Color _couleurPrincipale = Colors.blue;
  int _dureePomodoro = 25;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerPreferences();
    });
  }

  Future<void> _chargerPreferences() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      // Rafraîchir toutes les données (y compris les settings)
      await dbService.refresh();

      // Mettre à jour les variables locales avec les settings
      setState(() {
        _modeSombre = dbService.settings?.modeSombre ?? false;
        _notifications = dbService.settings?.notificationsActives ?? true;
        _heureRappel = dbService.settings?.heureRappel ??
            const TimeOfDay(hour: 18, minute: 0);
        _couleurPrincipale =
            dbService.settings?.couleurPrincipale ?? Colors.blue;
        _dureePomodoro = dbService.settings?.dureePomodoro ?? 25;
        _isLoading = false;
      });

      print('✅ Préférences chargées:');
      print('  - Mode sombre: $_modeSombre');
      print('  - Notifications: $_notifications');
      print('  - Heure rappel: ${_heureRappel.format(context)}');
      print('  - Durée Pomodoro: $_dureePomodoro min');
    } catch (e) {
      print('❌ Erreur chargement préférences: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _mettreAJourObjectif(int nouvellesMinutes) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    try {
      await dbService.updateObjectif(nouvellesMinutes);

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

  Future<void> _toggleDarkMode(bool value) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    try {
      await dbService.toggleDarkMode(value);
      setState(() => _modeSombre = value);
      print('✅ Mode sombre: $value');
    } catch (e) {
      print('❌ Erreur toggleDarkMode: $e');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    try {
      await dbService.toggleNotifications(value);
      setState(() => _notifications = value);
      print('✅ Notifications: $value');
    } catch (e) {
      print('❌ Erreur toggleNotifications: $e');
    }
  }

  Future<void> _selectReminderTime() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final initialTime = _heureRappel;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      try {
        await dbService.updateReminderTime(selectedTime);
        setState(() => _heureRappel = selectedTime);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('⏰ Rappel défini à ${selectedTime.format(context)}')),
        );
        print('✅ Heure rappel: ${selectedTime.format(context)}');
      } catch (e) {
        print('❌ Erreur updateReminderTime: $e');
      }
    }
  }

  Future<void> _selectColor() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une couleur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorOption(Colors.blue, 'Bleu', dbService),
              _buildColorOption(Colors.green, 'Vert', dbService),
              _buildColorOption(Colors.purple, 'Violet', dbService),
              _buildColorOption(Colors.orange, 'Orange', dbService),
              _buildColorOption(Colors.red, 'Rouge', dbService),
              _buildColorOption(Colors.teal, 'Turquoise', dbService),
              _buildColorOption(Colors.pink, 'Rose', dbService),
              _buildColorOption(Colors.indigo, 'Indigo', dbService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(
      Color color, String label, DatabaseService dbService) {
    final isSelected = _couleurPrincipale.value == color.value;

    return ListTile(
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
        ),
      ),
      title: Text(label),
      trailing:
          isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () async {
        try {
          await dbService.updateMainColor(color);
          setState(() => _couleurPrincipale = color);
          Navigator.pop(context);
          print('✅ Couleur principale: $label');
        } catch (e) {
          print('❌ Erreur updateMainColor: $e');
        }
      },
    );
  }

  Future<void> _updatePomodoroDuration(int minutes) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    try {
      await dbService.updatePomodoroDuration(minutes);
      setState(() => _dureePomodoro = minutes);
      print('✅ Durée Pomodoro: $minutes min');
    } catch (e) {
      print('❌ Erreur updatePomodoroDuration: $e');
    }
  }

  Future<void> _exportData() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final csvData = await dbService.exportDataAsCSV();

      // Pour le moment, on affiche juste dans la console
      // Vous pourriez utiliser un package de partage pour exporter le fichier
      print('📊 Données exportées:\n$csvData');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📊 Données exportées dans la console'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Erreur export: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reinitialiserDonnees() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Réinitialiser toutes les données ?'),
        content: const Text(
            'Cette action supprimera toutes vos sessions, matières et réinitialisera les objectifs et paramètres. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                setState(() => _isLoading = true);

                await dbService.resetAllData();
                await _chargerPreferences(); // Recharger les préférences après reset

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
                setState(() => _isLoading = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
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
    final dbService = Provider.of<DatabaseService>(context);
    final objectifMinutes = dbService.objectif?.objectifMinutes ?? 120;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Paramètres'),
        backgroundColor: _couleurPrincipale,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading || dbService.isLoading
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
                        isDesktop
                            ? 'Paramètres de l\'Application'
                            : 'Paramètres',
                        style: TextStyle(
                          fontSize: isDesktop ? 28.0 : 24.0,
                          fontWeight: FontWeight.bold,
                          color: _couleurPrincipale,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: isDesktop
                            ? _buildDesktopSettings(objectifMinutes)
                            : _buildMobileSettings(objectifMinutes),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMobileSettings(int objectifMinutes) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSettingSection('Objectifs', Icons.flag, [
            _buildSettingItem('Objectif quotidien', '', Icons.flag, 'objectif',
                objectifMinutes),
            _buildSettingItem('Durée Pomodoro', '$_dureePomodoro min',
                Icons.timer, 'pomodoro', objectifMinutes),
          ]),
          const SizedBox(height: 20),
          _buildSettingSection('Apparence', Icons.palette, [
            _buildSettingItem(
                'Mode sombre',
                _modeSombre ? 'Activé' : 'Désactivé',
                Icons.dark_mode,
                'switch',
                objectifMinutes),
            _buildSettingItem('Couleur principale', '', Icons.palette, 'color',
                objectifMinutes),
          ]),
          const SizedBox(height: 20),
          _buildSettingSection('Notifications', Icons.notifications, [
            _buildSettingItem(
                'Rappels d\'étude',
                _notifications ? 'Activées' : 'Désactivées',
                Icons.notifications,
                'switch',
                objectifMinutes),
            _buildSettingItem('Heure des rappels', _heureRappel.format(context),
                Icons.access_time, 'time', objectifMinutes),
          ]),
          const SizedBox(height: 20),
          _buildSettingSection('Données', Icons.backup, [
            _buildSettingItem('Exporter données', 'CSV', Icons.backup, 'export',
                objectifMinutes),
            _buildSettingItem('Réinitialiser données', '', Icons.restore,
                'danger', objectifMinutes),
          ]),
          const SizedBox(height: 20),
          _buildSettingSection('À propos', Icons.info, [
            _buildSettingItem(
                'Version', '1.0.0', Icons.info, 'normal', objectifMinutes),
            _buildSettingItem(
                'Contact support', '', Icons.email, 'normal', objectifMinutes),
            _buildSettingItem(
                'Évaluer l\'app', '', Icons.star, 'normal', objectifMinutes),
          ]),
        ],
      ),
    );
  }

  Widget _buildDesktopSettings(int objectifMinutes) {
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
                _buildSettingsMenuItem(
                    'Notifications', Icons.notifications, false),
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
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Définissez vos objectifs d\'étude personnalisés pour rester motivé et suivre votre progression.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  _buildDesktopGoalSettings(objectifMinutes),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSection(
      String titre, IconData icon, List<Widget> enfants) {
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
                Icon(icon, color: _couleurPrincipale),
                const SizedBox(width: 8),
                Text(
                  titre,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _couleurPrincipale),
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

  Widget _buildSettingItem(String titre, String valeur, IconData icone,
      String type, int objectifMinutes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icone, color: _couleurPrincipale),
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
                        final nouveau = objectifMinutes - 30;
                        if (nouveau >= 30) {
                          _mettreAJourObjectif(nouveau);
                        }
                      },
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${objectifMinutes ~/ 60}h',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () {
                        _mettreAJourObjectif(objectifMinutes + 30);
                      },
                    ),
                  ],
                ),
              )
            : type == 'switch'
                ? Switch(
                    value:
                        titre == 'Mode sombre' ? _modeSombre : _notifications,
                    onChanged: (value) {
                      if (titre == 'Mode sombre') {
                        _toggleDarkMode(value);
                      } else if (titre == 'Rappels d\'étude') {
                        _toggleNotifications(value);
                      }
                    },
                    activeColor: _couleurPrincipale,
                  )
                : type == 'time'
                    ? TextButton(
                        onPressed: _selectReminderTime,
                        child: Text(
                          valeur,
                          style: TextStyle(color: _couleurPrincipale),
                        ),
                      )
                    : type == 'color'
                        ? GestureDetector(
                            onTap: _selectColor,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _couleurPrincipale,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                          )
                        : type == 'pomodoro'
                            ? SizedBox(
                                width: 100,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      onPressed: () {
                                        if (_dureePomodoro > 5) {
                                          _updatePomodoroDuration(
                                              _dureePomodoro - 5);
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '$_dureePomodoro',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16),
                                      onPressed: () {
                                        if (_dureePomodoro < 60) {
                                          _updatePomodoroDuration(
                                              _dureePomodoro + 5);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : type == 'export'
                                ? IconButton(
                                    icon: const Icon(Icons.share),
                                    onPressed: _exportData,
                                    color: _couleurPrincipale,
                                  )
                                : type == 'danger'
                                    ? IconButton(
                                        icon: const Icon(Icons.warning,
                                            color: Colors.red),
                                        onPressed: _reinitialiserDonnees,
                                      )
                                    : Text(
                                        valeur,
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
        onTap: type == 'normal' ? () => print('$titre tapped') : null,
      ),
    );
  }

  Widget _buildDesktopGoalSettings(int objectifMinutes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Objectif quotidien actuel:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${(objectifMinutes / 60).toStringAsFixed(0)} heures ($objectifMinutes minutes)',
          style: TextStyle(
              fontSize: 18,
              color: _couleurPrincipale,
              fontWeight: FontWeight.bold),
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
                value: objectifMinutes.toDouble(),
                min: 30,
                max: 480,
                divisions: 15,
                label: '${(objectifMinutes / 60).toStringAsFixed(0)}h',
                activeColor: _couleurPrincipale,
                onChanged: (value) {
                  setState(() {});
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
                color: _couleurPrincipale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(objectifMinutes / 60).toStringAsFixed(0)}h',
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Conseil',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _couleurPrincipale),
                ),
                const SizedBox(height: 8),
                const Text(
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
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final objectifMinutes = dbService.objectif?.objectifMinutes ?? 120;

    return ElevatedButton(
      onPressed: () => _mettreAJourObjectif(minutes),
      style: ElevatedButton.styleFrom(
        backgroundColor: objectifMinutes == minutes
            ? _couleurPrincipale
            : Colors.grey.shade200,
        foregroundColor:
            objectifMinutes == minutes ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildSettingsMenuItem(String titre, IconData icone, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color:
            isActive ? _couleurPrincipale.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? _couleurPrincipale : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading:
            Icon(icone, color: isActive ? _couleurPrincipale : Colors.grey),
        title: Text(
          titre,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? _couleurPrincipale : Colors.grey.shade700,
          ),
        ),
        onTap: () => print('$titre menu tapped'),
      ),
    );
  }
}
