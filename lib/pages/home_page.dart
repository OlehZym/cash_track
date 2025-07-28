import 'package:flutter/material.dart';
import 'cash_track_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final void Function(ThemeMode) toggleTheme;
  final ThemeMode currentThemeMode;

  const HomePage({
    super.key,
    required this.toggleTheme,
    required this.currentThemeMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CashTrackPage(),
      SettingsPage(
        onThemeChanged: widget.toggleTheme,
        currentThemeMode: widget.currentThemeMode,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash track'),
        iconTheme: const IconThemeData(color: Color(0xFF2ecc71)),
      ),
      drawer: NavigationDrawer(
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
        selectedIndex: _selectedIndex,
        children: [
          NavigationDrawerDestination(
            icon: Image.asset('assets/icons/cash_track.png',
                width: 32, height: 32),
            selectedIcon: Image.asset(
              'assets/icons/cash_track.png',
              width: 32,
              height: 32,
            ),
            label: const Text('Cash track'),
          ),
          NavigationDrawerDestination(
            icon: Image.asset(
              'assets/icons/settings.png',
              width: 25,
              height: 25,
            ),
            label: const Text('Налаштування'),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
    );
  }
}
