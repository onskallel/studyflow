import 'package:flutter/material.dart';

class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {
  final List<Map<String, dynamic>> _matieres = [
    {
      'nom': 'Mathématiques',
      'couleur': Colors.blue,
      'priorite': 2,
      'temps': '4h30',
      'progression': 0.6,
    },
    {
      'nom': 'Physique',
      'couleur': Colors.green,
      'priorite': 1,
      'temps': '2h15',
      'progression': 0.3,
    },
    {
      'nom': 'Anglais',
      'couleur': Colors.orange,
      'priorite': 0,
      'temps': '3h00',
      'progression': 0.5,
    },
  ];

  void _showAddMatiereDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('➕ Nouvelle matière'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nom de la matière',
              border: OutlineInputBorder(),
              hintText: 'Ex: Chimie, Histoire...',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final nom = controller.text.trim();
                if (nom.isNotEmpty) {
                  _ajouterMatiere(nom);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _ajouterMatiere(String nom) {
    setState(() {
      _matieres.add({
        'nom': nom,
        'couleur': Colors.blue, // Couleur par défaut
        'priorite': 1, // Priorité moyenne par défaut
        'temps': '0h00',
        'progression': 0.0,
      });
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "$nom" ajoutée avec succès'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _supprimerMatiere(int index) {
    final nomMatiere = _matieres[index]['nom'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la matière ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$nomMatiere" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _matieres.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Mes Matières'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMatiereDialog(context),
            tooltip: 'Ajouter une matière',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMatiereDialog(context),
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 600;
          
          return Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) ...[
                  const Text(
                    'Gestion des Matières',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // COMPTEUR DE MATIÈRES
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.library_books, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '${_matieres.length} matière${_matieres.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // LISTE/GRILLE DES MATIÈRES
                Expanded(
                  child: _matieres.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.library_books, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucune matière',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              Text(
                                'Cliquez sur + pour ajouter une matière',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : isDesktop ? _buildDesktopGrid() : _buildMobileList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 📱 LISTE VERTICALE POUR MOBILE
  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: _matieres.length,
      itemBuilder: (context, index) {
        final matiere = _matieres[index];
        return _buildMatiereCard(matiere, index, true);
      },
    );
  }

  // 🖥️ GRID 2 COLONNES POUR DESKTOP
  Widget _buildDesktopGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: _matieres.length,
      itemBuilder: (context, index) {
        final matiere = _matieres[index];
        return _buildMatiereCard(matiere, index, false);
      },
    );
  }

  Widget _buildMatiereCard(Map<String, dynamic> matiere, int index, bool isMobile) {
    final prioriteIcons = ['📘', '📗', '🔥'];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: matiere['couleur'],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    matiere['nom'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(prioriteIcons[matiere['priorite']]),
                if (isMobile) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _supprimerMatiere(index),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text('⏱️ ${matiere['temps']} cette semaine'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: matiere['progression'],
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(matiere['couleur']),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${(matiere['progression'] * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                if (!isMobile) ...[
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => _supprimerMatiere(index),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}