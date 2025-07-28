import 'package:hive/hive.dart';

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
