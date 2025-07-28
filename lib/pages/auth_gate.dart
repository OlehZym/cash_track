import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'home_page.dart';

class AuthGate extends StatefulWidget {
  final void Function(ThemeMode) toggleTheme;
  final ThemeMode currentThemeMode;

  const AuthGate({
    super.key,
    required this.toggleTheme,
    required this.currentThemeMode,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final storage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();

  bool _pinSet = false;
  bool _authenticated = false;
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    String? pin = await storage.read(key: 'pin');
    if (pin == null) {
      setState(() {
        _pinSet = false;
      });
    } else {
      setState(() {
        _pinSet = true;
      });

      try {
        bool didAuth = await auth.authenticate(
          localizedReason: 'Підтвердьте особу',
          options: const AuthenticationOptions(
            biometricOnly: true, // Только биометрия
            useErrorDialogs: false, // Без системного PIN-окна
            stickyAuth: false,
          ),
        );

        if (didAuth) {
          setState(() {
            _authenticated = true;
          });
        }

        // Если отпечаток не сработал — ничего не делаем.
        // Пользователь сможет ввести PIN вручную (UI уже показывает поле).
      } catch (e) {
        // Если ошибка в биометрии — тоже ничего, пользователь вводит PIN
        debugPrint('Biometric auth error: $e');
      }
    }
  }

  // void _resetPin() async {
  //   await storage.delete(key: 'pin');
  //   setState(() {
  //     _pinSet = false;
  //     _authenticated = false;
  //     _pinController.clear();
  //   });
  // }

  void _verifyPin() async {
    String? savedPin = await storage.read(key: 'pin');
    if (_pinController.text == savedPin) {
      setState(() {
        _authenticated = true;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Невірний PIN')));
    }
  }

  void _setPin() async {
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN має бути мінімум 4 цифри')),
      );
      return;
    }
    await storage.write(key: 'pin', value: _pinController.text);
    setState(() {
      _pinSet = true;
      _authenticated = true;
    });
  }

  void fingerprint() async {
    try {
      bool didAuth = await auth.authenticate(
        localizedReason: 'Підтвердьте особу',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: false,
          stickyAuth: false,
        ),
      );

      if (didAuth) {
        setState(() {
          _authenticated = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Помилка біометрії')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      return HomePage(
        toggleTheme: widget.toggleTheme,
        currentThemeMode: widget.currentThemeMode,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_pinSet ? 'Введіть PIN' : 'Встановіть PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              maxLength: 8,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'PIN',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePin = !_obscurePin;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pinSet ? _verifyPin : _setPin,
                  child: Text(_pinSet ? 'Увійти' : 'Встановити PIN'),
                ),
                IconButton(
                  onPressed: fingerprint,
                  icon: const Icon(Icons.fingerprint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
