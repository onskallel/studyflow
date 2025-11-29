import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedTimeRange = 0; // 0: Semaine, 1: Mois, 2: Total

  // Données exemple pour les graphiques
  final Map<String, double> _tempsParMatiere = {
    'Mathématiques': 4.5,
    'Physique': 2.25,
    'Anglais': 3.0,
    'Chimie': 1.5,
  };

  final List<double> _tempsParJour = [1.5, 2.0, 1.0, 0.5, 2.5, 1.0, 3.0]; // Lundi à Dimanche

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statistiques'),
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
                  isDesktop ? 'Analyses et Statistiques' : 'Statistiques',
                  style: TextStyle(
                    fontSize: isDesktop ? 28.0 : 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // SÉLECTION PÉRIODE
                _buildTimeRangeSelector(),
                const SizedBox(height: 20),
                
                // CONTENU PRINCIPAL AVEC EXPANDED POUR ÉVITER OVERFLOW
                Expanded(
                  child: isDesktop ? _buildDesktopStats() : _buildMobileStats(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmall = constraints.maxWidth < 400;
            
            return isSmall 
                ? Column(
                    children: [
                      _buildTimeRangeOption('Cette semaine', 0),
                      const SizedBox(height: 8),
                      _buildTimeRangeOption('Ce mois', 1),
                      const SizedBox(height: 8),
                      _buildTimeRangeOption('Total', 2),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTimeRangeOption('Cette semaine', 0),
                      _buildTimeRangeOption('Ce mois', 1),
                      _buildTimeRangeOption('Total', 2),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildTimeRangeOption(String text, int value) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeRange = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: const BoxConstraints(minWidth: 120),
        decoration: BoxDecoration(
          color: _selectedTimeRange == value ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedTimeRange == value ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _selectedTimeRange == value ? Colors.blue : Colors.grey.shade600,
            fontWeight: _selectedTimeRange == value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 📱 VERSION MOBILE
  Widget _buildMobileStats() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatsSummary(),
            const SizedBox(height: 20),
            _buildTempsParMatiereChart(),
            const SizedBox(height: 20),
            _buildTempsParJourChart(),
            const SizedBox(height: 20),
            _buildProductivityCard(),
            const SizedBox(height: 20), // Espace supplémentaire en bas
          ],
        ),
      ),
    );
  }

  // 🖥️ VERSION DESKTOP
  Widget _buildDesktopStats() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COLONNE GAUCHE
            Expanded(
              flex: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatsSummary(),
                  const SizedBox(height: 20),
                  _buildProductivityCard(),
                ],
              ),
            ),
            
            const SizedBox(width: 20),
            
            // COLONNE DROITE
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTempsParMatiereChart(),
                  const SizedBox(height: 20),
                  _buildTempsParJourChart(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final totalHeures = _tempsParMatiere.values.reduce((a, b) => a + b);
    final objectifQuotidien = 2.0; // 2 heures par jour
    final objectifAtteint = (totalHeures / 7 / objectifQuotidien * 100).clamp(0, 100);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Résumé de la Semaine',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isSmall = constraints.maxWidth < 300;
                final crossAxisCount = isSmall ? 2 : 4;
                final mainAxisCount = isSmall ? 2 : 1;
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isSmall ? 1.2 : 1.0,
                  children: [
                    _buildStatItem('⏱️', '${totalHeures.toStringAsFixed(1)}h', 'Temps total'),
                    _buildStatItem('📚', '${_tempsParMatiere.length}', 'Matières'),
                    _buildStatItem('🎯', '${objectifAtteint.toInt()}%', 'Objectif'),
                    _buildStatItem('📈', '4.2', 'Moyenne/jour'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String valeur, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          valeur, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label, 
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTempsParMatiereChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⏱️ Temps par Matière',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _tempsParMatiere.entries.map((entry) {
                    final color = _getColorForMatiere(entry.key);
                    return PieChartSectionData(
                      color: color,
                      value: entry.value,
                      title: '${entry.value}h',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // LÉGENDE
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _tempsParMatiere.entries.map((entry) {
                final color = _getColorForMatiere(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempsParJourChart() {
    final jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Temps par Jour',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 4,
                  barGroups: _tempsParJour.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Colors.blue,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              jours[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 Productivité',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProductivityItem('📊 Session la plus longue', '2h 30min'),
            _buildProductivityItem('⚡ Session moyenne', '1h 15min'),
            _buildProductivityItem('🎯 Jour le plus productif', 'Lundi'),
            _buildProductivityItem('🏆 Matière préférée', 'Mathématiques'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label, 
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getColorForMatiere(String matiere) {
    final colors = {
      'Mathématiques': Colors.blue,
      'Physique': Colors.green,
      'Anglais': Colors.orange,
      'Chimie': Colors.purple,
    };
    return colors[matiere] ?? Colors.grey;
  }
}