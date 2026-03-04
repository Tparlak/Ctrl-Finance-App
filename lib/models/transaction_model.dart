import 'package:hive/hive.dart';
import '../data/models/receipt_item.dart';

part 'transaction_model.g.dart';

/// type values: 'income', 'expense', 'transfer'
@HiveType(typeId: 2)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String type; // 'income' | 'expense' | 'transfer'

  @HiveField(3)
  String fromAccountId;

  @HiveField(4)
  String? toAccountId; // only for transfers

  @HiveField(5)
  String? categoryId;

  @HiveField(6)
  String description;

  @HiveField(7)
  DateTime date;

  @HiveField(8)
  String? receiptImagePath;

  @HiveField(9)
  List<ReceiptItem>? receiptItems; // Phase 7

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    required this.description,
    required this.date,
    this.receiptImagePath,
    this.receiptItems,
  });
}
