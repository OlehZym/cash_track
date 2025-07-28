import 'package:cash_track/models/transaction_adapter.dart';
import 'package:cash_track/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/auth_gate.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');

  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? 2;

  runApp(CashTrackApp(initialThemeMode: ThemeMode.values[themeIndex]));
}

class CashTrackApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const CashTrackApp({super.key, required this.initialThemeMode});

  @override
  State<CashTrackApp> createState() => _CashTrackAppState();
}

class _CashTrackAppState extends State<CashTrackApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _toggleTheme(ThemeMode newTheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', newTheme.index);
    setState(() {
      _themeMode = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мій щоденник',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: AuthGate(toggleTheme: _toggleTheme, currentThemeMode: _themeMode),
    );
  }
}
