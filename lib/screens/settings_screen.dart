import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Paramètres'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 600;
          
          return Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDesktop ? 'Paramètres de l\'Application' : 'Paramètres',
                  style: TextStyle(fontSize: isDesktop ? 28.0 : 24.0, fontWeight: FontWeight.bold),
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
    return ListView(
      children: [
        _buildSettingSection('Objectifs', [
          _buildSettingItem('Objectif quotidien', '2 heures', Icons.flag),
          _buildSettingItem('Objectif par matière', 'Personnalisé', Icons.school),
        ]),
        const SizedBox(height: 20),
        _buildSettingSection('Apparence', [
          _buildSettingItem('Mode sombre', 'Désactivé', Icons.dark_mode),
          _buildSettingItem('Couleur principale', 'Bleu', Icons.palette),
        ]),
        const SizedBox(height: 20),
        _buildSettingSection('Données', [
          _buildSettingItem('Exporter données', '', Icons.backup),
          _buildSettingItem('Réinitialiser', '', Icons.restore),
        ]),
      ],
    );
  }

  Widget _buildDesktopSettings() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MENU LATÉRAL
        SizedBox(
          width: 200,
          child: Card(
            elevation: 4,
            child: ListView(
              children: [
                _buildSettingsMenuItem('Objectifs', Icons.flag, true),
                _buildSettingsMenuItem('Apparence', Icons.palette, false),
                _buildSettingsMenuItem('Données', Icons.backup, false),
                _buildSettingsMenuItem('À propos', Icons.info, false),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 20),
        
        // CONTENU
        Expanded(
          child: Card(
            elevation: 4,
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Objectifs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Text('Configuration des objectifs d\'étude...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSection(String titre, List<Widget> enfants) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...enfants,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String titre, String valeur, IconData icone) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titre),
      trailing: Text(valeur, style: const TextStyle(color: Colors.grey)),
      onTap: () => print('$titre tapped'),
    );
  }

  Widget _buildSettingsMenuItem(String titre, IconData icone, bool isActive) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titre),
      tileColor: isActive ? Colors.blue.shade50 : null,
      onTap: () => print('$titre menu tapped'),
    );
  }
}