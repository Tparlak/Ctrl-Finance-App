// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CarExpenseAdapter extends TypeAdapter<CarExpense> {
  @override
  final int typeId = 4;

  @override
  CarExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CarExpense(
      title: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      kilometers: fields[3] as double?,
      notes: fields[4] as String?,
      category: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CarExpense obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.kilometers)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
