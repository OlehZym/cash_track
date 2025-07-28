import 'package:cash_track/widgets/add_transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:cash_track/models/transaction.dart';

class CashTrackPage extends StatefulWidget {
  const CashTrackPage({super.key});

  @override
  State<CashTrackPage> createState() => _CashTrackPageState();
}

class _CashTrackPageState extends State<CashTrackPage> {
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: const Color.fromARGB(255, 0, 38, 255),
        child: const Icon(Icons.add, size: 30),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Баланс: ${balance.toStringAsFixed(2)} грн',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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
  final _textKey = GlobalKey();
  final logger = Logger();

  @override
  void didUpdateWidget(covariant TransactionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.t.note != widget.t.note) {
      _expanded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          _checkOverflow();
        });
      });
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Future.delayed(const Duration(milliseconds: 50), () {
      //     _checkOverflow();
      //     logger.i('_checkOverflow');
      //   });
      // });
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _checkOverflow();
  //   });
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     Future.delayed(const Duration(milliseconds: 100), () {
  //       _checkOverflow();
  //     });
  //   });
  // }

  void _checkOverflow() {
    final textContext = _textKey.currentContext;
    if (textContext == null) return;

    final textRender = textContext.findRenderObject();
    if (textRender is! RenderBox) return;

    final height = textRender.size.height;

    final textStyle = DefaultTextStyle.of(context).style.merge(
          const TextStyle(color: Colors.grey),
        );
    final span = TextSpan(
      text: widget.t.note,
      style: textStyle,
    );

    final tp = TextPainter(
      text: span,
      textDirection:
          Directionality.of(context), // получение направления из контекста
    );
    tp.layout(maxWidth: textRender.size.width);
    final oneLineHeight = tp.height;

    final isOverflow = height < oneLineHeight + 1; // небольшая погрешность
    logger.i(
        'oneLineHeight = $oneLineHeight, height = $height, isOverflow = $isOverflow');
    logger.i('${widget.t.note}');
    if (_isOverflowing != isOverflow) {
      setState(() {
        _isOverflowing = isOverflow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    return Column(
      children: [
        ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t.type == TransactionType.income ? '+' : '-'}${t.amount.toStringAsFixed(2)} грн — ${t.category}',
              ),
              if (t.note != null && t.note!.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        t.note!,
                        key: _textKey,
                        maxLines: _expanded ? null : 1,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
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
        ),
        const Divider(),
      ],
    );
  }
}
