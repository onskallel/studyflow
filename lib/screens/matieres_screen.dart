import 'package:flutter/material.dart';
import '../database/database_adapter.dart';
import '../models/matiere.dart';

class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {
  final StudyFlowDatabase _dbHelper = getDatabase();
  List<Matiere> _matieres = [];
  bool _isLoading = true;
  
  // Clé pour le RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _chargerMatieres();
  }

  Future<void> _chargerMatieres() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final matieres = await _dbHelper.getMatieres();
      if (mounted) {
        setState(() {
          _matieres = matieres;
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

  // Fonction pour rafraîchir manuellement
  Future<void> _onRefresh() async {
    await _chargerMatieres();
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

  String _getPriorityText(int priorite) {
    switch (priorite) {
      case 0: return 'Basse';
      case 1: return 'Moyenne';
      case 2: return 'Haute';
      default: return 'Inconnue';
    }
  }

  IconData _getPriorityIcon(int priorite) {
    switch (priorite) {
      case 0: return Icons.arrow_downward;
      case 1: return Icons.remove;
      case 2: return Icons.arrow_upward;
      default: return Icons.help;
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

  // Fonction pour récupérer le temps étudié par matière
  Future<Map<int, int>> _getTempsParMatiere() async {
    try {
      // Utilisez la méthode existante ou calculez manuellement
      final tempsParMatiere = await _dbHelper.getTempsParMatiere();
      final Map<int, int> result = {};
      
      // Convertir Map<String, int> en Map<int, int>
      for (var matiere in _matieres) {
        result[matiere.id!] = tempsParMatiere[matiere.nom] ?? 0;
      }
      
      return result;
    } catch (e) {
      print('❌ Erreur calcul temps par matière: $e');
      return {};
    }
  }

  // Fonction pour récupérer le nombre de sessions par matière
  Future<Map<int, int>> _getSessionsParMatiere() async {
    try {
      final sessions = await _dbHelper.getSessions();
      final Map<int, int> result = {};
      
      for (var session in sessions) {
        result[session.matiereId] = (result[session.matiereId] ?? 0) + 1;
      }
      
      return result;
    } catch (e) {
      print('❌ Erreur comptage sessions: $e');
      return {};
    }
  }

  void _showAddMatiereDialog(BuildContext context) {
    final TextEditingController nomController = TextEditingController();
    String selectedColor = '#2196F3';
    int selectedPriority = 1;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('➕ Nouvelle matière'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la matière',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Chimie, Histoire...',
                        prefixIcon: Icon(Icons.book),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Sélecteur de priorité
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Priorité :'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPriorityButton(
                              context: context,
                              label: 'Basse', 
                              priority: 0, 
                              selectedPriority: selectedPriority, 
                              setDialogState: setDialogState,
                              onSelected: () {
                                setDialogState(() {
                                  selectedPriority = 0;
                                });
                              },
                            ),
                            _buildPriorityButton(
                              context: context,
                              label: 'Moyenne', 
                              priority: 1, 
                              selectedPriority: selectedPriority, 
                              setDialogState: setDialogState,
                              onSelected: () {
                                setDialogState(() {
                                  selectedPriority = 1;
                                });
                              },
                            ),
                            _buildPriorityButton(
                              context: context,
                              label: 'Haute', 
                              priority: 2, 
                              selectedPriority: selectedPriority, 
                              setDialogState: setDialogState,
                              onSelected: () {
                                setDialogState(() {
                                  selectedPriority = 2;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Sélecteur de couleur
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Couleur :'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            '#2196F3', '#4CAF50', '#FF5722',
                            '#9C27B0', '#FF9800', '#E91E63',
                          ].map((color) {
                            return GestureDetector(
                              onTap: () => setDialogState(() => selectedColor = color),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _parseColor(color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedColor == color 
                                      ? Colors.black 
                                      : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: selectedColor == color
                                    ? const Center(
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nom = nomController.text.trim();
                    if (nom.isNotEmpty) {
                      await _ajouterMatiere(nom, selectedColor, selectedPriority);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Veuillez entrer un nom'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPriorityButton({
    required BuildContext context,
    required String label,
    required int priority,
    required int selectedPriority,
    required Function setDialogState,
    required VoidCallback onSelected,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onSelected,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedPriority == priority 
              ? _getPriorityColor(priority)
              : Colors.grey.shade200,
            foregroundColor: selectedPriority == priority 
              ? Colors.white 
              : Colors.grey.shade800,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  Future<void> _ajouterMatiere(String nom, String couleur, int priorite) async {
    try {
      final nouvelleMatiere = Matiere(
        nom: nom,
        couleur: couleur,
        priorite: priorite,
        objectifHebdo: 0,
      );
      
      final id = await _dbHelper.insertMatiere(nouvelleMatiere);
      
      // Recharger immédiatement
      await _chargerMatieres();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "$nom" ajoutée avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur ajout matière: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _supprimerMatiere(int id, String nom) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la matière ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$nom" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbHelper.deleteMatiere(id);
                await _chargerMatieres();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗑️ "$nom" supprimée'),
                    backgroundColor: Colors.grey,
                  ),
                );
              } catch (e) {
                print('❌ Erreur suppression: $e');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showEditObjectifDialog(Matiere matiere) {
    final TextEditingController controller = TextEditingController(
      text: matiere.objectifHebdo.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎯 Objectif pour ${matiere.nom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Objectif hebdomadaire (en minutes) :'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes par semaine',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickGoalButton('30min', 30, controller),
                _buildQuickGoalButton('1h', 60, controller),
                _buildQuickGoalButton('2h', 120, controller),
                _buildQuickGoalButton('5h', 300, controller),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes >= 0) {
                final matiereModifiee = Matiere(
                  id: matiere.id,
                  nom: matiere.nom,
                  couleur: matiere.couleur,
                  priorite: matiere.priorite,
                  objectifHebdo: minutes,
                );
                
                try {
                  await _dbHelper.updateMatiere(matiereModifiee);
                  await _chargerMatieres();
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Objectif de $minutes min défini'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('❌ Erreur mise à jour objectif: $e');
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGoalButton(String label, int minutes, TextEditingController controller) {
    return ElevatedButton(
      onPressed: () => controller.text = minutes.toString(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
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
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMatiereDialog(context),
            tooltip: 'Ajouter une matière',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: LayoutBuilder(
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                  const Spacer(),
                                  FutureBuilder<Map<int, int>>(
                                    future: _getSessionsParMatiere(),
                                    builder: (context, snapshot) {
                                      final totalSessions = snapshot.data?.values.fold(0, (sum, count) => sum + count) ?? 0;
                                      return Text(
                                        '$totalSessions sessions',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // LISTE/GRILLE DES MATIÈRES
                          _matieres.isEmpty
                              ? Container(
                                  height: MediaQuery.of(context).size.height * 0.6,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.library_books,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aucune matière',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ajoutez votre première matière',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => _showAddMatiereDialog(context),
                                          child: const Text('Ajouter une matière'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : isDesktop ? _buildDesktopGrid() : _buildMobileList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMatiereDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 📱 LISTE VERTICALE POUR MOBILE
  Widget _buildMobileList() {
    return Column(
      children: _matieres.map((matiere) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildMatiereCard(matiere, true),
        );
      }).toList(),
    );
  }

  // 🖥️ GRID 2 COLONNES POUR DESKTOP
  Widget _buildDesktopGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _matieres.map((matiere) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 64) / 2,
          child: _buildMatiereCard(matiere, false),
        );
      }).toList(),
    );
  }

  Widget _buildMatiereCard(Matiere matiere, bool isMobile) {
    final couleur = _parseColor(matiere.couleur);
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getMatiereStats(matiere.id!),
      builder: (context, snapshot) {
        final tempsMatiere = snapshot.data?['temps'] ?? 0;
        final sessionsCount = snapshot.data?['sessions'] ?? 0;
        final progression = matiere.objectifHebdo > 0 
            ? (tempsMatiere / matiere.objectifHebdo).clamp(0, 1)
            : 0;
        
        return Container(
          constraints: BoxConstraints(
            maxHeight: isMobile ? 280 : 260,
          ),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                              matiere.nom,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Row(
                              children: [
                                Icon(
                                  _getPriorityIcon(matiere.priorite),
                                  size: 14,
                                  color: _getPriorityColor(matiere.priorite),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getPriorityText(matiere.priorite),
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
                      IconButton(
                        icon: const Icon(Icons.flag, size: 18),
                        onPressed: () => _showEditObjectifDialog(matiere),
                        tooltip: 'Définir objectif',
                        color: Colors.blue,
                      ),
                      if (isMobile)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _supprimerMatiere(matiere.id!, matiere.nom),
                          tooltip: 'Supprimer',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Objectif hebdomadaire
                  InkWell(
                    onTap: () => _showEditObjectifDialog(matiere),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flag, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Objectif: ${matiere.objectifHebdo} min/semaine',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: matiere.objectifHebdo > 0 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Statistiques
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$tempsMatiere min étudiés',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.list, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$sessionsCount sessions',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Progression
                  LinearProgressIndicator(
                    value: progression,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(couleur),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progression * 100).toInt()}% complété',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$tempsMatiere/${matiere.objectifHebdo} min',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  if (!isMobile) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () => _supprimerMatiere(matiere.id!, matiere.nom),
                        tooltip: 'Supprimer',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getMatiereStats(int matiereId) async {
    try {
      final tempsParMatiere = await _getTempsParMatiere();
      final sessionsParMatiere = await _getSessionsParMatiere();
      
      return {
        'temps': tempsParMatiere[matiereId] ?? 0,
        'sessions': sessionsParMatiere[matiereId] ?? 0,
      };
    } catch (e) {
      print('❌ Erreur stats matière: $e');
      return {'temps': 0, 'sessions': 0};
    }
  }
}