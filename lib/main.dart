import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');
  runApp(const CashTrackApp());
}

class CashTrackApp extends StatelessWidget {
  const CashTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashTrack',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

enum TransactionType { income, expense }

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final TransactionType type;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final DateTime date;
  @HiveField(5)
  final String? note;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    return Transaction(
      id: reader.readString(),
      type: TransactionType.values[reader.readInt()],
      amount: reader.readDouble(),
      category: reader.readString(),
      date: DateTime.parse(reader.readString()),
      note: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.type.index);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.category);
    writer.writeString(obj.date.toIso8601String());
    writer.writeString(obj.note ?? '');
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _box = Hive.box<Transaction>('transactions');

  void _addTransaction([Transaction? existing]) async {
    final result = await showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddTransactionForm(existing: existing),
    );
    if (result != null) {
      if (existing != null) {
        final key = existing.key;
        await _box.put(key, result);
      } else {
        await _box.add(result);
      }
      setState(() {});
    }
  }

  void _deleteTransaction(int key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить транзакцию?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Удалить')),
        ],
      ),
    );

    if (confirm == true) {
      await _box.delete(key);
      setState(() {});
    }
  }

  double _calculateTotal(TransactionType type) {
    return _box.values
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final income = _calculateTotal(TransactionType.income);
    final expense = _calculateTotal(TransactionType.expense);
    final balance = income - expense;

    return Scaffold(
      appBar: AppBar(title: const Text('CashTrack')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Баланс: ${balance.toStringAsFixed(2)} грн',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _box.listenable(),
                builder: (context, Box<Transaction> box, _) {
                  final items = box.toMap().entries.toList().reversed.toList();
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final entry = items[index];
                      final t = entry.value;
                      final key = entry.key;

                      return ListTile(
                        title: Text(
                            '${t.type == TransactionType.income ? '+' : '-'}${t.amount.toStringAsFixed(2)} грн — ${t.category}'),
                        subtitle: Text(DateFormat.yMMMd().format(t.date)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.amber),
                              onPressed: () => _addTransaction(t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTransaction(key),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTransactionForm extends StatefulWidget {
  final Transaction? existing;
  const AddTransactionForm({super.key, this.existing});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late final DateTime _selectedDate;
  bool showScrollView = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amountController =
        TextEditingController(text: existing?.amount.toString());
    _categoryController = TextEditingController(text: existing?.category ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _type = existing?.type ?? TransactionType.income;
    _selectedDate = existing?.date ?? DateTime.now();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final tx = Transaction(
        id: widget.existing?.id ?? const Uuid().v4(),
        type: _type,
        amount: double.parse(_amountController.text),
        category: _categoryController.text,
        date: _selectedDate,
        note: _noteController.text,
      );
      Navigator.of(context).pop(tx);
    }
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 16,
        right: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
            child: Column(
          children: [
            DropdownButtonFormField<TransactionType>(
              value: _type,
              items: const [
                DropdownMenuItem(
                  value: TransactionType.income,
                  child: Text('Приход'),
                ),
                DropdownMenuItem(
                  value: TransactionType.expense,
                  child: Text('Расход'),
                ),
              ],
              onChanged: (val) => setState(() => _type = val!),
              decoration: const InputDecoration(labelText: 'Тип'),
            ),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Сумма'),
              keyboardType: TextInputType.number,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Введите сумму' : null,
            ),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Категория'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Введите категорию' : null,
            ),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Комментарий'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _submit,
                  child:
                      Text(widget.existing != null ? 'Сохранить' : 'Добавить'),
                ),
                const SizedBox(width: 26),
                ElevatedButton(
                  onPressed: _close,
                  child: const Text('Закрыть'),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ],
        )),
      ),
    );
  }
}
