// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceiptItemAdapter extends TypeAdapter<ReceiptItem> {
  @override
  final int typeId = 8;

  @override
  ReceiptItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptItem(
      name: fields[0] as String,
      price: fields[1] as double,
      quantity: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
