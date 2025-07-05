import 'package:cash_track/main.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
