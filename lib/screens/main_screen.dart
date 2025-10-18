import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'home_screen.dart';
import 'systems_screen.dart';
import 'habits_screen.dart';
import 'goals_screen.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';
import 'focus_mode_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),        
    const SystemsScreen(),     
    const HabitsScreen(),      
    const GoalsScreen(),       
    const JournalScreen(),     
    const SettingsScreen(),
    const FocusModeScreen(),   // Index 6
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex.clamp(0, _screens.length - 1),
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index >= 0 && index < _screens.length) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}
