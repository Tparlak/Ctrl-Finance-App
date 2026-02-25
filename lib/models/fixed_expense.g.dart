// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FixedExpenseAdapter extends TypeAdapter<FixedExpense> {
  @override
  final int typeId = 3;

  @override
  FixedExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FixedExpense(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      billArrivalDate: fields[3] as DateTime,
      dueDate: fields[4] as DateTime,
      paymentDate: fields[5] as DateTime?,
      isPaid: fields[6] as bool,
      accountId: fields[7] as String?,
      monthYear: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FixedExpense obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.billArrivalDate)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.paymentDate)
      ..writeByte(6)
      ..write(obj.isPaid)
      ..writeByte(7)
      ..write(obj.accountId)
      ..writeByte(8)
      ..write(obj.monthYear);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
