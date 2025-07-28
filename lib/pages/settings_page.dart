import 'package:flutter/material.dart';
import 'change_pin_page.dart';

class SettingsPage extends StatefulWidget {
  final void Function(ThemeMode)? onThemeChanged;
  final ThemeMode currentThemeMode;

  const SettingsPage({
    super.key,
    this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _selectedThemeMode;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.currentThemeMode;
  }

  void _onThemeChanged(ThemeMode? mode) {
    if (mode == null) return;
    setState(() {
      _selectedThemeMode = mode;
    });
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Тема оформлення'),
          subtitle: Row(
            children: [
              Text(
                _selectedThemeMode == ThemeMode.system
                    ? 'Системна'
                    : _selectedThemeMode == ThemeMode.dark
                        ? 'Темна'
                        : 'Світла',
              ),
              const Spacer(),
              PopupMenuButton<ThemeMode>(
                icon: const Icon(Icons.settings),
                onSelected: (ThemeMode themeMode) {
                  _onThemeChanged(themeMode);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: ThemeMode.light,
                    child: Text('Світла'),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Темна'),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.system,
                    child: Text('Системна'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChangePinPage()),
                );
              },
              label: const Text('Змінити PIN',
                  style: TextStyle(color: Colors.blue)),
              icon: Image.asset(
                'assets/icons/change_password.png',
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
