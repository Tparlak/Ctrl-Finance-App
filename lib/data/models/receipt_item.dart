import 'package:hive/hive.dart';

part 'receipt_item.g.dart';

@HiveType(typeId: 8)
class ReceiptItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double price;

  @HiveField(2)
  int? quantity;

  ReceiptItem({
    required this.name,
    required this.price,
    this.quantity,
  });
}
