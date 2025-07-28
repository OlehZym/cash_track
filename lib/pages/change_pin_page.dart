import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final storage = const FlutterSecureStorage();

  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _changePin() async {
    final currentPin = await storage.read(key: 'pin');

    if (_currentPinController.text != currentPin) {
      _showMessage('Поточний PIN неправильний');
      return;
    }

    if (_newPinController.text.length < 4) {
      _showMessage('Новий PIN має бути мінімум 4 цифри');
      return;
    }

    if (_newPinController.text != _confirmPinController.text) {
      _showMessage('Новий PIN і підтвердження не співпадають');
      return;
    }

    await storage.write(key: 'pin', value: _newPinController.text);
    _showMessage('PIN успішно змінено');
    if (!mounted) return;
    Navigator.of(context).pop(); // Возврат назад после смены PIN
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Змінити PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _currentPinController,
              keyboardType: TextInputType.number,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Поточний PIN',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrent = !_obscureCurrent;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPinController,
              keyboardType: TextInputType.number,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Новий PIN',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Підтвердження нового PIN',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _changePin,
              child: const Text('Змінити PIN'),
            ),
          ],
        ),
      ),
    );
  }
}
