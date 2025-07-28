import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cash_track/models/transaction.dart';

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
              decoration: const InputDecoration(
                labelText: 'Тип',
                labelStyle: TextStyle(color: Colors.green),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              dropdownColor: Colors.white, // Цвет выпадающего меню
              iconEnabledColor: Colors.green, // Цвет стрелочки
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
            ),
            TextFormField(
              controller: _amountController,
              cursorColor: Colors.green, // Цвет курсора
              decoration: const InputDecoration(
                hintText: 'Сумма',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Введите сумму' : null,
            ),
            TextFormField(
              controller: _categoryController,
              cursorColor: Colors.green,
              decoration: const InputDecoration(
                hintText: 'Категория',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Введите категорию' : null,
            ),
            TextFormField(
              controller: _noteController,
              cursorColor: Colors.green,
              decoration: const InputDecoration(
                hintText: 'Комментарий',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _submit,
                  child: Text(
                    widget.existing != null ? 'Сохранить' : 'Добавить',
                    style:
                        const TextStyle(color: Color.fromARGB(255, 47, 202, 0)),
                  ),
                ),
                const SizedBox(width: 26),
                TextButton(
                  onPressed: _close,
                  child: const Text(
                    'Закрыть',
                    style: TextStyle(color: Colors.red),
                  ),
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
