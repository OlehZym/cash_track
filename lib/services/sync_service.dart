import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

// import 'package:cash_track/models/transaction.dart';

class SyncService {
  // final Box<Transaction> _txBox = Hive.box<Transaction>('transactions');
  final Box _syncBox = Hive.box('sync');

  Timer? _timer;

  void startPeriodicSync() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != [ConnectivityResult.none]) {
        await sync();
      }
    });
  }

  Future<void> sync() async {
    try {
      // Відправити локальні нові/змінені транзакції на сервер
      final pendingTxs =
          _syncBox.get('pendingTxs', defaultValue: <String>[]) as List<String>;

      for (var txJson in pendingTxs) {
        final txMap = jsonDecode(txJson) as Map<String, dynamic>;
        final response = await http.post(
          Uri.parse('https://your-server.com/api/transactions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer your_token_here'
          },
          body: jsonEncode(txMap),
        );
        if (response.statusCode == 200) {
          // Видаляємо успішно надіслані
          pendingTxs.remove(txJson);
          await _syncBox.put('pendingTxs', pendingTxs);
        }
      }

      // Синхронізація PIN
      final pendingPin = _syncBox.get('pendingPin') as String?;
      if (pendingPin != null) {
        final pinResp = await http.post(
          Uri.parse('https://your-server.com/update-pin'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer your_token_here'
          },
          body: jsonEncode({'newPin': pendingPin}),
        );

        if (pinResp.statusCode == 200) {
          await _syncBox.delete('pendingPin');
        }
      }
    } catch (e) {
      // Лог або ігнорувати
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
