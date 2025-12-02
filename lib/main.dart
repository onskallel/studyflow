import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/matieres_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/timer_screen.dart';

void main() {
  runApp(const StudyFlowApp());
}

class StudyFlowApp extends StatelessWidget {
  const StudyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyFlow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ResponsiveLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({super.key});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MatieresScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 📱 MOBILE - Écran < 600px
        if (constraints.maxWidth < 600) {
          return Scaffold(
            body: _screens[_currentIndex],
            bottomNavigationBar: _buildBottomNavBar(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TimerScreen()),
                );
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.timer),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          );
        } 
        // 🖥️ DESKTOP - Écran >= 600px
        else {
          return Scaffold(
            body: Row(
              children: [
                // BARRE LATÉRALE POUR PC
                _buildNavigationRail(),
                
                // CONTENU PRINCIPAL
                Expanded(
                  child: _screens[_currentIndex],
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TimerScreen()),
                );
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.timer),
            ),
          );
        }
      },
    );
  }

  // 📱 BOTTOM NAV BAR POUR MOBILE
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Matières'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
      ],
    );
  }

  // 🖥️ NAVIGATION RAIL POUR DESKTOP
  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home),
          label: Text('Accueil'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_books),
          label: Text('Matières'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart),
          label: Text('Stats'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Paramètres'),
        ),
      ],
    );
  }
}