import 'package:cash_track/add_transaction_form.dart';
import 'package:cash_track/main.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
// import 'dart:ui' as ui;
import 'dart:ui' as ui show TextDirection;

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
              child: const Text(
                'Отмена',
                style: TextStyle(color: Color.fromARGB(255, 0, 194, 26)),
              )),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Удалить',
                style: TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
              )),
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

                      return TransactionTile(
                        t: t,
                        onEdit: () => _addTransaction(t),
                        onDelete: () => _deleteTransaction(key),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: IconButton(
        onPressed: _addTransaction,
        icon: const Icon(
          Icons.add,
          size: 50,
          color: Color.fromARGB(255, 0, 38, 255),
        ),
      ),
    );
  }
}

class TransactionTile extends StatefulWidget {
  final Transaction t;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.t,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _expanded = false;
  bool _isOverflowing = false;
  BoxConstraints? _lastConstraints;

  void _checkOverflow(BoxConstraints constraints) {
    if (_lastConstraints != null &&
        _lastConstraints!.maxWidth == constraints.maxWidth &&
        _lastConstraints!.minWidth == constraints.minWidth &&
        _lastConstraints!.maxHeight == constraints.maxHeight &&
        _lastConstraints!.minHeight == constraints.minHeight) {
      return;
    }
    _lastConstraints = constraints;

    final text = widget.t.note ?? '';
    final textStyle = DefaultTextStyle.of(context)
        .style
        .merge(const TextStyle(color: Colors.grey));

    final span = TextSpan(text: text, style: textStyle);

    final tp = TextPainter(
      text: span,
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    );
    tp.layout(maxWidth: constraints.maxWidth);

    final doesOverflow = tp.didExceedMaxLines;

    if (_isOverflowing != doesOverflow) {
      // Вызываем setState после окончания текущего build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isOverflowing = doesOverflow;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${t.type == TransactionType.income ? '+' : '-'}${t.amount.toStringAsFixed(2)} грн — ${t.category}',
          ),
          if (t.note != null && t.note!.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                _checkOverflow(constraints);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        t.note!,
                        maxLines: _expanded ? null : 1,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: DefaultTextStyle.of(context)
                            .style
                            .merge(const TextStyle(color: Colors.grey)),
                      ),
                    ),
                    if (_isOverflowing)
                      IconButton(
                        icon: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            _expanded = !_expanded;
                          });
                        },
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      subtitle: Text(DateFormat.yMMMd().format(t.date)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.amber),
            onPressed: widget.onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
